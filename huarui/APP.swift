//
//  APP.swift
//  huarui
//
//  Created by sswukang on 15/2/4.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import UIKit
import Foundation

typealias Byte = UInt8

class APP: NSObject {
    struct param {
		static var themeColor: UIColor!
		static var selectedColor: UIColor!
        static var backgroundImgName: String!
    }
}


//MARK: - 全局方法

func runOnMainQueue(block: ()->Void) {
    dispatch_async(dispatch_get_main_queue(), block)
}

func runOnGlobalQueue(block: ()->Void) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block)
}

/**延时delayMs毫秒之后在主线程运行block*/
func runOnMainQueueDelay(delayMs: Int64, block: ()->Void) {
    let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(delayMs * 1000_000))
    dispatch_after(delay, dispatch_get_main_queue(), block)
}

/**
延时delayMs毫秒之后在主线程运行block

- parameter delayMs: 毫秒
- parameter block:   block
*/
func runOnGlobalQueueDelay(delayMs: Int64, block: ()->Void) {
    let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(delayMs * 1000_000))
    dispatch_after(delay, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block)
}

///本地化的字符串
func NSLocalizedString(key: String) -> String {
	return NSLocalizedString(key, comment: key)
}

///设备模型
enum CurrentDeviceModel {
	case iPad
	case iPhone
	case iPodTouch
	case Unknow
}




