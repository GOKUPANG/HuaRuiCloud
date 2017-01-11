//
//  swift
//  huarui
//
//  Created by sswukang on 15/1/6.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import Foundation

//MARK: - 全局静态值

/** 数据帧长度 */
let DATA_FRAME_MAX: Int			= 1440
///发送UDP的端口
let UDP_HOST_PORT: UInt16        = 9881
///连接本地主机的端口
let TCP_HOST_PORT_WIFI: UInt16   = 9882
///连接服务器的端口
let TCP_HOST_PORT_NET: UInt16    = 9889
/**发送广播的次数*/
let SEND_BROADCAST_TIMES         = 3
/**每次发送广播之后接收的超时时间（毫秒）*/
let BROADCAST_TIME_OUT: Int32    = 1500
/**TCP接收超时，单位毫秒*/           //门锁相关  原来是6000
let TCP_RCV_TIMEOUT: Int         = 8000
/**TCP创建连接超时，单位毫秒*/
let TCP_CNCT_TIMEOUT: Int        = 5000

///登陆超时时间，单位为毫秒
//let LOGIN_TIME_OUT:Int32         = 5000

/// 登陆超时时间  ，原本是5秒 现在改成10秒
let LOGIN_TIME_OUT:Int32         = 10000




///搜索主机的广播地址
let BROADCAST_ADDRESS            = "255.255.255.255"
/**外网服务器IP地址*/
let NET_SERVER_ADDR              = "120.24.183.44"
/**正式版更新的url*/
let UPDATE_VERSION_URL_FULL      = "http://183.63.118.58:9885/commons/ios/ios_phone/full/version.json"

/**测试版更新的url*/
let UPDATE_VERSION_URL_BETA      = "http://183.63.118.58:9885/commons/ios/ios_phone/beta/version_beta.json"
/**讯飞语音appid*/
let IFLY_APPID                   = "55307f53"
/// 友盟数据统计
let UMENG_APP_KEY				 = "5684ecc067e58e2cc2002804"

///传感器值
let SOLAR_MAX: Int = 4000
/** solar min */
let SOLAR_MIN: Int = 0
/** gas max */
let GAS_MAX: Float = 100.00;
/** gas min */
let GAS_MIN: Float = 0;
/** temp max */
let AQS_TEMP_MAX: Float = 60.0;
/** temp min */
let AQS_TEMP_MIN: Float = -10.0;
/** 空气质量传感器 max */
let AQS_HUMI_MAX: Float = 100.0;
/** 空气质量传感器 min */
let AQS_HUMI_MIN: Float = 0;


///域domain，
let kDomain = "com.huaruicloud"

//MARK: --通知的key

/// 查询设备完成
let kNotificationQueryDone = "hr_query_device_done"
/// 登陆完成
let kNotificationUserDidLogined  = "hr_user_did_logined"
/// 网络状态改变，如断开/连接Wifi，切换到WWAN。。。
let kNotificationNetworkStatusChanged = "hr_network_status_changed"
/// 与主机/服务器连接的Socket断开了
let kNotificationDidSocketDisconnected = "hr_did_socket_disconnected"
/// App与主机/服务器连接成功
let kNotificationDidSocketConnected = "hr_did_socket_connected"
/// 删除设备
let kNotificationDeviceDidDeleted = "hr_deivce_did_deleted"

//MARK: -- APP样式

//1px的线宽
let singleLineWidth = 1/UIScreen.mainScreen().scale
//画1px宽度的线是的偏移值
let singleLineAdjustOffset = singleLineWidth/2


//MARK: --share todo
let SHARETODO_NOTHING = 0
///编辑情景
let SHARETODO_EDIT_SCENE = 100
///记录空调遥控按键
let SHARETODO_RECORD_AIR_CTRL = 101
///记录电视遥控按键
let SHARETODO_RECORD_TV_CTRL = 102
///记录电视遥控按键
let SHARETODO_RECORD_RGB_COLOR = 103
///电视遥控学习红外
let SHARETODO_LEARNING_TV_CTRL = 104
/// 注册并编辑继电器设备
let SHARETODO_REGISTER_AND_EDIT_RELAY = 105
/// 查看情景
let SHARETODO_VIEW_SCENE_DETAIL = 106
/// 编辑或新建情景
let SHARETODO_EDIT_OR_CREATE_SCENE = 107



//MARK: --计算属性

///版本号
var appVersionStr: String {
	if let version = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as? String {
		return version
	} else {
		return ""
	}
}

///当前设备
var currentDeviceModel: CurrentDeviceModel {
	switch UIDevice.currentDevice().model {
	case "iPad":
		return .iPad
	case "iPhone":
		return .iPhone
	case "iPod Touch":
		return .iPodTouch
	default:
		return .Unknow
	}
}
/// 网络状态检测
let reachChecker = Reachability.reachabilityForInternetConnection()
