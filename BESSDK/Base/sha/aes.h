//
//  aes.h
//  BesAll
//
//  Created by 范羽 on 2021/9/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface aes : NSObject

+ (NSData *)encryptWithContent:(NSData *)content password:(NSData *)password;
+ (NSData *)decryptWithContent:(NSData *)content password:(NSData *)password;

@end

NS_ASSUME_NONNULL_END
