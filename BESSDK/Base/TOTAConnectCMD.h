//
//  TOTAConnectCMD.h
//  BesAll
//
//  Created by 范羽 on 2021/9/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TOTAConnectCMD : NSObject

- (NSData *)totaStartData;
- (NSData *)totaConfirm;
- (NSData *)totaEncryptData:(NSData *)data;
- (NSData *)totaDecodeData:(NSData *)data;
- (NSData *)getTotaV2Packet:(NSData *)data;
- (NSData *)setTotaV2PacketData:(NSData *)receiveData decode:(BOOL)decode;
- (int)receiveData:(NSData *)receiveData;
- (void)setAes_key:(NSData *)data;
- (NSData *)getAes_key;

@end

NS_ASSUME_NONNULL_END
