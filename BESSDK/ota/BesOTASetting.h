//
//  BesOtaSetting.h
//  BesAll
//
//  Created by 范羽 on 2021/2/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BesOTASetting : NSObject

@property (copy, nonatomic) NSData *flashOffsetData;
@property (copy, nonatomic) NSString *btAddr;
@property (copy, nonatomic) NSString *btName;
@property (copy, nonatomic) NSString *bleAddr;
@property (copy, nonatomic) NSString *bleName;

@property (assign, nonatomic) BOOL isClearData;
@property (assign, nonatomic) BOOL isBTAddrOpen;
@property (assign, nonatomic) BOOL isBTNameOpen;
@property (assign, nonatomic) BOOL isBLEAddrOpen;
@property (assign, nonatomic) BOOL isBLENameOpen;

- (void)updateFlashOffsetData:(NSData *)offsetData;

- (NSData *)getFlashOffsetData;
- (NSData *)getSwitchData;
- (NSData *)getBTAddrData;
- (NSData *)getBTNameData;
- (NSData *)getBLEAddrData;
- (NSData *)getBLENameData;


- (NSData *)getTotalSettingData;

@end

NS_ASSUME_NONNULL_END
