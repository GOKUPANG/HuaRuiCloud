//
//  HRDatabase.swift
//  huarui
//
//  Created by sswukang on 16/1/22.
//  Copyright © 2016年 huarui. All rights reserved.
//

import Foundation

class HRDatabase: NSObject  {
	
	///自定义变量，是否应该在线，作为网络断开之后重连的依据
	var shouldOnline: Bool = false
	
	/**当前登陆的账号*/
    var acount: HRAcount     = HRAcount()
	/**连接的主机/服务器*/
    var server: HRServerHost = HRServerHost() {
		didSet{
			let bytes = server.IPAddr.getBytes()
			NSUserDefaults.standardUserDefaults().setValue("\(bytes[0]).\(bytes[1]).\(bytes[2]).\(bytes[3])", forKey: "hostIPAddressString")
		}
	}
	/**HR8000/HR8001智能主机设备*/
	dynamic var master: HRMaster?
	
	///设备数据，所有的设备都保存在这个字典，key是设备类型，value是设备数组
	private var devices = [Byte: [HRDevice]]()
	
	
	private override init() {}
	//建立单例
	class func shareInstance() -> HRDatabase{
		struct Singleton{
			static var predicate: dispatch_once_t  = 0
			static var instance: HRDatabase? = nil
		}
		dispatch_once(&Singleton.predicate, {
			Singleton.instance = HRDatabase()
		})
		return Singleton.instance!
	}
	
	//MARK: - 计算属性
	
	/// 楼层
	var floors: [HRFloorInfo] {
		get {
			if let fls = self.devices[HRDeviceType.FloorInfo.rawValue] as? [HRFloorInfo] {
				return fls
			}
			return [HRFloorInfo]()
		}
		set { self.devices[HRDeviceType.FloorInfo.rawValue] = newValue }
	}
	
	/// 红外转发器
	var infrareds: [HRInfraredTransmitUnit] {
		get {
			if let _infrareds = self.devices[HRDeviceType.InfraredTransmitUnit.rawValue] as? [HRInfraredTransmitUnit] {
				return _infrareds
			}
			return [HRInfraredTransmitUnit]()
		}
		set { self.devices[HRDeviceType.InfraredTransmitUnit.rawValue] = newValue }
	}
	
	
	//MARK: - 保存设备
	
	/**
	保存设备
	- parameter dev: 设备对象
	- returns: 返回和设备相同类型的数组，以及保存的设备所在的索引
	*/
	func saveDevice(dev: HRDevice) -> ([HRDevice], Int) {
		if devices[dev.devType] == nil {
			devices[dev.devType] = [HRDevice]()
		}
		let index = devices[dev.devType]!.appendReplace(dev)
		return (devices[dev.devType]!, index)
	}
	
	//MARK: - 删除设备
	
	/**清空所有设备数据*/
	func deleteAll(){
		master = nil
		devices.removeAll(keepCapacity: false)
	}
	
	/**
	删除指定的设备类型
	
	- parameter devType: 设备类型
	*/
	func remove(devType: HRDeviceType) {
		self.remove(devType.rawValue)
	}
	
	
	/**
	删除指定类型所有设备
	- parameter devType: 设备类型
	*/
	func remove(devType: Byte) {
		switch devType {
		case HRDeviceType.Master.rawValue: self.master = nil
			/**广播专用，亦指所有设备类型*/
		case HRDeviceType.Braodcast.rawValue: deleteAll()
		default:
			devices[devType] = nil
		}
	}
	
	/**
	删除指定的设备
	
	- parameter devType: 设备类型
	- parameter devAddr: 设备地址
	- returns: 返回被删除的设备，如果参数指定的设备不存在，则返回nil
	*/
	func removeDevice(devType: HRDeviceType, devAddr: UInt32) -> HRDevice? {
		return removeDevice(devType.rawValue, devAddr: devAddr)
	}
	
	func removeDevice(devType: Byte, devAddr: UInt32) -> HRDevice? {
		switch devType {
		case HRDeviceType.Master.rawValue:
			self.master = nil
		default:
			if let devs = devices[devType] {
				for (idx, dev) in devs.enumerate() where dev.devAddr == devAddr {
					return devices[devType]!.removeAtIndex(idx)
				}
			}
		}
		return nil
	}
	
	/**
	删除情景
	
	- parameter sceneId: 情景ID
	
	- returns: 被删除的情景，和其所在情景数组的索引
	*/
	func removeScene(id sceneId: Byte) -> (HRScene, Int)? {
		if let scenes = devices[HRDeviceType.Scene.rawValue] as? [HRScene] {
			for (idx, curScene) in scenes.enumerate() where curScene.id == sceneId {
				if let sceneByRm = devices[HRDeviceType.Scene.rawValue]?.removeAtIndex(idx) as? HRScene {
					return (sceneByRm, idx)
				}
			}
		}
		return nil
	}
	
	/**
	删除应用设备
	- parameter appDevType: 应用设备类型
	- parameter id: 应用设备ID
	- returns: 被删除的应用设备
	*/
	func removeApplyDevice(appDevType:Byte, id: UInt32) -> HRApplianceApplyDev? {
		if let appDevs = devices[HRDeviceType.ApplyDevice.rawValue] as? [HRApplianceApplyDev] {
			for (idx, curAppDev) in appDevs.enumerate() where curAppDev.appDevType == appDevType && curAppDev.appDevID == id {
				if let appDevByRm = devices[HRDeviceType.ApplyDevice.rawValue]?.removeAtIndex(idx) as? HRApplianceApplyDev {
					return appDevByRm
				}
			}
		}
		return nil
	}
	 
	
	//MARK: - 获取设备
	
	/**
	获取设备
	- parameter devType: 设备类型
	- parameter devAddr: 设备地址
	*/
	func getDevice(devType: Byte, devAddr: UInt32) -> HRDevice? {
		if let devs = devices[devType] {
			for dev in devs where dev.devAddr == devAddr {
				return dev
			}
		}
		return nil
	}
	/**
	获取设备
	- parameter devType: 设备类型
	- parameter devAddr: 设备地址
	*/
	func getDevice(devType: HRDeviceType, devAddr: UInt32) -> HRDevice? {
		return getDevice(devType.rawValue, devAddr: devAddr)
	}
	
	/**
	获取情景
	- parameter id: 情景ID
	- returns: 情景
	*/
	func getScene(sceneId id: Byte) -> HRScene? {
		if let scenes = devices[HRDeviceType.Scene.rawValue] as? [HRScene] {
			for scene in scenes where scene.id == id {
				return scene
			}
		}
		return nil
	}
	
	/**
	获取应用设备
	- parameter id: 应用设备ID
	- returns: 应用设备
	*/
	func getApplyDevice(appId id: UInt32) -> HRApplianceApplyDev? {
		if let appDevs = devices[HRDeviceType.ApplyDevice.rawValue] as? [HRApplianceApplyDev] {
			for appDev in appDevs where appDev.appDevID == id {
				return appDev
			}
		}
		return nil
	}
	
	/**
	获取指定类型设备
	- parameter devType: 设备类型
	- returns: 返回指定类型的所有设备，如果不存在该类型的设备，则返回nil
	*/
	func getDevicesOfType(devType: Byte) -> [HRDevice]? {
		if devices[devType] == nil {
			devices[devType] = [HRDevice]()
		}
		return devices[devType]!
	}
	
	/**
	获取指定类型设备
	- parameter devType: 设备类型
	- returns: 返回指定类型的所有设备，如果不存在该类型的设备，则返回nil
	*/
	func getDevicesOfType(devType: HRDeviceType) -> [HRDevice]? {
		return getDevicesOfType(devType.rawValue)
		
	}
	
	/**
	获取指定类型的设备，返回的长度为0的数组
	- parameter devType: 设备类型
	- returns: 设备数组，如果没有该设备，则数组count为0
	*/
	func getNonilDevicesOfType(devType: HRDeviceType) -> [HRDevice] {
		return getNonilDevicesOfType(devType.rawValue)
	}
	
	/**
	获取指定类型的设备，返回的长度为0的数组
	- parameter devType: 设备类型
	- returns: 设备数组，如果没有该设备，则数组count为0
	*/
	func getNonilDevicesOfType(devType: Byte) -> [HRDevice] {
		if let devs = getDevicesOfType(devType) {
			return devs
		}
		return [HRDevice]()
	}
	
	/**
	获取指定类型的设备
	- parameter devTypes: 类型集合，可以指定多个类型。
	- returns: 返回所有指定类型的设备，即使这些都不存在这些类型的设备，也不会返回nil
	*/
	func getDevicesOfTypes(devTypes: [Byte]) -> [HRDevice] {
		var devs = [HRDevice]()
		for type in devTypes {
			if let sigDevs = getDevicesOfType(type) {
				devs += sigDevs
			}
		}
		return devs
	}
	
	/**
	获取指定类型的设备
	- parameter devTypes: 类型集合，可以指定多个类型。
	- returns: 返回所有指定类型的设备，即使这些都不存在这些类型的设备，也不会返回nil
	*/
	func getDevicesOfTypes(devTypes: [HRDeviceType]) -> [HRDevice] {
		var devs = [HRDevice]()
		for type in devTypes {
			if let sigDevs = getDevicesOfType(type.rawValue) {
				devs += sigDevs
			}
		}
		return devs
	}
	
	var floorNames: [String] {
		var names = [String]()
		if let floors = getDevicesOfType(HRDeviceType.FloorInfo.rawValue) as? [HRFloorInfo] {
			for floor in floors {
				names.append(floor.name)
			}
		}
		return names
	}
	
	var roomNames: [String: [String]] {
		var namesDic = [String: [String]]()
		if let floors = getDevicesOfType(HRDeviceType.FloorInfo.rawValue) as? [HRFloorInfo] {
			for floor in floors {
				var roomNames = [String]()
				for room in floor.roomInfos {
					roomNames.append(room.name)
				}
				namesDic[floor.name] = roomNames
			}
		}
		return namesDic
	}
	
	///可编辑的权限，如果acount的权限为2或3则为可编辑权限，其他为不可编辑
	static var isEditPermission: Bool {
        
		let permission = HRDatabase.shareInstance().acount.permission
		return permission == 2 || permission == 3
        
	}
	
	/// 管理员
	static var isAdminUser: Bool {
		return HRDatabase.shareInstance().acount.permission == 2
	}
	
	/// 超级用户
	static var isSuperUser: Bool {
		return HRDatabase.shareInstance().acount.permission == 3
	}
	
	/**获取控制类电器设备，包括继电器，开关，插座，应用设备，电机控制器，各类传感器...*/
	func getAllCtrlDevices() -> [HRDevice]{
		var ctrlDevs = [HRDevice]()
		for relay in getAllRelays() {
			ctrlDevs.append(relay)
		}
		let ctrlTypes: [HRDeviceType] = [
			.RGBLamp,
			.CurtainControlUnit,
			.Manipulator,
			.ApplyDevice,
			.GasSensor,
			.HumiditySensor,
			.SolarSensor,
			.AirQualitySensor,
		]
		ctrlDevs += getDevicesOfTypes(ctrlTypes)
		return ctrlDevs
	}
	
	/**获取所有继电器控制盒的所有通道*/
	func getAllRelays() -> [HRRelayInBox] {
		var relays = [HRRelayInBox]()
		let relayBoxs = self.getAllRelayBoxs()
		for box in relayBoxs {
			for relay in box.relays {
				relays.append(relay)
			}
		}
		return relays
	}
	
	/**
	获取所有继电器控制盒大类型的设备
	- returns: `[HRRelayComplexes]`
	*/
	func getAllRelayBoxs() -> [HRRelayComplexes] {
		return getDevicesOfTypes(HRDeviceType.relayTypes()) as! [HRRelayComplexes]
	}
	
	
	/**获取指定房间的所有设备(包括继电器、开关、插座、应用设备和窗帘)*/
	func getDevicesFromRoom(floorId: UInt16, roomId: UInt16) -> [HRDevice] {
		let ctrlTypes: [HRDeviceType] =  [
			.RGBLamp,
			.CurtainControlUnit,
			.Manipulator,
			.ApplyDevice,
		]
		var allDevs:[HRDevice] = getAllRelays()
		allDevs += getDevicesOfTypes(ctrlTypes)
		return allDevs.reduce([HRDevice]()) { (reDevs, device) -> [HRDevice] in
			var _reDevs = reDevs
			if device.insRoomID == roomId && device.insFloorID == floorId {
				_reDevs.append(device)
			}
			return _reDevs
		}
	}
	
	
	/**获取指定房间的所有设备(包括继电器、开关、插座、应用设备和窗帘)*/
	func getDevicesFromRoom(floor: String, room: String) -> [HRDevice]?{
		let roomId  = getRoomID(floor, roomName: room)
		let floorId = getFloorID(floor)
		if roomId == nil || floorId == nil {
			return nil
		}
		return getDevicesFromRoom(UInt16(floorId!), roomId: roomId!)
	}
	
	///获取楼层里的所有设备，
	///
	/// - parameter floorID: 楼层ID
	/// - parameter deviceMask: 设备mask， 也可以理解为过滤，只要是在deviceMask中制定的设备类型，就会返回。
	/// - returns 返回设备数组
	func getDevicesFromFloor(floorID: UInt16, devicesMask mask: [HRDeviceType]) -> [HRDevice] {
		return getDevicesOfTypes(mask).filter { (curDev) -> Bool in
			return curDev.insFloorID == floorID
		}
	}
	
	/**获取指定楼层的房间列表*/
	func getRooms(floorId: UInt16) -> [HRRoomInfo]?{
		if let floors = getDevicesOfType(.FloorInfo) as? [HRFloorInfo] {
			for floor in floors {
				if floor.id == floorId {
					return floor.roomInfos
				}
			}
		}
		return nil
	}
	
	/**获取指定楼层的房间列表*/
	func getRooms(floorName: String) -> [HRRoomInfo]?{
		if let floors = getDevicesOfType(.FloorInfo) as? [HRFloorInfo] {
			for floor in floors {
				if floor.name == floorName {
					return floor.roomInfos
				}
			}
		}
		return nil
	}
	
	/**获取房间ID*/
	func getRoomID(floorName: String, roomName: String) -> UInt16? {
		if let floors = getDevicesOfType(.FloorInfo) as? [HRFloorInfo] {
			for floor in floors {
				if floor.name == floorName {
					for room in floor.roomInfos {
						if room.name == roomName {
							return room.id
						}
					}
				}
			}
			Log.warn("getRoomID：该房间不存在或已重命名(楼层名：\(floorName), 房间名：\(roomName))")
		}
		return nil
	}
	
	
	/**获取楼层ID*/
	func getFloorID(floorName: String) -> UInt16? {
		if let floors = getDevicesOfType(.FloorInfo) as? [HRFloorInfo] {
			for floor in floors{
				if floor.name == floorName {
					return floor.id
				}
			}
			Log.warn("getRoomID：该楼层不存在或已重命名(楼层名：\(floorName))")
		}
		return nil
	}
	
	/**获取所有传感器设备*/
	func getAllSensors() -> [HRSensor] {
		return getDevicesOfTypes(HRDeviceType.sensorTypes()) as! [HRSensor]
	}
	
	
	func getAllMotorDev() -> [HRMotorCtrlDev] {
		return getDevicesOfTypes(HRDeviceType.motorTypes()) as! [HRMotorCtrlDev]
	}
	
	//MARK: - 一些方法
	
	/**
	检查设备名字是否有错，用于检测命名是否符合规定
	
	- parameter devType: 设备类型，不同类型不同规则，另外还要根据设备类型判断是否存在同名
	- parameter name:    要测试的名字
	- parameter allowDuplication: 是否允许设备名重复, 默认为`false`
	- returns: 如果符合命名规则，返回nil，否则返回错误
	*/
	func checkName(devType: Byte, name: String, allowDuplication: Bool = false) -> NSError? {
		if name.isEmpty {
			return NSError(code: .Other, description: "名称不能为空")
		}
		switch devType {
		case HRDeviceType.UserInfo.rawValue:
			if !name.isUserName {
				return NSError(code: .UseIllegalChar, description: "用户名只能包含数字、字母、汉字及下划线")
			}
			if name.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 32 {
				return NSError(code: .DevNameTooLong, description: "用户名长度超过限制")
			}
		default:
			if !name.isDeviceName {
				return NSError(code: .UseIllegalChar, description: "名称中只能包含数字、字母、汉字、下划线和空格")
			}
			if name.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 32 {
				return NSError(code: .DevNameTooLong, description: "名称长度超过限制")
			}
		}
		//如果allowDuplication为false的话, 即不允许重名，则进行重名检查
		if let devs = self.getDevicesOfType(devType) where !allowDuplication {
			for dev in devs where dev.name == name {
				return NSError(code: .DuplicateName, description: "\"\(name)\"已被使用，请另取其他名称")
			}
		}
		return nil
	}
	
}

extension Array {
	
	///替换的方式追加一个元素，如果有数组里面已经有相同的元素了，则替换之，注意：本方法只对HRDevice类型的数组才会替换，其他类型的相当于append()方法。替换的条件是：只要设备地址相同，就会替换
	///
	///- returns: 返回新元素的索引
	mutating func appendReplace(newElement:Element) -> Int{
		//如果是情景，则对比情景ID
		if let dev = newElement as? HRScene {
			for i in 0..<self.count {
				let element = self[i]
				if (element as! HRScene).id == dev.id {
					Log.warn("情景重复，新情景：\(dev.name), 替换旧情景：\((element as! HRScene).name), id=\(dev.id)")
					self.removeAtIndex(i)
					self.insert(newElement, atIndex: i)
					return i
				}
			}
		}
			//如果是定时任务，则对比定时任务ID
		else if let dev = newElement as? HRTask {
			for i in 0..<self.count {
				let element = self[i]
				if (element as! HRTask).id == dev.id {
					self.removeAtIndex(i)
					self.insert(newElement, atIndex: i)
					return i
				}
			}
		}
			//如果是楼层，则对比楼层ID
		else if let dev = newElement as? HRFloorInfo {
			for i in 0..<self.count {
				let element = self[i]
				if (element as! HRFloorInfo).id == dev.id {
					self.removeAtIndex(i)
					self.insert(newElement, atIndex: i)
					return i
				}
			}
		}
			//如果是应用设备，则对比应用设备ID
		else if let dev = newElement as? HRApplianceApplyDev {
			for i in 0..<self.count {
				let element = self[i]
				if (element as! HRApplianceApplyDev).appDevID == dev.appDevID {
					self.removeAtIndex(i)
					self.insert(newElement, atIndex: i)
					return i
				}
			}
		}
			//如果是用户信息，则对比用户ID
		else if let dev = newElement as? HRUserInfo {
			for i in 0..<self.count {
				let element = self[i]
				if (element as! HRUserInfo).id == dev.id {
					self.removeAtIndex(i)
					self.insert(newElement, atIndex: i)
					return i
				}
			}
		}
			//HRDevice应该是最后对比的
		else if let dev = newElement as? HRDevice {
			for i in 0..<self.count {
				let element = self[i]
				if (element as! HRDevice).devAddr == dev.devAddr {
					self.removeAtIndex(i)
					self.insert(newElement, atIndex: i)
					return i
				}
			}
		}
		self.append(newElement)
		return self.count-1
	}
}