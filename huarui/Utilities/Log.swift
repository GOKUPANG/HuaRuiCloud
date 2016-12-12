//
//  Log.swift
//  huarui
//
//  Created by sswukang on 16/3/21.
//  Copyright © 2016年 huarui. All rights reserved.
//

import Foundation


///调试等级,分为5个等级
///
/// 1、输出大于或等于VERBOSE日志级别的信息
/// 2、输出大于或等于DEBUG日志级别的信息
/// 3、输出大于或等于INFO日志级别的信息
/// 4、输出大于或等于WARN日志级别的信息
/// 5、仅输出ERROR日志级别的信息.
let DEBUG_LEVEL = 1

///调试
///
/// 1、Log.v的输出为白色，输出大于或等于VERBOSE日志级别的信息
/// 2、Log.d的输出为绿色，输出大于或等于DEBUG日志级别的信息
/// 3、Log.i的输出为蓝色，输出大于或等于INFO日志级别的信息
/// 4、Log.w的输出为橙色, 输出大于或等于WARN日志级别的信息
/// 5、Log.e的输出为红色，仅输出ERROR日志级别的信息.
class Log {
	///任何信息，输出要求DEBUG_LEVEL<=1
	class func verbose(message: String, function: String = #function) {
		//#if DEBUG
		if DEBUG_LEVEL <= 1 {
			DDLogVerbose(message)
		}
		//#endif
	}
	///调试信息，输出要求DEBUG_LEVEL<=2
	class func debug(message: String, function: String = #function) {
		//#if DEBUG
		if DEBUG_LEVEL <= 2 {
			DDLogDebug(message)
		}
		//#endif
	}
	///一般信息，输出要求DEBUG_LEVEL<=3
	class func info(message: String, function: String = #function) {
		//#if DEBUG
		if DEBUG_LEVEL <= 3 {
			DDLogInfo(message)
		}
		//#endif
	}
	///警告信息，输出要求DEBUG_LEVEL<=4
	class func warn(message: String, function: String = #function) {
		//#if DEBUG
		if DEBUG_LEVEL <= 4 {
			DDLogWarn(message)
		}
		//#endif
	}
	///出错信息，输出要求DEBUG_LEVEL<=5
	class func error(message: String, function: String = #function) {
		//#if DEBUG
		if DEBUG_LEVEL <= 5 {
			DDLogError(message)
		}
		//#endif
	}
}

