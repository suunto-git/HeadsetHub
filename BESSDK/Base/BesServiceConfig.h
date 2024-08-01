//
//  BesServiceConfig.h
//  BesAll
//
//  Created by 范羽 on 2021/1/28.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "BesSdkConstants.h"
@class BesSdkConstants;
NS_ASSUME_NONNULL_BEGIN

@interface BesServiceConfig : NSObject

@property (nonatomic, assign) BesDeviceProtocol protocol;
@property (nonatomic, strong) CBPeripheral *device;
@property (nonatomic, strong) CBUUID *serviceUUID;
@property (nonatomic, strong) CBUUID *characteristicsUUID;
//ota
@property (nonatomic, assign) int USER_FLAG;
@property (nonatomic, strong) NSString *localPath;
@property (nonatomic, assign) int getBreakpoint;
@property (nonatomic, assign) int curUser;//1:fw 2:language 3:combine
@property (nonatomic, assign) int curUpgateType;//0x01: apply NORMAL MODE //0x02: apply FAST MODE
@property (nonatomic, assign) BOOL isWithoutResponse;

@property (nonatomic, assign) BOOL totaConnect;
@property (nonatomic, assign) BOOL useTotaV2;

@end

NS_ASSUME_NONNULL_END
