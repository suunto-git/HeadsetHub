//
//  BesUUID.m
//  BesAll
//
//  Created by 范羽 on 2021/1/30.
//

#import "BesUUID.h"
#import "../tools/NSString+XCYCoreOperation.h"

@implementation BesUUID

//获取已经进入OTA模式，重置后的Services的UUID
+ (CBUUID *)getBesOTAServicesUUID
{
    //Service的UUID
    NSString *dataStr = @"66666666666666666666666666666666";
    NSData *serviceuuidData = [dataStr dataFromHexString_xcy];
    CBUUID *serviceuuid = [CBUUID UUIDWithData:serviceuuidData];
    
    return serviceuuid;
}

//获取已经进入OTA模式，重置后的Characteristics的UUID
+ (CBUUID *)getBesOTACharacteristicsUUID
{
    NSString *dataStr = @"77777777777777777777777777777777";
    NSData *uuidData = [dataStr dataFromHexString_xcy];
    CBUUID *uuid = [CBUUID UUIDWithData:uuidData];
    
    return uuid;
}
//TOTA
+ (CBUUID *)getBesTotaServicesUUID
{
    //Service的UUID
    NSString *dataStr = @"86868686868686868686868686868686";
    NSData *serviceuuidData = [dataStr dataFromHexString_xcy];
    CBUUID *serviceuuid = [CBUUID UUIDWithData:serviceuuidData];
    
    return serviceuuid;
}
//TOTA
+ (CBUUID *)getBesTotaCharacteristicsUUID
{
    NSString *dataStr = @"97979797979797979797979797979797";
    NSData *uuidData = [dataStr dataFromHexString_xcy];
    CBUUID *uuid = [CBUUID UUIDWithData:uuidData];
    
    return uuid;
}

+ (CBUUID *)getBesBleWifiServicesUUID
{
    NSString *dataStr = @"01000100000010008000009078563412";
    NSData *uuidData = [dataStr dataFromHexString_xcy];
    CBUUID *uuid = [CBUUID UUIDWithData:uuidData];

    return uuid;
}

+ (CBUUID *)getBesBleWifiCharacteristicsUUID
{
    NSString *dataStr = @"03000300000010008000009278563412";
    NSData *uuidData = [dataStr dataFromHexString_xcy];
    CBUUID *uuid = [CBUUID UUIDWithData:uuidData];

    return uuid;
}

+ (CBUUID *)getBesBleWifiCharacteristicsUUID_RX
{
    NSString *dataStr = @"02000200000010008000009178563412";
    NSData *uuidData = [dataStr dataFromHexString_xcy];
    CBUUID *uuid = [CBUUID UUIDWithData:uuidData];

    return uuid;
}

@end
