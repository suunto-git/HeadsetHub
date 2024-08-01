//
//  BesOtaCMD.h
//  BesAll
//
//  Created by 范羽 on 2021/2/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface BesOtaCMD : NSObject

- (void)setOtaUser:(int)user isGatt:(BOOL)isGatt isWithoutRsp:(BOOL)withoutResponse isTota:(BOOL)isTota useTotaV2:(BOOL)totaV2 identifier:(NSString *)identifier;

- (NSData *)getCurrentVersionCMD;
- (NSData *)getROLESwitchRandomIDCMD;

- (int)receiveData:(NSData *)receiveData curOtaResult:(int)curOtaResult;

- (int)getCurrentDeviceType;
- (NSString *)getCurrentVersion;
- (NSString *)getRoleSwitchRandomID;
- (NSData *)getOtaProtocolVersionCMD:(BOOL)currentOrLegacy;
- (NSData *)getSetOtaUserCMD:(int)curUser;
- (NSData *)getSetUpgrateTypeCMD:(int)curUpgateType;
- (NSData *)getSelectSideCMD;
- (NSData *)getCheckBreakPointCMD;
- (NSData *)getStartOTAPacketCMD:(NSData *)data;
- (NSData *)getOTAConfigureCMD:(NSData *)data;
- (NSData *)getDataPacketCMD:(NSData *)data;
- (NSData *)getImageOverwritingConfirmationPacketCMD;
- (void)notifySuccess;
- (NSString *)besOtaProgress:(int)total;
- (void)crcConfirmError;
- (void)setCrcConfirmState:(BOOL)state;

@end

NS_ASSUME_NONNULL_END
