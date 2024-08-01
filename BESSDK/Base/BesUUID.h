//
//  BesUUID.h
//  BesAll
//
//  Created by 范羽 on 2021/1/30.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

@interface BesUUID : NSObject

+ (CBUUID *)getBesOTAServicesUUID;
+ (CBUUID *)getBesOTACharacteristicsUUID;
+ (CBUUID *)getBesTotaServicesUUID;
+ (CBUUID *)getBesTotaCharacteristicsUUID;
+ (CBUUID *)getBesBleWifiServicesUUID;
+ (CBUUID *)getBesBleWifiCharacteristicsUUID;
+ (CBUUID *)getBesBleWifiCharacteristicsUUID_RX;

@end

NS_ASSUME_NONNULL_END
