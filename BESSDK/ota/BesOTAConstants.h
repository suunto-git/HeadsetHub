//
//  BesOtaConstants.h
//  BesAll
//
//  Created by 范羽 on 2021/2/1.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    STATUS_UNKNOWN,
    STATUS_STARTED,
    STATUS_UPDATING,
    STATUS_PAUSED,
    STATUS_CANCELED,
    STATUS_VERIFYING,
    STATUS_VERIFIED,
    STATUS_FAILED,
    STATUS_SUCCEED,//finished
    STATUS_REBOOT
} BesOTAStatus;


NS_ASSUME_NONNULL_BEGIN
    //cmd msg
    static int                        OTA_CMD_RETURN = 0x00000900;
    static int          OTA_CMD_GET_PROTOCOL_VERSION = 0x00000901;
    static int               OTA_CMD_SET_OAT_USER_OK = 0x00000902;
    static int                   OTA_CMD_GET_HW_INFO = 0x00000903;
    static int       OTA_CMD_SET_UPGRADE_TYPE_NORMAL = 0x00000904;
    static int         OTA_CMD_SET_UPGRADE_TYPE_FAST = 0x00000905;
    static int       OTA_CMD_ROLESWITCH_GET_RANDOMID = 0x00000906;
    static int                OTA_CMD_SELECT_SIDE_OK = 0x00000907;
    static int           OTA_CMD_BREAKPOINT_CHECK_80 = 0x00000908;
    static int              OTA_CMD_BREAKPOINT_CHECK = 0x00000909;
    static int             OTA_CMD_SEND_CONFIGURE_OK = 0x00000910;
    static int                    OTA_CMD_DISCONNECT = 0x00000911;
    static int                 OTA_CMD_SEND_OTA_DATA = 0x00000912;
    static int             OTA_CMD_CRC_CHECK_PACKAGE = 0x00000913;
    static int          OTA_CMD_CRC_CHECK_PACKAGE_OK = 0x00000914;
    static int               OTA_CMD_WHOLE_CRC_CHECK = 0x00000915;
    static int            OTA_CMD_WHOLE_CRC_CHECK_OK = 0x00000916;
    static int            OTA_CMD_IMAGE_OVER_CONFIRM = 0x00000917;
    static int                OTA_SEND_DATA_PROGRESS = 0x00000918;
    static int                OTA_STOP_DATA_TRANSFER = 0x00000919;
//error
    static int                   OTA_START_OTA_ERROR = 0x00000940;
    static int             OTA_CMD_SELECT_SIDE_ERROR = 0x00000941;
    static int          OTA_CMD_SEND_CONFIGURE_ERROR = 0x00000942;
    static int       OTA_CMD_CRC_CHECK_PACKAGE_ERROR = 0x00000943;
    static int         OTA_CMD_WHOLE_CRC_CHECK_ERROR = 0x00000944;
    static int      OTA_CMD_IMAGE_OVER_CONFIRM_ERROR = 0x00000945;
    static int            OTA_CMD_SET_OAT_USER_ERROR = 0x00000946;

//handle_msg
   static int              MSG_GET_VERSION_TIME_OUT = 0x00000950;
   static int             MSG_GET_RANDOMID_TIME_OUT = 0x00000951;
   static int                MSG_OTA_OVER_RECONNECT = 0x00000952;
   static int     MSG_GET_PROTOCOL_VERSION_TIME_OUT = 0x00000953;
   static int         MSG_GET_UPGRATE_TYPE_TIME_OUT = 0x00000954;
   static int          MSG_GET_SELECT_SIDE_TIME_OUT = 0x00000955;
   static int    MSG_GET_CRC_CHECK_PACKAGE_TIME_OUT = 0x00000956;
   static int                 MSG_SET_USER_TIME_OUT = 0x00000957;

   //devicetype
    static int                    DEVICE_TYPE_STEREO = 0x00000930;
    static int          DEVICE_TYPE_TWS_CONNECT_LEFT = 0x00000931;
    static int         DEVICE_TYPE_TWS_CONNECT_RIGHT = 0x00000932;


    static Byte               CONFIRM_BYTE_PASS = 0x01;
    static Byte               CONFIRM_BYTE_FAIL = 0x00;


  //SPHelper
    static NSString*                    BES_OTA_RANDOM_CODE_LEFT = @"BES_OTA_RANDOM_CODE";
    static NSString*                         BES_OTA_CURRENT_MTU = @"BES_OTA_CURRENT_MTU";
    static NSString*              BES_OTA_IS_MULTIDEVICE_UPGRADE = @"BES_OTA_IS_MULTIDEVICE_UPGRADE";

    static BOOL                    DEFAULT_CLEAR_USER_DATA = false;
    static BOOL                  DEFAULT_UPDATE_BT_ADDRESS = false;
    static BOOL                     DEFAULT_UPDATE_BT_NAME = false;
    static BOOL                 DEFAULT_UPDATE_BLE_ADDRESS = false;
    static BOOL                    DEFAULT_UPDATE_BLE_NAME = false;

    //@"YES" : @"NO"
    static NSString*               KEY_OTA_CONFIG_CLEAR_USER_DATA = @"ota_config_clear_user_data";
    static NSString*             KEY_OTA_CONFIG_UPDATE_BT_ADDRESS = @"ota_config_update_bt_address";
    static NSString*       KEY_OTA_CONFIG_UPDATE_BT_ADDRESS_VALUE = @"ota_config_update_bt_address_value";
    static NSString*                KEY_OTA_CONFIG_UPDATE_BT_NAME = @"ota_config_update_bt_name";
    static NSString*          KEY_OTA_CONFIG_UPDATE_BT_NAME_VALUE = @"ota_config_update_bt_name_value";
    static NSString*            KEY_OTA_CONFIG_UPDATE_BLE_ADDRESS = @"ota_config_update_ble_address";
    static NSString*      KEY_OTA_CONFIG_UPDATE_BLE_ADDRESS_VALUE = @"ota_config_update_ble_address_value";
    static NSString*               KEY_OTA_CONFIG_UPDATE_BLE_NAME = @"ota_config_update_ble_name";
    static NSString*         KEY_OTA_CONFIG_UPDATE_BLE_NAME_VALUE = @"ota_config_update_ble_name_value";

@interface BesOtaConstants : NSObject



@end

NS_ASSUME_NONNULL_END
