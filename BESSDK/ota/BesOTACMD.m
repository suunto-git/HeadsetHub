//
//  BesOtaCMD.m
//  BesAll
//
//  Created by 范羽 on 2021/2/1.
//

#import "BesOTACMD.h"
#import "../utils/ArrayUtil.h"
#import "BesSdkConstants.h"
#import "BesOTAConstants.h"
#import "../tools/NSData+XCYCoreTransfor.h"
#import "BesOTASetting.h"

    static Byte B_8C = (Byte) 0x8C;
    static Byte B_8D = (Byte) 0x8D;
    static Byte B_80 = (Byte) 0x80;
    static Byte B_81 = (Byte) 0x81;
    static Byte B_85 = (Byte) 0x85;
    static Byte B_86 = (Byte) 0x86;
    static Byte B_87 = (Byte) 0x87;
    static Byte B_82 = (Byte) 0x82;
    static Byte B_83 = (Byte) 0x83;
    static Byte B_88 = (Byte) 0x88;
    static Byte B_84 = (Byte) 0x84;
    static Byte B_8B = (Byte) 0x8B;
    static Byte B_8E = (Byte) 0x8E;
    static Byte B_8F = (Byte) 0x8F;
    static Byte B_90 = (Byte) 0x90;
    static Byte B_91 = (Byte) 0x91;
    static Byte B_92 = (Byte) 0x92;
    static Byte B_93 = (Byte) 0x93;
    static Byte B_95 = (Byte) 0x95;
    static Byte B_99 = (Byte) 0x99;
    static Byte B_9A = (Byte) 0x9A;
    static Byte B_97 = (Byte) 0x97;
    static Byte B_98 = (Byte) 0x98;
    static Byte B_9B = (Byte) 0x9B;
    static Byte B_9C = (Byte) 0x9C;
    static Byte B_9D = (Byte) 0x9D;
    static Byte B_9E = (Byte) 0x9E;

    static int pl = 1; //packetType length
    static int ll = 0; //USER length bytes' length: USER_FLAG == 0 ? 0 : 4

    static int checkBytesLength = 8 * 1024;
    static int BLE_SINGLE_PACKE_MAC_BYTES = 256 ;


@interface BesOtaCMD()
{
    NSData *emptyByte, *magicCode;
    int deviceType;
    NSString *versionMsg;
    int USER_FLAG;
    BOOL isWithoutResponse;
    BOOL isTotaConnect;
    BOOL useTotaV2;
    NSString *deviceId;

    Byte deviceTypeBytes;
    NSString *curVersionLeft;
    NSString *curVersionRight;
    NSString *roleSwitchRandomID;
    NSData *beforeRandomCode;
    int curSendLength;
    int curSendPacketLength;
    int curConfirmLength;
    int beforeSendLength;
    int mMtu;
    NSString *mSwVersion;
    NSString *mHwVersion;
    BOOL crcConfirm;
    int crcConfirmTimes;
    int packetPayload;
    int onePercentBytes;
    NSData *mOtaImageData;
    
    BOOL isGattConnect;
}

@end

@implementation BesOtaCMD

- (void)setOtaUser:(int)user isGatt:(BOOL)isGatt isWithoutRsp:(BOOL)withoutResponse isTota:(BOOL)isTota useTotaV2:(BOOL)totaV2 identifier:(nonnull NSString *)identifier {
    USER_FLAG = user;
    isWithoutResponse = withoutResponse;
    isTotaConnect = isTota;
    isGattConnect = isGatt;
    useTotaV2 = totaV2;
    deviceId = identifier;
    if (isGattConnect) {
        checkBytesLength = 32 * 1024;
    }
    NSLog(@"setOtaUser-----%d", USER_FLAG);
    if (USER_FLAG == 1) {
        ll = 4;
    } else {
        ll = 0;
    }
    roleSwitchRandomID = @"";
    versionMsg = @"";
    emptyByte = [NSData data];
    Byte b1[4] = {0x42, 0x45, 0x53, 0x54};
    magicCode = [NSData dataWithBytes:b1 length:4];
    mMtu = DEFAULT_MTU;
    crcConfirm = false;
    crcConfirmTimes = 0;
    packetPayload = 0;
    onePercentBytes = 0;
}

- (NSData *)getCurrentVersionCMD {
    NSData *pt = [NSData dataWithBytes:(Byte *){&B_8E} length:pl];
    NSData *lBytes = emptyByte;
    if (USER_FLAG  == 1) {
        lBytes = [ArrayUtil intToBytes:magicCode.length];
    }

    NSData *bytes = [ArrayUtil dataSplic:pt l:lBytes magic:magicCode data:emptyByte];
    if (isTotaConnect) {
        return [self convertToTotaCMD:bytes];
    }
    return bytes;
}

- (int)getCurrentDeviceType {
    return deviceType;
}

- (NSString *)getCurrentVersion {
    NSString *v = @"";
    if (deviceType == DEVICE_TYPE_STEREO) {
        v = [NSString stringWithFormat:@"stereo:%@ \n%@", curVersionLeft, versionMsg];
        versionMsg = @"";
    } else if (deviceType == DEVICE_TYPE_TWS_CONNECT_LEFT) {
        v = [NSString stringWithFormat:@"TWS left:%@", curVersionLeft];
    } else if (deviceType == DEVICE_TYPE_TWS_CONNECT_RIGHT) {
        v = [NSString stringWithFormat:@"TWS right:%@", curVersionRight];
    }
    return v;
}

- (NSData *)getOtaProtocolVersionCMD:(BOOL)currentOrLegacy {
    NSData *pt = [NSData dataWithBytes:(Byte *){&B_99} length:pl];
    NSData *lBytes = emptyByte;
    Byte vBytesB[4] = {0x00};
    vBytesB[3] = currentOrLegacy ? 0x01 : 0x00;
    NSData *vBytes = [NSData dataWithBytes:vBytesB length:4];
    if (USER_FLAG  == 1) {
        lBytes = [ArrayUtil intToBytes:vBytes.length];
    }
    NSData *bytes = [ArrayUtil dataSplic:pt l:lBytes magic:emptyByte data:vBytes];
    if (isTotaConnect) {
        return [self convertToTotaCMD:bytes];
    }
    return bytes;
}

- (NSData *)getSetOtaUserCMD:(int)curUser {
    NSData *pt = [NSData dataWithBytes:(Byte *){&B_97} length:pl];
    NSData *lBytes = emptyByte;
    Byte vBytesB[1] = {0x00};
    if (curUser == 1) {
        vBytesB[0] = 0x01;
    } else if (curUser == 2) {
        vBytesB[0] = 0x02;
    } else if (curUser == 3) {
        vBytesB[0] = 0x03;
    } else if (curUser == 4) {
        vBytesB[0] = 0x04;
    } else if (curUser == 5) {
        vBytesB[0] = 0x05;
    } else if (curUser == 6) {
        vBytesB[0] = 0x06;
    }
    NSData *vBytes = [NSData dataWithBytes:vBytesB length:1];

    if (USER_FLAG  == 1) {
        lBytes = [ArrayUtil intToBytes:vBytes.length];
    }
    NSData *bytes = [ArrayUtil dataSplic:pt l:lBytes magic:emptyByte data:vBytes];
    if (isTotaConnect) {
        return [self convertToTotaCMD:bytes];
    }
    return bytes;
}
//0x01: apply NORMAL MODE
//0x02: apply FAST MODE
- (NSData *)getSetUpgrateTypeCMD:(int)curUpgateType {
    NSData *pt = [NSData dataWithBytes:(Byte *){&B_9D} length:pl];
    NSData *lBytes = emptyByte;
    Byte vBytesB[1] = {0x01};
    if (curUpgateType == 1) {
        vBytesB[0] = 0x01;
    } else if (curUpgateType == 2) {
        vBytesB[0] = 0x02;
    }
    NSData *vBytes = [NSData dataWithBytes:vBytesB length:1];
    if (USER_FLAG  == 1) {
        lBytes = [ArrayUtil intToBytes:vBytes.length];
    }
    NSData *bytes = [ArrayUtil dataSplic:pt l:lBytes magic:emptyByte data:vBytes];
    if (isTotaConnect) {
        return [self convertToTotaCMD:bytes];
    }
    return bytes;
}


- (NSString *)getRoleSwitchRandomID {
    return roleSwitchRandomID;
}


- (NSData *)getROLESwitchRandomIDCMD {
    NSData *pt = [NSData dataWithBytes:(Byte *){&B_9B} length:pl];
    NSData *lBytes = emptyByte;
    if (USER_FLAG  == 1) {
        lBytes = [ArrayUtil intToBytes:0];
    }
    NSData *bytes = [ArrayUtil dataSplic:pt l:lBytes magic:emptyByte data:emptyByte];
    if (isTotaConnect) {
        return [self convertToTotaCMD:bytes];
    }
    return bytes;
}

- (NSData *)getSelectSideCMD {
    NSData *pt = [NSData dataWithBytes:(Byte *){&B_90} length:pl];
    NSData *lBytes = emptyByte;
    if (USER_FLAG  == 1) {
        lBytes = [ArrayUtil intToBytes:1];
    }
    Byte b1[4] = {deviceTypeBytes};
    NSData *bytes = [ArrayUtil dataSplic:pt l:lBytes magic:emptyByte data:[NSData dataWithBytes:b1 length:1]];
    if (isTotaConnect) {
        return [self convertToTotaCMD:bytes];
    }
    return bytes;
}

- (NSData *)getCheckBreakPointCMD {
    NSData *pt = [NSData dataWithBytes:(Byte *){&B_8C} length:pl];
    NSData *lBytes = emptyByte;
    Byte randomCodeB[32] = {0x00};
    NSData *randomCode = [NSData dataWithBytes:randomCodeB length:32];
    Byte segmentBytesB[4] = {0x01, 0x02, 0x03, 0x04};
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults valueForKey:[NSString stringWithFormat:@"%@%@", BES_OTA_RANDOM_CODE_LEFT, deviceId]]) {
        randomCode = [ArrayUtil toData:[defaults valueForKey:[NSString stringWithFormat:@"%@%@", BES_OTA_RANDOM_CODE_LEFT, deviceId]]];
    }
    beforeRandomCode = randomCode;
    NSData *segmentBytes = [NSData dataWithBytes:segmentBytesB length:4];
    
    NSMutableData *subData = [[NSMutableData alloc] initWithCapacity:1];
    [subData appendData:randomCode];
    [subData appendData:segmentBytes];
    int32_t crc32 = [subData CRC32Value_xcy];
    NSData *crc32Bytes = [NSData dataWithBytes:&crc32 length:4];
    
    int dataL = (int)(randomCode.length + segmentBytes.length + crc32Bytes.length);
    if (USER_FLAG  == 1) {
        lBytes = [ArrayUtil intToBytes:magicCode.length + dataL];
    }
    NSMutableData *fullData = [[NSMutableData alloc] initWithCapacity:1];
    [fullData appendData:randomCode];
    [fullData appendData:segmentBytes];
    [fullData appendData:crc32Bytes];
    NSData *bytes = [ArrayUtil dataSplic:pt l:lBytes magic:magicCode data:fullData];
    if (isTotaConnect) {
        return [self convertToTotaCMD:bytes];
    }
    return bytes;
}

- (NSData *)getStartOTAPacketCMD:(NSData *)data {
    NSData *pt = [NSData dataWithBytes:(Byte *){&B_80} length:pl];
    NSData *lBytes = emptyByte;
    NSUInteger dataLength = data.length;
    NSData *imageSize = [NSData dataWithBytes:&dataLength length:4];
    NSData *subData = [data subdataWithRange:NSMakeRange(0, data.length)];
    int32_t crc32 = [subData CRC32Value_xcy];
    NSData *crc32OfImage = [NSData dataWithBytes:&crc32 length:4];
    if (USER_FLAG  == 1) {
        lBytes = [ArrayUtil intToBytes:magicCode.length + imageSize.length + crc32OfImage.length];
    }
    NSMutableData *fullData = [[NSMutableData alloc] initWithCapacity:1];
    [fullData appendData:imageSize];
    [fullData appendData:crc32OfImage];
    NSData *bytes = [ArrayUtil dataSplic:pt l:lBytes magic:magicCode data:fullData];
    if (isTotaConnect) {
        return [self convertToTotaCMD:bytes];
    }
    return bytes;
}

- (NSData *)getOTAConfigureCMD:(NSData *)data {
    NSData *pt = [NSData dataWithBytes:(Byte *){&B_86} length:pl];
    NSData *lBytes = emptyByte;
    BesOTASetting *setting = [[BesOTASetting alloc] init];
    [setting updateFlashOffsetData:[data subdataWithRange:NSMakeRange(data.length - 4, 4)]];
    NSData *settingData = [setting getTotalSettingData];
    if (USER_FLAG  == 1) {
        lBytes = [ArrayUtil intToBytes:settingData.length];
    }
    NSData *bytes = [ArrayUtil dataSplic:pt l:lBytes magic:emptyByte data:settingData];
    if (isTotaConnect) {
        return [self convertToTotaCMD:bytes];
    }
    return bytes;
}

- (NSData *)getDataPacketCMD:(NSData *)data {
    if (onePercentBytes == 0) {
        [self readlocalImageData:(int)data.length];
    }
    mOtaImageData = data;
    NSData *lBytes = emptyByte;
    if (crcConfirm) {
        crcConfirm = false;
        NSData *crcPt = [NSData dataWithBytes:(Byte *){&B_82} length:pl];
        NSData *crc32OfSegment = [self getCrc32OfSegment:data];
        int crcDataL = (int)magicCode.length + (int)crc32OfSegment.length;
        if (USER_FLAG == 1) {
            lBytes = [ArrayUtil intToBytes:crcDataL];
        }
        NSData *bytes = [ArrayUtil dataSplic:crcPt l:lBytes magic:magicCode data:crc32OfSegment];
        if (isTotaConnect) {
            return [self convertToTotaCMD:bytes];
        }
        return bytes;
    }
    if (beforeSendLength == data.length || curSendLength == data.length) {
        NSData *wholeCrcPt = [NSData dataWithBytes:(Byte *){&B_88} length:pl];
        if (USER_FLAG == 1) {
            lBytes = [ArrayUtil intToBytes:0];
        }
        NSData *bytes = [ArrayUtil dataSplic:wholeCrcPt l:lBytes magic:emptyByte data:emptyByte];
        if (isTotaConnect) {
            return [self convertToTotaCMD:bytes];
        }
        return bytes;
    }
    
    NSData *pt = [NSData dataWithBytes:(Byte *){&B_85} length:pl];
    NSData *packetData = [self getDataPacket:data];
    int dataL = (int)packetData.length;
    if (USER_FLAG  == 1) {
        lBytes = [ArrayUtil intToBytes:dataL];
    }
    NSData *bytes = [ArrayUtil dataSplic:pt l:lBytes magic:emptyByte data:packetData];
    if (isTotaConnect) {
        return [self convertToTotaCMD:bytes];
    }
    return bytes;
}

- (NSData *)getDataPacket:(NSData *)mOtaImageData {
//    if (USER_FLAG == 1 && isWithoutResponse) {
        //特定长度校验
        if (curSendLength + packetPayload > mOtaImageData.length) {
            curSendPacketLength = (int)mOtaImageData.length - curSendLength;
            crcConfirm = true;
        }
        else if (beforeSendLength > 0 && crcConfirmTimes == 0) {
            crcConfirmTimes = beforeSendLength / checkBytesLength;
            curSendPacketLength = packetPayload;
        }
        else if (curSendLength + packetPayload > checkBytesLength * (crcConfirmTimes + 1) || curSendLength + packetPayload == checkBytesLength * (crcConfirmTimes + 1)) {
            curSendPacketLength = checkBytesLength * (crcConfirmTimes + 1) - curSendLength;
            crcConfirm = true;
        }
        else {
            curSendPacketLength = packetPayload;
        }
        if (curSendLength + curSendPacketLength == (crcConfirmTimes + 1) * checkBytesLength) {
            crcConfirm = true;
        }
//    } else {
//        //每1%校验
//        if (beforeSendLength > 0 && crcConfirmTimes == 0) {
//            crcConfirmTimes = beforeSendLength / onePercentBytes;
//            curSendPacketLength = packetPayload;
//        }
//        else if (curSendLength + packetPayload > onePercentBytes * (crcConfirmTimes + 1) || curSendLength + packetPayload == onePercentBytes * (crcConfirmTimes + 1)) {
//            curSendPacketLength = onePercentBytes * (crcConfirmTimes + 1) - curSendLength;
//            crcConfirm = true;
//        }
//        else if (curSendLength + packetPayload > mOtaImageData.length) {
//            curSendPacketLength = (int)mOtaImageData.length - curSendLength;
//            crcConfirm = true;
//        }
//        else {
//            curSendPacketLength = packetPayload;
//        }
//    }
    return [mOtaImageData subdataWithRange:NSMakeRange(curSendLength, curSendPacketLength)];
}

- (void)readlocalImageData:(int)imageSize {
    onePercentBytes = [self calculateBLEOnePercentBytes:imageSize];
}

- (int)calculateBLEOnePercentBytes:(int)imageSize {
    int onePercentBytesL = imageSize / 100;
    if (imageSize < BLE_SINGLE_PACKE_MAC_BYTES) {
        onePercentBytesL = imageSize;
    }
    else {
        int rightBytes = 0;
        if (onePercentBytesL < BLE_SINGLE_PACKE_MAC_BYTES) {
            rightBytes = BLE_SINGLE_PACKE_MAC_BYTES - onePercentBytesL;
        }
        else {
            rightBytes = BLE_SINGLE_PACKE_MAC_BYTES - onePercentBytesL % BLE_SINGLE_PACKE_MAC_BYTES;
        }
        if (rightBytes != 0) {
            onePercentBytesL = onePercentBytesL + rightBytes;
        }
    }
    if (onePercentBytesL < 4 * 1024) {
        onePercentBytesL = 4 * 1024;
    }
    int tempCount = (imageSize + onePercentBytesL - 1) / onePercentBytesL;
    NSLog(@"imageSize---%d----onePercentBytes---%d-----crc total Count----%d", imageSize, onePercentBytesL, tempCount);
    return onePercentBytesL;
}

- (NSData *)getCrc32OfSegment:(NSData *)data {
    NSData *crcSegmentData;
//    if (USER_FLAG == 1 && isWithoutResponse) {
        //特定长度校验
        crcSegmentData = [data subdataWithRange:NSMakeRange(checkBytesLength * crcConfirmTimes, curSendLength - checkBytesLength * crcConfirmTimes)];
//    } else {
//        //每1%校验
//        crcSegmentData = [data subdataWithRange:NSMakeRange(onePercentBytes * crcConfirmTimes, curSendLength - onePercentBytes * crcConfirmTimes)];
//    }
    int32_t crc32 = [crcSegmentData CRC32Value_xcy];
    NSData *crc32Bytes = [NSData dataWithBytes:&crc32 length:4];
    return crc32Bytes;
}

- (NSData *)getImageOverwritingConfirmationPacketCMD {
    NSData *pt = [NSData dataWithBytes:(Byte *){&B_92} length:pl];
    NSData *lBytes = emptyByte;
    if (USER_FLAG == 1) {
        lBytes = [ArrayUtil intToBytes:magicCode.length];
    }
    NSData *bytes = [ArrayUtil dataSplic:pt l:lBytes magic:magicCode data:emptyByte];
    if (isTotaConnect) {
        return [self convertToTotaCMD:bytes];
    }
    return bytes;
}



- (void)notifySuccess {
    NSLog(@"notifySuccess---------%d", curSendPacketLength);
    curSendLength += curSendPacketLength;
}

- (int)receiveData:(NSData *)receiveData curOtaResult:(int)curOtaResult {
    if (receiveData == nil || receiveData.length < 1) {
        NSLog(@"receiveData == nil || receiveData.length < 1");
        return 0;
    }
    Byte data[receiveData.length];
    [receiveData getBytes:data length:receiveData.length];
    if (data[0] == B_8F) {
        int typeL = pl + ll + (int)magicCode.length;
        deviceTypeBytes = data[typeL];
        if (deviceTypeBytes == 0x00) {
            deviceType = DEVICE_TYPE_STEREO;
            if (USER_FLAG == 1) {
                int lbl = 0;
                NSData *lb = [receiveData subdataWithRange:NSMakeRange(pl, ll)];
                [lb getBytes:&lbl length:4];
                if (lbl > 15) {
                    NSData *msgData = [receiveData subdataWithRange:NSMakeRange(typeL + 8 + 1, receiveData.length - (typeL + 8 + 1))];
                    versionMsg = [[[NSString alloc] initWithBytes:msgData.bytes length:msgData.length encoding:NSASCIIStringEncoding] stringByReplacingOccurrencesOfString:@"-" withString:@" "];
                }
            }
            
        } else if (deviceTypeBytes == 0x01) {
            deviceType = DEVICE_TYPE_TWS_CONNECT_LEFT;
        } else if (deviceTypeBytes == 0x02) {
            deviceType = DEVICE_TYPE_TWS_CONNECT_RIGHT;
        }
        int vl = 4;
        NSData *curVersionLeftData = [receiveData subdataWithRange:NSMakeRange(typeL + 1, vl)];
        NSData *curVersionRightData = [receiveData subdataWithRange:NSMakeRange(typeL + 1 + vl, vl)];
        curVersionLeft = [ArrayUtil dealWithString:[ArrayUtil toHex:curVersionLeftData]];
        curVersionRight = [ArrayUtil dealWithString:[ArrayUtil toHex:curVersionRightData]];
        return [self getReturnResultWith:OTA_CMD_GET_HW_INFO curState:curOtaResult];
    }
    else if (data[0] == B_91) {
        int confirmL = pl + ll;
        if (data[confirmL] == CONFIRM_BYTE_PASS) {
            return [self getReturnResultWith:OTA_CMD_SELECT_SIDE_OK curState:curOtaResult];
        }
        return [self getReturnResultWith:OTA_CMD_SELECT_SIDE_ERROR curState:curOtaResult];
    }
    else if (data[0] == B_8D) {
        int breakpointL = pl + ll;
        Byte bpLengthBytes[4];
        [receiveData getBytes:bpLengthBytes range:NSMakeRange(breakpointL, 4)];
        [[NSData dataWithBytes:bpLengthBytes length:4] getBytes:&curSendLength length:4];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if (curSendLength > 0) {
            beforeSendLength = curSendLength;
            curConfirmLength = curSendLength;
            if ([defaults valueForKey:BES_OTA_CURRENT_MTU]) {
                mMtu = [[defaults valueForKey:BES_OTA_CURRENT_MTU] intValue];
                NSLog(@"mtu--------%d", mMtu);
                packetPayload = mMtu - pl - ll;
                if (useTotaV2) {
                    packetPayload = (packetPayload - 20) / 16 * 15 + 16;
                }
                curSendPacketLength = packetPayload;
            }
            return [self getReturnResultWith:OTA_CMD_BREAKPOINT_CHECK curState:curOtaResult];
        } else {
            Byte bpRandomBytes[32];
            [receiveData getBytes:bpRandomBytes range:NSMakeRange(breakpointL + 4, 32)];
            [defaults setObject:[ArrayUtil toHex:[NSData dataWithBytes:bpRandomBytes length:32]] forKey:[NSString stringWithFormat:@"%@%@", BES_OTA_RANDOM_CODE_LEFT, deviceId]];
            NSLog(@"bpRandomBytes--------%@", [ArrayUtil toHex:[NSData dataWithBytes:bpRandomBytes length:32]]);
            return [self getReturnResultWith:OTA_CMD_BREAKPOINT_CHECK_80 curState:curOtaResult];
        }
    }
    else if (data[0] == B_81) {
        int vl = pl + ll + (int)magicCode.length;
        NSData *swVersionBytes = [receiveData subdataWithRange:NSMakeRange(vl, 2)];
        mSwVersion = [ArrayUtil dealWithString:[ArrayUtil toHex:swVersionBytes]];
        NSLog(@"mSwVersion-------%@", mSwVersion);
        NSData *hwVersionBytes = [receiveData subdataWithRange:NSMakeRange(vl + swVersionBytes.length, 2)];
        mHwVersion = [ArrayUtil dealWithString:[ArrayUtil toHex:hwVersionBytes]];
        NSLog(@"mHwVersion-------%@", mHwVersion);

        NSData *mtuBytes = [receiveData subdataWithRange:NSMakeRange(vl + swVersionBytes.length + hwVersionBytes.length, 2)];
        NSUInteger maxLength = 0;
        [mtuBytes getBytes:&maxLength length:2];
        if (maxLength == 0 ||
            maxLength > DEFAULT_MTU) {
            maxLength = DEFAULT_MTU;
        }
        NSLog(@"mtu----------%ld", maxLength);
        mMtu = (int)maxLength;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:[NSString stringWithFormat:@"%lu", (unsigned long)maxLength] forKey:BES_OTA_CURRENT_MTU];
        packetPayload = mMtu - pl - ll;
        if (useTotaV2) {
            packetPayload = (packetPayload - 20) / 16 * 15 + 16;
        }
        return [self getReturnResultWith:OTA_CMD_BREAKPOINT_CHECK curState:curOtaResult];
    }
    else if (data[0] == B_87) {
        int confirmL = pl + ll;
        if (data[confirmL] == CONFIRM_BYTE_PASS) {
            return OTA_CMD_SEND_CONFIGURE_OK;
        }
        return [self getReturnResultWith:OTA_CMD_SEND_CONFIGURE_ERROR curState:curOtaResult];
    }
    else if (data[0] == B_83) {
        int confirmL = pl + ll;
        if (data[confirmL] == CONFIRM_BYTE_PASS) {
            crcConfirmTimes ++;
            curConfirmLength = curSendLength;
            crcConfirm = false;
            if (curSendLength == mOtaImageData.length) {
                return OTA_CMD_WHOLE_CRC_CHECK;
            }
            return OTA_CMD_CRC_CHECK_PACKAGE_OK;
        }
        return OTA_CMD_CRC_CHECK_PACKAGE_ERROR;
    }
    else if (data[0] == B_84) {
        int confirmL = pl + ll;
        if (data[confirmL] == CONFIRM_BYTE_PASS) {
            return OTA_CMD_WHOLE_CRC_CHECK_OK;
        }
        return OTA_CMD_WHOLE_CRC_CHECK_ERROR;
    }
    else if (data[0] == B_93) {
        int confirmL = pl + ll;
        if (data[confirmL] == CONFIRM_BYTE_PASS) {
            return [self getReturnResultWith:OTA_CMD_IMAGE_OVER_CONFIRM curState:curOtaResult];
        }
        return [self getReturnResultWith:OTA_CMD_IMAGE_OVER_CONFIRM_ERROR curState:curOtaResult];
    }
    else if (data[0] == B_95) {
        return OTA_CMD_DISCONNECT;
    }
    else if (data[0] == B_9A) {
        USER_FLAG = 1;
        [self setOtaUser:USER_FLAG isGatt:isGattConnect isWithoutRsp:isWithoutResponse isTota:isTotaConnect useTotaV2:useTotaV2 identifier:deviceId];
        return [self getReturnResultWith:OTA_CMD_GET_PROTOCOL_VERSION curState:curOtaResult];
    }
    else if (data[0] == B_98) {
        int confirmL = pl + ll;
        if (data[confirmL] == CONFIRM_BYTE_PASS) {
            return OTA_CMD_SET_OAT_USER_OK;
        }
        return [self getReturnResultWith:OTA_CMD_SET_OAT_USER_ERROR curState:curOtaResult];
    }
    else if (data[0] == B_9E) {
        int confirmL = pl + ll;
        if (data[confirmL] == 0x01) {
            return OTA_CMD_SET_UPGRADE_TYPE_NORMAL;
        } else if (data[confirmL] == 0x02) {
            return OTA_CMD_SET_UPGRADE_TYPE_FAST;
        }
    }
    else if (data[0] == B_9C) {
        NSString *dataStr = [ArrayUtil toHex:receiveData];
        roleSwitchRandomID = [dataStr substringWithRange:NSMakeRange(dataStr.length - 4, 4)];
        return OTA_CMD_ROLESWITCH_GET_RANDOMID;
    }
    else if (data[0] == B_8B) {
        return OTA_CMD_SEND_OTA_DATA;
    }
    else {
        NSLog(@"receiveData: error");
    }

    
    return 0;
}

- (void)crcConfirmError {
    curSendLength = curConfirmLength;
}

- (NSData *)convertToTotaCMD:(NSData *)data {
    int totaBytesL = (int)data.length + 2 + 2;
    Byte totaBytes[totaBytesL];
    NSData *dataDL = [ArrayUtil intToLittleBytes:data.length];
    Byte dataDB[dataDL.length];
    [dataDL getBytes:dataDB length:dataDL.length];
    totaBytes[0] = (Byte) 0x00;
    totaBytes[1] = (Byte) 0x90;
    totaBytes[2] = dataDB[0];
    totaBytes[3] = dataDB[1];
    Byte dataB[data.length];
    [data getBytes:dataB length:data.length];
    for (int i = 4; i < totaBytesL; i ++) {
        totaBytes[i] = dataB[i - 4];
    }
    return [NSData dataWithBytes:totaBytes length:totaBytesL];
}

- (int)getReturnResultWith:(int)state curState:(int)curState {
    if (state < curState) {
        return OTA_CMD_RETURN;
    }
    return state;
}

- (NSString *)besOtaProgress:(int)total {
    if (total == 0) {
        return @"0.00";
    }
    double v1 = curSendLength * 100;
    return [NSString stringWithFormat:@"%0.2f", v1 / total];
}

- (void)setCrcConfirmState:(BOOL)state {
    crcConfirm = state;
}

@end
