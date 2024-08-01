//
//  BesOtaService.m
//  BesAll
//
//  Created by 范羽 on 2021/1/30.
//

#import "BesOTAService.h"
#import "BesOTACMD.h"
#import "BesOTAConstants.h"
#import "../utils/ArrayUtil.h"
#import "../utils/FileUtils.h"

@interface BesOTAService()
{
    int curOtaResult;
    NSString *roleSwitchRandomID;
    BOOL roleSwitchDisconnect;
    NSData *totaData;
    BesOTAStatus mOTAStatus;
    BOOL isConnect;
    int getVersionRetryTimes;
    int getProtocolRetryTimes;
    int setUserRetryTimes;
    int crcPackageRetryTimes;
    int connectRetryTimes;
    int getCrcConfirmRetryTimes;
    BOOL currentOrLegacy;
    int USER_FLAG;
    int curUser;//1:fw 2:language 3:combine
    int curUpgateType;
    BOOL isWithoutResponse;
    
    BOOL scanSuccess;
}

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) int timerCount;
@property (nonatomic, strong) BesBaseService *service;
@property (nonatomic, strong) BesOtaCMD *besOtaCMD;
@property (nonatomic, strong) BesServiceConfig *serviceConfig;

@end

@implementation BesOTAService

- (instancetype)initWithConfig:(BesServiceConfig *)config {
    if (self = [super init]) {
        self.serviceConfig = config;
        self.service = [[BesBaseService alloc] initWithConfig:self.serviceConfig];
        self.besOtaCMD = [[BesOtaCMD alloc] init];
    }
    return self;
}

- (void)dealloc {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    
    [self removeNotification];

    if (self.service) {
        [self.service stopScan];
        [self.service removeNotification];
        self.service = nil;
    }
}

- (void)connectDecviceWithConfig:(BesServiceConfig *)config {
    curOtaResult = 0;
    isWithoutResponse = NO;
    mOTAStatus = STATUS_UNKNOWN;
    roleSwitchRandomID = @"";
    roleSwitchDisconnect = NO;
    getVersionRetryTimes = 0;
    getProtocolRetryTimes = 0;
    setUserRetryTimes = 0;
    crcPackageRetryTimes = 0;
    connectRetryTimes = 0;
    getCrcConfirmRetryTimes = 0;
    isConnect = NO;
    currentOrLegacy = YES;
    scanSuccess = NO;
    self.serviceConfig = config;
    
    USER_FLAG = self.serviceConfig.USER_FLAG ? self.serviceConfig.USER_FLAG : 0;
    curUser = self.serviceConfig.curUser ? self.serviceConfig.curUser : 1;
    curUpgateType = self.serviceConfig.curUpgateType ? self.serviceConfig.curUpgateType : 1;
    isWithoutResponse = self.serviceConfig.isWithoutResponse ? self.serviceConfig.isWithoutResponse : isWithoutResponse;

    [self.besOtaCMD setOtaUser:USER_FLAG isGatt:(self.serviceConfig.protocol == BES_PROTOCOL_GATT ? YES : NO) isWithoutRsp:isWithoutResponse isTota:self.serviceConfig.totaConnect useTotaV2:self.serviceConfig.useTotaV2 identifier:self.serviceConfig.device.identifier.UUIDString];
    
    NSLog(@"initWithConfig---------%@", self.serviceConfig.device);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onStatusChangedNoti:) name:BES_NOTI_STATE_CHANGED object:self.serviceConfig.device];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFailed:) name:BES_NOTI_STATE_FAILED object:self.serviceConfig.device];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDataReceived:) name:BES_NOTI_DATA_RECEIVE object:self.serviceConfig.device];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onWriteSuccessOrError:) name:BES_NOTI_WRITE_ERROR object:self.serviceConfig.device];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onTotaConnectState:) name:BES_NOTI_TOTA_CON_STATE object:self.serviceConfig.device];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(msgTimeOut) name:BES_NOTI_MSG_TIMEOUT object:self.serviceConfig.device];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(msgTimeOutWithWhat:) name:BES_NOTI_MSG_TIMEOUT_WHAT object:self.serviceConfig.device];

    [self.service connectDecvice:config];
}

- (void)disconnect:(CBPeripheral *)device {
    [self.service disconnect:device];
}

- (void)removeNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:BES_NOTI_STATE_CHANGED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:BES_NOTI_STATE_FAILED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:BES_NOTI_DATA_RECEIVE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:BES_NOTI_WRITE_ERROR object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:BES_NOTI_TOTA_CON_STATE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:BES_NOTI_MSG_TIMEOUT object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:BES_NOTI_MSG_TIMEOUT_WHAT object:nil];
    [self.service removeNotification];
}

- (void)sendData:(NSData *)data {
    if (mOTAStatus == STATUS_PAUSED) {
        return;
    }
    [self.service sendData:data device:self.serviceConfig.device];
}

- (void)sendDataWithOutResponse:(NSData *)data {
    if (mOTAStatus == STATUS_PAUSED) {
        return;
    }
    [self.service sendDataWithOutResponse:data device:self.serviceConfig.device];
}

- (void)sendData:(NSData *)data delay:(int)millis {
    if (mOTAStatus == STATUS_PAUSED) {
        return;
    }
    [self.service sendData:data delay:millis device:self.serviceConfig.device];
}

- (void)setOtaConfig:(BesServiceConfig *)config {
    self.serviceConfig.localPath = config.localPath;
    NSLog(@"setOtaConfig-----------%@", config.device);

}

- (BOOL)startDataTransfer {
    [self LOG:[NSString stringWithFormat:@"startDataTransfer-------------%@", self.serviceConfig.device]];
    [self LOG:[NSString stringWithFormat:@"startDataTransfer-------------%d", curOtaResult]];

    if (curOtaResult == OTA_CMD_BREAKPOINT_CHECK_80) {
        [self sendData:[self.besOtaCMD getStartOTAPacketCMD:totaData]];
        return true;
    }
    [self LOG:[NSString stringWithFormat:@"startDataTransfer-------------curOtaResult != OTA_CMD_BREAKPOINT_CHECK_80"]];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (self.serviceConfig.localPath == nil || ![fileManager fileExistsAtPath:self.serviceConfig.localPath]) {
        [self callBackErrorMessage:OTA_START_OTA_ERROR];
        return NO;
    }
    totaData = [NSData dataWithContentsOfFile:self.serviceConfig.localPath];
    if (self.serviceConfig.getBreakpoint == 0) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults removeObjectForKey:[NSString stringWithFormat:@"%@%@", BES_OTA_RANDOM_CODE_LEFT, self.serviceConfig.device.identifier.UUIDString]];
    }
    if (curOtaResult == OTA_CMD_SEND_OTA_DATA && mOTAStatus != STATUS_PAUSED) {
        return false;
    }
    [self startOta];
    return YES;
}

- (void)stopDataTransfer {
    mOTAStatus = STATUS_CANCELED;
    [self callBackStateChangedMessage:OTA_STOP_DATA_TRANSFER msg:@""];
    
    [self removeNotification];
    if (self.service) {
        [self.service stopScan];
//        [self.service disconnect:self.serviceConfig.device];
        self.service = nil;
    }
}

- (void)pausedDataTransfer {
    mOTAStatus = STATUS_PAUSED;
    [self.timer invalidate];
    self.timer = nil;
}

- (BesOTAStatus)getOTAStatus {
    return mOTAStatus;
}

- (BesConnectState)getDeviceConnectState:(BesServiceConfig *)config {
    return [self.service getDeviceConnectState:config];
}

- (void)getCurrentVersion {
    mOTAStatus = STATUS_STARTED;
    [self sendData:[self.besOtaCMD getCurrentVersionCMD]];
    [self.service addTimeOut:3000 what:MSG_GET_VERSION_TIME_OUT device:self.serviceConfig.device];
}

- (void)startOta {
    curOtaResult = 0;
    mOTAStatus = STATUS_STARTED;

    [self sendUpgrateTypeData];
//    [self sendGetROLESwitchRandomIDData];
}

- (void)sendGetProtocolVersionData {
    sleep(1);
    [self sendData:[self.besOtaCMD getOtaProtocolVersionCMD:currentOrLegacy]];
    [self.service addTimeOut:3000 what:MSG_GET_PROTOCOL_VERSION_TIME_OUT device:self.serviceConfig.device];
}

- (void)sendSetUserData {
    sleep(1);
    [self sendData:[self.besOtaCMD getSetOtaUserCMD:curUser]];
    [self.service addTimeOut:3000 what:MSG_SET_USER_TIME_OUT device:self.serviceConfig.device];
}

- (void)sendUpgrateTypeData {
    [self sendData:[self.besOtaCMD getSetUpgrateTypeCMD:curUpgateType]];
    [self.service addTimeOut:3000 what:MSG_GET_UPGRATE_TYPE_TIME_OUT device:self.serviceConfig.device];
}

- (void)sendGetROLESwitchRandomIDData {
    if (roleSwitchRandomID.length > 0) {
        [self sendSelectSideData];
        return;
    }
    [self sendData:[self.besOtaCMD getROLESwitchRandomIDCMD]];
    [self.service addTimeOut:3000 what:MSG_GET_RANDOMID_TIME_OUT device:self.serviceConfig.device];
}

- (void)sendSelectSideData {
    [self sendData:[self.besOtaCMD getSelectSideCMD]];
    [self.service addTimeOut:3000 what:MSG_GET_SELECT_SIDE_TIME_OUT device:self.serviceConfig.device];
}

- (void)besSendData {
    if (mOTAStatus == STATUS_PAUSED) {
        return;
    }
    NSLog(@"besSendData--------");
    if (roleSwitchDisconnect) {
        [self.timer invalidate];
        self.timer = nil;
        return;
    }
    
    int interval = 50;
    if (USER_FLAG == 1 && isWithoutResponse) {
        if (self.serviceConfig.protocol == BES_PROTOCOL_GATT) {
            interval = 50;
            if ([[NSUserDefaults standardUserDefaults] valueForKey:@"BESINTERVAL_gatt"]) {
                interval = ((NSString *)[[NSUserDefaults standardUserDefaults] valueForKey:@"BESINTERVAL_gatt"]).intValue;
            }
        } else if (self.serviceConfig.protocol == BES_PROTOCOL_BLE) {
            interval = 50;
            if ([[NSUserDefaults standardUserDefaults] valueForKey:@"BESINTERVAL_ble"]) {
                interval = ((NSString *)[[NSUserDefaults standardUserDefaults] valueForKey:@"BESINTERVAL_ble"]).intValue;
            }
        }
        [self LOG:[NSString stringWithFormat:@"interval--------%d", interval]];
        self.timer = [NSTimer scheduledTimerWithTimeInterval:(double)interval / 1000 target:self selector:@selector(timerSendData) userInfo:nil repeats:YES];
        [self.timer fire];
    } else {
        [self sendPacketDataOld];
    }
}

- (void)timerSendData {
    NSLog(@"timerSendData-------");
    [self sendPacketData];
}

- (void)sendPacketData {
    if (roleSwitchDisconnect) {
        [self.timer invalidate];
        self.timer = nil;
        return;
    }
    if (!totaData) {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(onOTAProgressChanged:device:)]) {
        [self.delegate onOTAProgressChanged:[self.besOtaCMD besOtaProgress:(int)totaData.length] device:self.serviceConfig.device];
    }
    [self LOG:[NSString stringWithFormat:@"process----%@-------%@", self.serviceConfig.device, [self.besOtaCMD besOtaProgress:(int)totaData.length]]];
    
    NSData *data = [self.besOtaCMD getDataPacketCMD:totaData];
    Byte dataB[data.length];
    [data getBytes:dataB length:data.length];
    if (dataB[self.serviceConfig.totaConnect ? 4 : 0] != 0x85) {
        curOtaResult = 0;
        [self.timer invalidate];
        self.timer = nil;
    } else if (dataB[self.serviceConfig.totaConnect ? 4 : 0] == 0x85 && dataB[self.serviceConfig.totaConnect ? (4 + 1) : (0 + 1)] == 0x00) {
        [self.timer invalidate];
        self.timer = nil;
        return;
    } else {
        [self.besOtaCMD notifySuccess];
    }
    if (dataB[self.serviceConfig.totaConnect ? 4 : 0] == (Byte)0x82) {
        [self.service addTimeOut:5000 what:MSG_GET_CRC_CHECK_PACKAGE_TIME_OUT device:self.serviceConfig.device];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.timer) {
            [self.service sendDataWithOutResponse:data device:self.serviceConfig.device];
        } else {
            [self.service sendData:data device:self.serviceConfig.device];
        }
    });
}

- (void)sendPacketDataOld {
    if (!totaData) {
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(onOTAProgressChanged:device:)]) {
        [self.delegate onOTAProgressChanged:[self.besOtaCMD besOtaProgress:(int)totaData.length] device:self.serviceConfig.device];
    }
    
    NSData *data = [self.besOtaCMD getDataPacketCMD:totaData];
    Byte dataB[data.length];
    [data getBytes:dataB length:data.length];
    if (dataB[self.serviceConfig.totaConnect ? 4 : 0] != 0x85) {
        curOtaResult = 0;
    }
    if (dataB[self.serviceConfig.totaConnect ? 4 : 0] == (Byte)0x82) {
        [self.service addTimeOut:5000 what:MSG_GET_CRC_CHECK_PACKAGE_TIME_OUT device:self.serviceConfig.device];
    }
    [self.service sendData:data device:self.serviceConfig.device];
}

- (void)scanToReConnected {
    [self LOG:[NSString stringWithFormat:@"scanToReConnected--------"]];
    curOtaResult = 0;
    mOTAStatus = STATUS_REBOOT;
    [self.service stopScan];
    
    scanSuccess = NO;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        sleep(3);
        NSLog(@"scansuccess-------%d", self->scanSuccess);
        if (!(self->scanSuccess)) {
            NSLog(@"!scansuccess------------");
            [self scanToReConnected];
        }
    });
    
    [self.service startScanWithServices:@[] options:@{} isGatt:self.serviceConfig.protocol == BES_PROTOCOL_GATT ? YES : NO];
}

- (void)onScanResult:(CBPeripheral *)device advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    [self LOG:[NSString stringWithFormat:@"onScanResult-------------%@", device]];
    scanSuccess = YES;

    NSData *data = advertisementData[@"kCBAdvDataManufacturerData"];
    if (data) {
        Byte bytes[[data length]];
        [data getBytes:bytes range:NSMakeRange(0, data.length)];
        for(int i = 0; i < data.length; i ++) {
            NSData *idata = [data subdataWithRange:NSMakeRange(i, 1)];
            bytes[i] = ((Byte*)[idata bytes])[0];
        }
                  
        NSString *macs = @"";
        for (int i = 0; i < data.length; i ++) {
            NSString *strByte = [[NSString stringWithFormat:@"%02x",bytes[i]] uppercaseString];
            macs = [NSString stringWithFormat:@"%@%@", macs, strByte];
        }
        macs = [macs substringFromIndex:macs.length - 4];
        [self LOG:[NSString stringWithFormat:@"scanToReConnected -->macs----%@", macs]];

        if ([roleSwitchRandomID.uppercaseString isEqualToString:macs.uppercaseString]) {
            [self.service stopScan];
            self.serviceConfig.device = device;
            [self connectDecviceWithConfig:self.serviceConfig];
        }
    }
}

#pragma mark-----------noti
- (void)onTotaConnectState:(NSNotification *)noti {
    BOOL state = [[noti.userInfo valueForKey:@"data"] isEqual:@"YES"] ? YES : NO;
    if (state == true) {
        NSLog(@"----------totaSuccess");
        [self LOG:[NSString stringWithFormat:@"onStatusChanged: ------TotaSUCCESS"]];
        if ([self.delegate respondsToSelector:@selector(onStatusChanged:msg:device:)]) {
            [self.delegate onStatusChanged:BES_CONNECT_NOTIFY_SUCCESS msg:@"" device:self.serviceConfig.device];
        }
        roleSwitchDisconnect = NO;
        connectRetryTimes = 0;
        isConnect = YES;
        [self callBackStateChangedMessage:BES_CONNECT_SUCCESS msg:@""];
        if (self.serviceConfig.USER_FLAG == 1) {
            [self sendGetProtocolVersionData];
        } else {
//            [self getCurrentVersion];
            [self sendSetUserData];
        }
        
    } else {
        NSLog(@"----------totaError");
        if ([self.delegate respondsToSelector:@selector(onFailed:msg:device:)]) {
            [self.delegate onFailed:BES_CONNECT_NOTIFY_FAIL msg:@"TOTA Error" device:self.serviceConfig.device];
        }
    }
}

- (void)onStatusChangedNoti:(NSNotification *)noti {
    NSString *msg = [noti.userInfo valueForKey:BES_NOTI_KEY_MSG];
    BesConnectStateCorrect state = [[noti.userInfo valueForKey:BES_NOTI_KEY_STATE] integerValue];
    if ([self.delegate respondsToSelector:@selector(onStatusChanged:msg:device:)]) {
        [self.delegate onStatusChanged:state msg:msg device:self.serviceConfig.device];
    }
    if (!self.serviceConfig.totaConnect && state == BES_CONNECT_NOTIFY_SUCCESS) {
        [self LOG:[NSString stringWithFormat:@"onStatusChanged: ------SUCCESS"]];
        roleSwitchDisconnect = NO;
        connectRetryTimes = 0;
        isConnect = YES;
        [self callBackStateChangedMessage:BES_CONNECT_SUCCESS msg:@""];
        if (self.serviceConfig.USER_FLAG == 1) {
            [self sendGetProtocolVersionData];
        } else {
//            [self getCurrentVersion];
            [self sendSetUserData];
        }
    }
}

- (void)onFailed:(NSNotification *)noti {
    NSString *msg = [noti.userInfo valueForKey:BES_NOTI_KEY_MSG];
    BesConnectStateCorrect state = [[noti.userInfo valueForKey:BES_NOTI_KEY_STATE] integerValue];
    
    [self LOG:[NSString stringWithFormat:@"onFailed----------%lu----%@", (unsigned long)state, msg]];

    isConnect = NO;
    if (mOTAStatus == STATUS_CANCELED) {
        return;
    }
    if (mOTAStatus != STATUS_UNKNOWN) {
        if (mOTAStatus != STATUS_SUCCEED && mOTAStatus != STATUS_CANCELED && mOTAStatus != STATUS_FAILED && roleSwitchRandomID.length > 0) {
            [self scanToReConnected];
        } else if (mOTAStatus == STATUS_SUCCEED) {
            //耳机升级后重连
            [self.service addTimeOut:15000 what:MSG_OTA_OVER_RECONNECT device:self.serviceConfig.device];
        } else {
            [self callBackErrorMessage:BES_CONNECT_FAIL];
        }
        return;
    }
    connectRetryTimes ++;
    if (connectRetryTimes > 2) {
        [self callBackStateChangedMessage:BES_CONNECT_FAIL msg:@"重试3次后失败"];
        [self.service stopScan];
        return;
    }
    [self connectDecviceWithConfig:self.serviceConfig];
}

- (void)onDataReceived:(NSNotification *)noti {
    if (!isConnect) {
        return;
    }
    NSData *data = (NSData *)[noti.userInfo valueForKey:@"data"];

    [self LOG:[NSString stringWithFormat:@"OTA onDataReceived-----%@---%@", noti.object, data]];

    if ([self.delegate respondsToSelector:@selector(onDataReceived:device:)]) {
        [self.delegate onDataReceived:data device:self.serviceConfig.device];
    }
    if (self.serviceConfig.totaConnect && data.length > 4) {
        Byte finData[data.length - 4];
        [data getBytes:finData range:NSMakeRange(4, data.length - 4)];
        data = [NSData dataWithBytes:finData length:data.length - 4];
    } else if (self.serviceConfig.totaConnect) {
        [self LOG:[NSString stringWithFormat:@"onDataReceived error"]];
        return;
    }
    int result = [self.besOtaCMD receiveData:data curOtaResult:curOtaResult];
    [self LOG:[NSString stringWithFormat:@"receiveData result----------%d", result]];
    if (result != 0) {
        curOtaResult = result;
    }
    if (result == OTA_CMD_GET_HW_INFO) {
        getVersionRetryTimes = 0;
        [self.service removeTimeOutWithWhat:MSG_GET_VERSION_TIME_OUT device:self.serviceConfig.device];
        [self callBackStateChangedMessage:result msg:[self.besOtaCMD getCurrentVersion]];
        if (roleSwitchRandomID.length > 0 && mOTAStatus != STATUS_SUCCEED) {
            [self startOta];
            return;
        }
        
    } else if (result == OTA_CMD_GET_PROTOCOL_VERSION) {
        [self.service removeTimeOutWithWhat:MSG_GET_PROTOCOL_VERSION_TIME_OUT device:self.serviceConfig.device];
        getProtocolRetryTimes = 0;
        [self callBackStateChangedMessage:result msg:@""];
        [self sendData:[self.besOtaCMD getSetOtaUserCMD:curUser]];
    } else if (result == OTA_CMD_SET_OAT_USER_OK) {
        setUserRetryTimes = 0;
        [self.service removeTimeOutWithWhat:MSG_SET_USER_TIME_OUT device:self.serviceConfig.device];
        [self callBackStateChangedMessage:result msg:@""];
        [self getCurrentVersion];
    } else if (result == OTA_CMD_SET_UPGRADE_TYPE_NORMAL) {
        [self.service removeTimeOutWithWhat:MSG_GET_UPGRATE_TYPE_TIME_OUT device:self.serviceConfig.device];
        [self callBackStateChangedMessage:result msg:@""];
        [self sendGetROLESwitchRandomIDData];
    } else if (result == OTA_CMD_SET_UPGRADE_TYPE_FAST) {
        [self.service removeTimeOutWithWhat:MSG_GET_UPGRATE_TYPE_TIME_OUT device:self.serviceConfig.device];
        [self callBackStateChangedMessage:result msg:@""];
        [self sendGetROLESwitchRandomIDData];
    } else if (result == OTA_CMD_ROLESWITCH_GET_RANDOMID) {
        [self.service removeTimeOutWithWhat:MSG_GET_RANDOMID_TIME_OUT device:self.serviceConfig.device];
        roleSwitchRandomID = [self.besOtaCMD getRoleSwitchRandomID];
        [self callBackStateChangedMessage:result msg:roleSwitchRandomID];
        [self sendSelectSideData];
    } else if (result == OTA_CMD_SELECT_SIDE_OK) {
        [self.service removeTimeOutWithWhat:MSG_GET_SELECT_SIDE_TIME_OUT device:self.serviceConfig.device];
        [self callBackStateChangedMessage:result msg:@""];
        [self sendData:[self.besOtaCMD getCheckBreakPointCMD]];
    } else if (result == OTA_CMD_BREAKPOINT_CHECK_80) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if ([defaults valueForKey:BES_OTA_IS_MULTIDEVICE_UPGRADE]) {
            //  sendData
            [self sendData:[self.besOtaCMD getStartOTAPacketCMD:totaData]];
        } else {
            // show config
            [self callBackStateChangedMessage:result msg:@""];
        }
    } else if (result == OTA_CMD_BREAKPOINT_CHECK) {
        [self callBackStateChangedMessage:result msg:@""];
        [self sendData:[self.besOtaCMD getOTAConfigureCMD:totaData]];
    } else if (result == OTA_CMD_SEND_OTA_DATA) {
        [self.besOtaCMD notifySuccess];
        NSLog(@"result == OTA_CMD_SEND_OTA_DATA------");
        [self besSendData];
    } else if (result == OTA_CMD_SEND_CONFIGURE_OK) {
        curOtaResult = OTA_CMD_SEND_OTA_DATA;
        mOTAStatus = STATUS_UPDATING;
        [self callBackStateChangedMessage:result msg:@""];
        NSLog(@"result == OTA_CMD_SEND_CONFIGURE_OK------");
        [self besSendData];
    } else if (result == OTA_CMD_CRC_CHECK_PACKAGE_OK) {
        [self.service removeTimeOutWithWhat:MSG_GET_CRC_CHECK_PACKAGE_TIME_OUT device:self.serviceConfig.device];
        getCrcConfirmRetryTimes = 0;
        crcPackageRetryTimes = 0;
        curOtaResult = OTA_CMD_SEND_OTA_DATA;
        NSLog(@"result == OTA_CMD_CRC_CHECK_PACKAGE_OK------");
        [self besSendData];
    } else if (result == OTA_CMD_WHOLE_CRC_CHECK) {
        [self.service removeTimeOutWithWhat:MSG_GET_CRC_CHECK_PACKAGE_TIME_OUT device:self.serviceConfig.device];
        NSLog(@"result == OTA_CMD_WHOLE_CRC_CHECK------");
        mOTAStatus = STATUS_VERIFYING;
        [self besSendData];
    } else if (result == OTA_CMD_DISCONNECT) {
        [self callBackStateChangedMessage:result msg:@""];
        roleSwitchDisconnect = true;
        //疑问
        if (mOTAStatus == STATUS_SUCCEED) {
            [self.service addTimeOut:3000 what:OTA_CMD_DISCONNECT device:self.serviceConfig.device];
        }
    } else if (result == OTA_CMD_WHOLE_CRC_CHECK_OK) {
        mOTAStatus = STATUS_VERIFIED;
        [self callBackStateChangedMessage:result msg:@""];
        [self sendData:[self.besOtaCMD getImageOverwritingConfirmationPacketCMD]];
    } else if (result == OTA_CMD_IMAGE_OVER_CONFIRM) {
        [self LOG:[NSString stringWithFormat:@"onDataReceived: -------ota success"]];

        mOTAStatus = STATUS_SUCCEED;
        [self callBackSuccessMessage:result];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"%@%@", BES_OTA_RANDOM_CODE_LEFT, self.serviceConfig.device.identifier.UUIDString]];
    } else if (result == OTA_CMD_CRC_CHECK_PACKAGE_ERROR && crcPackageRetryTimes < 3) {
        [self.service removeTimeOutWithWhat:MSG_GET_CRC_CHECK_PACKAGE_TIME_OUT device:self.serviceConfig.device];
        crcPackageRetryTimes ++;
        [self callBackStateChangedMessage:result msg:[NSString stringWithFormat:@"%d", crcPackageRetryTimes]];
        [self.besOtaCMD crcConfirmError];
        curOtaResult = OTA_CMD_SEND_OTA_DATA;
        NSLog(@"result == OTA_CMD_CRC_CHECK_PACKAGE_ERROR && crcPackageRetryTimes < 3------");

        [self besSendData];
    }
    else if (result == OTA_CMD_RETURN) {
        [self LOG:[NSString stringWithFormat:@"onDataReceived: OTA_CMD_RETURN------------OTA_CMD_RETURN"]];

    }
    else if ((result == OTA_START_OTA_ERROR || result == OTA_CMD_SELECT_SIDE_ERROR || result == OTA_CMD_SEND_CONFIGURE_ERROR || result == OTA_CMD_CRC_CHECK_PACKAGE_ERROR || result == OTA_CMD_WHOLE_CRC_CHECK_ERROR || result == OTA_CMD_IMAGE_OVER_CONFIRM_ERROR || result == OTA_CMD_SET_OAT_USER_ERROR)) {
        if (result == OTA_CMD_CRC_CHECK_PACKAGE_ERROR) {
            [self.service removeTimeOutWithWhat:MSG_GET_CRC_CHECK_PACKAGE_TIME_OUT device:self.serviceConfig.device];
        } else if (result == OTA_CMD_SET_OAT_USER_ERROR) {
            setUserRetryTimes = 0;
            [self.service removeTimeOutWithWhat:MSG_SET_USER_TIME_OUT device:self.serviceConfig.device];
        }
//        mOTAStatus = STATUS_FAILED;
//        [self callBackErrorMessage:result];
        //receive wrong cmd
        
    }
}

- (void)onWriteSuccessOrError:(NSNotification *)noti {
    if (USER_FLAG < 1 || !isWithoutResponse) {
        [self LOG:[NSString stringWithFormat:@"写入成功----%@", noti.userInfo]];
        if (curOtaResult == OTA_CMD_SEND_OTA_DATA) {
            [self.besOtaCMD notifySuccess];
            NSLog(@"onWriteSuccessOrError------");
            [self besSendData];
        }
    }
}

- (void)msgTimeOut {
//    [self LOG:[NSString stringWithFormat:@"--------msgTimeOut"]];


}

- (void)msgTimeOutWithWhat:(NSNotification *)noti {
    int what = [[noti.userInfo valueForKey:@"data"] intValue];
    
    [self LOG:[NSString stringWithFormat:@"--------msgTimeOutWithWhat----%d", what]];

    if (what == MSG_GET_VERSION_TIME_OUT) {
        if (getVersionRetryTimes > 2) {
            [self callBackErrorMessage:what];
        } else if (isConnect) {
            getVersionRetryTimes ++;
            [self getCurrentVersion];
        } else {
            getVersionRetryTimes = 0;
        }
    }
    else if (what == OTA_CMD_DISCONNECT || !isConnect) {
        [self.service disconnect:self.serviceConfig.device];
    }
    else if (what == MSG_GET_RANDOMID_TIME_OUT) {
        [self callBackStateChangedMessage:what msg:@""];
        [self sendSelectSideData];
    } else if (what == MSG_OTA_OVER_RECONNECT) {
        //
        [self LOG:[NSString stringWithFormat:@"升级成功后扫描重连"]];

    } else if (what == MSG_GET_PROTOCOL_VERSION_TIME_OUT) {
        if (roleSwitchRandomID.length > 0) {
            [self disconnect:self.serviceConfig.device];
            return;
        }
        if (USER_FLAG == 1) {
            if (getProtocolRetryTimes > 2 || !isConnect) {
                mOTAStatus = STATUS_FAILED;
                [self callBackErrorMessage:MSG_GET_PROTOCOL_VERSION_TIME_OUT];
            } else {
                getProtocolRetryTimes ++;
                [self sendGetProtocolVersionData];
            }
            return;
        }
        [self sendUpgrateTypeData];
    } else if (what == MSG_GET_UPGRATE_TYPE_TIME_OUT) {
        [self callBackStateChangedMessage:what msg:@""];
        [self sendGetROLESwitchRandomIDData];
    } else if (what == MSG_GET_CRC_CHECK_PACKAGE_TIME_OUT) {
        //resend 82
        if (getCrcConfirmRetryTimes > 1) {
            [self callBackErrorMessage:OTA_CMD_CRC_CHECK_PACKAGE_ERROR];
            return;
        }
        getCrcConfirmRetryTimes ++;
        [self.besOtaCMD setCrcConfirmState:true];
        NSLog(@"MSG_GET_CRC_CHECK_PACKAGE_TIME_OUT------");
        [self besSendData];
    } else if (what == MSG_SET_USER_TIME_OUT) {
        if (setUserRetryTimes > 1) {
            if (USER_FLAG == 0) {
                [self getCurrentVersion];
            } else {
                [self callBackErrorMessage:OTA_CMD_SET_OAT_USER_ERROR];
            }
            return;
        }
        setUserRetryTimes ++;
        [self sendSetUserData];
    }
}

//callback
- (void)callBackStateChangedMessage:(int)state msg:(NSString *)msg {
    if ([self.delegate respondsToSelector:@selector(onOtaStatusChanged:msg:device:)]) {
        [self.delegate onOtaStatusChanged:state msg:msg device:self.serviceConfig.device];
    }
}

- (void)callBackErrorMessage:(int)state {
    if ([self.delegate respondsToSelector:@selector(onOtaError:device:)]) {
        [self.delegate onOtaError:state device:self.serviceConfig.device];
    }
}

- (void)callBackSuccessMessage:(int)state {
    if ([self.delegate respondsToSelector:@selector(onOtaSuccess:device:)]) {
        [self.delegate onOtaSuccess:state device:self.serviceConfig.device];
    }
}

- (void)LOG:(NSString *)text {
    if (BES_SHOW_CONSOLE_LOG) {
        NSLog(@"%@", text);
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults valueForKey:BES_SAVE_LOG_KEY]) {
        [defaults setObject:BES_SAVE_DEFAULT_VALUE forKey:BES_SAVE_LOG_KEY];
    }
    if ([[defaults valueForKey:BES_SAVE_LOG_KEY] isEqual:@"YES"] && [defaults valueForKey:BES_SAVE_LOG_TITLE_KEY]) {
        [FileUtils saveStringToDocumentWithName:[NSString stringWithFormat:@"%@.txt", [defaults valueForKey:BES_SAVE_LOG_TITLE_KEY]] text:text];
    }
}


@end
