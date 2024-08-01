//
//  BesBaseService.m
//  BesAll
//
//  Created by 范羽 on 2021/1/29.
//

#import "BesBaseService.h"
#import "TOTAConnectCMD.h"

@interface BesBaseService()

@property (nonatomic, strong) BesBTConnector *btConnector;
@property (nonatomic, assign) BOOL mTotaConnect;
@property (nonatomic, assign) BOOL useTotaV2;
@property (nonatomic, assign) BOOL totaSuccess;
@property (nonatomic, strong) TOTAConnectCMD *mTotaConnectCMD;

@end

@implementation BesBaseService

- (instancetype)initWithConfig:(BesServiceConfig *)config {
    if (self = [super init]) {
        self.btConnector = [BesBTConnector shareInstance];
        
        if (config.totaConnect) {
            self.mTotaConnectCMD = [[TOTAConnectCMD alloc] init];
            if ([self getDeviceConnectState:config] == BES_CONNECT) {
                [self.mTotaConnectCMD setAes_key:[self.btConnector getTotaAesKey:config.device]];
            }
        } else {
            self.mTotaConnectCMD = nil;
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onStatusChangedNoti:) name:BES_NOTI_STATE_CHANGED object:config.device];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFailed:) name:BES_NOTI_STATE_FAILED object:config.device];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDataReceived:) name:BES_NOTI_BASE_DATA_RECEIVE object:config.device];
    }
    return self;
}

- (void)startScanWithServices:(NSArray<CBUUID *>*)services options:(NSDictionary<NSString *,id> *)options isGatt:(BOOL)isGatt {
    [self.btConnector startScanWithServices:services options:options isGatt:isGatt];
}

- (void)dealloc {
    self.mTotaConnectCMD = nil;
    self.btConnector = nil;
}

- (void)stopScan {
    [self.btConnector stopScan];
}

- (NSArray<CBPeripheral *> *)getCurConnectDevices {
    return [self.btConnector getCurConnectDevices];
}

- (BesConnectState)getDeviceConnectState:(BesServiceConfig *)config {
    return [self.btConnector getDeviceConnectState:config];
}

- (void)connectDecvice:(BesServiceConfig *)config {
    if (!config.device) {
        NSLog(@"device == null");
        return;
    }
    
    self.mTotaConnect = config.totaConnect;
    self.useTotaV2 = config.useTotaV2;
    self.totaSuccess = NO;
    
    BesConnectState state = [self getDeviceConnectState:config];
    if (self.mTotaConnectCMD && config.totaConnect && state == BES_CONNECT) {
        [self.mTotaConnectCMD setAes_key:[self.btConnector getTotaAesKey:config.device]];
        [self totaConnectSucess:config.device];
        return;
    } else if (state == BES_CONNECT_TOTA) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self.btConnector disconnect:config.device];
            sleep(1);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.btConnector connectDecvice:config];
            });
        });
        
        return;
    }
    [self.btConnector connectDecvice:config];
}

- (void)disconnect:(CBPeripheral *)device {
    [self.btConnector disconnect:device];

    [self removeNotification];
}

- (void)removeNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:BES_NOTI_STATE_CHANGED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:BES_NOTI_STATE_FAILED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:BES_NOTI_BASE_DATA_RECEIVE object:nil];
}

- (void)sendData:(NSData *)data device:(CBPeripheral *)device {
    [self addTimeOut:10000 device:device];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL totaEncryption = ([defaults valueForKey:BES_TOTA_ENCRYPTION_KEY] && [[defaults valueForKey:BES_TOTA_ENCRYPTION_KEY] isEqual:@"YES"]) ? YES : NO;
    [self.btConnector sendData:(self.totaSuccess && totaEncryption) ? (self.useTotaV2 ? [self.mTotaConnectCMD getTotaV2Packet:[self.mTotaConnectCMD totaEncryptData:data]] : [self.mTotaConnectCMD totaEncryptData:data]) : self.useTotaV2 ? [self.mTotaConnectCMD getTotaV2Packet:data] : data device:device];
}

- (void)sendDataWithOutResponse:(NSData *)data device:(CBPeripheral *)device {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL totaEncryption = ([defaults valueForKey:BES_TOTA_ENCRYPTION_KEY] && [[defaults valueForKey:BES_TOTA_ENCRYPTION_KEY] isEqual:@"YES"]) ? YES : NO;
    [self.btConnector sendDataWithOutResponse:(self.totaSuccess && totaEncryption) ? (self.useTotaV2 ? [self.mTotaConnectCMD getTotaV2Packet:[self.mTotaConnectCMD totaEncryptData:data]] : [self.mTotaConnectCMD totaEncryptData:data]) : self.useTotaV2 ? [self.mTotaConnectCMD getTotaV2Packet:data] : data device:device];
}

- (void)sendData:(NSData *)data delay:(int)millis device:(nonnull CBPeripheral *)device {
    [self performSelector:@selector(sendData:device:) withObject:data afterDelay:millis / 1000];
}

- (void)addTimeOut:(int)millis device:(nonnull CBPeripheral *)device {
    [self performSelector:@selector(msgTimeOutWith:) withObject:device afterDelay:millis / 1000];
}

- (void)addTimeOut:(int)millis what:(int)what device:(nonnull CBPeripheral *)device {
    [self performSelector:@selector(msgTimeOutWithWhatAndDevice:) withObject:@{@"what" : [NSString stringWithFormat:@"%d", what], @"index" : device} afterDelay:millis / 1000];
}

- (void)msgTimeOutWith:(CBPeripheral *)device {
    NSNotification *timeoutNoti = [NSNotification notificationWithName:BES_NOTI_MSG_TIMEOUT object:device];
    [[NSNotificationCenter defaultCenter] postNotification:timeoutNoti];
}

- (void)msgTimeOutWithWhatAndDevice:(NSDictionary *)dic {
    if (((NSString *)[dic valueForKey:@"what"]).intValue == BES_NOTI_MSG_TIMEOUT_TOTA_START) {
        [self totaConnectFail:[dic valueForKey:@"index"]];
        return;
    }
    NSNotification *timeoutWhatNoti = [NSNotification notificationWithName:BES_NOTI_MSG_TIMEOUT_WHAT object:[dic valueForKey:@"index"] userInfo:@{@"data" : [dic valueForKey:@"what"]}];
    [[NSNotificationCenter defaultCenter] postNotification:timeoutWhatNoti];
}

- (void)removeTimeOut {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(msgTimeOutWith:) object:nil];
}

- (void)removeTimeOutWithWhat:(int)what device:(nonnull CBPeripheral *)device {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(msgTimeOutWithWhatAndDevice:) object:@{@"what" : [NSString stringWithFormat:@"%d", what], @"index" : device}];
}

#pragma mark------noti
- (void)onStatusChangedNoti:(NSNotification *)noti {
    [self removeTimeOut];
    BesConnectStateCorrect state = [[noti.userInfo valueForKey:BES_NOTI_KEY_STATE] integerValue];
    if (self.mTotaConnect && !self.totaSuccess && state == BES_CONNECT_NOTIFY_SUCCESS) {
        NSLog(@"----%@-----%@", self.mTotaConnectCMD, [self.mTotaConnectCMD totaStartData]);
        [self sendData:[self.mTotaConnectCMD totaStartData] device:noti.object];
        [self addTimeOut:5000 what:BES_NOTI_MSG_TIMEOUT_TOTA_START device:noti.object];
        return;
    }
}

- (void)onFailed:(NSNotification *)noti {
    self.totaSuccess = NO;
}

- (void)onDataReceived:(NSNotification *)noti {
    [self removeTimeOut];
    NSData *data = (NSData *)[noti.userInfo valueForKey:@"data"];
    
    if (self.mTotaConnect && !self.totaSuccess) {
        int result = [self.mTotaConnectCMD receiveData:self.useTotaV2 ? [self.mTotaConnectCMD setTotaV2PacketData:data decode:NO] : data];
        if (result == BES_TOTA_CONFIRM) {
            [self removeTimeOutWithWhat:BES_NOTI_MSG_TIMEOUT_TOTA_START device:noti.object];
            [self sendData:[self.mTotaConnectCMD totaConfirm] device:noti.object];
        } else if (result == BES_TOTA_SUCCESS) {
            [self totaConnectSucess:noti.object];
        } else if (result == BES_TOTA_ERROR) {
            [self totaConnectFail:noti.object];
        }
        NSLog(@"result--------%d", result);
        return;
    }
    
    NSLog(@"Base onDataReceived-----%@---%@", noti.object, data);

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL totaEncryption = ([defaults valueForKey:BES_TOTA_ENCRYPTION_KEY] && [[defaults valueForKey:BES_TOTA_ENCRYPTION_KEY] isEqual:@"YES"]) ? YES : NO;
    NSNotification *dataReceiveNoti = [NSNotification notificationWithName:BES_NOTI_DATA_RECEIVE object:noti.object userInfo:@{@"data" : (self.totaSuccess && totaEncryption) ? (self.useTotaV2 ? [self.mTotaConnectCMD setTotaV2PacketData:data decode:YES] : [self.mTotaConnectCMD totaDecodeData:data]) : data}];
    [[NSNotificationCenter defaultCenter] postNotification:dataReceiveNoti];
}

- (void)totaConnectSucess:(CBPeripheral *)device {
    self.totaSuccess = YES;
    
    [self.btConnector saveTotaAesKey:[self.mTotaConnectCMD getAes_key] device:device];
    
    NSNotification *totaConStateNoti = [NSNotification notificationWithName:BES_NOTI_TOTA_CON_STATE object:device userInfo:@{@"data" : @"YES"}];
    [[NSNotificationCenter defaultCenter] postNotification:totaConStateNoti];
}

- (void)totaConnectFail:(CBPeripheral *)device {
    self.totaSuccess = NO;
    NSNotification *totaConStateNoti = [NSNotification notificationWithName:BES_NOTI_TOTA_CON_STATE object:device userInfo:@{@"data" : @"NO"}];
    [[NSNotificationCenter defaultCenter] postNotification:totaConStateNoti];
    [self.btConnector disconnect:device];
}

@end
