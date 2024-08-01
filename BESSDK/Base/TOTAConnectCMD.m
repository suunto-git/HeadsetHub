//
//  TOTAConnectCMD.m
//  BesAll
//
//  Created by 范羽 on 2021/9/26.
//

#import "TOTAConnectCMD.h"
#import "../utils/ArrayUtil.h"
#import "sha/BesFunc.h"
#import "sha/Sha256.h"
#import "BesSdkConstants.h"
#import "sha/aes.h"
#import "../tools/NSData+XCYCoreTransfor.h"

static Byte B_OP = (Byte) 0x10;
static Byte B_01 = (Byte) 0x01;
static Byte B_02 = (Byte) 0x02;
static Byte B_03 = (Byte) 0x03;
static Byte B_04 = (Byte) 0x04;
static int L_OP = 2;//OPCode length

@implementation TOTAConnectCMD

{
    NSData *random_b;
    NSData *random_a;
    NSData *aes_key;
    NSData *hash_key_b;
    
    NSData *cashData;
    NSData *cashReceiveData;
    NSData *head;
    NSData *tail;
    NSData *dataLen;
    NSData *crc;
}

- (NSData *)totaStartData {
    int rbl = 0;
    rbl = arc4random() % 112 + 16;
    int opl = 5;
    Byte rbb[rbl + opl];
    Byte random_bb[rbl];
    for (int i = 0; i < rbl; i ++) {
        int rb = arc4random() % 255;
        rbb[i + opl] = rb;
        random_bb[i] = rb;
    }
    random_b = [NSData dataWithBytes:random_bb length:rbl];
    NSLog(@"random_b--------%@", random_b);
    rbb[0] = B_01;
    rbb[1] = B_OP;
    NSData *rbld = [ArrayUtil intToLittleBytes:rbl + 1];
    Byte *dByte = (Byte *)[rbld bytes];
    rbb[2] = dByte[0];
    rbb[3] = dByte[1];
    NSData *rblld = [ArrayUtil intToOneBytes:rbl];
    Byte *dlByte = (Byte *)[rblld bytes];
    rbb[4] = dlByte[0];
    NSData *bData = [NSData dataWithBytes:rbb length:rbl + opl];
    return bData;
}

- (NSData *)totaConfirm {
    Byte hbb[hash_key_b.length + L_OP + 2 + 1];
    hbb[0] = B_03;
    hbb[1] = B_OP;
    NSData *hbld = [ArrayUtil intToLittleBytes:hash_key_b.length + 1];
    Byte *dByte = (Byte *)[hbld bytes];
    hbb[2] = dByte[0];
    hbb[3] = dByte[1];
    NSData *hblld = [ArrayUtil intToOneBytes:hash_key_b.length];
    Byte *dlByte = (Byte *)[hblld bytes];
    hbb[4] = dlByte[0];
    
    Byte hash_key_bb[hash_key_b.length];
    [hash_key_b getBytes:hash_key_bb length:hash_key_b.length];
    for (int i = L_OP + 2 + 1; i < hash_key_b.length + L_OP + 2 + 1; i ++) {
        hbb[i] = hash_key_bb[i - (L_OP + 2 + 1)];
    }
    NSData *hData = [NSData dataWithBytes:hbb length:hash_key_b.length + L_OP + 2 + 1];
    return hData;
}

- (NSData *)totaEncryptData:(NSData *)data {
    return [aes encryptWithContent:data password:aes_key];
}

- (NSData *)totaDecodeData:(NSData *)data {
    return [aes decryptWithContent:data password:aes_key];
}

- (NSData *)getTotaV2Packet:(NSData *)data {
    head = [ArrayUtil strToData:@"HEAD"];
    tail = [ArrayUtil strToData:@"TAIL"];
    dataLen = [NSData dataWithBytes:(Byte[]){(Byte)0x00, (Byte)0x00, (Byte)0x00, (Byte)0x00} length:4];
    crc = [NSData dataWithBytes:(Byte[]){(Byte)0x00, (Byte)0x00, (Byte)0x00, (Byte)0x00} length:4];

    NSData *dataLen = [ArrayUtil intToBytes:data.length];
    int32_t crc32 = [data CRC32Value_xcy];
    NSData *crc32Bytes = [NSData dataWithBytes:&crc32 length:4];
    NSData *bytes = [ArrayUtil dataSplic:[ArrayUtil dataMerger:head data2:dataLen] l:data magic:crc32Bytes data:tail];
    return bytes;
}

- (NSData *)setTotaV2PacketData:(NSData *)receiveData decode:(BOOL)decode {
    if (![head isEqualToData:[receiveData subdataWithRange:NSMakeRange(0, head.length)]] || ![tail isEqualToData:[receiveData subdataWithRange:NSMakeRange(receiveData.length - tail.length, tail.length)]]) {
        receiveData = [ArrayUtil dataMerger:cashReceiveData data2:receiveData];
    }
    if (![head isEqualToData:[receiveData subdataWithRange:NSMakeRange(0, head.length)]]) {
        return [NSData dataWithBytes:(Byte[]){(Byte)0x00} length:1];
    }
    dataLen = [receiveData subdataWithRange:NSMakeRange(head.length, dataLen.length)];
    int curDataLen = 0;
    [dataLen getBytes:&curDataLen length:4];
    long curLen = head.length + dataLen.length + curDataLen + crc.length + tail.length;
    if (curLen < receiveData.length) {
        cashReceiveData = [receiveData subdataWithRange:NSMakeRange(curLen, receiveData.length - curLen)];
    }
    NSData *data = [receiveData subdataWithRange:NSMakeRange(head.length + dataLen.length, curDataLen)];
    int32_t crc32 = [data CRC32Value_xcy];
    NSData *mCrc = [NSData dataWithBytes:&crc32 length:4];
    //crc
    crc = [receiveData subdataWithRange:NSMakeRange(head.length + dataLen.length + curDataLen, crc.length)];
    if (![crc isEqualToData:mCrc]) {
        return [NSData dataWithBytes:(Byte[]){(Byte)0x01} length:1];
    }
    //data
    if (cashData != nil && cashData.length > 0) {
        data = [ArrayUtil dataMerger:cashData data2:data];
    }
    if (decode) {
        data = [self totaDecodeData:data];
        NSLog(@"decode--------%@", data);
    }
    
    int cmdCodeLen = 2;
    int cmdDataLen = 2;
    NSData *cmdDataLenD = [data subdataWithRange:NSMakeRange(cmdCodeLen, cmdDataLen)];
    int cmdDataLenL = 0;
    [cmdDataLenD getBytes:&cmdDataLenL length:4];
    NSLog(@"cmdDataLenL--------%@", data);
    if (cmdDataLenL + cmdCodeLen + cmdDataLen > data.length) {
        cashData = data;
        return [NSData dataWithBytes:(Byte[]){(Byte)0x02} length:1];
    }
    return data;
}

//00101000636f6e6e65637420737563636573732e success
//001012007368616b652068616e64206661696c65642e fail
- (int)receiveData:(NSData *)receiveData {
    NSLog(@"tota receive--------%@", [ArrayUtil toHex:receiveData]);
    Byte data[receiveData.length];
    [receiveData getBytes:data length:receiveData.length];
    if (data[0] == B_02 && data[1] == B_OP) {
        //random_a
        Byte random_alb[2];
        int random_al = 0;
        [receiveData getBytes:random_alb range:NSMakeRange(L_OP, 2)];
        [[NSData dataWithBytes:random_alb length:2] getBytes:&random_al length:2];
        
        Byte random_ab[random_al - 1];
        [receiveData getBytes:random_ab range:NSMakeRange(L_OP + 2 + 1, random_al - 1)];
        random_a = [NSData dataWithBytes:random_ab length:random_al - 1];
        NSLog(@"random_a--------%@", random_a);
        //hash_key_b
        NSData *random = [BesFunc func1WithA:random_a b:random_b];
        NSLog(@"random--------%@", random);
        hash_key_b = [Sha256 getSHA256WithData:random];
        NSLog(@"hash_key_b--------%@", hash_key_b);
        aes_key = [BesFunc funcWithHash:hash_key_b];
        return BES_TOTA_CONFIRM;
    } else if (data[0] == (Byte) 0x00 && data[1] == B_OP) {
        if (receiveData.length > 15 && data[12] == (Byte) 0x73 && data[13] == (Byte) 0x75 && data[14] == (Byte) 0x63) {
            return BES_TOTA_SUCCESS;
        } else {
            return BES_TOTA_ERROR;
        }
    }
    return 0;
}

- (void)setAes_key:(NSData *)data {
    aes_key = data;
}

- (NSData *)getAes_key {
    return aes_key;
}

@end
