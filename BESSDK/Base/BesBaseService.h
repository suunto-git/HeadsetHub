//
//  BesBaseService.h
//  BesAll
//
//  Created by 范羽 on 2021/1/29.
//

#import <Foundation/Foundation.h>
#import "../connect/BesBTConnector.h"
#import "BesServiceConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface BesBaseService : NSObject


- (instancetype)initWithConfig:(BesServiceConfig *)config;
- (void)startScanWithServices:(NSArray<CBUUID *>*)services options:(NSDictionary<NSString *,id> *)options isGatt:(BOOL)isGatt;
- (void)stopScan;
- (NSArray<CBPeripheral *> *)getCurConnectDevices;
- (void)connectDecvice:(BesServiceConfig *)config;
- (void)disconnect:(CBPeripheral *)device;
- (void)removeNotification;
- (BesConnectState)getDeviceConnectState:(BesServiceConfig *)config;
- (void)sendData:(NSData *)data device:(CBPeripheral *)device;
- (void)sendDataWithOutResponse:(NSData *)data device:(CBPeripheral *)device;
- (void)sendData:(NSData *)data delay:(int)millis device:(CBPeripheral *)device;

- (void)addTimeOut:(int)millis device:(CBPeripheral *)device;
- (void)addTimeOut:(int)millis what:(int)what device:(CBPeripheral *)device;
- (void)removeTimeOutWithWhat:(int)what device:(CBPeripheral *)device;

@end

NS_ASSUME_NONNULL_END
