//
//  Sha256.h
//  BesAll
//
//  Created by 范羽 on 2021/9/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Sha256 : NSObject

+ (NSData *)getSHA256WithData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
