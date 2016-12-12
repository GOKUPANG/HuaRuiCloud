//
//  HRError.swift
//  huarui
//
//  Created by sswukang on 15/3/27.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import Foundation

enum HRErrorCode: Int {
    case Success            =  0
    
    //Socket错误
    case QueryHostFail      = -1
	///连接已经关闭
    case ConnectionClosed   = -2
	///连接超时
    case ConnectTimeout     = -3
	///连接还在线，但是无效
	case InProgress			= -4
	///Socket未打开
    case SocketNotOpen      = -126
	///未知错误
    case UnknowError        = -127
    
    /**没有网络*/
    case NoConnection       = 1000
    /**超时*/
    case Timeout            = 1001
    /**用户名或密码错误*/
    case AuthDenied         = 1002
    /**收到无效数据*/
    case InvalidData        = 1003
    /**主机不在线*/
    case HostOffline        = 1004
    /**主机没有注册到服务器上*/
    case HostNoRegistration = 1005
    /**内部错误，一般是生成发送帧的时候失败了*/
    case InternalError      = 1006
    /**数据异常*/
	case DataError          = 1007
	/**电池电量不足*/
	case BatteryLowPower    = 1008
	/**登陆超时。已搜索到并连上主机或服务器，但是发送登陆帧时超时没有响应*/
	case LoginTimeout		= 1009
    /**接收到异常帧，1010-1030*/
    case FrameError         = 1010
    case FrameErrorUnknow   = 1031
    ///网络数据包长度超过最大值
    case TooMaxFrameData    = 1040
    ///登陆主机是返回的数据异常，一般都是数据域长度不足导致的
    case LoginRcvDataError  = 1041
    ///搜索主机异常，返回的数据不正确
	case SearchHostDataError = 1042
	///搜索主机超时
	case SearchHostTimeout   = 1043
	///没有权限
	case PermissionDinied    = 1044
	///创建、修改或删除应用设备时主机返回操作失败0x01
	case CreateEditDeleteAppDevFail = 1045
	///红外学习的时候接收的返回帧数据域长度不对
	case InfraredLearnRetDataTooSmall = 1046
	///红外学习失败
	case InfraredLearnFailure = 1047
	///红外学习返回“请求失败”
	case InfraredLearnRequestFailure = 1048
	///在非Wifi的情况下搜索本地主机导致失败
	case SearchLocalServerWithoutWifiStatus = 1049
	///操作用户信息是返回失败结果
	case UserManageFailed	  = 1050
	///创建或编辑楼层返回错误
	case CreateOrEditFloorReturnFailed = 1051
	///修改门锁密码返回错误
	case ChangeDoorLockPasswdRetFailed = 1052
	///设置传感器联动动作值的时候传入了不支持的传感器设备类型
	case SensorNotSupport = 1053
	///传感器联动绑定是设备数量超过限制
	case SensorBindTooMuchDevices = 1054
	///控制RGB灯时出错，参数不对或缺少参数
	case OperateRGBLampFailed = 1055
	/// 使用了非法字符
	case UseIllegalChar		= 1056
	/// 设备或用户名重名
	case DuplicateName		= 1057
	/// 设备名称字符长度超过限制
	case DevNameTooLong		= 1058
	/// 没有学习红外码
	case NoInfraredKeys		= 1059
	
    //外网连接的Socket错误，在原Socket错误的基础上-1500
    case NetQueryHostFail      = -1501
	case NetConnectionClosed   = -1502
	case NetConnectTimeout     = -1503
	case NetInProgress		   = -1504
    case NetSocketNotOpen      = -1626
    case NetUnknowError        = -1627
    
    /**2cu邮箱格式错误*/
    case EmailFormatError   = 1100
    /**2cu邮箱已经使用*/
    case EmailUsed          = 1101
    /**2cu用户不存在*/
    case UserNoExist        = 1102
    /**2cu密码错误*/
    case PasswdError        = 1103
    /**2cu登陆失败*/
    case LoginFailure       = 1104
    /**没有结果， 可能是没有网络*/
	case NoResult			= 1105
    
    case Other              = 3333
	
	/// 生成错误对象
	var error: NSError {
		return NSError(code: self)
	}
	
	/// 错误描述
	var description: String {
		switch self {
		case Success			: return "成功"
		case QueryHostFail		: return "Query Host Fail"
		case ConnectionClosed	: return "连接已经关闭"
		case ConnectTimeout		: return "连接超时"
			///连接还在线，但是无效
		case InProgress			: return "连接失败"
			///Socket未打开
		case SocketNotOpen		: return "网络未连接"
			///未知错误
		case UnknowError			: return "未知错误"
			
			/**没有网络*/
		case NoConnection		: return "网络连接不可用"
			/**超时*/
		case Timeout			: return "等待超时"
			/**用户名或密码错误*/
		case AuthDenied			: return "用户名或密码错误"
			/**收到无效数据*/
		case InvalidData		: return "收到无效数据"
			/**主机不在线*/
		case HostOffline		: return "主机不在线"
			/**主机没有注册到服务器上*/
		case HostNoRegistration : return "主机没有注册到服务器上"
			/**内部错误，一般是生成发送帧的时候失败了*/
		case InternalError		: return "内部数据错误"
			/**数据异常*/
		case DataError			: return "数据异常"
			/**电池电量不足*/
		case BatteryLowPower		: return "电池电量不足"
			/**登陆超时。已搜索到并连上主机或服务器，但是发送登陆帧时超时没有响应*/
		case LoginTimeout		: return "登陆超时"
			/**接收到异常帧，1010-1030*/
		case FrameError			: return "收到异常的数据"
		case FrameErrorUnknow	: return "收到未知异常的数据"
			///网络数据包长度超过最大值
		case TooMaxFrameData		: return "网络数据包超过限制"
			///登陆主机是返回的数据异常，一般都是数据域长度不足导致的
		case LoginRcvDataError	: return "登陆时发生异常"
			///搜索主机异常，返回的数据不正确
		case SearchHostDataError : return "搜索主机时发生异常"
			///搜索主机超时
		case SearchHostTimeout	: return "搜索主机超时"
			///没有权限
		case PermissionDinied	: return "没有权限"
			///创建、修改或删除应用设备时主机返回操作失败0x01
		case CreateEditDeleteAppDevFail	: return "操作失败"
			///红外学习的时候接收的返回帧数据域长度不对
		case InfraredLearnRetDataTooSmall	: return "返回异常数据"
			///红外学习失败
		case InfraredLearnFailure			: return "红外学习失败"
			///红外学习返回“请求失败”
		case InfraredLearnRequestFailure	: return "请求失败"
			///在非Wifi的情况下搜索本地主机导致失败
		case SearchLocalServerWithoutWifiStatus  : return "搜索失败"
			///操作用户信息是返回失败结果
		case UserManageFailed				: return "操作失败"
			///创建或编辑楼层返回错误
		case CreateOrEditFloorReturnFailed  : return "操作失败"
			///修改门锁密码返回错误
		case ChangeDoorLockPasswdRetFailed  : return "操作失败"
			///设置传感器联动动作值的时候传入了不支持的传感器设备类型
		case SensorNotSupport				: return "操作失败：添加了不支持的设备"
			///传感器联动绑定时设备数量超过限制
		case SensorBindTooMuchDevices		: return "操作失败：设备数量超过限制"
			///控制RGB灯时出错，参数不对或缺少参数
		case OperateRGBLampFailed			: return "操作失败：缺少参数"
		case UseIllegalChar					: return "使用了非法字符"
		case DuplicateName					: return "名称重复"
		case DevNameTooLong					: return "名称字符长度超过限制"
		case .NoInfraredKeys					: return "没有学习红外码"
			
			//外网连接的Socket错误，在原Socket错误的基础上-1500
		case NetQueryHostFail			: return "Internet: Query Host Fail"
		case NetConnectionClosed		: return "服务器连接已关闭"
		case NetConnectTimeout			: return "连接服务器超时"
		case NetInProgress				: return "连接服务器失败"
		case NetSocketNotOpen			: return "网络连接不可用"
		case NetUnknowError				: return "未知的网络错误"
			
			/**2cu邮箱格式错误*/
		case EmailFormatError	: return "邮箱格式错误"
			/**2cu邮箱已经使用*/
		case EmailUsed			: return "邮箱已经使用"
			/**2cu用户不存在*/
		case UserNoExist		: return "用户不存在"
			/**2cu密码错误*/
		case PasswdError			: return "密码错误"
			/**2cu登陆失败*/
		case LoginFailure		: return "登陆失败"
			/**没有结果， 可能是没有网络*/
		case NoResult			: return "没有结果"
			
		case Other				: return "其他错误"
		}
	}
}

extension NSError {
	
	convenience init(code: HRErrorCode, description: String) {
		self.init(code: code.rawValue, description: description)
	}
	
	convenience init(code: HRErrorCode) {
		self.init(code: code.rawValue, description: code.description)
	}
}
