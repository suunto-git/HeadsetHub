//
//  Sha256.m
//  BesAll
//
//  Created by 范羽 on 2021/9/28.
//

#import "Sha256.h"
#import <CommonCrypto/CommonDigest.h>

@implementation Sha256

+ (NSData *)getSHA256WithData:(NSData *)data {
    unsigned char result[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data.bytes, (CC_LONG)data.length, result);
    return [NSData dataWithBytes:result length:CC_SHA256_DIGEST_LENGTH];
}

@end
