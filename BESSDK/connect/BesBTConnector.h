//
//  BesBTConnector.h
//  BesAll
//
//  Created by 范羽 on 2021/1/22.
//

#import <Foundation/Foundation.h>
#import "../Base/BesUUID.h"
#import "BesSdkConstants.h"
#import "../Base/BesServiceConfig.h"

@interface BesBTConnector : NSObject

+ (instancetype)shareInstance;
- (void)destroy;
- (void)startScanWithServices:(NSArray<CBUUID *>*)services options:(NSDictionary<NSString *,id> *)options isGatt:(BOOL)isGatt;
- (void)stopScan;
- (void)connectDecvice:(BesServiceConfig *)config;
- (void)disconnect:(CBPeripheral *)device;
- (void)sendData:(NSData *)data device:(CBPeripheral *)device;
- (void)sendDataWithOutResponse:(NSData *)data device:(CBPeripheral *)device;
- (NSArray<CBPeripheral *> *)getCurConnectDevices;
- (BesConnectState)getDeviceConnectState:(BesServiceConfig *)config;
- (void)saveTotaAesKey:(NSData *)data device:(CBPeripheral *)device;
- (NSData *)getTotaAesKey:(CBPeripheral *)device;

@end

