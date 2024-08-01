//
//  BesSdkConstants.h
//  BesAll
//
//  Created by 范羽 on 2021/1/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
typedef enum : NSUInteger {
    BES_PROTOCOL_BLE,
    BES_PROTOCOL_GATT,
} BesDeviceProtocol;

typedef enum : NSUInteger {
    BES_CONNECT_SUCCESS,
    BES_CONNECT_DISCOVERSERVICE_SUCCESS,
    BES_CONNECT_NOTIFY_SUCCESS,
} BesConnectStateCorrect;

typedef enum : NSUInteger {
    BES_DISCONNECT,
    BES_CONNECT_FAIL,
    BES_CONNECT_DISCOVERSERVICE_FAIL,
    BES_CONNECT_NOTIFY_FAIL,
    BES_SENDDATA_ERROR
} BesConnectStateError;

typedef enum : NSUInteger {
    BES_CONFIG_ERROR,  //current config parameter incomplete
    BES_NO_CONNECT,    //The current status is No connection
    BES_CONNECT_NOTOTA,//The current status Is connected, not TOTA connection, does not match current config
    BES_CONNECT_TOTA,  //The current status Is connected, TOTA connection, does not match current config
    BES_CONNECT        //The current status Is connected, match current config, you can use it directly
} BesConnectState;

//handle_msg
   static int                                MSG_TIME_OUT = 0x00000404;
   static int                         MSG_PARAMETER_ERROR = 0x00000405;

   static int                                 DEFAULT_MTU = 509;

   static NSString                      *BES_SAVE_LOG_KEY = @"BES_SAVE_LOG";//YES:NO
   static NSString                *BES_SAVE_DEFAULT_VALUE = @"YES";
   static NSString                *BES_SAVE_LOG_TITLE_KEY = @"BES_SAVE_LOG_TITLE";
   static BOOL                       BES_SHOW_CONSOLE_LOG = true;

//TOTA
   static int                              BES_TOTA_START = 0x00000300;
   static int                            BES_TOTA_CONFIRM = 0x00000301;
   static int                            BES_TOTA_SUCCESS = 0x00000302;
   static int                              BES_TOTA_ERROR = 0x00000303;
   static NSString               *BES_TOTA_ENCRYPTION_KEY = @"BES_TOTA_ENCRYPTION_KEY";
   static NSString                   *BES_TOTA_USE_TOTAV2 = @"BES_TOTA_USE_TOTAV2";
   static NSString             *BES_TOTA_ENCRYPTION_VALUE = @"YES";
   static NSString             *BES_TOTA_USE_TOTAV2_VALUE = @"YES";

//notifications
   static NSString                    *BES_NOTI_KEY_STATE = @"BES_NOTI_KEY_STATE";
   static NSString                      *BES_NOTI_KEY_MSG = @"BES_NOTI_KEY_MSG";
   static NSString              *BES_NOTI_KEY_SCAN_DEVICE = @"BES_NOTI_KEY_SCAN_DEVICE";
   static NSString                 *BES_NOTI_KEY_SCAN_ADV = @"BES_NOTI_KEY_SCAN_ADV";
   static NSString                *BES_NOTI_KEY_SCAN_RSSI = @"BES_NOTI_KEY_SCAN_RSSI";

   static NSString                *BES_NOTI_STATE_CHANGED = @"BES_NOTI_STATE_CHANGED";
   static NSString                 *BES_NOTI_STATE_FAILED = @"BES_NOTI_STATE_FAILED";
   static NSString                 *BES_NOTI_DATA_RECEIVE = @"BES_NOTI_DATA_RECEIVE";
   static NSString            *BES_NOTI_BASE_DATA_RECEIVE = @"BES_NOTI_BASE_DATA_RECEIVE";
   static NSString                  *BES_NOTI_WRITE_ERROR = @"BES_NOTI_WRITE_ERROR";
   static NSString                  *BES_NOTI_SCAN_RESULT = @"BES_NOTI_SCAN_RESULT";
   static NSString               *BES_NOTI_TOTA_CON_STATE = @"BES_NOTI_TOTA_CONNECT_STATE";
   static NSString                  *BES_NOTI_MSG_TIMEOUT = @"BES_NOTI_MSG_TIMEOUT";
   static NSString             *BES_NOTI_MSG_TIMEOUT_WHAT = @"BES_NOTI_MSG_TIMEOUT_WHAT";

   static int             BES_NOTI_MSG_TIMEOUT_TOTA_START = 0x00000401;


@interface BesSdkConstants : NSObject





@end

NS_ASSUME_NONNULL_END
