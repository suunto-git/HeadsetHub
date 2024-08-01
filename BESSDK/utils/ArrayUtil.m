//
//  ArrayUtil.m
//  BesAll
//
//  Created by 范羽 on 2021/2/1.
//

#import "ArrayUtil.h"
#import "../tools/NSString+XCYCoreOperation.h"

@implementation ArrayUtil

+ (NSData *)strToData:(NSString *)str {
    return [str dataUsingEncoding:NSUTF8StringEncoding];
}

+ (NSData *)toData:(NSString *)str {
    NSString *dataStr = str;
    NSMutableData *fullData = [[NSMutableData alloc] initWithCapacity:1];
    [fullData appendData:[dataStr dataFromHexString_xcy]];
    return fullData.copy;
}

+ (NSData *)intToBytes:(long)length {
    int value = (int)length;
    Byte byte[4] = {};
    byte[3] = (Byte) ((value>>24) & 0xFF);
    byte[2] = (Byte) ((value>>16) & 0xFF);
    byte[1] = (Byte) ((value>>8) & 0xFF);
    byte[0] = (Byte) (value & 0xFF);
    return [NSData dataWithBytes:byte length:4];
}

+ (NSData *)intToLittleBytes:(long)length {
    int value = (int)length;
    Byte byte[2] = {};
    byte[1] = (Byte) ((value>>8) & 0xFF);
    byte[0] = (Byte) (value & 0xFF);
    return [NSData dataWithBytes:byte length:2];
}

+ (NSData *)intToOneBytes:(long)length {
    int value = (int)length;
    Byte byte[1] = {};
    byte[0] = (Byte) (value & 0xFF);
    return [NSData dataWithBytes:byte length:1];
}

+ (NSString *)decimalToHex:(int)value {
    long long int tmpid = value;
    NSString *nLetterValue;
    NSString *str = @"";
    long long int ttmpig;
    for (int i = 0; i < 9; i++) {
        ttmpig = tmpid % 16;
        tmpid = tmpid / 16;
        switch (ttmpig) {
            case 10:
                nLetterValue = @"A";
                break;
            case 11:
                nLetterValue = @"B";
                break;
            case 12:
                nLetterValue = @"C";
                break;
            case 13:
                nLetterValue = @"D";
                break;
            case 14:
                nLetterValue = @"E";
                break;
            case 15:
                nLetterValue = @"F";
                break;
            default:
                nLetterValue = [[NSString alloc] initWithFormat:@"%lli", ttmpig];
        }
        str = [nLetterValue stringByAppendingString:str];
        if (tmpid == 0) {
            break;
        }
    }
    return [NSString stringWithFormat:@"%@%@", str.length == 1 ? @"0" : @"", str];
}

+ (NSString *)dealWithString:(NSString *)str
{
    NSString *doneTitle = @"";
    int count = 0;
    for (int i = 0; i < str.length; i ++) {

        count++;
        doneTitle = [doneTitle stringByAppendingString:[str substringWithRange:NSMakeRange(i, 1)]];
        if (count == 2) {
            doneTitle = [NSString stringWithFormat:@"%@.", doneTitle];
            count = 0;
        }
    }
    NSLog(@"%@", doneTitle);
    return doneTitle;
}

+ (NSData *)dataSplic:(NSData *)pt l:(NSData *)l magic:(NSData *)magic data:(NSData *)data {
    NSMutableData *mutData = [NSMutableData dataWithData:pt];
    [mutData appendData:l];
    [mutData appendData:magic];
    [mutData appendData:data];
    return mutData.copy;
}

+ (NSData *)dataMerger:(NSData *)data1 data2:(NSData *)data2 {
    NSMutableData *mutData = [NSMutableData dataWithData:data1];
    if (data2 != nil) {
        [mutData appendData:data2];
    }
    return mutData.copy;
}

+ (NSString *)toHex:(NSData *)data {
    if (!data || [data length] == 0) {
        return @"";
    }
    NSMutableString *string = [[NSMutableString alloc] initWithCapacity:[data length]];
    
    [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        unsigned char *dataBytes = (unsigned char*)bytes;
        for (NSInteger i = 0; i < byteRange.length; i++) {
            NSString *hexStr = [NSString stringWithFormat:@"%x", (dataBytes[i]) & 0xff];
            if ([hexStr length] == 2) {
                [string appendString:hexStr];
            } else {
                [string appendFormat:@"0%@", hexStr];
            }
        }
    }];
    
    return string;
}

//将字符串转化为16进制
+ (NSString *)hexStringFromString:(NSString *)string {
    NSData *myD = [string dataUsingEncoding:NSUTF8StringEncoding];
    Byte *bytes = (Byte *)[myD bytes];
    NSMutableString *resultStr = [[NSMutableString alloc] init];
    for(int i = 0; i < [myD length]; i ++) {
        NSString *newHexStr = [NSString stringWithFormat:@"%x", bytes[i] & 0xff];
        if([newHexStr length] == 1) {
            newHexStr = [NSString stringWithFormat:@"0%@", newHexStr];
        }
        [resultStr appendString:newHexStr];
    }
    return resultStr;
}

+ (Byte)bitToByte:(NSString *)bitStr {
    unsigned long result;
    if (!bitStr.length) {
        return 0;
    }
    NSInteger length = bitStr.length;
    if (length != 4 && length != 8) {
        return 0;
    }
    if (length == 8) {
        if ([bitStr characterAtIndex:0] == '0') { // 正数
            result = strtoul([bitStr UTF8String], 0, 2);
        } else { // 负数
            result = strtoul([bitStr UTF8String], 0, 2) - 256;
        }
    } else {
        result = strtoul([bitStr UTF8String], 0, 2); // 2进制转为10进制
    }
    return (Byte)result;
}

+ (NSString *)byteToBitStr:(Byte)byte {
    Byte array[8] = {0};
    for (int i = 7; i >= 0; i--) {
        array[i] = (Byte)(byte & 1);
        byte = (Byte) (byte >> 1);
    }//array 为8位bit的数组
    NSString *byteStr = @"";
    for (int i = 0; i < 8; i ++) {
        byteStr = [NSString stringWithFormat:@"%@%hhu", byteStr, array[i]];
    }
    return byteStr;
}

@end
