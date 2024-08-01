//
//  aes.m
//  BesAll
//
//  Created by 范羽 on 2021/9/28.
//

#import "aes.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>

@implementation aes

+ (NSData *)encryptWithContent:(NSData *)content password:(NSData *)password {
//    NSLog(@"password------%@", password);
//    NSLog(@"content------%@", content);
    int inLen = (int)content.length;
    int finLen = inLen % 16 != 0 ? inLen + 16 - (inLen % 16) : inLen;
    Byte ob[inLen];
    [content getBytes:ob length:inLen];
    Byte nb[finLen];
    for (int i = 0; i < inLen; i ++) {
        nb[i] = ob[i];
    }
    for (int i = inLen; i < finLen; i ++) {
        nb[i] = (Byte) 0x00;
    }
    content = [NSData dataWithBytes:nb length:finLen];
//    NSLog(@"content------%@", content);
    NSUInteger dataLength = content.length;
    size_t bufferSize = dataLength;
    void *buffer = malloc(bufferSize);
    size_t numBytesEncrypted = 0;
    Byte iv[16] = {(Byte) 0x00, (Byte) 0x01, (Byte) 0x02, (Byte) 0x03, (Byte) 0x04, (Byte) 0x05, (Byte) 0x06, (Byte) 0x07, (Byte) 0x08, (Byte) 0x09, (Byte) 0x0a, (Byte) 0x0b, (Byte) 0x0c, (Byte) 0x0d, (Byte) 0x0e, (Byte) 0x0f};

    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES, 0, password.bytes, password.length, iv, content.bytes, dataLength, buffer, bufferSize, &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
    }
    free(buffer);
    return nil;
}

+ (NSData *)decryptWithContent:(NSData *)content password:(NSData *)password {
    NSUInteger dataLength = content.length;
    size_t bufferSize = dataLength;
    void *buffer = malloc(bufferSize);
    size_t numBytesEncrypted = 0;
    Byte iv[16] = {(Byte) 0x00, (Byte) 0x01, (Byte) 0x02, (Byte) 0x03, (Byte) 0x04, (Byte) 0x05, (Byte) 0x06, (Byte) 0x07, (Byte) 0x08, (Byte) 0x09, (Byte) 0x0a, (Byte) 0x0b, (Byte) 0x0c, (Byte) 0x0d, (Byte) 0x0e, (Byte) 0x0f};

    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES, 0, password.bytes, password.length, iv, content.bytes, dataLength, buffer, bufferSize, &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
    }
    free(buffer);
    return nil;
}

@end
