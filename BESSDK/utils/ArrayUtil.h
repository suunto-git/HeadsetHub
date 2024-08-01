//
//  ArrayUtil.h
//  BesAll
//
//  Created by 范羽 on 2021/2/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ArrayUtil : NSObject

+ (NSData *)strToData:(NSString *)str;

+ (NSData *)toData:(NSString *)str;

+ (NSData *)intToBytes:(long)length;

+ (NSData *)intToLittleBytes:(long)length;

+ (NSData *)intToOneBytes:(long)length;

+ (NSString *)dealWithString:(NSString *)str;

+ (NSData *)dataSplic:(NSData *)pt l:(NSData *)l magic:(NSData *)magic data:(NSData *)data;

+ (NSData *)dataMerger:(NSData *)data1 data2:(NSData *)data2;

+ (NSString *)toHex:(NSData *)data;

+ (NSString *)hexStringFromString:(NSString *)string;

+ (Byte)bitToByte:(NSString *)bitStr;

+ (NSString *)byteToBitStr:(Byte)byte;

@end

NS_ASSUME_NONNULL_END
