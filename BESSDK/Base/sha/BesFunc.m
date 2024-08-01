//
//  BesFunc.m
//  BesAll
//
//  Created by 范羽 on 2021/9/28.
//

#import "BesFunc.h"
#import "../../utils/ArrayUtil.h"

@implementation BesFunc

+ (NSData *)func1WithA:(NSData *)a b:(NSData *)b {
    if (a.length > b.length) {
        Byte ob[b.length];
        [b getBytes:ob length:b.length];
        Byte nb[a.length];
        for (int i = 0; i < b.length; i ++) {
            nb[i] = ob[i];
        }
        for (int i = (int)b.length; i < a.length; i ++) {
            nb[i] = (Byte) 0x00;
        }
        b = [NSData dataWithBytes:nb length:a.length];
    } else if (a.length < b.length) {
        Byte oa[a.length];
        [a getBytes:oa length:a.length];
        Byte na[b.length];
        for (int i = 0; i < a.length; i ++) {
            na[i] = oa[i];
        }
        for (int i = (int)a.length; i < b.length; i ++) {
            na[i] = (Byte) 0x00;
        }
        a = [NSData dataWithBytes:na length:b.length];
    }
    NSLog(@"func1 - a ----%@", [ArrayUtil toHex:a]);
    NSLog(@"func1 - b ----%@", [ArrayUtil toHex:b]);
    Byte rand_key[a.length];
    Byte ab[a.length];
    Byte bb[a.length];
    [a getBytes:ab length:a.length];
    [b getBytes:bb length:a.length];
    for (int i = 0; i < a.length; i ++) {
        rand_key[i] = [self generate_random_algorithmWithId:i a:ab[i] b:bb[i]];
    }
        
    return [NSData dataWithBytes:rand_key length:a.length];
}

+ (NSData *)funcWithHash:(NSData *)hash_key {
    Byte key[16];
    Byte hash_key_b[hash_key.length];
    [hash_key getBytes:hash_key_b length:hash_key.length];
    for (int i = 0; i < 16; i ++) {
        key[i] = hash_key_b[2 * i];
    }
    return [NSData dataWithBytes:key length:16];
}


+ (Byte)generate_random_algorithmWithId:(int)i a:(Byte)a b:(Byte)b {
    int op = i % 6;
    switch (op) {
        case 0:
            return (Byte) (a + b);
        case 1:
            return (Byte) (a * b);
        case 2:
            return (Byte) (a & b);
        case 3:
            return (Byte) (a | b);
        case 4:
            return (Byte) (a ^ b);
        case 5:
            return (Byte) (a*a + b*b);
        default:
            return 0x00;
    }
}

@end
