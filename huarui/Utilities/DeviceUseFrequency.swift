//
//  FrequencySort.swift
//  huarui
//
//  Created by sswukang on 15/3/17.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

/**
json格式：
[
	{
		"acount" : "hr8001",
		"devices" : 
		[
			{
				"lastTime" : 1438161782.079293,
				"count" : 3,
				"devAddr" : 111,
				"minorID": 0,
				"name" : "设备1",
				"devType" : 90
			},
			{
				"devType" : 90,
				"lastTime" : 1438162071.778781,
				"devAddr" : 222,
				"minorID": 0,
				"count" : 3,
				"name" : "设备2"
			}
		]
	}
]
**/

import Foundation


let MaxDeviceUseFrequency = 50
let jsonFile = "device_use_frequency.json"

///设备使用频率
class DeviceUseFrequency {
	
	
	
	///获取本地记录的设备，结合本地设备返回常用设备数组，索引越小代表使用频率越高
	///
	///- parameter devices: 数据库中的设备列表
	class func getLocalDevicesBySort(acount: String, devices: [HRDevice]) -> [HRDevice]{
		var resultDevs = [HRDevice]()
		
		//1.打开文件
		let path = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.AllDomainsMask, true)
		
		let filePath = NSURL(fileURLWithPath: path[0]).URLByAppendingPathComponent(jsonFile)!.path!

		if !NSFileManager.defaultManager().fileExistsAtPath(filePath) {
			Log.error("读JSON文件出错：【\(jsonFile)】文件不存在。")
			//文件不存在
			return resultDevs
		}
		guard let data = NSData(contentsOfFile: filePath) else {
			Log.error("读JSON文件出错：没有内容。")
			return resultDevs
		}
		var error: NSError?
		//2.读出列表
		let json = JSON(data: data, options: NSJSONReadingOptions.AllowFragments, error: &error)
		if let err = error {
			Log.error("读JSON文件出错：\(err.localizedDescription)")
			return resultDevs
		}
		var localDevs: JSON = nil
		for (_, subJson) in json {
			if subJson["acount"].string == acount {
				localDevs = subJson["devices"]
			}
		}
		if localDevs == nil {
			return resultDevs
		}
		//3.从新数组中提取设备
		for devJson in localDevs.arrayValue {
			for dev in devices {
				if deviceEqualJson(dev, json: devJson) {
					resultDevs.append(dev)
				}
			}
		}
		
		
//		let str = NSString(data: JSON(newDevs).rawData(options: NSJSONWritingOptions.PrettyPrinted, error: nil)!, encoding: NSUTF8StringEncoding)
//		println(str!)
		
		return resultDevs
	}
	
	
	///添加一个设备
	class func addDevice(acount: String, device: HRDevice) {
		
		//1.打开文件
		let path = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.AllDomainsMask, true)
		let filePath = NSURL(fileURLWithPath: path[0]).URLByAppendingPathComponent(jsonFile)!.path!

		if !NSFileManager.defaultManager().fileExistsAtPath(filePath) {
			//文件不存在
			let contents = NSString(string: "[ ]").dataUsingEncoding(NSUTF8StringEncoding)
			NSFileManager.defaultManager().createFileAtPath(filePath, contents: contents, attributes: nil)
		}
		var error: NSError?
		var json = JSON(data: NSData(contentsOfFile: filePath)!, options: NSJSONReadingOptions.AllowFragments, error: &error)
		if let err = error {
			Log.error("addDevice.添加设备到JSON中出错：\(err.localizedDescription)")
			return
		}
		if json.object as! NSObject == NSNull() {
			json = JSON(NSArray())
		}
		//2.查找账户
		var acountJson: JSON = JSON(["acount": acount])
		for (index, subJson) in json {
			if subJson["acount"].string == acount {
				acountJson.object = json.arrayObject!.removeAtIndex(Int(index)!)
			}
		}
		
		//3.查找设备，如果有设备，则替换；如果没有，则追加
		var newDevJson = newDeviceJson(device)
		
		if acountJson["devices"].arrayObject == nil {	//如果一个设备都没有
			acountJson["devices"] = [newDevJson.object]
		} else {	//如果有设备
			
			///是否有相同的设备
			var hasSameDevice = false
			//搜索相同设备
			for (index, devJson) in acountJson["devices"] {
				if deviceEqualJson(device, json: devJson) {
					newDevJson["count"].intValue = devJson["count"].intValue == Int.max ? 100 : devJson["count"].intValue + 1
					newDevJson["lastTime"].doubleValue = NSDate().timeIntervalSince1970
					acountJson["devices"].arrayObject?.removeAtIndex(Int(index)!)
					hasSameDevice = true
					break
				}
			}
			//如果没有相同设备，则判断列表是否达到最大长度，如果是，则去除最不常用的
			if !hasSameDevice &&
				acountJson["devices"].arrayValue.count == MaxDeviceUseFrequency {
					//去除最不常用的设备方法，使用次数count最小的，如果有多个最小的count值，则删除时间lastTime最小的
					var minValue = Int.max
					var minCount = 0
					var minIndex = 0
					for (index, dev) in acountJson["devices"] {
						if dev["count"].intValue <= minValue {
							minCount += 1
							minValue = dev["count"].intValue
							minIndex = Int(index)!
						}
					}
					if minCount > 1 {	//最少使用次数的设备多于1个
						var minTime = acountJson["devices"][0]["lastTime"].doubleValue
						for (index, dev) in acountJson["devices"] {
							if dev["count"].intValue == minValue &&
								dev["lastTime"].doubleValue <= minTime {
									minTime = dev["lastTime"].doubleValue
									minIndex = Int(index)!
							}
						}
					}
					acountJson["devices"].arrayObject?.removeAtIndex(minIndex)
			}
			acountJson["devices"].arrayObject?.append(newDevJson.object)
			//重新排序
			acountJson["devices"].arrayObject = (acountJson["devices"].arrayObject!).sort(sortGT)
			
		}
		json.arrayObject?.append(acountJson.object)
		
		(try? json.rawData(options: NSJSONWritingOptions.PrettyPrinted))?.writeToFile(filePath, atomically: false)
//		var jstr = NSString(data: json.rawData(options: NSJSONWritingOptions.PrettyPrinted, error: nil)!, encoding: NSUTF8StringEncoding)
//		println("最终json：\n\(jstr!)")
	}
	
	/// 删除设备
	class func removeDevice(acount: String, device: HRDevice){
		//1.打开文件
		let path = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.AllDomainsMask, true)
		let filePath = NSURL(fileURLWithPath: path[0]).URLByAppendingPathComponent(jsonFile)!.path!
		
		if !NSFileManager.defaultManager().fileExistsAtPath(filePath) {
			return
		}
		var error: NSError?
		//2.读出列表
		var json = JSON(data: NSData(contentsOfFile: filePath)!, options: NSJSONReadingOptions.AllowFragments, error: &error)
		if let err = error {
			Log.error("removeDevice.从JSON中删除设备出错：\(err.localizedDescription)")
			return
		}
		
		for (aindex, subJson) in json {
			if subJson["acount"].string == acount {
				json[Int(aindex)!]["devices"].arrayObject = subJson["devices"].arrayObject?.filter({
					return !self.deviceEqualJson(device, json: JSON($0))
				})
				break
			}
		}
		(try? json.rawData(options: NSJSONWritingOptions.PrettyPrinted))?.writeToFile(filePath, atomically: false)
	}
	
	private class func newDeviceJson(device: HRDevice) -> JSON {
		let _minorID: UInt32
		switch device.devType {
		case HRDeviceType.ApplyDevice.rawValue :
			_minorID = (device as! HRApplianceApplyDev).appDevID
		case HRDeviceType.relayTypes():
			if let relay = device as? HRRelayInBox {
				_minorID = UInt32(relay.relaySeq)
			} else {
				_minorID = 0
			}
		default:
			_minorID = 0
		}
		let jsonDic = [
			"name" : device.name,
			"devType" : Int(device.devType),
			"devAddr" : UInt(device.devAddr),
			"minorID" : UInt(_minorID),
			"count": 1,
			"lastTime": NSDate().timeIntervalSince1970
		]
		
		return JSON(jsonDic)
	}
	
	///判断设备是否和json数据是相同的
	private class func deviceEqualJson(device: HRDevice, json: JSON) -> Bool {
		switch device.devType {
		case HRDeviceType.ApplyDevice.rawValue:
			return device.devAddr == json["devAddr"].uInt32Value
				&& (device as! HRApplianceApplyDev).appDevID == json["minorID"].uInt32Value
		case HRDeviceType.relayTypes():
			if device is HRRelayComplexes {
				return device.devAddr == json["devAddr"].uInt32Value
			} else {
				return device.devAddr == json["devAddr"].uInt32Value
				&& (device as! HRRelayInBox).relaySeq == json["minorID"].uInt8Value
			}
		default:
			return device.devAddr == json["devAddr"].uInt32Value
		}
		
		
	}
	
	private class func sortGT(obj1: AnyObject, obj2: AnyObject) -> Bool{
		let json1 = obj1 as! NSDictionary
		let json2 = obj2 as! NSDictionary
		let count1 = json1["count"]!.intValue
		let count2 = json2["count"]!.intValue
		if count1 > count2 {
			return true
		}
		else if count1 == count2 {
			if json1["lastTime"]!.doubleValue > json2["lastTime"]!.doubleValue {
				return true
			}
		}
		return false
	}
}
