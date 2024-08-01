//
//  BesBTCenterManager.m
//  BesAll
//
//  Created by 范羽 on 2021/1/22.
//


#import "BesBTConnector.h"
#import "../tools/NSString+XCYCoreOperation.h"
#import "../utils/ArrayUtil.h"
#import "../utils/FileUtils.h"

typedef enum : NSUInteger {
    BES_WORKTYPE_UNKNOW,
    BES_WORKTYPE_SCAN_DEVICE,
    BES_WORKTYPE_CONNECT_DEVICE,
} CentralManagerWorkType;

static NSString *emptyObj = @"";
static NSString *totaEmptyObj = @"tota";

@interface BesBTConnector()<CBCentralManagerDelegate,CBPeripheralDelegate>
{
    NSDictionary *gattOptions;
    BOOL connectTimeout;
}
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, assign) CBManagerState centralManagerState;
@property (nonatomic, strong) NSMutableArray *characteristics;
@property (nonatomic, strong) NSMutableArray *mBluetoothList;
@property (nonatomic, strong) NSMutableArray *serviceConfigs;
@property (nonatomic, strong) NSMutableArray *totaAesKeys;
@property (nonatomic, strong) NSMutableArray<CBPeripheral *> *discoverPeripherals;
@property (nonatomic, assign) BesDeviceProtocol protocol;
@property (nonatomic, assign) CentralManagerWorkType workType;

@end

@implementation BesBTConnector

- (instancetype)init {
    if (self = [super init]) {
        _centralManagerState = CBManagerStateUnknown;
        self.workType = BES_WORKTYPE_UNKNOW;
        if (!self.centralManager) {
            [self initCentralManager];
        }
    }
    return self;
}

+ (instancetype)shareInstance {
    static BesBTConnector *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (void)destroy {
    [self.centralManager stopScan];
    for (CBPeripheral *peropheral in _mBluetoothList) {
        [self.centralManager cancelPeripheralConnection:peropheral];
    }
    self.mBluetoothList = nil;
    self.characteristics = nil;
    self.discoverPeripherals = nil;
    self.serviceConfigs = nil;
    self.totaAesKeys = nil;

    self.centralManager = nil;
}

- (NSArray<CBPeripheral *> *)getCurConnectDevices {
    NSMutableArray *mutArr = [NSMutableArray array];
    for (int i = 0; i < self.mBluetoothList.count; i ++) {
        NSString *totaAesKey = self.totaAesKeys[i];
        if (self.characteristics[i] != emptyObj && (totaAesKey.length > 0 ? (totaAesKey != totaEmptyObj) : YES)) {
            [mutArr addObject:self.mBluetoothList[i]];
        }
    }
    return mutArr.copy;
}

- (BesConnectState)getDeviceConnectState:(BesServiceConfig *)config {
    if (!config.device || !config.serviceUUID || !config.characteristicsUUID) {
        return BES_CONFIG_ERROR;
    }
    BesServiceConfig *oldConfig = [self getCurConfig:config.device];
    if ([self.mBluetoothList containsObject:config.device] && [self getCurCharacteristic:config.device] && oldConfig && (oldConfig.totaConnect ? [self getCurTotaAesKey:config.device] != nil : YES)) {
        if ([config.serviceUUID.UUIDString isEqual:oldConfig.serviceUUID.UUIDString] && [config.characteristicsUUID.UUIDString isEqual:oldConfig.characteristicsUUID.UUIDString]) {
            return BES_CONNECT;
        }
        return oldConfig.totaConnect ? BES_CONNECT_TOTA : BES_CONNECT_NOTOTA;
    }
    return BES_NO_CONNECT;
}

- (void)saveTotaAesKey:(NSData *)data device:(CBPeripheral *)device {
    [self array:self.totaAesKeys addObject:data index:[self getCurIndex:device]];
}

- (NSData *)getTotaAesKey:(CBPeripheral *)device {
    return [self getCurTotaAesKey:device];
}

- (int)getCurIndex:(CBPeripheral *)device {
    for (int i = 0; i < self.mBluetoothList.count; i ++) {
        if (device == self.mBluetoothList[i]) {
            return i;
        }
    }
    return 10000;
}

- (BesServiceConfig *)getCurConfig:(CBPeripheral *)device {
    if (self.serviceConfigs.count < [self getCurIndex:device]) {
        return nil;
    }
    NSObject *obj = self.serviceConfigs[[self getCurIndex:device]];
    if ([obj isKindOfClass:[BesServiceConfig class]]) {
        return (BesServiceConfig *)obj;
    }
    return nil;
}

- (CBCharacteristic *)getCurCharacteristic:(CBPeripheral *)device {
    if (self.characteristics.count < [self getCurIndex:device]) {
        return nil;
    }
    NSObject *obj = self.characteristics[[self getCurIndex:device]];
    if ([obj isKindOfClass:[CBCharacteristic class]]) {
        return (CBCharacteristic *)obj;
    }
    return nil;
}

- (NSData *)getCurTotaAesKey:(CBPeripheral *)device {
    if (self.totaAesKeys.count < [self getCurIndex:device]) {
        return nil;
    }
    NSObject *obj = self.totaAesKeys[[self getCurIndex:device]];
    if ([obj isKindOfClass:[NSData class]]) {
        return (NSData *)obj;
    }
    return nil;
}

- (void)array:(NSMutableArray *)arr addObject:(id)obj index:(int)index {
    if (arr.count > index) {
        [arr replaceObjectAtIndex:index withObject:obj];
    }
}

- (void)array:(NSMutableArray *)arr resetObjectAtIndex:(int)index {
    if (arr.count > index) {
        [arr replaceObjectAtIndex:index withObject:emptyObj];
    }
}

- (BOOL)isNewDeviceWithConfig:(BesServiceConfig *)config {
    if ([self.mBluetoothList containsObject:config.device]) {
//        BesServiceConfig *oldConfig = [self getCurConfig:device];
//        if (!oldConfig) {
//            return NO;
//        }
//        if (config == oldConfig) {
//            return NO;
//        }
//        if (oldConfig.serviceUUID == config.serviceUUID && oldConfig.characteristicsUUID == config.characteristicsUUID) {
//            return NO;
//        }
        return NO;
    }
    return YES;
}

#pragma mark---connect
- (void)connectDecvice:(BesServiceConfig *)config {
    if (self.centralManager == nil || config.device == nil) {
        [self LOG:[NSString stringWithFormat:@"connectDecvice------%@---%@", self.centralManager, config.device]];
        [self statusChangedError:BES_CONNECT_FAIL msg:@"设备或控制器为空" device:config.device];
        return;
    }
    if ([self isNewDeviceWithConfig:config]) {
        [self.mBluetoothList addObject:config.device];
        [self.serviceConfigs addObject:emptyObj];
        [self.characteristics addObject:emptyObj];
        [self.totaAesKeys addObject:config.totaConnect ? totaEmptyObj : emptyObj];
        [self LOG:[NSString stringWithFormat:@"connectDecviceAdd----mBluetoothList--%@---serviceConfigs--%@---characteristics--%@---totaAesKeys--%@---", self.mBluetoothList, self.serviceConfigs, self.characteristics, self.totaAesKeys]];
    } else {
        [self LOG:[NSString stringWithFormat:@"connectDecvice----mBluetoothList--%@---serviceConfigs--%@---characteristics--%@---totaAesKeys--%@---", self.mBluetoothList, self.serviceConfigs, self.characteristics, self.totaAesKeys]];

    }
    [self array:self.serviceConfigs addObject:config index:[self getCurIndex:config.device]];
    [self array:self.totaAesKeys addObject:config.totaConnect ? totaEmptyObj : emptyObj index:[self getCurIndex:config.device]];

    connectTimeout = true;
    [self performSelector:@selector(connectDeviceTimeout:) withObject:config.device afterDelay:15];
    [self LOG:[NSString stringWithFormat:@"connectDecvice------------"]];
    self.workType = BES_WORKTYPE_CONNECT_DEVICE;
    [self.centralManager connectPeripheral:config.device options:nil];
}

- (void)connectDeviceTimeout:(CBPeripheral *)device {
    if (connectTimeout) {
        [self statusChangedError:BES_CONNECT_FAIL msg:@"Connect Device Timeout" device:device];
    }
}

- (void)disconnect:(CBPeripheral *)device {
    if (self.centralManager && device) {
        CBCharacteristic *characteristic = [self getCurCharacteristic:device];
        if (characteristic) {
            [device setNotifyValue:NO forCharacteristic:characteristic];
        }
        
        [self.centralManager cancelPeripheralConnection:device];
        [self array:self.characteristics resetObjectAtIndex:[self getCurIndex:device]];
        [self array:self.serviceConfigs resetObjectAtIndex:[self getCurIndex:device]];
        [self array:self.totaAesKeys resetObjectAtIndex:[self getCurIndex:device]];
    }
}

- (void)startScanWithServices:(NSArray<CBUUID *>*)services options:( NSDictionary<NSString *,id> *)options isGatt:(BOOL)isGatt {
    self.workType = BES_WORKTYPE_SCAN_DEVICE;
    if (isGatt) {
        if (!gattOptions) {
            gattOptions = options;
        }
        if (@available(iOS 13.0, *)) {
            [self.centralManager registerForConnectionEventsWithOptions:gattOptions];
        } else {
            // Fallback on earlier versions
        }
    } else {
        [self.centralManager scanForPeripheralsWithServices:services options:gattOptions];
    }
}

- (void)stopScan {
    [self.centralManager stopScan];
}

- (void)sendData:(NSData *)data device:(CBPeripheral *)device {
    [self LOG:[NSString stringWithFormat:@"sendData---%d----%lu", [self getCurIndex:device], (unsigned long)data.length]];
    CBCharacteristic *characteristic = [self getCurCharacteristic:device];
    if (characteristic) {
        [self LOG:[NSString stringWithFormat:@"sendData------%@", [ArrayUtil toHex:data]]];
        [device writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    }
}

- (void)sendDataWithOutResponse:(NSData *)data device:(CBPeripheral *)device {
    [self LOG:[NSString stringWithFormat:@"sendDataWithOutResponse---%d----%lu", [self getCurIndex:device], (unsigned long)data.length]];
    [self LOG:[NSString stringWithFormat:@"sendDataWithOutResponse------%@", [ArrayUtil toHex:data]]];
    CBCharacteristic *characteristic = [self getCurCharacteristic:device];
    if (characteristic) {
        [device writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
    }
}

#pragma mark-------------CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(nonnull CBCentralManager *)central {
    CBManagerState state = (CBManagerState)central.state;
    _centralManagerState = state;
    switch (central.state) {
        case CBManagerStateUnknown:
            NSLog(@">>>CBCentralManagerStateUnknown");
            break;
        case CBManagerStateResetting:
            NSLog(@">>>CBCentralManagerStateResetting");
            break;
        case CBManagerStateUnsupported:
            NSLog(@">>>CBCentralManagerStateUnsupported");
            break;
        case CBManagerStateUnauthorized:
            NSLog(@">>>CBCentralManagerStateUnauthorized");
            break;
        case CBManagerStatePoweredOff:
            NSLog(@">>>CBCentralManagerStatePoweredOff");
            break;
        case CBManagerStatePoweredOn:
            NSLog(@">>>CBManagerStatePoweredOn");
            //fany test 待解决
            if (self.workType == BES_WORKTYPE_SCAN_DEVICE) {
                [self startScanWithServices:nil options:gattOptions isGatt:gattOptions ? YES : NO];
            }
//            else if (self.workType == BES_WORKTYPE_CONNECT_DEVICE) {
//                [self connectDecvice:self.mDevice config:self.serviceConfig];
//            }
            break;
        default:
            break;
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    [self LOG:[NSString stringWithFormat:@"didConnectPeripheral"]];
    self.workType = BES_WORKTYPE_UNKNOW;
    [self.centralManager stopScan];
    [self statusChanged:BES_CONNECT_SUCCESS msg:@"" device:peripheral];
    peripheral.delegate = self;
    BesServiceConfig *config = [self getCurConfig:peripheral];
    if (config) {
        [self discoverServices:@[config.serviceUUID] device:peripheral];
    }
}

- (void)centralManager:(CBCentralManager *)central connectionEventDidOccur:(CBConnectionEvent)event forPeripheral:(CBPeripheral *)peripheral {
    NSDictionary *data = @{BES_NOTI_KEY_SCAN_DEVICE : peripheral, BES_NOTI_KEY_SCAN_ADV : @"", BES_NOTI_KEY_SCAN_RSSI : @""};
    NSNotification *scanNoti = [NSNotification notificationWithName:BES_NOTI_SCAN_RESULT object:nil userInfo:data];
    [[NSNotificationCenter defaultCenter] postNotification:scanNoti];
    
}
#pragma mark---discoverServices
- (void)discoverServices:(nullable NSArray<CBUUID *> *)serviceUUIDs device:(CBPeripheral *)device {
    [device discoverServices:serviceUUIDs];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    connectTimeout = false;
    CBService * __nullable findService = nil;
    BesServiceConfig *config = [self getCurConfig:peripheral];
    if (!config) {
        [self statusChangedError:BES_CONNECT_DISCOVERSERVICE_FAIL msg:@"no BesServiceConfig" device:peripheral];
        return;
    }
    for (CBService *service in peripheral.services) {
        if ([[service UUID] isEqual:config.serviceUUID]) {
            findService = service;
        }
    }
    if (findService) {
        [self LOG:[NSString stringWithFormat:@"findService-------%@", findService]];
        [peripheral discoverCharacteristics:@[config.characteristicsUUID] forService:findService];
        [self statusChanged:BES_CONNECT_DISCOVERSERVICE_SUCCESS msg:@"" device:peripheral];
    } else {
        [self statusChangedError:BES_CONNECT_DISCOVERSERVICE_FAIL msg:error.userInfo.description device:peripheral];
    }
}
#pragma mark---DiscoverCharacteristics
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    [self LOG:[NSString stringWithFormat:@"didDiscoverCharacteristicsForService---------%@", service]];
    BesServiceConfig *config = [self getCurConfig:peripheral];
    if (!config) {
        [self statusChangedError:BES_CONNECT_DISCOVERSERVICE_FAIL msg:@"no BesServiceConfig" device:peripheral];
        return;
    }
    for (CBCharacteristic *characteristic in service.characteristics) {
        [self LOG:[NSString stringWithFormat:@"characteristic---------%@", characteristic.UUID]];
        if ([characteristic.UUID isEqual:config.characteristicsUUID]) {
            [self array:self.characteristics addObject:characteristic index:[self getCurIndex:peripheral]];
            
            CBCharacteristicProperties properties = characteristic.properties;
            if (properties & CBCharacteristicPropertyWrite) {

            }
            if (properties & CBCharacteristicPropertyNotify) {
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                return;
            }
            if (properties & CBCharacteristicPropertyWriteWithoutResponse) {
      
            }
            if (properties & CBCharacteristicPropertyIndicate) {
              
            }
            [self statusChanged:BES_CONNECT_NOTIFY_SUCCESS msg:@"" device:peripheral];
        }
    }
}
#pragma mark---notify
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        [self LOG:[NSString stringWithFormat:@"receive error----%@", error.userInfo.description]];
        [self statusChangedError:BES_SENDDATA_ERROR msg:error.userInfo.description device:peripheral];
    } else {
        [self LOG:[NSString stringWithFormat:@"btconnector receive----%@--%@", peripheral, characteristic.value]];
        NSNotification *dataReceiveNoti = [NSNotification notificationWithName:BES_NOTI_BASE_DATA_RECEIVE object:peripheral userInfo:@{@"data" : characteristic.value}];
        [[NSNotificationCenter defaultCenter] postNotification:dataReceiveNoti];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    [self LOG:[NSString stringWithFormat:@"didUpdateNotification------%@", error]];
    if (characteristic.isNotifying) {
        [self LOG:[NSString stringWithFormat:@"didUpdateNotification-----%@------%@", peripheral, characteristic.UUID]];
        [self statusChanged:BES_CONNECT_NOTIFY_SUCCESS msg:@"" device:peripheral];
    } else {
        NSLog(@"Notification stopped on %@.  Disconnecting", characteristic);
        NSLog(@"%@", characteristic);
        [self.centralManager cancelPeripheralConnection:peripheral];
        NSLog(@"didUpdateNotificationStateForCharacteristic-----%@", error.userInfo.description);
        if (error.userInfo.description && [error.userInfo.description containsString:@"Encryption is insufficient"]) {
            [self.centralManager connectPeripheral:self.mBluetoothList[[self getCurIndex:peripheral]] options:nil];
            return;
        }
        [self statusChangedError:BES_CONNECT_NOTIFY_FAIL msg:error.userInfo.description device:peripheral];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSNotification *onWriteNoti = [NSNotification notificationWithName:BES_NOTI_WRITE_ERROR object:peripheral userInfo:@{@"error" : error.description ? error : @"null"}];
    [[NSNotificationCenter defaultCenter] postNotification:onWriteNoti];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    connectTimeout = false;
    [self LOG:[NSString stringWithFormat:@"---------didFailToConnectPeripheral"]];
    [self statusChangedError:BES_CONNECT_FAIL msg:error.userInfo.description device:peripheral];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    [self LOG:[NSString stringWithFormat:@"---------didDisconnectPeripheral"]];
    [self disconnect:peripheral];
    [self statusChangedError:BES_DISCONNECT msg:error.userInfo.description device:peripheral];
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    self.workType = BES_WORKTYPE_UNKNOW;
    NSDictionary *data = @{BES_NOTI_KEY_SCAN_DEVICE : peripheral, BES_NOTI_KEY_SCAN_ADV : advertisementData, BES_NOTI_KEY_SCAN_RSSI : RSSI};
    NSNotification *scanNoti = [NSNotification notificationWithName:BES_NOTI_SCAN_RESULT object:nil userInfo:data];
    [[NSNotificationCenter defaultCenter] postNotification:scanNoti];
}

#pragma mark-------------method
- (void)initCentralManager {
#if  __IPHONE_OS_VERSION_MIN_REQUIRED > __IPHONE_6_0
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], CBCentralManagerOptionShowPowerAlertKey,
                             @"XCYBluetoothRestore", CBCentralManagerOptionRestoreIdentifierKey,
                             nil];
    
#else
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], CBCentralManagerOptionShowPowerAlertKey,
                             nil];
#endif
    
    NSArray *backgroundModes = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"UIBackgroundModes"];
    if ([backgroundModes containsObject:@"bluetooth-central"]) {
        // The background model
        self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:options];
    }
    else {
        // Non-background mode
        self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }
}

#pragma mark - getter/Setter

- (NSMutableArray *)mBluetoothList {
    if (_mBluetoothList) {
        return _mBluetoothList;
    }
    _mBluetoothList = [[NSMutableArray alloc] initWithCapacity:1];
    return _mBluetoothList;
}

- (NSMutableArray<CBPeripheral *> *)discoverPeripherals {
    if (_discoverPeripherals) {
        return _discoverPeripherals;
    }
    
    _discoverPeripherals = [[NSMutableArray alloc] initWithCapacity:1];
    return _discoverPeripherals;
}

- (NSMutableArray *)serviceConfigs {
    if (_serviceConfigs) {
        return _serviceConfigs;
    }

    _serviceConfigs = [[NSMutableArray alloc] initWithCapacity:1];
    return _serviceConfigs;
}

- (NSMutableArray *)totaAesKeys {
    if (_totaAesKeys) {
        return _totaAesKeys;
    }

    _totaAesKeys= [[NSMutableArray alloc] initWithCapacity:1];
    return _totaAesKeys;
}

- (NSMutableArray *)characteristics {
    if (_characteristics) {
        return _characteristics;
    }

    _characteristics = [[NSMutableArray alloc] initWithCapacity:1];
    return _characteristics;
}

#pragma mark-----------simplify delegate
- (void)statusChanged:(BesConnectStateCorrect)state msg:(NSString *)msg device:(CBPeripheral *)device {
    NSDictionary *data = @{BES_NOTI_KEY_STATE : [NSString stringWithFormat:@"%lu", (unsigned long)state], BES_NOTI_KEY_MSG : msg == nil ? @"" : msg};
    NSNotification *statusChangedNoti = [NSNotification notificationWithName:BES_NOTI_STATE_CHANGED object:device userInfo:data];
    [[NSNotificationCenter defaultCenter] postNotification:statusChangedNoti];
}

- (void)statusChangedError:(BesConnectStateError)state msg:(NSString *)msg device:(CBPeripheral *)device {
    NSDictionary *data = @{BES_NOTI_KEY_STATE : [NSString stringWithFormat:@"%lu", (unsigned long)state], BES_NOTI_KEY_MSG : msg == nil ? @"" : msg};
    NSNotification *failedNoti = [NSNotification notificationWithName:BES_NOTI_STATE_CHANGED object:device userInfo:data];
    [[NSNotificationCenter defaultCenter] postNotification:failedNoti];
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
