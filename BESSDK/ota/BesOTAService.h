//
//  BesOtaService.h
//  BesAll
//
//  Created by 范羽 on 2021/1/30.
//

#import <Foundation/Foundation.h>
#import "../Base/BesBaseService.h"
#import "BesOTAConstants.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BesOTAServiceDelegate <NSObject>

@required
- (void)onStatusChanged:(BesConnectStateCorrect)state msg:(NSString *)msg device:(CBPeripheral *)device;
- (void)onFailed:(BesConnectStateError)state msg:(NSString *)msg device:(CBPeripheral *)device;
- (void)onDataReceived:(NSData *)data device:(CBPeripheral *)device;
- (void)onOtaStatusChanged:(int)state msg:(NSString *)msg device:(CBPeripheral *)device;
- (void)onOTAProgressChanged:(NSString *)progress device:(CBPeripheral *)device;
- (void)onOtaError:(int)state device:(CBPeripheral *)device;
- (void)onOtaSuccess:(int)state device:(CBPeripheral *)device;

@end

@interface BesOTAService : NSObject

@property (nonatomic, weak) id<BesOTAServiceDelegate> delegate;

- (instancetype)initWithConfig:(BesServiceConfig *)config;

- (void)connectDecviceWithConfig:(BesServiceConfig *)config;
- (void)disconnect:(CBPeripheral *)device;
- (void)setOtaConfig:(BesServiceConfig *)config;
- (BOOL)startDataTransfer;
- (void)stopDataTransfer;
- (void)pausedDataTransfer;
- (BesOTAStatus)getOTAStatus;
- (BesConnectState)getDeviceConnectState:(BesServiceConfig *)config;

@end

NS_ASSUME_NONNULL_END
