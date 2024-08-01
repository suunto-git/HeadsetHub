//
//  BesOtaSetting.m
//  BesAll
//
//  Created by 范羽 on 2021/2/8.
//

#import "BesOTASetting.h"
#import "../tools/NSString+XCYCoreOperation.h"
#import "../tools/NSData+XCYCoreTransfor.h"
#import "BesOTAConstants.h"


@implementation BesOTASetting

- (void)updateFlashOffsetData:(NSData *)offsetData {
    _flashOffsetData = offsetData;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.isClearData = DEFAULT_CLEAR_USER_DATA;
    self.isBTAddrOpen = DEFAULT_UPDATE_BT_ADDRESS;
    self.isBTNameOpen = DEFAULT_UPDATE_BT_NAME;
    self.isBLEAddrOpen = DEFAULT_UPDATE_BLE_ADDRESS;
    self.isBLENameOpen = DEFAULT_UPDATE_BLE_NAME;
    
    if ([defaults valueForKey:KEY_OTA_CONFIG_CLEAR_USER_DATA]) {
        self.isClearData = [[defaults valueForKey:KEY_OTA_CONFIG_CLEAR_USER_DATA] isEqualToString:@"YES"] ? YES : NO;
    }
    if ([defaults valueForKey:KEY_OTA_CONFIG_UPDATE_BT_ADDRESS] && [[defaults valueForKey:KEY_OTA_CONFIG_UPDATE_BT_ADDRESS] isEqualToString:@"YES"] && [defaults valueForKey:KEY_OTA_CONFIG_UPDATE_BT_ADDRESS_VALUE]) {
        self.isBTAddrOpen = YES;
        self.btAddr = [defaults valueForKey:KEY_OTA_CONFIG_UPDATE_BT_ADDRESS_VALUE];
    }
    if ([defaults valueForKey:KEY_OTA_CONFIG_UPDATE_BT_NAME] && [[defaults valueForKey:KEY_OTA_CONFIG_UPDATE_BT_NAME] isEqualToString:@"YES"] && [defaults valueForKey:KEY_OTA_CONFIG_UPDATE_BT_NAME_VALUE]) {
        self.isBTNameOpen = YES;
        self.btName = [defaults valueForKey:KEY_OTA_CONFIG_UPDATE_BT_NAME_VALUE];
    }
    if ([defaults valueForKey:KEY_OTA_CONFIG_UPDATE_BLE_ADDRESS] && [[defaults valueForKey:KEY_OTA_CONFIG_UPDATE_BLE_ADDRESS] isEqualToString:@"YES"] && [defaults valueForKey:KEY_OTA_CONFIG_UPDATE_BLE_ADDRESS_VALUE]) {
        self.isBLEAddrOpen = YES;
        self.bleAddr = [defaults valueForKey:KEY_OTA_CONFIG_UPDATE_BLE_ADDRESS_VALUE];
    }
    if ([defaults valueForKey:KEY_OTA_CONFIG_UPDATE_BLE_NAME] && [[defaults valueForKey:KEY_OTA_CONFIG_UPDATE_BLE_NAME] isEqualToString:@"YES"] && [defaults valueForKey:KEY_OTA_CONFIG_UPDATE_BLE_NAME_VALUE]) {
        self.isBLENameOpen = YES;
        self.bleName = [defaults valueForKey:KEY_OTA_CONFIG_UPDATE_BLE_NAME_VALUE];
    }
}

- (NSData *)getFlashOffsetData {

    NSData *subData = [_flashOffsetData subdataWithRange:NSMakeRange(0, 3)];
    NSMutableData *data = [NSMutableData dataWithData:subData];
    [data appendData:[@"00" dataFromHexString_xcy]];
    return data;
}

- (NSData *)getSwitchData {
    
    int switchInt = 0;
    NSNumber *switchNumber = [NSNumber numberWithBool:_isBLEAddrOpen];
    int subInt = [switchNumber intValue];
    switchInt = subInt;
    
    switchNumber = [NSNumber numberWithBool:_isBTAddrOpen];
    subInt = [switchNumber intValue];
    switchInt = (switchInt << 1) + subInt;
    
    switchNumber = [NSNumber numberWithBool:_isBLENameOpen];
    subInt = [switchNumber intValue];
    switchInt = (switchInt << 1) + subInt;
    
    switchNumber = [NSNumber numberWithBool:_isBTNameOpen];
    subInt = [switchNumber intValue];
    switchInt = (switchInt << 1) + subInt;
    
    switchNumber = [NSNumber numberWithBool:_isClearData];
    subInt = [switchNumber intValue];
    switchInt = (switchInt << 1) + subInt;
    
    NSData *data = [NSData dataWithBytes:&switchInt length:1];
    NSMutableData *paddingData = [[NSMutableData alloc] initWithLength:3];
    NSMutableData *fullData = [[NSMutableData alloc] initWithCapacity:1];
    [fullData appendData:data];
    [fullData appendData:paddingData];
    
    return fullData;
}

- (NSData *)getBTAddrData {
    
    if (!_isBTAddrOpen) {
    
        NSMutableData *defaultdata = [[NSMutableData alloc] initWithLength:6];
        return defaultdata;
    }
    
    NSData *data = [_btAddr dataFromHexString_xcy];
    NSMutableData *fullData = [[NSMutableData alloc] initWithData:data];
    NSMutableData *paddingData = [[NSMutableData alloc] initWithLength:(6-data.length)];
    [fullData appendData:paddingData];
    
    return fullData;
}

- (NSData *)getBTNameData {
    
    if (!_isBTNameOpen) {
        
        return [[NSMutableData alloc] initWithLength:32];
    }
    
    NSData *data = [_btName dataUsingEncoding:NSASCIIStringEncoding];
    NSMutableData *fullData = [[NSMutableData alloc] initWithData:data];
    NSMutableData *paddingData = [[NSMutableData alloc] initWithLength:(32-data.length)];
    [fullData appendData:paddingData];
    
    return fullData;
    
}

- (NSData *)getBLEAddrData {
    
    if (!_isBLEAddrOpen) {
        
        NSMutableData *defaultdata = [[NSMutableData alloc] initWithLength:6];
        return defaultdata;
    }
    
    NSData *data = [_bleAddr dataFromHexString_xcy];
    NSMutableData *fullData = [[NSMutableData alloc] initWithData:data];
    NSMutableData *paddingData = [[NSMutableData alloc] initWithLength:(6 - data.length)];
    [fullData appendData:paddingData];
    
    return fullData;
}

- (NSData *)getBLENameData {
    
    if (!_isBLENameOpen) {
        
        return [[NSMutableData alloc] initWithLength:32];
    }
    
    NSData *data = [_bleName dataUsingEncoding:NSASCIIStringEncoding];
    
    NSMutableData *fullData = [[NSMutableData alloc] initWithData:data];
    NSMutableData *paddingData = [[NSMutableData alloc] initWithLength:(32 - data.length)];
    [fullData appendData:paddingData];
    
    return fullData;
}

- (NSData *)getTotalSettingData {
    NSData *switchData = [self getSwitchData];
    NSData *offSetData = [self getFlashOffsetData];
    NSData *btAddrData = [self getBTAddrData];
    NSData *btNameData = [self getBTNameData];
    NSData *bleAddrData = [self getBLEAddrData];
    NSData *bleNameData = [self getBLENameData];
    
    NSMutableData *infoData = [[NSMutableData alloc] initWithCapacity:1];
    [infoData appendData:offSetData];
    [infoData appendData:switchData];
    [infoData appendData:btNameData];
    [infoData appendData:bleNameData];
    [infoData appendData:btAddrData];
    [infoData appendData:bleAddrData];
    
    //
    NSInteger totalLength = infoData.length + 4;
    NSData *lengthData = [NSData dataWithBytes:&totalLength length:4];
    
    NSMutableData *totalData = [[NSMutableData alloc] initWithCapacity:1];
    [totalData appendData:lengthData];
    [totalData appendData:infoData];
    
    //
    int32_t crc32 = [totalData CRC32Value_xcy];
    NSData *crc32Data = [NSData dataWithBytes:&crc32 length:4];
    
    [totalData appendData:crc32Data];

    return totalData;
}

@end
