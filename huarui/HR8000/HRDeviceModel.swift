//
//  HRDeviceModel.swift
//  huarui
//
//  Created by sswukang on 15/7/24.
//  Copyright (c) 2015年 huarui. All rights reserved.
//
/** Device Models的UML图：
<img src="http://yuml.me/diagram/plain;dir:LR/class/
[HRDevice]%3E[HRApplianceApplyDev（应用设备）],
[HRDevice]%3E[HRRFDevice（RF设备）],
[HRDevice]%3E[HRScene（情景）],
[HRDevice]%3E[HRTask（定时任务）],
[HRDevice]%3E[HRFloorInfo（楼层）],
[HRDevice]%3E[HRUserInfo（用户）],
[HRRFDevice（RF设备）]%3E[HRRelayComplexes（继电器类基类）{bg:wheat}],
[HRRFDevice（RF设备）]%3E[HRSmartBed（智能床）],
[HRRFDevice（RF设备）]%3E[HRDoorBell（门铃）],
[HRRFDevice（RF设备）]%3E[HRDoorLock（门锁）],
[HRRFDevice（RF设备）]%3E[HRMotor（电机类）{bg:yellowgreen}],
[HRRFDevice（RF设备）]%3E[HRInfraredTransmitUnit（红外转发器）],
[HRRFDevice（RF设备）]%3E[HRBluetoothCtrlUnit（蓝牙遥控器）],
[HRRFDevice（RF设备）]%3E[HRRGBLamp（RGB灯）],
[HRRFDevice（RF设备）]%3E[HRScenePanel（情景面板）],
[HRRFDevice（RF设备）]%3E[HRMaster（智能主机）],
[HRRFDevice（RF设备）]%3E[HRSensor（传感器）{bg:turquoise}],
[HRRelayComplexes（继电器类基类）]%3E[HRLiveWireSwitch（单火开关）{bg:wheat}],
[HRRelayComplexes（继电器类基类）]%3E[HRSwitchPanel（智能开关）{bg:wheat}],
[HRRelayComplexes（继电器类基类）]%3E[HRSocketPanel（智能插座）{bg:wheat}],
[HRRelayComplexes（继电器类基类）]%3E[HRRelayCtrlBox（继电器控制盒）{bg:wheat}],
[HRMotor（电机类）]%3E[HRCurtainCtrlDev（窗帘控制器）{bg:yellowgreen}],
[HRMotor（电机类）]%3E[HRManipulator（机械手）{bg:yellowgreen}],
[HRSensor（传感器）]%3E[HRHumiditySensor（湿敏）{bg:turquoise}],
[HRSensor（传感器）]%3E[HRAirQualitySensor（空气质量）{bg:turquoise}],
[HRSensor（传感器）]%3E[HRGasSensor（可燃气）{bg:turquoise}],
[HRSensor（传感器）]%3E[HRSolarSensor（光照）{bg:turquoise}]
">

*/

import Foundation

//MARK: - HRAcount 当前登陆的账号
/**当前登陆的账号*/
class HRAcount: NSObject {
	/**用户名，占32个字节*/
	var userName: String    = ""
	/**密码，占16个字节*/
	var password: String    = ""
	///权限。占1个字节
	/// - 0 表示密码或用户不正确，
	/// - 1 表示低级权限只能查看控制，
	/// - 2 表示高级权限可以添加、删除、修改等操作，
	/// - 3 表示超级权限，
	/// - 4 表示主机没有注册到服务器上，
	/// - 5 表示主机不在线。
	/// - 当结果值不为1、2、3任一值时后续的内容无意义。
	var permission: Byte    = 0
	/**主机地址，占4个字节。该地址前面加[48, 52]即为主机的mac地址，并不是描述智能主机ID的“主机地址”，HRServerHost类中的hostAddr才是你要找智能主机的“主机地址”。（! == ! 我真的崩溃了！！！）*/
	var hostAddr: UInt32    = 0
	/**主机状态。占1个字节
	* b0位 表示参数的状态，0表示未设RF通信参数，1表示已设RF通信参数
	* b1位 表示主从的状态，0表示主主机，1表示从主机
	* b2－b7位 保留备用，暂无意义。
	*/
	var hostState: Byte   = 0
	
	///是否已经设置了RF参数, 返回true代表已经设置了
	var haveSetRFParameter: Bool {
		get { return (hostState & 0b0000_0001) != 0x00 }
		set { hostState |= newValue ? 0b0000_0001:0b0000_0000 }
	}
	
	
	class func initWithDataFrame(frameData data: [Byte]) -> HRAcount?{
		if data.count < 54 {
			Log.error("解析HRAcount数据时异常：数据长度不足54")
			return nil
		}
		let acount = HRAcount()
		if let name = ContentHelper.encodeGbkData(Array(data[0...31])){
			acount.userName = name
		}
		if let passwd = ContentHelper.encodeGbkData(Array(data[32...47])){
			acount.password = passwd
		}
		acount.permission = data[48]
		acount.hostAddr = UInt32(fourBytes: Array(data[49...52]))
		acount.hostState = data[53]
		return acount
	}
	
	///判断是否登陆成功
	///
	///- returns: 如果成功，则返回nil，失败则返回失败的原因
	func loginSuccessful() -> NSError? {
		switch permission {
		case 0:
			//用户名或密码错误
			return NSError(domain: "用户名或密码错误", code: HRErrorCode.AuthDenied.rawValue, userInfo: nil)
		case 4:
			//主机没有注册到服务器上，针对外网登陆
			return NSError(domain: "主机没有注册到服务器上", code: HRErrorCode.HostNoRegistration.rawValue, userInfo: nil)
		case 5:
			//主机不在线，针对外网登陆
            
          //  print("主机不在线")
			return NSError(domain: "主机不在线", code: HRErrorCode.HostOffline.rawValue, userInfo: nil)
		default: //登陆成功
			return nil
		}
	}
}


//MARK: - HRDevice
/**设备基类*/
class HRDevice: NSObject, NSCopying {
	/**设备类型*/
	var devType: Byte          = HRDeviceType.Braodcast.rawValue
	/**设备地址，占4个字节*/
	var devAddr   : UInt32     = 0
	/**设备/情景名字，占32字节*/
	var name   : String     = ""
	/**主机地址*/
	var hostAddr: UInt32 = 0
	
	/**安装所在的房间ID，占2个字节*/
	var insRoomID: UInt16         = 0
	/**安装所在的楼层ID，占2个字节*/
	var insFloorID: UInt16        = 0
	
	required override init() { }
	
	///重载copyWithZone
	func copyWithZone(zone: NSZone) -> AnyObject {
		let theCopyDev = self.dynamicType.init()
        theCopyDev.devType    = self.devType
        theCopyDev.devAddr    = self.devAddr
        theCopyDev.name       = self.name
        theCopyDev.hostAddr   = self.hostAddr
        theCopyDev.insFloorID = self.insFloorID
        theCopyDev.insRoomID  = self.insRoomID
		return theCopyDev
	}
	
	///安装所在的楼层名
	var insFloorName: String? {
		for floor in HRDatabase.shareInstance().floors {
			if floor.id == self.insFloorID {
				return floor.name
			}
		}
		return nil
	}
	
	///安装所在的房间名
	var insRoomName: String? {
		if let rooms = HRDatabase.shareInstance().getRooms(self.insFloorID) {
			for room in rooms {
				if room.id == self.insRoomID {
					return room.name
				}
			}
		}
		return nil
	}
	
	/// 是否有非法名称的错误
	var illegalNameError: NSError? {
		return HRDatabase.shareInstance().checkName(devType, name: name)
	}
	
	/**
	删除设备，同时主机上的设备也会被删除
	
	- parameter result: 结果回调
	*/
	func deleteFromRemote(result: ((NSError?)->Void)?) {
		if self is HRApplianceApplyDev { //如果是应用设备，则调用应用设备的删除方法
			(self as! HRApplianceApplyDev).removeFromRemote(result)
		} else if self is HRFloorInfo {	 //如果是楼层
			
		} else if self is HRScene {		//如果是情景
			HR8000Service.shareInstance().removeScene(self as! HRScene, result: result)
		} else if self is HRTask {		//如果是定时任务
			HR8000Service.shareInstance().removeTask(self as! HRTask, result: result)
		} else {
			HR8000Service.shareInstance().deleteRemoteDevice([self], result: result)
		}
	}
	
	
}

extension HRDevice {
	///设备安装所在房间的名字
	var roomName: String? {
		if self is HRScene || self is HRTask || self is HRUserInfo || self is HRFloorInfo {
			return nil
		}
		for floor in HRDatabase.shareInstance().floors
			where floor.id == self.insFloorID {
				for room in floor.roomInfos where insRoomID == room.id {
					return room.name
				}
		}
		return nil
	}
	
	///设备安装所在楼层的名字
	var floorName: String? {
		if self is HRScene || self is HRTask || self is HRUserInfo || self is HRFloorInfo {
			return nil
		}
		for floor in HRDatabase.shareInstance().floors
			where floor.id == self.insFloorID {
				return floor.name
		}
		return nil
	}
}


//重载HRDevice类的==符号
func ==(left: HRDevice, right: HRDevice) -> Bool{
	if  left.devAddr    == right.devAddr  &&
		left.hostAddr   == right.hostAddr &&
		left.name       == right.name {
			return true
	}
	return false
}

///RF设备
class HRRFDevice: HRDevice {
	/**信道，占1个字节*/
	var channel: Byte      = 0
	/**RF地址码，占1个字节*/
	var RFAddr: Byte       = 0
	/**软件版本，，占1个字节*/
	var RFVersion: Byte      = 0
	
	var RFVersionString: String {
		return "\(RFVersion >> 4).\(RFVersion & 0b0000_1111)"
	}
	
	required init() {
		super.init()
	}
	
	override func copyWithZone(zone: NSZone) -> AnyObject {
		let theCopyDev = super.copyWithZone(zone) as! HRRFDevice
        theCopyDev.channel   = self.channel
        theCopyDev.RFAddr    = self.RFAddr
        theCopyDev.RFVersion = self.RFVersion
		return theCopyDev
	}
}


///提供服务的主机，可能是外网服务器，也可能是局域网的智能主机
class HRServerHost {
	///IP地址
	var IPAddr : UInt32 = 0
	var port   : UInt16 = TCP_HOST_PORT_WIFI
	var name   : String = ""
	///主机地址，每个提供服务的主机都会返回一个主机地址，该地址不是IP地址，而是智能主机的一个ID
	var hostAddr: UInt32 = 0
	///主机的Mac地址
	var macAddr = [Byte]()
	
	/**
	创建一个服务器的host对象
	
	- returns 服务器的host对象
	*/
	class func newServerHost() -> HRServerHost {
		let host = HRServerHost()
		host.name = "Server"
		host.IPAddr = UInt32(fourBytes: Array(ContentHelper.hostStringToArry(NET_SERVER_ADDR)!).reverse())
		host.hostAddr = 0x0000_0000
		host.port = TCP_HOST_PORT_NET
		host.macAddr = [0,0,0,0,0,0]
		
		return host
	}
	
	///使用UDP包数据初始化
	class func initWithUDPFrame(frame: HRFrame) -> HRServerHost? {
		if frame.command != HRCommand.BraodcastSearchHost.rawValue || frame.data.count < 46 {
			Log.error("HRHost.initWithFrame:数据域长度不对")
			return nil
		}
		let host = HRServerHost()
		host.IPAddr = UInt32(fourBytes: Array(frame.data[0...3]))
		host.macAddr = Array(frame.data[4...9])
		if let name = ContentHelper.encodeGbkData(Array(frame.data[10...41])) {
			host.name = name
		}
		host.hostAddr = UInt32(fourBytes: Array(frame.data[42...45]))
		return host
	}
	
	func getHostIPAddrString() -> String {
		let bytes = Array(IPAddr.getBytes().reverse())
		return "\(bytes[0]).\(bytes[1]).\(bytes[2]).\(bytes[3])"
	}
}

//MARK: - 0x00 HRHost

///HR8000智能主机，设备类型0x00
class HRMaster: HRRFDevice {
	///IP地址。因为本主机不一定是主主机，也有可能是服务器ip，所以不能将ip地址当成主主机地址，主主机地址应该是hostAddr
	var IPAddr : UInt32 = 0
	var port   : UInt16 = TCP_HOST_PORT_WIFI
	///主机的物理地址
	var macAddr: [Byte] {
		let bytes = HRDatabase.shareInstance().acount.hostAddr.getBytes()
		return [0x48, 0x52] + bytes
	}
	///主机版本
	var version = HRVersion()
	
	var IPAddrString: String {
		let bytes: [Byte] = IPAddr.getBytes()
		return "\(bytes[3]).\(bytes[2]).\(bytes[1]).\(bytes[0])"
	}
	
	var macAddrString: String {
		var str = ""
		let _macAddr = macAddr
		for i in 0..<_macAddr.count {
			str += NSString(format: "%.2X", _macAddr[i]) as String
			if i != _macAddr.count - 1 {
				str += ":"
			}
		}
		return str
	}
	
//	//从本地读出ip地址
//	class func getHostIPAddrFromLocal() -> UInt32? {
//		if let ipStr = NSUserDefaults.standardUserDefaults().valueForKey("hostIPAddressString") as? String {
//			if let bytes = ContentHelper.hostStringToArry(ipStr) {
//				return UInt32(fourBytes: bytes)
//			}
//		}
//		return nil
//	}
	
	class func initWithDataFrame(hostAddr: UInt32, frame: [Byte]) -> (HRMaster, Int) {
		/**********************************
		元素      长度         名称
		0         1         设备类型
		1-4       4         设备地址
		5         1         信道
		6         1         RF地址码
		7         1         软件版本
		8-11	  4			主机IP地址
		12-13	  2			主机端口号
		14-17	  4			主机软件版本
		18-19	  2			备用
		***********************************///
        
        
		let master = HRMaster()
		master.devType   = HRDeviceType.Master.rawValue
		master.devAddr   = UInt32(fourBytes: Array(frame[1...4]))
		master.hostAddr  = hostAddr
		master.channel   = frame[5]
		master.RFAddr    = frame[6]
		master.RFVersion = frame[7]
		master.IPAddr = UInt32(fourBytes: Array(frame[8...11]))
		master.port = UInt16(twoBytes: Array(frame[12...13]))
		master.version = HRVersion.initWithFrameData(Array(frame[14...17]))!
    
		Log.debug("智能主机(0x00): \t名称：\(master.name), IP：\(frame[8...11]), version：\(master.version.toString)")
    //    print("智能主机(0x00): \t名称：\(master.name), IP：\(frame[8...11]), version：\(master.version.toString)")
		return (master, 20)
        
        
	}
	
}


///主机的软件版本号
struct HRVersion {
	///主版本号。格式：主.次.修正.编译
	var major: Byte     = 0
	///次版本号。格式：主.次.修正.编译
	var junior: Byte    = 0
	///修正版本号。格式：主.次.修正.编译
	var fixed: Byte     = 0
	///编译版本号。格式：主.次.修正.编译
	var build: UInt16 = 0
	
	
	///使用byte数组初始化
	///
	/// - parameter data: 数组长度必须大于等于4
	static func initWithFrameData(data: [Byte]) -> HRVersion?{
		var ver = HRVersion()
		if data.count < 4 {
			return nil
		}
		ver.major  = (data[3] & 0b1111_1000) >> 3
		ver.junior = ((data[3] & 0b0000_0111) << 5) | ((data[2] & 0b1111_0000) >> 4)
		ver.fixed  = ((data[2] & 0b0000_1111) << 4) | ((data[1] & 0b1111_0000) >> 4)
		ver.build  = (UInt16(data[1] & 0b0000_1111) << 8) | UInt16(data[0])
		return ver
	}
    
    
    
	
	///文字描述
	var toString: String {
        
        
        print("\(major).\(junior).\(fixed).\(build)")
        
		return "\(major).\(junior).\(fixed).\(build)"
	}
}


//MARK: - _ HRRelayComplexes 继电器复合体设备，为继电器控制盒、智能开关、智能插座、单火开关的基类
///继电器复合体设备，为继电器控制盒、智能开关、智能插座、单火开关的基类
class HRRelayComplexes: HRRFDevice {
	/**保留以后使用，占28个字节*/
	var resever: [Byte]    = Array()
	/**按键有效通道，占1个字节*/
	var effKey: Byte       = 0
	/**继电器的有效通道，指所有继电器通道状态，两位表示一个通道, 0表示关，1表示开，3表示无效。共占1个字节。*/
	var states:Byte        = 0 {
		didSet {
			for i in 0..<relays.count {
				relays[i].setState(states, seqInBox: relays[i].relaySeq)
			}
		}
	}
	/**继电器个数，占1个字节*/
	var relayTotal: Byte   = 0
	/**继电器控制盒里的所有继电器，这是一个Relay类的数组*/
	var relays: [HRRelayInBox] = Array()
	
	required init() {
		super.init()
	}
	
	class func initWithDataFrame(relayBox: HRRelayComplexes, hostAddr: UInt32, dataFrame frame: [Byte]) -> (HRRelayComplexes, Int){
		/**********************************
		元素      长度         名称
		0         1         设备类型
		1-4       4         设备地址
		5         1         信道
		6         1         RF地址码
		7         1         软件版本
		8-39      32        设备名称
		40-41     2         安装所在房间的ID
		42-43     2         安装所在的楼层ID
		44-71     28        保留以后使用
		72        1         按键有效通道
		73        1         继电器有效通道
		74        1         继电器关联状态的继电器个数
		75-       N         继电器关联状态（多个）
		
		继电器关联状态:
		0         1         继电器序号
		1         1         关联用电设备类型
		2-33      32        用电设备名称
		34-35     2         用电设备安装所在房间ID
		36-37     2         用电设备安装所在楼层ID
		38-65     28        保留以后使用
		***********************************///
		relayBox.hostAddr  = hostAddr
		relayBox.devType   = frame[0]
		relayBox.devAddr   = UInt32(fourBytes: Array(frame[1...4]))
		relayBox.channel   = frame[5]
		relayBox.RFAddr    = frame[6]
		relayBox.RFVersion   = frame[7]
		if let name = ContentHelper.encodeGbkData(Array(frame[8...39])) {
			relayBox.name = name
		}
		relayBox.insRoomID  = UInt16(twoBytes: Array(frame[40...41]))
		relayBox.insFloorID = UInt16(twoBytes: Array(frame[42...43]))
		relayBox.resever    = Array(frame[44...71])
		relayBox.effKey = frame[72]
		relayBox.states = frame[73]
		relayBox.relayTotal = frame[74]
		
		switch relayBox.devType {
		case HRDeviceType.RelayControlBox.rawValue:
			Log.debug("继电器控制盒: \t名称：\(relayBox.name), 负载(\(relayBox.relayTotal)):")
		case HRDeviceType.SocketPanel.rawValue:
			Log.debug("智能插座: \t名称：\(relayBox.name), 负载(\(relayBox.relayTotal)):")
		case HRDeviceType.SwitchPanel.rawValue:
			Log.debug("智能开关控制盒: \t名称：\(relayBox.name), 负载(\(relayBox.relayTotal)):")
		case HRDeviceType.LiveWireSwitch.rawValue:
			Log.debug("单火开关: \t名称：\(relayBox.name), 负载(\(relayBox.relayTotal)):")
		default:
			Log.debug("未知继电器类型: \t名称：\(relayBox.name), 负载(\(relayBox.relayTotal)):")
		}
		
		if relayBox.relayTotal > 0 {
			for i in 0...relayBox.relayTotal-1 {
				let bindBasePos = 75 + 66 * Int(i)
				let relay = HRRelayInBox()
				relay.devType   = relayBox.devType
				relay.hostAddr  = hostAddr
				relay.devAddr   = relayBox.devAddr
				relay.relayBox  = relayBox
				relay.relaySeq  = frame[bindBasePos]
				relay.elecType  = frame[bindBasePos+1]
				if let name = ContentHelper.encodeGbkData(Array(frame[bindBasePos+2...bindBasePos+33])){
					relay.name     = name
					relay.elecName = name
				}
				relay.insRoomID  = UInt16(twoBytes: Array(frame[bindBasePos+34...bindBasePos+35]))
				relay.insFloorID = UInt16(twoBytes: Array(frame[bindBasePos+36...bindBasePos+37]))
				relay.resever    = Array(frame[bindBasePos+38...bindBasePos+65])
				relay.setState(relayBox.states, seqInBox: i)
				relay.devAddr = relayBox.devAddr
				Log.debug("\t\t\(relay.relaySeq)、名称：\(relay.name)")
				relayBox.relays.append(relay)
			}
		}
		let count = 75 + Int(relayBox.relayTotal) * 66
		return (relayBox, count)
	}
}

/**继电器类，该类描述的是继电器控制盒的一个通道*/
class HRRelayInBox: HRDevice {
	/**继电器序号，占1个字节*/
	var relaySeq: Byte          = 0
	/**关联用电设备类型，占1个字节*/
	var elecType: Byte          = 0
	/**用电设备名称，占32个字节*/
	var elecName: String        = ""
	/**保留以后使用，占28个字节*/
	var resever: [Byte]         = Array()
	/// 包含该继电器的继电器控制盒对象引用
	weak var relayBox: HRRelayComplexes!
	/**该继电器的状态，开/关/无效这3种状态*/
	private var _state:HRRelayRouteState = .OFF
	/**该继电器的状态，开/关/无效这3种状态. 只读，如要设置该属性，请使用setState方法*/
	var state:HRRelayRouteState { return _state }
	
	/**
	设置继电器的状态。
	
	- parameter states: 该继电器所在控制盒的states
	- parameter seqInBox: 该继电器在控制盒中的和序号
	*/
	func setState(states: Byte, seqInBox: Byte) {
		switch ((states >> (seqInBox * 2)) & 0b0000_0011) {
		case HRRelayRouteState.OFF.rawValue:
			self._state = .OFF
		case HRRelayRouteState.ON.rawValue:
			self._state = .ON
		default:
			self._state = .Invalid
		}
	}
	
	/**
	设置继电器的状态。
	
	- parameter state: 继电器状态
	*/
	func setState(state:HRRelayRouteState) {
		self._state = state
		//清除位
		self.relayBox.states &= ~(0b0000_0011 << (self.relaySeq * 2))
		//设置位
		self.relayBox.states |= (state.rawValue << (self.relaySeq * 2))
	}
	
	///操作控制继电器、智能开关、智能插座
	///
	///- parameter actionType: 控制类型，比如开、关、翻转、无效；
	///- parameter result:   结果回调(是否成功，信息)
	func operate(actionType: HRRelayOperateType, result: (NSError?)->Void) {
       // print("在这里实现")
		HR8000Service.shareInstance().operateRelay(actionType: actionType, relay: self, callback: result)
	}
}

/**继电器操作类型*/
enum HRRelayOperateType: UInt8 {
	/**关闭, 0*/
	case Close   = 0b0000_0000
	/**打开, 1*/
	case Open    = 0b0000_0001
	/**取反，2*/
	case Reverse = 0b0000_0010
	/**保持不变或无效, 3*/
	case Keep    = 0b0000_0011
}
/**继电器控制盒里通道的状态*/
enum HRRelayRouteState:Byte {
	/**关，有效,0x00*/
	case OFF     = 0b0000_0000
	/**开，有效, 0x01*/
	case ON      = 0b0000_0001
	///取反，0x02
	case Reverse = 0b0000_0010
	/**无效,0x03*/
	case Invalid = 0b0000_0011
}

//MARK: - 0x01 HRSwitchPanel
/**智能开关面板结构体（0x01），用于描述一个智能开关面板设备*/
class HRSwitchPanel: HRRelayComplexes {
	required init() {
		super.init()
		self.devType = HRDeviceType.SwitchPanel.rawValue
	}
	
	class func initWithDataFrame(hostAddr: UInt32, dataFrame frame: [Byte]) -> (HRSwitchPanel, Int) {
		let (switchPanel, len) = super.initWithDataFrame(HRSwitchPanel(), hostAddr: hostAddr, dataFrame: frame)
		return (switchPanel as! HRSwitchPanel, len)
	}
}

//MARK: - 0x02 HRScenePanel 情景面板
/**情景面板类（0x02），用来描述一个情景面板*/
class HRScenePanel: HRRFDevice {
	/**保留以后使用，占28个字节*/
	var resever: [Byte]    = Array()
	/**按键的有效通道，也就是有多少个有效的按键的意思，占1个字节*/
	var enableKeys: Byte   = 0
	/**按键绑定状态，共有4路，占52个字节*/
	var keyStatusBind: [HRScenePanelBindStates] = Array()
	
	///有效按键数量，该值由解析enableKeys获得
	var enableKeysCount: Int {
		var count = 0
		for i in 0...3 {
			count += (Int(enableKeys) & (0b0000_0011 << (i*2))) == 0 ? 1:0
		}
		return count
	}
	
	class func ininWithDataFrame(hostAddr: UInt32, dataFrame frame: [Byte]) -> (HRScenePanel, Int) {
		/**********************************
		元素      长度         名称
		0         1         设备类型
		1-4       4         设备地址
		5         1         信道
		6         1         RF地址码
		7         1         软件版本
		8-39      32        设备名称
		40-41     2         安装所在房间的ID
		42-43     2         安装所在的楼层ID
		44-71     28        保留以后使用
		72        1         按键有效通道
		73-124    52        按键绑定的状态
		
		按键绑定的状态，共4个通道，每个通道有以下字段:
		0-3       4         设备或情景所属的主机地址
		4         1         绑定类型
		5-8       4         绑定的设备地址或情景id
		9-12      4         绑定的操作
		***********************************///
		let panel = HRScenePanel()
		panel.devType   = HRDeviceType.ScenePanel.rawValue
		panel.devAddr   = UInt32(fourBytes: Array(frame[1...4]))
		panel.hostAddr  = hostAddr
		panel.channel   = frame[5]
		panel.RFAddr    = frame[6]
		panel.RFVersion   = frame[7]
		if let name = ContentHelper.encodeGbkData(Array(frame[8...39])) {
			panel.name = name
		}
		panel.insRoomID  = UInt16(twoBytes: Array(frame[40...41]))
		panel.insFloorID = UInt16(twoBytes: Array(frame[42...43]))
		panel.resever    = Array(frame[44...71])
		panel.enableKeys = frame[72]
		for i in 0...3 {
			let basePos = 73 + 13 * Int(i)
			let state = HRScenePanelBindStates()
            state.hostAddr = UInt32(fourBytes: Array(frame[basePos...basePos+3]))
            state.devType  = frame[basePos+4]
            state.devAddr  = UInt32(fourBytes: Array(frame[basePos+5...basePos+8]))
            state.operation = UInt32(fourBytes: Array(frame[basePos+9...basePos+12]))
			
			panel.keyStatusBind.append(state)
		}
		Log.debug("情景面板：\t名称：\(panel.name)\t有效通道：\(panel.enableKeys)")
		return (panel, 125)
	}
}

/**情景面板按键绑定的状态*/
class HRScenePanelBindStates {
	/**设备或情景所属主机地址，占4个字节*/
	var hostAddr: UInt32    = 0
	/**绑定类型，占1个字节：0表示无绑定，0xfd表示绑定情景，具体的设备类型表示绑定设备，0xff表示无效即无该按键。*/
	var devType: Byte      = 0
	/**绑定的设备地址或情景id，占4个字节：如果无效或无绑定则填0xffffffffff。*/
	var devAddr: UInt32 = 0
	/**绑定的操作，占4个字节：0表示关，1表示开，2取反，>=3无效。*/
	var operation: UInt32  = 0
	///描述
	var description: String = ""
}

//MARK: - 0x03 HRSocketPanel 智能插座
/**智能插座面板类（0x03），用于描述一个智能插座面板设备*/
class HRSocketPanel: HRRelayComplexes {
	required init() {
		super.init()
		self.devType = HRDeviceType.SocketPanel.rawValue
	}
	
	class func initWithDataFrame(hostAddr: UInt32, dataFrame frame: [Byte]) -> (HRSocketPanel, Int) {
		let (socket, len) = super.initWithDataFrame(HRSocketPanel(), hostAddr: hostAddr, dataFrame: frame)
		return (socket as! HRSocketPanel, len)
	}
}

//MARK: - 0x04 HRRelayCtrlBox 继电器控制盒
///继电器控制盒类（0x04），用于描述一个继电器控制盒设备。一般一个继电器控制盒里面会有几个继电器，每个继电器用来控制一个用电设备
class HRRelayCtrlBox: HRRelayComplexes {
	required init() {
		super.init()
		self.devType = HRDeviceType.RelayControlBox.rawValue
	}
	
	class func initWithDataFrame(hostAddr: UInt32, dataFrame frame: [Byte]) -> (HRRelayCtrlBox, Int) {
		let (relayBox, len) = super.initWithDataFrame(HRRelayCtrlBox(), hostAddr: hostAddr, dataFrame: frame)
		return (relayBox as! HRRelayCtrlBox, len)
	}
}

//MARK: - 0x05 HRRGBLamp RGB灯

///RGB灯
class HRRGBLamp: HRRFDevice {
	///模式，当前设备所处的模式
    var mode: Byte = 0;
	///RGB值。
    var rgbValue    = HRRGBValue()
	
	class func initWithDataFrame(hostAddr: UInt32, dataFrame frame: [Byte]) -> (HRRGBLamp, Int) {
		/**********************************
		元素      长度         名称
		0         1         设备类型
		1-4       4         设备地址
		5         1         信道
		6         1         RF地址码
		7         1         软件版本
		8-39      32        设备名称
		40-41     2         安装所在房间的ID
		42-43     2         安装所在的楼层ID
		44-71     28        保留以后使用
		72		  1         模式
		73-75	  3			RGB值，依次为R、G、B
		***********************************///
		let lamp = HRRGBLamp()
		lamp.hostAddr  = hostAddr
		lamp.devType   = frame[0]
		lamp.devAddr   = UInt32(fourBytes: Array(frame[1...4]))
		lamp.channel   = frame[5]
		lamp.RFAddr    = frame[6]
		lamp.RFVersion   = frame[7]
		if let name = ContentHelper.encodeGbkData(Array(frame[8...39])) {
			lamp.name = name
		}
		lamp.insRoomID  = UInt16(twoBytes: Array(frame[40...41]))
		lamp.insFloorID = UInt16(twoBytes: Array(frame[42...43]))
		lamp.mode = frame[72]
		lamp.rgbValue = HRRGBValue(r: frame[73], g: frame[74], b: frame[75])
		Log.debug("RGB灯：\t名称：\(lamp.name)")
		
		return (lamp, 76)
	}
	
	func turnOnOff(on: Bool, result: ((NSError?)->Void)?) {
		if on {
			setRGB(0xFF, G: 0xFF, B: 0xFF, result: result)
		} else {
			setRGB(0x00, G: 0x00, B: 0x00, result: result)
		}
	}
	
	func setRGB(R: Byte, G: Byte, B: Byte, result: ((NSError?)->Void)?) {
		HR8000Service.shareInstance().doOperateRGBLamp(self, mode: .RGB, rgbValues: [R, G, B], speed: nil, duration: nil, result: result)
	}
	
	/**
	切换到跳变模式
	
	- parameter speed:    速度，范围1~3，分别对应慢中快。当mode为Gradient、Step、Rainbow这三种模式时，该参数不能为空，其他模式该参数无效
	- parameter duration: 循环时间，范围0~7200秒。当mode为Gradient、Step、Rainbow这三种模式时，该参数不能为空，其他模式该参数无效，0表示无限循环
	- parameter result:   控制返回的结果。
	*/
	func setToStepMode(speed: Byte, duration: UInt16, result: ((NSError?)->Void)?) {
		HR8000Service.shareInstance().doOperateRGBLamp(self, mode: .Step, rgbValues: nil, speed: speed, duration: duration, result: result)
	}
	
	/// 切换到渐变模式
	func setToGradientMode(speed: Byte, duration: UInt16, result: ((NSError?)->Void)?) {
		HR8000Service.shareInstance().doOperateRGBLamp(self, mode: .Gradient, rgbValues: nil, speed: speed, duration: duration, result: result)
	}
	
	/// 切换到彩虹模式
	func setToRainbowMode(speed: Byte, duration: UInt16, result: ((NSError?)->Void)?) {
		HR8000Service.shareInstance().doOperateRGBLamp(self, mode: .Rainbow, rgbValues: nil, speed: speed, duration: duration, result: result)
	}
	
	/// 切换到照明模式
	func setToLightingMode(result: ((NSError?)->Void)?) {
		HR8000Service.shareInstance().doOperateRGBLamp(self, mode: .Lighting, rgbValues: nil, speed: nil, duration: nil, result: result)
	}
	
	/// 切换到夜起模式
	func setToNightMode(result: ((NSError?)->Void)?) {
		HR8000Service.shareInstance().doOperateRGBLamp(self, mode: .Night, rgbValues: nil, speed: nil, duration: nil, result: result)
	}
}

///RGB值描述类型
struct HRRGBValue {
	var r: Byte = 0
	var g: Byte = 0
	var b: Byte = 0
	
	init() {}
	
	init(r: Byte, g: Byte, b: Byte) {
		self.r = r
		self.g = g
		self.b = b
	}
	
	var color: UIColor {
		return UIColor(R: Int(r), G: Int(g), B: Int(b), alpha: 1)
	}
}

//MARK: - 0x06 HRBluetoothCtrlUnit 蓝牙遥控器
/**蓝牙遥控器类（0x06），用于描述一个蓝牙遥控器设备*/
typealias HRBluetoothCtrlUnit = HRInfraredTransmitUnit

//MARK: - 0x07 HRInfraredTransmitUnit 红外转发器
/**红外转发器类（0x07），用于描述一个红外转发器设备*/
class HRInfraredTransmitUnit: HRRFDevice  {
	/**码库存储空间，占2个字节*/
	var codeSpace: UInt16  = 0
	
	class func initWithDataFrame(hostAddr: UInt32, dataFrame frame: [Byte]) -> (HRInfraredTransmitUnit, Int) {
		/**********************************
		元素      长度         名称
		0         1         设备类型
		1-4       4         设备地址
		5         1         信道
		6         1         RF地址码
		7         1         软件版本
		8-39      32        设备名称
		40-41     2         安装所在房间的ID
		42-43     2         安装所在的楼层ID
		44-71     28        保留以后使用
		72-73     2         码库存储空间
		***********************************///
		let unit = HRInfraredTransmitUnit()
		unit.hostAddr  = hostAddr
		unit.devType   = frame[0]
		unit.devAddr   = UInt32(fourBytes: Array(frame[1...4]))
		unit.channel   = frame[5]
		unit.RFAddr    = frame[6]
		unit.RFVersion   = frame[7]
		if let name = ContentHelper.encodeGbkData(Array(frame[8...39])) {
			unit.name = name
		}
		unit.insRoomID  = UInt16(twoBytes: Array(frame[40...41]))
		unit.insFloorID = UInt16(twoBytes: Array(frame[42...43]))
		unit.codeSpace  = UInt16(twoBytes: Array(frame[72...73]))
		
		Log.debug("红外转发器：\t名称：\(unit.name)")
		return (unit, 74)
	}
}

/**红外学习状态*/
enum HRInfraredLearnStatus: Byte {
	/**没有学习*/
	case NoLearning = 0x00
	/**已经学习了*/
	case HavaLeared = 0x01
}

//MARK: - 电机控制器类
/**电机控制器类，用于窗帘，投影的荧幕，开窗器，机械手等电机控制的设备*/
class HRMotorCtrlDev: HRRFDevice  {
	/**保留以后使用，占28个字节*/
	var resever: [Byte]    = Array()
	/**当前状态，占1个字节*/
	var status:HRMotorCtrlStatus = .Stop
	
	func setState(stateByte: Byte) {
		switch stateByte & 0b0000_0011 {
		case 0:
			status = .Close
		case 1:
			status = .Open
		default:
			status = .Stop
		}
	}
	
	class func initWithDataFrame(hostAddr: UInt32, dataFrame frame: [Byte]) -> (HRMotorCtrlDev, Int){
		/**********************************
		元素      长度         名称
		0         1         设备类型
		1-4       4         设备地址
		5         1         信道
		6         1         RF地址码
		7         1         软件版本
		8-39      32        设备名称
		40-41     2         安装所在房间的ID
		42-43     2         安装所在的楼层ID
		44-71     28        保留以后使用
		72        1         状态，开/关/停
		***********************************///
		let motor = HRMotorCtrlDev()
		motor.hostAddr  = hostAddr
		motor.devType   = HRDeviceType.CurtainControlUnit.rawValue
		motor.devAddr   = UInt32(fourBytes: Array(frame[1...4]))
		motor.channel   = frame[5]
		motor.RFAddr    = frame[6]
		motor.RFVersion   = frame[7]
		if let name = ContentHelper.encodeGbkData(Array(frame[8...39])) {
			motor.name = name
		}
		motor.insRoomID  = UInt16(twoBytes: Array(frame[40...41]))
		motor.insFloorID = UInt16(twoBytes: Array(frame[42...43]))
		motor.resever    = Array(frame[44...71])
		motor.setState(frame[72])
		
		Log.debug("电机类控制器：\t名称：\(motor.name),\t状态：\(motor.status)")
		
		return (motor, 73)
	}
	
	///打开窗帘
	func open(result: (NSError?)->Void) {
		HR8000Service.shareInstance().operateCurtain(actionType: .Open, motor: self, callback: result)
	}
	
	///停止窗帘移动
	func stop(result: (NSError?)->Void) {
		HR8000Service.shareInstance().operateCurtain(actionType: .Stop, motor: self, callback: result)
	}
	
	///关闭窗帘
	func close(result: (NSError?)->Void) {
		HR8000Service.shareInstance().operateCurtain(actionType: .Close, motor: self, callback: result)
	}
}

/**电机类MotorCtrl的状态值*/
enum HRMotorCtrlStatus: Byte{
	/**关闭*/
	case Close  = 0b0000_0000
	/**打开*/
	case Open   = 0b0000_0001
	/**停止*/
	case Stop   = 0b0000_0010
}

enum HRMotorOperateType: UInt8 {
	/**关闭, 0*/
	case Close   = 0b0000_0000
	/**打开, 1*/
	case Open    = 0b0000_0001
	/**停止，2*/
	case Stop    = 0b0000_0010
}

//MARK: - 0x08 HRCurtainCtrlDev 窗帘控制器
/**窗帘控制器类（0x08）*/
class HRCurtainCtrlDev: HRMotorCtrlDev {
	
	required init() {
		super.init()
		devType = HRDeviceType.CurtainControlUnit.rawValue
	}
	
	override class func initWithDataFrame(hostAddr: UInt32, dataFrame frame: [Byte]) -> (HRCurtainCtrlDev, Int) {
		let (motor, len) = super.initWithDataFrame(hostAddr, dataFrame: frame)
		let curtain = HRCurtainCtrlDev()
        curtain.name       = motor.name
		curtain.hostAddr   = motor.hostAddr
        curtain.devAddr    = motor.devAddr
        curtain.channel    = motor.channel
        curtain.RFAddr     = motor.RFAddr
        curtain.RFVersion    = motor.RFVersion
        curtain.insRoomID  = motor.insRoomID
        curtain.insFloorID = motor.insFloorID
        curtain.resever    = motor.resever
        curtain.status     = motor.status
		return (curtain, len)
	}
}



//MARK: - 0x09 HRInfraredDetector 红外入侵探测器
/**红外入侵探测器,0x09*/
typealias HRInfraredDetector = HRDoorBell

//MARK: - 0x0A HRDoorMagCard 智能门磁
/**智能门磁,0x0A*/
typealias HRDoorMagCard = HRDoorBell





//MARK: - 0x0B HRDoorLock 智能门锁
/**智能门锁类（0xB）,*/
class HRDoorLock: HRRFDevice {
	/**保留以后使用，占28个字节*/
	var resever: [Byte]     = Array()
	/**布防状态，占1个字节，为0代表撤防，为1代表布防。*/
	var protectStatus: Byte = 0
	/**状态，占1个字节，为0代表门磁合上；为1代表门磁分开。*/
	var status: Byte        = 0
	
	class func initWithDataFrame(type: Byte, hostAddr: UInt32, frame: [Byte]) -> (HRDoorLock, Int){
		/**********************************
		元素      长度         名称
		0         1         设备类型
		1-4       4         设备地址
		5         1         信道
		6         1         RF地址码
		7         1         软件版本
		8-39      32        设备名称
		40-41     2         安装所在房间的ID
		42-43     2         安装所在的楼层ID
		44-71     28        保留以后使用
		**/
		let lock = HRDoorLock()
        
        //斌注释 关于门锁 主机地址 继承于 设备基类
		lock.hostAddr  = hostAddr
        /**设备类型 继承于设备基类*/
		lock.devType   = type
        /**设备地址，占4个字节 继承于设备基类 byte数组的第一个到第四个字节*/
		lock.devAddr   = UInt32(fourBytes: Array(frame[1...4]))
        /**信道，占1个字节 继承于 rf设备 */
		lock.channel   = frame[5]
        /**RF地址码，占1个字节 继承于 rf设备*/
		lock.RFAddr    = frame[6]
        /**软件版本，，占1个字节 继承于 rf设备*/
		lock.RFVersion   = frame[7]
        
        /**
         数据转字符串，使用GBK编码
         
         - parameter data: byte数组
         - returns: 字符串
         */
        
        //MARK: - ContentHelper
        
        /**
         * 本类用于包装发送的帧或解析接收的帧
         */
		if let name = ContentHelper.encodeGbkData(Array(frame[8...39])) {
            //8-39  32   设备名称  继承于设备基类
            
			lock.name = name
		}
        /**安装所在的房间ID，占2个字节 */

		lock.insRoomID  = UInt16(twoBytes: Array(frame[40...41]))
        
        /**安装所在的楼层ID，占2个字节*/
        
		lock.insFloorID = UInt16(twoBytes: Array(frame[42...43]))
        
        /**保留以后使用，占28个字节*/
		lock.resever    = Array(frame[44...71])
        
        /**布防状态，占1个字节，为0代表撤防，为1代表布防。*/
        lock.protectStatus = frame[72]
        
        /**状态，占1个字节，为0代表门磁合上；为1代表门磁分开。*/
		lock.status     = frame[73]
		
		Log.debug("智能门锁：\t名称：\(lock.name),状态：\(lock.status)")
        
        print("智能门锁：\t名称：\(lock.name),状态：\(lock.status)")
      
		
		return (lock, 74)
	}
	
	
    
    
    
    
    
	func unlock(password: String, result: (NSError?)->Void){
		HR8000Service.shareInstance().unlockDoor(self, passwd: password, callback: result)
	}
}





//MARK:- 斌门锁相关 0x15HRSmartLock

class HRSmartDoor: HRRFDevice {
    
    /**保留以后使用，占28个字节*/
    var resever: [Byte]     = Array()
    /**布防状态，占1个字节，为0代表撤防，为1代表布防。*/
    var protectStatus: Byte = 0
    /**状态，占1个字节，0x01代表未配对；0x02代表已配对。*/
    var status: Byte        = 0

    
    //type表示为设备类型
    class func initWithDataFrame(type:Byte,hostAddr:UInt32,frame:[Byte]) -> (HRSmartDoor,Int){
        
        /**********************************
         元素      长度         名称
         0         1         设备类型
         1-4       4         设备地址
         5         1         信道
         6         1         RF地址码
         7         1         软件版本
         8-39      32        设备名称
         40-41     2         安装所在房间的ID
         42-43     2         安装所在的楼层ID
         44-71     28        保留以后使用
         **/

        
        let lock = HRSmartDoor()
        
        lock.hostAddr = hostAddr
        
        /**设备类型 继承于设备基类*/
        lock.devType   = type
        /**设备地址，占4个字节 继承于设备基类 byte数组的第一个到第四个字节*/
        lock.devAddr   = UInt32(fourBytes: Array(frame[1...4]))
        /**信道，占1个字节 继承于 rf设备 */
        lock.channel   = frame[5]
        /**RF地址码，占1个字节 继承于 rf设备*/
        lock.RFAddr    = frame[6]
        /**软件版本，，占1个字节 继承于 rf设备*/
        lock.RFVersion   = frame[7]
        if let name = ContentHelper.encodeGbkData(Array(frame[8...39])) {
            //8-39  32   设备名称  继承于设备基类
            
            lock.name = name
        }
        
        /**安装所在的房间ID，占2个字节 */
        
        lock.insRoomID  = UInt16(twoBytes: Array(frame[40...41]))
        
        /**安装所在的楼层ID，占2个字节*/
        
        lock.insFloorID = UInt16(twoBytes: Array(frame[42...43]))
        
        /**保留以后使用，占28个字节*/
        lock.resever    = Array(frame[44...71])
        
        
        /**布防状态，占1个字节，为0代表撤防，为1代表布防。*/
        lock.protectStatus = frame[72]
        
        /**状态，占1个字节，0x01代表未配对；0x02代表已配对。*/
        lock.status     = frame[73]
        
        
        
        print("新的智能门锁：\t名称：\(lock.name),状态：\(lock.status)")

        

        return (lock,74)
        
        
        
        }

    func unlockSmartDoor(password: String, result: (NSError?)->Void){
        HR8000Service.shareInstance().unlockSmartDoor(self, passwd: password, callback: result)
    }
}



//MARK: - 0x0C HRDoorBell 智能门铃
/**智能门铃类（0x0C）,*/
class HRDoorBell: HRRFDevice  {
	/**保留以后使用，占28个字节*/
	var resever: [Byte]     = Array()
	/**布防状态，占1个字节，为0代表撤防，为1代表布防。*/
	var protectStatus: Byte = 0
	/**状态，占1个字节，为0代表门磁合上；为1代表门磁分开。*/
	var status: Byte        = 0
	
	class func initWithDataFrame(type: Byte, hostAddr: UInt32, frame: [Byte]) -> (HRDoorBell, Int){
		/**********************************
		元素      长度         名称
		0         1         设备类型
		1-4       4         设备地址
		5         1         信道
		6         1         RF地址码
		7         1         软件版本
		8-39      32        设备名称
		40-41     2         安装所在房间的ID
		42-43     2         安装所在的楼层ID
		44-71     28        保留以后使用
		**/
		let bell = HRDoorBell()
		bell.hostAddr  = hostAddr
		bell.devType   = type
		bell.devAddr   = UInt32(fourBytes: Array(frame[1...4]))
		bell.channel   = frame[5]
		bell.RFAddr    = frame[6]
		bell.RFVersion   = frame[7]
		if let name = ContentHelper.encodeGbkData(Array(frame[8...39])) {
			bell.name = name
		}
		bell.insRoomID  = UInt16(twoBytes: Array(frame[40...41]))
		bell.insFloorID = UInt16(twoBytes: Array(frame[42...43]))
		bell.resever    = Array(frame[44...71])
		bell.protectStatus = frame[72]
		bell.status     = frame[73]
		
		Log.debug("入侵探测器/智能门磁/智能门锁/智能门铃：\t名称：\(bell.name),状态：\(bell.status)")
		
		return (bell, 74)
	}
}

//MARK: - _ HRSensor 传感器基类
///传感器基类
class HRSensor: HRRFDevice {
	/**保留以后使用，占28个字节*/
	var resever: [Byte]    = Array()
	
	///查询光照、燃气、温湿度空气、湿敏探测器等传感器的值，查询结果请会在HRSensorValuesDelegate中返回
	func queryValue(){
		HR8000Service.shareInstance().querySensorValue(self)
	}
	
	override func copyWithZone(zone: NSZone) -> AnyObject {
		let theCopyDev = super.copyWithZone(zone) as! HRSensor
		theCopyDev.resever = self.resever
		return theCopyDev
	}
}

//MARK: - 0x0D HRSolarSensor 光照传感器
/**光照传感器,0x0D*/
class HRSolarSensor: HRSensor{
	
	/**联动标志*/
	var linkMark: Byte     = 0
	/**联动动作值 - 上限值*/
	var linkUpperValue: UInt16  = 0
	/**联动动作值 - 下限值*/
	var linkLowerValue: UInt16  = 0
	/**联动绑定*/
	var sensorBinds: [HRSensorBind] = Array()
	
	///联动启用
	var linkEnable: Bool {
		get { return linkMark != 0x00 }
		set { self.linkMark = newValue ? 0x01 : 0x00 }
	}
	
	required init(){}
	
	override func copyWithZone(zone: NSZone) -> AnyObject {
		let theCopyDev = super.copyWithZone(zone) as! HRSolarSensor
		theCopyDev.linkMark = self.linkMark
		theCopyDev.linkLowerValue = self.linkLowerValue
		theCopyDev.linkUpperValue = self.linkUpperValue
		for bind in self.sensorBinds {
			theCopyDev.sensorBinds.append(bind.copySensorbind())
		}
		return theCopyDev
	}
	
	class func initWithDataFrame(hostAddr: UInt32, dataFrame frame: [Byte]) -> (HRSolarSensor, Int){
		/**********************************
		元素      长度         名称
		0         1         设备类型
		1-4       4         设备地址
		5         1         信道
		6         1         RF地址码
		7         1         软件版本
		8-39      32        设备名称
		40-41     2         安装所在房间的ID
		42-43     2         安装所在的楼层ID
		44-71     28        保留以后使用
		72        1         联动标志
		73-76     4         联动动作值，下限值(2B)+上限值(2B)
		77-       N         多级联动绑定HRSensorBind
		***********************************///
		let solar = HRSolarSensor()
		solar.hostAddr  = hostAddr
		solar.devType   = HRDeviceType.SolarSensor.rawValue
		solar.devAddr   = UInt32(fourBytes: Array(frame[1...4]))
		solar.channel   = frame[5]
		solar.RFAddr    = frame[6]
		solar.RFVersion   = frame[7]
		if let name = ContentHelper.encodeGbkData(Array(frame[8...39])) {
			solar.name = name
		}
		solar.insRoomID  = UInt16(twoBytes: Array(frame[40...41]))
		solar.insFloorID = UInt16(twoBytes: Array(frame[42...43]))
		solar.resever    = Array(frame[44...71])
		solar.linkMark   = frame[72]
		solar.linkLowerValue = UInt16(twoBytes: Array(frame[73...74]))
		solar.linkUpperValue = UInt16(twoBytes: Array(frame[75...76]))
		var count = 77
		for level in 1...4{
			let levelBase = count
			var bind = HRSensorBind()
			bind.level = level
			bind.devCount = frame[levelBase+0]
			count += 1
			for i in 0..<bind.devCount {
				//情景中的设备：
				// (0-3) 设备或情景所属主机，占4个字节
				//（4）   设备类型，占1个字节
				//（5-8） 设备地址，占4个字节
				//（9-12）设备绑定的操作，占4个字节
				//（13-16）延时码
				let devBase = levelBase + 1 + 17 * Int(i)
				let dev = HRDevInScene()
				dev.hostAddr  = UInt32(fourBytes: Array(frame[devBase+0...devBase+3]))
				dev.devType   = frame[devBase+4]
				dev.devAddr   = UInt32(fourBytes: Array(frame[devBase+5...devBase+8]))
				dev.actBinds  = Array(frame[devBase+9...devBase+12])
				dev.delayCode = Array(frame[devBase+13...devBase+16])
				count += 17
				bind.devInScenes.append(dev)
			}
			solar.sensorBinds.append(bind)
			
		}
		
		Log.debug("光照传感器：\t名称：\(solar.name)")
		
		return (solar, count)
	}
	
}

/**传感器的联动绑定*/
struct HRSensorBind{
	/**联动等级*/
	var level: Int     = 0
	/**情景中的设备数量*/
	var devCount: Byte = 0
	/**情景中的设备信息*/
	var devInScenes: [HRDevInScene] = Array()
	
	func copySensorbind() -> HRSensorBind {
		var theCopyBind = HRSensorBind()
		theCopyBind.level = self.level
		theCopyBind.devCount = self.devCount
		for devInScene in devInScenes {
			theCopyBind.devInScenes.append(devInScene.copy() as! HRDevInScene)
		}
		
		return theCopyBind
	}
}

//MARK: - 0x0E HRGasSensor 可燃气体探测器
///可燃气体探测器,0x0E
class HRGasSensor: HRSensor {
	/**联动标志*/
	var linkMark: Byte     = 0
	/**联动动作值 - */
	var linkLowerValue: Float  = 0
	/**联动动作值*/
	var linkUpperValue: Float  = 0
	/**联动绑定*/
	var sensorBinds: [HRSensorBind] = Array()
	
	///联动启用
	var linkEnable: Bool {
		get { return linkMark != 0x00 }
		set { self.linkMark = newValue ? 0x01 : 0x00 }
	}
	
	required init() {
		super.init()
		self.devType = HRDeviceType.GasSensor.rawValue
	}
	
	override func copyWithZone(zone: NSZone) -> AnyObject {
		let theCopyDev = super.copyWithZone(zone) as! HRGasSensor
		theCopyDev.linkMark = self.linkMark
		theCopyDev.linkLowerValue = self.linkLowerValue
		theCopyDev.linkUpperValue = self.linkUpperValue
		for bind in self.sensorBinds {
			theCopyDev.sensorBinds.append(bind.copySensorbind())
		}
		return theCopyDev
	}
	
	class func initWithDataFrame(hostAddr: UInt32, dataFrame frame: [Byte]) -> (HRGasSensor, Int){
		/**********************************
		元素      长度         名称
		0         1         设备类型
		1-4       4         设备地址
		5         1         信道
		6         1         RF地址码
		7         1         软件版本
		8-39      32        设备名称
		40-41     2         安装所在房间的ID
		42-43     2         安装所在的楼层ID
		44-71     28        保留以后使用
		72        1         联动标志
		73-76     4         联动动作值，下限值(2B)+上限值(2B)
		77-       N         多级联动绑定HRSensorBind
		***********************************///
		let gas = HRGasSensor()
		gas.hostAddr  = hostAddr
		gas.devType   = HRDeviceType.GasSensor.rawValue
		gas.devAddr   = UInt32(fourBytes: Array(frame[1...4]))
		gas.channel   = frame[5]
		gas.RFAddr    = frame[6]
		gas.RFVersion   = frame[7]
		if let name = ContentHelper.encodeGbkData(Array(frame[8...39])) {
			gas.name = name
		}
		gas.insRoomID  = UInt16(twoBytes: Array(frame[40...41]))
		gas.insFloorID = UInt16(twoBytes: Array(frame[42...43]))
		gas.resever    = Array(frame[44...71])
		gas.linkMark   = frame[72]
		gas.linkLowerValue = Float(UInt16(twoBytes: Array(frame[73...74]))) / 100.0
		gas.linkUpperValue = Float(UInt16(twoBytes: Array(frame[75...76]))) / 100.0
		var count = 77
		var bind = HRSensorBind()
		bind.level = 1
		bind.devCount = frame[77]
		count += 1
		for i in 0..<bind.devCount{
			//情景中的设备：
			// (0-3) 设备或情景所属主机，占4个字节
			//（4）   设备类型，占1个字节
			//（5-8） 设备地址，占4个字节
			//（9-12）设备绑定的操作，占4个字节
			//（13-16）延时码，占4个字节
			let devBase = 78 + 17 * Int(i)
			let dev = HRDevInScene()
			dev.hostAddr  = UInt32(fourBytes: Array(frame[devBase+0...devBase+3]))
			dev.devType   = frame[devBase+4]
			dev.devAddr   = UInt32(fourBytes: Array(frame[devBase+5...devBase+8]))
			dev.actBinds  = Array(frame[devBase+9...devBase+12])
			dev.delayCode = Array(frame[devBase+13...devBase+16])
			count += 17
			bind.devInScenes.append(dev)
		}
		gas.sensorBinds.append(bind)
		
		Log.debug("可燃气体传感器：\t名称：\(gas.name)")
		
		return (gas, count)
	}
}

//MARK: - 0x0F HRAirQualitySensor 温湿度空气质量探测器
///温湿度空气质量探测器，0x0F
class HRAirQualitySensor: HRSensor {
	/**温度联动标志*/
	var linkMarkTemp: Byte    = 0
	/**湿度联动标志*/
	var linkMarkHumid: Byte    = 0
	/**空气质量联动标志*/
	var linkMarkAir: Byte     = 0
	/**温度联动动作值 - 下限值*/
	var linkLowerValueTemp: Float = 0
	/**温度联动动作值 - 上限值*/
	var linkUpperValueTemp: Float = 0
	/**湿度联动动作值 - 下限值*/
	var linkLowerValueHumid: Float = 0
	/**湿度联动动作值 - 上限值*/
	var linkUpperValueHumid: Float = 0
	/**空气质量联动动作值 - 下限值*/
	var linkLowerValueAir: Float  = 0
	/**空气质量联动动作值 - 上限值*/
	var linkUpperValueAir: Float  = 0
	/**温度联动绑定*/
	var sensorBindsTemp: [HRSensorBind] = Array()
	/**湿度联动绑定*/
	var sensorBindsHumi: [HRSensorBind] = Array()
	/**空气质量联动绑定*/
	var sensorBindsAir: [HRSensorBind] = Array()
	
	///联动启用
	var linkTempEnable: Bool {
		get { return linkMarkTemp != 0x00 }
		set { self.linkMarkTemp = newValue ? 0x01 : 0x00 }
	}
	
	///联动启用
	var linkHumidEnable: Bool {
		get { return linkMarkHumid != 0x00 }
		set { self.linkMarkHumid = newValue ? 0x01 : 0x00 }
	}
	
	required init() {
		super.init()
		self.devType = HRDeviceType.AirQualitySensor.rawValue
	}
	
	override func copyWithZone(zone: NSZone) -> AnyObject {
		let theCopyDev = super.copyWithZone(zone) as! HRAirQualitySensor
        theCopyDev.linkMarkTemp        = self.linkMarkTemp
        theCopyDev.linkMarkHumid       = self.linkMarkHumid
        theCopyDev.linkMarkAir         = self.linkMarkAir
        theCopyDev.linkLowerValueTemp  = self.linkLowerValueTemp
        theCopyDev.linkUpperValueTemp  = self.linkUpperValueTemp
        theCopyDev.linkLowerValueHumid = self.linkLowerValueHumid
        theCopyDev.linkUpperValueHumid = self.linkUpperValueHumid
        theCopyDev.linkLowerValueAir   = self.linkLowerValueAir
		theCopyDev.linkUpperValueAir   = self.linkUpperValueAir
		for bind in self.sensorBindsTemp {
			theCopyDev.sensorBindsTemp.append(bind.copySensorbind())
		}
		for bind in self.sensorBindsHumi {
			theCopyDev.sensorBindsHumi.append(bind.copySensorbind())
		}
		for bind in self.sensorBindsAir {
			theCopyDev.sensorBindsAir.append(bind.copySensorbind())
		}
		return theCopyDev
	}
	
	class func initWithDataFrame(hostAddr: UInt32, dataFrame frame: [Byte]) -> (HRAirQualitySensor, Int){
		/**********************************
		元素      长度         名称
		0         1         设备类型
		1-4       4         设备地址
		5         1         信道
		6         1         RF地址码
		7         1         软件版本
		8-39      32        设备名称
		40-41     2         安装所在房间的ID
		42-43     2         安装所在的楼层ID
		44-71     28        保留以后使用
		72        1         温度联动标志
		73        1         湿度联动标志
		74        1         空气质量联动标志
		75-78     4         温度的联动动作值，下限值(2B)+上限值(2B)
		79-82     4         湿度的联动动作值，下限值(2B)+上限值(2B)
		83-86     4         空气质量的联动动作值，下限值(2B)+上限值(2B)
		89-       N         温度的2级联动绑定HRSensorBind
		-         N         湿度的2级联动绑定HRSensorBind
		-         N         空气质量的1级联动绑定HRSensorBind
		***********************************///
		let aqs = HRAirQualitySensor()
		aqs.hostAddr  = hostAddr
		aqs.devType   = HRDeviceType.AirQualitySensor.rawValue
		aqs.devAddr   = UInt32(fourBytes: Array(frame[1...4]))
		aqs.channel   = frame[5]
		aqs.RFAddr    = frame[6]
		aqs.RFVersion   = frame[7]
		if let name = ContentHelper.encodeGbkData(Array(frame[8...39])) {
			aqs.name = name
		}
		aqs.insRoomID  = UInt16(twoBytes: Array(frame[40...41]))
		aqs.insFloorID = UInt16(twoBytes: Array(frame[42...43]))
		aqs.resever    = Array(frame[44...71])
		aqs.linkMarkTemp    = frame[72]
		aqs.linkMarkHumid   = frame[73]
		aqs.linkMarkAir     = frame[74]
        aqs.linkLowerValueTemp  = Float(NSNumber(unsignedShort: UInt16(twoBytes: Array(frame[75...76]))).shortValue) / 10
        aqs.linkUpperValueTemp  = Float(NSNumber(unsignedShort: UInt16(twoBytes: Array(frame[77...78]))).shortValue) / 10
        aqs.linkLowerValueHumid = Float(NSNumber(unsignedShort: UInt16(twoBytes: Array(frame[79...80]))).shortValue) / 10
        aqs.linkUpperValueHumid = Float(NSNumber(unsignedShort: UInt16(twoBytes: Array(frame[81...82]))).shortValue) / 10
        aqs.linkLowerValueAir   = Float(NSNumber(unsignedShort: UInt16(twoBytes: Array(frame[83...84]))).shortValue) / 10
        aqs.linkUpperValueAir   = Float(NSNumber(unsignedShort: UInt16(twoBytes: Array(frame[85...86]))).shortValue) / 10
		
		var count = 87
		//温度的2级联动绑定
		for level in 1...2{
			let levelBase = count
			var bind = HRSensorBind()
			bind.level = level
			bind.devCount = frame[levelBase+0]
			count += 1
			for i in 0..<bind.devCount {
				//情景中的设备：
				// (0-3) 设备或情景所属主机，占4个字节
				//（4）   设备类型，占1个字节
				//（5-8） 设备地址，占4个字节
				//（9-12）设备绑定的操作，占4个字节
				//（13-16）延时码
				let dev = HRDevInScene()
				let devBase = levelBase + 1 + 17 * Int(i)
				dev.hostAddr  = UInt32(fourBytes: Array(frame[devBase+0...devBase+3]))
				dev.devType   = frame[devBase+4]
				dev.devAddr   = UInt32(fourBytes: Array(frame[devBase+5...devBase+8]))
				dev.actBinds  = Array(frame[devBase+9...devBase+12])
				dev.delayCode = Array(frame[devBase+13...devBase+16])
				count += 17
				bind.devInScenes.append(dev)
			}
			aqs.sensorBindsTemp.append(bind)
		}
		
		//湿度的2级联动绑定
		for level in 1...2{
			let levelBase = count
			var bind = HRSensorBind()
			bind.level = level
			bind.devCount = frame[levelBase+0]
			count += 1
			for i in 0..<bind.devCount {
				//情景中的设备：
				// (0-3) 设备或情景所属主机，占4个字节
				//（4）   设备类型，占1个字节
				//（5-8） 设备地址，占4个字节
				//（9-12）设备绑定的操作，占4个字节
				//（13-16）延时码
				let dev = HRDevInScene()
				let devBase = levelBase + 1 + 17 * Int(i)
				dev.hostAddr  = UInt32(fourBytes: Array(frame[devBase+0...devBase+3]))
				dev.devType   = frame[devBase+4]
				dev.devAddr   = UInt32(fourBytes: Array(frame[devBase+5...devBase+8]))
				dev.actBinds  = Array(frame[devBase+9...devBase+12])
				dev.delayCode = Array(frame[devBase+13...devBase+16])
				count += 17
				bind.devInScenes.append(dev)
			}
			aqs.sensorBindsHumi.append(bind)
		}
		
		//空气质量的1级联动绑定
		for level in 1...1{
			let levelBase = count
			var bind = HRSensorBind()
			bind.level = level
			bind.devCount = frame[levelBase+0]
			count += 1
			for i in 0..<bind.devCount {
				//情景中的设备：
				// (0-3) 设备或情景所属主机，占4个字节
				//（4）   设备类型，占1个字节
				//（5-8） 设备地址，占4个字节
				//（9-12）设备绑定的操作，占4个字节
				//（13-16）延时码
				let dev = HRDevInScene()
				let devBase = levelBase + 1 + 17 * Int(i)
				dev.hostAddr  = UInt32(fourBytes: Array(frame[devBase+0...devBase+3]))
				dev.devType   = frame[devBase+4]
				dev.devAddr   = UInt32(fourBytes: Array(frame[devBase+5...devBase+8]))
				dev.actBinds  = Array(frame[devBase+9...devBase+12])
				dev.delayCode = Array(frame[devBase+13...devBase+16])
				count += 17
				bind.devInScenes.append(dev)
			}
			aqs.sensorBindsAir.append(bind)
		}
		
		Log.debug("温湿度空气质量探测器：\t名称：\(aqs.name)")
		
		return (aqs, count)
	}
	
}

//MARK: - 0x10 HRHumiditySensor 湿敏探测器
///湿敏探测器，0x10
class HRHumiditySensor: HRSensor{
	/**联动标志*/
	var linkMark: Byte     = 0
	/**联动绑定*/
	var sensorBinds: [HRSensorBind] = Array()
	
	///联动启用
	var linkEnable: Bool {
		get { return linkMark != 0x00 }
		set { self.linkMark = newValue ? 0x01 : 0x00 }
	}
	
	required init() {
		super.init()
		self.devType = HRDeviceType.HumiditySensor.rawValue
	}
	
	override func copyWithZone(zone: NSZone) -> AnyObject {
		let theCopyDev = super.copyWithZone(zone) as! HRHumiditySensor
		theCopyDev.linkMark    = self.linkMark
		for bind in self.sensorBinds {
			theCopyDev.sensorBinds.append(bind.copySensorbind())
		}
		return theCopyDev
	}
	
	class func initWithDataFrame(hostAddr: UInt32, dataFrame frame: [Byte]) -> (HRHumiditySensor, Int){
		/**********************************
		元素      长度         名称
		0         1         设备类型
		1-4       4         设备地址
		5         1         信道
		6         1         RF地址码
		7         1         软件版本
		8-39      32        设备名称
		40-41     2         安装所在房间的ID
		42-43     2         安装所在的楼层ID
		44-71     28        保留以后使用
		72        1         联动标志
		73-       N         多级联动绑定HRSensorBind
		***********************************///
		let hum = HRHumiditySensor()
		hum.hostAddr  = hostAddr
		hum.devType   = HRDeviceType.HumiditySensor.rawValue
		hum.devAddr   = UInt32(fourBytes: Array(frame[1...4]))
		hum.channel   = frame[5]
		hum.RFAddr    = frame[6]
		hum.RFVersion   = frame[7]
		if let name = ContentHelper.encodeGbkData(Array(frame[8...39])) {
			hum.name = name
		}
		hum.insRoomID  = UInt16(twoBytes: Array(frame[40...41]))
		hum.insFloorID = UInt16(twoBytes: Array(frame[42...43]))
		hum.resever    = Array(frame[44...71])
		hum.linkMark   = frame[72]
		var count = 73
		var bind = HRSensorBind()
		let levelBase = count
		bind.level = 1
		bind.devCount = frame[73]
		count += 1
		for i in 0..<bind.devCount{
			//情景中的设备：
			// (0-3) 设备或情景所属主机，占4个字节
			//（4）   设备类型，占1个字节
			//（5-8） 设备地址，占4个字节
			//（9-12）设备绑定的操作，占4个字节
			//（13-16）延时码
			let dev = HRDevInScene()
			let devBase = levelBase + 1 + 17 * Int(i)
			dev.hostAddr  = UInt32(fourBytes: Array(frame[devBase+0...devBase+3]))
			dev.devType   = frame[devBase+4]
			dev.devAddr   = UInt32(fourBytes: Array(frame[devBase+5...devBase+8]))
			dev.actBinds  = Array(frame[devBase+9...devBase+12])
			dev.delayCode = Array(frame[devBase+13...devBase+16])
			count += 17
			bind.devInScenes.append(dev)
		}
		hum.sensorBinds.append(bind)
		
		Log.debug("湿敏探测器：\t名称：\(hum.name)")
		
        
       // print("温敏探测器的长度\(count)")
        
		return (hum, count)
        
        
	}
}

//MARK: - 0x11 HRManipulator 机械手
/**机械手,0x11*/
class HRManipulator: HRMotorCtrlDev {
	
	required init() {
		super.init()
		devType = HRDeviceType.Manipulator.rawValue
	}
	
	override class func initWithDataFrame(hostAddr: UInt32, dataFrame frame: [Byte]) -> (HRManipulator, Int) {
		let (motor, len) = super.initWithDataFrame(hostAddr, dataFrame: frame)
		let manip = HRManipulator()
		manip.name       = motor.name
		manip.hostAddr   = motor.hostAddr
        manip.devAddr    = motor.devAddr
        manip.channel    = motor.channel
        manip.RFAddr     = motor.RFAddr
        manip.RFVersion    = motor.RFVersion
        manip.insRoomID  = motor.insRoomID
        manip.insFloorID = motor.insFloorID
        manip.resever    = motor.resever
        manip.status     = motor.status
		return (manip, len)
	}
}

//MARK: - 0x12 HRSmartBed 智能床控制器
///智能床控制器,0x12
class HRSmartBed: HRRFDevice {
	/**保留以后使用，占28个字节*/
	var resever: [Byte]    = Array()
	/**床头位置*/
	var headPos: Byte   = 0
	/**床尾位置*/
	var tailPos: Byte   = 0
	/**床头震动，0~3四种状态*/
	var headVib: Byte   = 0
	/**床尾震动，0~3四种状态*/
	var tailVib: Byte   = 0
	/**灯光状态， 0x00表示关闭，0x01表示打开*/
	var lampState : Byte   = 0
	
	class func initWithDataFrame(hostAddr: UInt32, dataFrame frame: [Byte]) -> (HRSmartBed, Int){
		/**********************************
		元素      长度         名称
		0         1         设备类型
		1-4       4         设备地址
		5         1         信道
		6         1         RF地址码
		7         1         软件版本
		8-39      32        设备名称
		40-41     2         安装所在房间的ID
		42-43     2         安装所在的楼层ID
		44-71     28        保留以后使用
		72        1         床头位置
		73        1         床尾位置
		74        1         床头震动
		75        1         床尾震动
		76        1         灯光状态
		***********************************///
		let bed = HRSmartBed()
		bed.hostAddr  = hostAddr
		bed.devType   = HRDeviceType.SmartBed.rawValue
		bed.devAddr   = UInt32(fourBytes: Array(frame[1...4]))
		bed.channel   = frame[5]
		bed.RFAddr    = frame[6]
		bed.RFVersion   = frame[7]
		if let name = ContentHelper.encodeGbkData(Array(frame[8...39])) {
			bed.name = name
		}
		bed.insRoomID  = UInt16(twoBytes: Array(frame[40...41]))
		bed.insFloorID = UInt16(twoBytes: Array(frame[42...43]))
		bed.resever    = Array(frame[44...71])
		bed.headPos    = frame[72]
		bed.tailPos    = frame[73]
		bed.headVib    = frame[74]
		bed.tailVib    = frame[75]
		bed.lampState  = frame[76]
		
		Log.debug("智能床：\t名称：\(bed.name)")
		
		return (bed, 77)
	}
	
	///床头位置上升
	func headPosUp() {
		HR8000Service.shareInstance().operateSmartBed(self, headPos: 0x01)
	}
	
	///床头位置下降
	func headPosDown() {
		HR8000Service.shareInstance().operateSmartBed(self, headPos: 0xFF)
	}
	
	///床尾位置上升
	func tailPosUp() {
		HR8000Service.shareInstance().operateSmartBed(self, tailPos: 0x01)
	}
	
	///床尾位置下降
	func tailPosDown() {
		HR8000Service.shareInstance().operateSmartBed(self, tailPos: 0xF0)
	}
	
	///床头震动
	///
	///- parameter level: 震动等级，0~3四种等级，0xFF表示保持不变
	func headMassage(level: Byte) {
		HR8000Service.shareInstance().operateSmartBed(self, headMassage: level)
		Log.debug("send headMassage:\(level)")
	}
	
	///床尾震动
	///
	///- parameter level: 震动等级，0~3四种等级，0xFF表示保持不变
	func tailMassage(level: Byte) {
		HR8000Service.shareInstance().operateSmartBed(self, tailMassage: level)
		Log.debug("send tailMassage:\(level)")
	}
	
	///灯光打开
	func lightOn() {
		HR8000Service.shareInstance().operateSmartBed(self, light: bSmartBedLightOn)
	}
	
	///灯光关闭
	func lightOff() {
		HR8000Service.shareInstance().operateSmartBed(self, light: bSmartBedLightOff)
	}
	
	//灯光切换
	func lightSwitch() {
		if lampState == 0x00 {
			self.lightOn()
		} else {
			self.lightOff()
		}
	}
	
	///灯光亮度
	func lightBrightness(value: Byte) {
		HR8000Service.shareInstance().operateSmartBed(self, light: value)
	}
	
	///多种控制
	func multiControl(headPos: Byte? = nil, tailPos: Byte? = nil, headMassage: Byte? = nil, tailMassage: Byte? = nil, light: Byte? = nil) {
		HR8000Service.shareInstance().operateSmartBed(self, headPos: headPos, tailPos: tailPos, headMassage: headMassage, tailMassage: tailMassage, light: light)
	}
	
}
///智能床之开灯
let bSmartBedLightOff :Byte = 0x00
///智能床之关灯
let bSmartBedLightOn  :Byte = 0x01


//MARK: - 0x14 单火开关
class HRLiveWireSwitch: HRRelayComplexes {
	required init() {
		super.init()
		self.devType = HRDeviceType.LiveWireSwitch.rawValue
	}
	
	class func initWithDataFrame(hostAddr: UInt32, dataFrame frame: [Byte]) -> (HRLiveWireSwitch, Int) {
		let (lwSwitch, len) = super.initWithDataFrame(HRLiveWireSwitch(), hostAddr: hostAddr, dataFrame: frame)
		return (lwSwitch as! HRLiveWireSwitch, len)
	}
}

//MARK: - 0xF8 HRUserInfo 用户信息类
/**用户信息类（0xF8），用于描述一个用户的信息*/
class HRUserInfo: HRDevice  {
	/**用户ID，占4个字节*/
	var id: UInt32 = 0
	/**权限，占1个字节*/
	var permission: Byte = 0
	
	var isAdministrator: Bool {
		return permission == 2
	}
	
	required init() {
		super.init()
		self.devType = HRDeviceType.UserInfo.rawValue
	}
	
	class func initWithDataFrame(dataFrame frame: [Byte]) -> (HRUserInfo, Int) {
		/**********************************
		元素      长度         名称
		0         1         设备类型
		1-4       4         用户id
		5-36      32        用户名
		37        1         权限
		***********************************/
		let user = HRUserInfo()
        user.devType = HRDeviceType.UserInfo.rawValue
        user.id      = UInt32(fourBytes: Array(frame[1...4]))
        user.devAddr = user.id
        
       //这句话的意思是把这个数据帧的5-36这32个字节的二进制数字转化成字符串 斌注释，也就是解码
		if let name = ContentHelper.encodeGbkData(Array(frame[5...36])) {
			user.name = name
		}
		user.permission = frame[37]
		user.insFloorID = UInt16(frame[38])
		user.insRoomID  = UInt16(frame[39])
		
		Log.debug("用户信息：\t用户名：\(user.name)，\t权限\(user.permission)")
        //print("用户信息：\t用户名：\(user.name)，\t权限\(user.permission)")
            
		
		return (user, 40)
	}
	
	override func copyWithZone(zone: NSZone) -> AnyObject {
		let user = super.copyWithZone(zone) as! HRUserInfo
        user.devAddr    = self.devAddr
        user.devType    = self.devType
        user.hostAddr   = self.hostAddr
        user.name       = self.name
        user.insFloorID = self.insFloorID
        user.insRoomID  = self.insRoomID
        user.id         = self.id
        user.permission = self.permission
		return user
	}
}

//MARK: - 0xF9 HRFloorInfo 楼层信息
/**楼层信息类（0xF9），用于描述一个楼层*/
class HRFloorInfo: HRDevice  {
	/**楼层ID，占4个字节*/
	var id: UInt16        = 0
	/**楼层里房间数，，占16个字节*/
	var roomTotal: UInt16 = 0
	/**楼层房间信息，这是一个RoomInfo结构体数组*/
	var roomInfos: [HRRoomInfo] = Array()
	
	required init() {
		super.init()
		self.devType = HRDeviceType.UserInfo.rawValue
	}
	
	class func initWithDataFrame(dataFrame frame: [Byte]) -> (HRFloorInfo, Int) {
		/**********************************
		元素      长度         名称
		0         1         设备类型
		1-4       4         楼层id
		5-36      32        楼层名
		37-38     2         楼层房间数
		39-       N         楼层房间信息
		
		楼层房间信息：
		0-1       2         房间ID
		2-33      32        房间名
		***********************************///
		let floor = HRFloorInfo()
        floor.devType = HRDeviceType.FloorInfo.rawValue
        floor.id      = UInt16(UInt32(fourBytes: Array(frame[1...4])))
        floor.devAddr = UInt32(floor.id)
		if let name = ContentHelper.encodeGbkData(Array(frame[5...36])) {
			floor.name = name
		}
		floor.roomTotal = UInt16(twoBytes: Array(frame[37...38]))
		if floor.roomTotal > 0 {
			for i in 0...floor.roomTotal-1 {
				let basePos = 39 + 34 * Int(i)
				let room = HRRoomInfo()
				room.floor = floor
				room.id = UInt16(twoBytes: Array(frame[basePos+0...basePos+1]))
				if let name = ContentHelper.encodeGbkData(Array(frame[basePos+2...basePos+33])) {
					room.name = name
				}
				floor.roomInfos.append(room)
			}
		}
        
        
        //print("\(floor.name),\(floor.roomTotal)")
		Log.debug("楼层信息：\t楼层名：\(floor.name),\t房间数：\(floor.roomTotal)")
		let count = 39 + 34*Int(floor.roomTotal)
		
		return (floor, count)
	}
}

/**房间信息*/
class HRRoomInfo  {
	/**主机地址*/
	var hostAddr: UInt32 = 0
	/**房间ID，占2个字节*/
	var id: UInt16 = 0
	/**房间名，占32个字节*/
	var name: String = ""
	///房间所处的楼层
	var floor: HRFloorInfo!
}

//MARK: - 0xFA HRApplianceApplyDev 应用设备
/**应用设备类（0xFA），用于描述一个应用设备*/
class HRApplianceApplyDev: HRDevice  {
	/**应用设备ID*/
	var appDevID: UInt32          = 0
	/**保留以后使用，占28个字节*/
	var resever: [Byte]           = Array()
	/**红外学习状态，占1个字节。可赋值：enum InfraredLearnStatus*/
	var infraredLearnStatus: Byte = 0
	/**应用设备类型，占1个字节，类型可选参考枚举HRAppDeviceType*/
	var appDevType: Byte          = 0x00
	/**红外转发器地址，占4个字节*/
	var infraredUnitAddr: UInt32  = 0
	/**按键学习状态*/
	var learnKeys: [HRInfraredKey]  = Array()
	
	
	class func initWithDataFrame(hostAddr: UInt32, dataFrame frame: [Byte]) -> (HRApplianceApplyDev, Int){
		/**********************************
		元素      长度         名称
		0         1         设备类型
		1-4       4         应用设备ID
		5-36      32        设备名称
		37-38     2         安装所在房间的ID
		39-40     2         安装所在的楼层ID
		41-68     28        保留以后使用
		69        1         红外学习状态：表示已学习按键数
		70        1         应用设备类型
		71-74     4         红外转发器地址
		75-       N         按键学习状态
		
		按键学习状态：
		0         1         按键编码
		1-4       4         码库索引
		***********************************///
		let apply = HRApplianceApplyDev()
		apply.hostAddr = hostAddr
		apply.devType  = HRDeviceType.ApplyDevice.rawValue
		apply.appDevID = UInt32(fourBytes: Array(frame[1...4]))
		apply.devAddr  = apply.appDevID
		if let name = ContentHelper.encodeGbkData(Array(frame[5...36])) {
			apply.name = name
		}
		apply.insRoomID  = UInt16(twoBytes: Array(frame[37...38]))
		apply.insFloorID = UInt16(twoBytes: Array(frame[39...40]))
		apply.resever    = Array(frame[41...68])
		apply.infraredLearnStatus = frame[69]
		apply.appDevType = frame[70]
		apply.infraredUnitAddr = UInt32(fourBytes: Array(frame[71...74]))
		if apply.infraredLearnStatus > 0 {
			for i in 0...apply.infraredLearnStatus-1 {
				let basePos = 75 + 5 * Int(i)
				let key = HRInfraredKey()
				key.keyCode = frame[basePos]
				key.codeLibType = frame[basePos + 1]
				key.codeLibIndex = UInt16(twoBytes: Array(frame[basePos+2...basePos+3]).reverse())
				key.operateCode = frame[basePos + 4]
				apply.learnKeys.append(key)
			}
		}
		
		Log.debug("应用设备：\t名称：\(apply.name), \t已学习的按键数：\(apply.infraredLearnStatus)")
		
		return (apply, 75 + 5 * Int(apply.infraredLearnStatus))
	}
	
	///保存应用设备信息到主机
	///
	///- parameter isCreate: 是否是创建的应用设备，如果是则填true, 如果是修改应用设备则填false
	///- parameter result:   结果回调
	func saveToRemote(isCreate: Bool , result: ((NSError?)->Void)?) {
		if isCreate {
			HR8000Service.shareInstance().createApplyDevice(hostAddr, appType: self.appDevType, name: name, floorId: insFloorID, roomId: insRoomID, InfraredDevAddr: infraredUnitAddr, result: result)
		} else {
			HR8000Service.shareInstance().modifyApplyDevice(self, result: result)
		}
	}
	
	func removeFromRemote(result: ((NSError?)->Void)?) {
		HR8000Service.shareInstance().deleteApplyDevice(self, result: result)
	}
	
	
	///初始化该应用设备红外码，只有绑定码库的应用设备才需要初始化，自定义学习的不用
	///
	///- parameter result 初始化结果
	func initInfrared(result: ((NSError?)->Void)?) {
		HR8000Service.shareInstance().initAirCtrl(self, completion: result)
	}
	
	
	///发送红外码，控制应用设备
	///
	///- parameter key:    红外码
	///- parameter ctrlType 操作类型，HRInfraredCtrlType， 默认为正常控制（.Normal）
	///- parameter tag:    标记
	///- parameter result: 结果
	func sendInfrared(infraredKey key: HRInfraredKey, ctrlType: HRInfraredCtrlType = .NormalCtrl, tag: Byte, result: ((NSError?)->Void)?) {
		HR8000Service.shareInstance().operateInfrared(self, ctrlType: ctrlType, infraredKey: key, tag: tag, callback: result)
	}
}


///红外转发的按键
class HRInfraredKey {
	/**按键编码*/
    var keyCode: Byte      = 0
	
	//以下3个属性构成红外码库索引，共4个字节
	///码库类型
    var codeLibType: Byte  = 0
	///码库索引号
    var codeLibIndex: UInt16 = 0
	///操作编码，也是设备状态值
    var operateCode: Byte  = 0
}

///红外码库类型
enum HRInfraredKeyCodeLibType: Byte {
	///空调
    case AirCtrl = 0x03
	///机顶盒
    case STB     = 0x04
	///自定义学习的码库
    case Custom  = 0xFF
}

///红外转发的操作类型
enum HRInfraredCtrlType: Byte {
	///初始化
    case Init         = 0x00
	///码库匹配
    case MatchLibrary = 0x01
	///正常操作
    case NormalCtrl   = 0x02
}

/**应用设备类型*/
enum HRAppDeviceType: Byte{
	/**表示该继电器设备没有关联用电设备*/
	case None      = 0x00
	/**灯*/
	case Lamp      = 0x01
	/**电视机*/
	case TV        = 0x02
	/**空调*/
	case AirCtrl   = 0x03
	/**机顶盒（Set Top Box）*/
	case STB       = 0x04
	/**窗帘*/
	case Curtain   = 0x05
	/**其他*/
	case Other     = 0x06
}

//MARK: - 0xFC HRTask 定时任务
///定时任务
class HRTask: HRDevice{
	/**任务id*/
	var id: Byte       = 0
	///定时任务图标id
	var icon: Byte       = 0
	///定时任务执行时间
	var time: HRTaskTime = HRTaskTime()
	///定时任务重复执行标志。某位置1表示对应的星期几重复执行，如第0位置1表示周一重复执行，0x00表示不重复执行。
	var repeation: Byte     = 0
	///定时任务有效标志： 0x01表示有效，0x00表示无效
	var enable: Bool     = false
	///定时任务设备数
	var devCount: Byte   = 0
	///定时任务中设备信息
	var devsInTask: [HRDevsInTask] = [HRDevsInTask]()
	
	required init() {
		super.init()
		devType = HRDeviceType.Task.rawValue
	}
	
	override func copyWithZone(zone: NSZone) -> AnyObject {
		let theCopyTask = super.copyWithZone(zone) as! HRTask
        theCopyTask.id   = self.id
        theCopyTask.icon = self.icon
        theCopyTask.time = self.time
		theCopyTask.repeation = self.repeation
		theCopyTask.enable = self.enable
		theCopyTask.devCount = self.devCount
		for dev in self.devsInTask {
			theCopyTask.devsInTask.append(dev.copy() as! HRDevsInTask)
		}
		return theCopyTask
	}
	
	/// 构造一个定时任务对象
	///
	/// - parameter hostAddr: 主机地址
	/// - parameter dataFrame: 数据域
	/// - returns: 如果失败则返回nil，如果成功则返回定时任务对象和从该数组中读取的长度，方便切除。
	class func initWithDataFrame(hostAddr: UInt32, dataFrame frame: [Byte]) -> (HRTask, Int){
		/*****************
		元素        长度       名称
		0           1       设备类型
		1-4         4       设备地址
		5           1       任务图标
		6-37        32      任务名称
		38-40       3       任务执行的时间，时分秒各占1字节
		41          1       任务重复执行标志
		42          1       任务有效标志
		43          1       任务中设备数量
		44-         N       任务中设备信息
		
		任务中的设备信息：
		0-3         4       所属主机
		4           1       绑定类型
		5-8         4       绑定地址
		9-12        4       绑定的操作
		13-16       4       延时码
		******************/
		let task = HRTask()
        task.hostAddr  = hostAddr
        task.devType   = HRDeviceType.Task.rawValue
        task.id        = frame[1]
		task.devAddr   = UInt32(task.id)
        task.icon      = frame[5]
        if let name    = ContentHelper.encodeGbkData(Array(frame[6...37])) {
        task.name      = name
		}
        task.time      = HRTaskTime(hour: frame[38], min: frame[39], sec: frame[40])
        task.repeation = frame[41]
        task.enable    = frame[42] == 0x01 ? true : false
        task.devCount  = frame[43]
        var count      = 44
		if task.devCount > 0 {
			for _ in 0..<task.devCount {
				let dev = HRDevsInTask()
				dev.hostAddr  = UInt32(fourBytes: Array(frame[count+0...count+3]))
				dev.devType   = frame[count+4]
				dev.devAddr   = UInt32(fourBytes: Array(frame[count+5...count+8]))
				dev.actBinds  = Array(frame[count+9...count+12])
				dev.delayCode = Array(frame[count+13...count+16])
				task.devsInTask.append(dev)
				count += 17
			}
		}
		Log.debug("定时任务: 名称：\(task.name), \t设备数量：\(task.devCount)")
		return (task, count)
	}
}

///定时任务执行时间
struct HRTaskTime {
	var hour : Byte = 0
	var min  : Byte = 0
	var sec  : Byte = 0
	
	init(){}
	
	init(hour: Byte, min: Byte, sec: Byte) {
		self.hour = hour
		self.min  = min
		self.sec  = sec
	}
	
	func toString() -> String {
		let hourStr = hour < 10 ? "0\(hour)" : "\(hour)"
		let minStr  = min < 10 ? "0\(min)" : "\(min)"
		//        let secStr  = sec < 10 ? "0\(sec)" : "\(sec)"
		
		return "\(hourStr):\(minStr)"
	}
	
	func date() -> NSDate? {
		let formatter = NSDateFormatter()
		//转换成东八区北京时间，主机的时间为0时区
		formatter.timeZone = NSTimeZone(forSecondsFromGMT: 8)
		formatter.dateFormat = "H:m:s"
		
		return formatter.dateFromString("\(hour):\(min):\(sec)")
	}
}

typealias HRDevsInTask = HRDevInScene
/////定时任务中设备信息
//struct HRDevsInTask {
//    ///所属主机地址
//    var hostAddr: UInt32   = 0
//    ///绑定类型
//    var bindType: Byte     = 0
//    ///绑定地址
//    var bindAddr: UInt32   = 0
//    ///绑定的操作。占4个字节，每一字节表示一路继电器0表示关，1表示开，2取反，>=3无效。
//    var bindAction: [Byte] = [Byte]()
//    ///延时码(注意单位是100ms，即1/10秒！！！)。占4个字节，每一字节表示一路继电器，无该值填0xff。
//    var delay: [Byte]      = [Byte]()
//}

//MARK: - 0xFD HRScene 情景
/**情景类(0xFD)，用来描述一个情景*/
class HRScene: HRDevice {
	/**情景ID，占4个字节*/
	var id: Byte       = 0
	/**情景图标，占1个字节*/
	var icon: Byte     = 1
	/**情景中的设备数量，占1个字节*/
	var devCount: Byte = 0
	/**情景的设备信息，包含多个设备。DevInSence是用于在Scene中描述设备的结构体*/
	var devices: [HRDevInScene] = [HRDevInScene]()
	
	required init() {
		super.init()
		self.devType = HRDeviceType.Scene.rawValue
	}
	
	override func copyWithZone(zone: NSZone) -> AnyObject {
		let theCopyScene = super.copyWithZone(zone) as! HRScene
		theCopyScene.id   = self.id
		theCopyScene.icon = self.icon
		theCopyScene.devCount = self.devCount
		for dev in self.devices {
			theCopyScene.devices.append(dev.copy() as! HRDevInScene)
		}
		return theCopyScene
	}
	
	/// 构造一个情景对象
	///
	/// - parameter cmdCode: 命令控制码,这里可以是HRCommand枚举的"CreateOrModifyScene"或"QueryDeviceInfo"两者之一。如果是其他则会返回nil。
	/// - parameter hostAddr: 主机地址
	/// - parameter dataFrame: 数据域
	/// - returns: 如果失败则返回nil，如果成功则返回情景对象和从该数组中读取的长度，方便切除。
	class func initWithDataFrame(cmdCode: Byte, hostAddr: UInt32, dataFrame: [Byte]) -> (HRScene?, Int?){
		if cmdCode != HRCommand.CreateOrModifyScene.rawValue && cmdCode != HRCommand.QueryDeviceInfo.rawValue {
			return (nil, nil)
		}
		var frame = dataFrame
		var count = 0
		//0（1B）是情景id，如果cmdCode(控制码)是QueryDeviceInfo，则情景id有4个字节，应该去掉其他3个来保证后面数据位置一致。
		//1（1B）是情景图标id
		//2-33（32B）是设备名称
		//34(1B)是情景中的设备数量
		if cmdCode == HRCommand.QueryDeviceInfo.rawValue {
			frame.removeAtIndex(0)
			count += 1
		}
		let scene = HRScene()
		scene.hostAddr = hostAddr
		scene.devType  = HRDeviceType.Scene.rawValue
		scene.id       = frame[0]
		scene.devAddr  = UInt32(frame[0])
		if cmdCode == HRCommand.QueryDeviceInfo.rawValue{
			frame.removeRange(1..<4)
			count += 3
		}
		scene.icon     = frame[1]
		if let name = ContentHelper.encodeGbkData(Array(frame[2...33])) {
			scene.name = name
		}
		scene.devCount = frame[34]
		count += 35
		if scene.devCount > 0 {
			for i in 0...scene.devCount-1 {
				//情景中的设备：
				// (0-3) 设备或情景所属主机，占4个字节
				//（4）   设备类型，占1个字节
				//（5-8） 设备地址，占4个字节
				//（9-12）设备绑定的操作，占4个字节
				//（13-?）延时码，如果cmdCode是CreateOrModifyScene则该字段占1个字节；如果是QueryDeviceInfo则该字段占4个字节。
				let dev = HRDevInScene()
				let devBase = 35 + 14 * Int(i)
				dev.hostAddr  = UInt32(fourBytes: Array(frame[devBase+0...devBase+3]))
				dev.devType   = frame[devBase+4]
				dev.devAddr   = UInt32(fourBytes: Array(frame[devBase+5...devBase+8]))
				dev.actBinds  = Array(frame[devBase+9...devBase+12])
				if cmdCode == HRCommand.QueryDeviceInfo.rawValue {
					dev.delayCode = Array(frame[devBase+13...devBase+16])
					frame.removeRange(devBase+14..<devBase+17)
					count += 3
				} else {
					dev.delayCode = [frame[devBase+13], 0, 0, 0]
				}
				count += 14
				scene.devices.append(dev)
			}
		}
		Log.debug("情景: 名称：\(scene.name),\t设备数量：\(scene.devCount)")
		return (scene, count)
	}
	
	func remove() {
		HR8000Service.shareInstance().removeScene(self)
	}
	
	func start(result: (NSError?)->Void) {
		HR8000Service.shareInstance().startScene(self, callback: result)
	}
	
	///保存该情景到主机中，或者说编辑情景。
	///
	///- parameter result: 结果回调
	func saveToRemote(result: (NSError?)->Void){
		HR8000Service.shareInstance().createOrModifyScene(self, isCreate: false, result: result)
	}
	
	///创建该情景，并保存到主机中。
	///
	///- parameter result: 结果回调
	func createToRemote(result: (NSError?)->Void){
		HR8000Service.shareInstance().createOrModifyScene(self, isCreate: true, result: result)
	}
}

func ==(scene1: HRScene, scene2: HRScene) -> Bool {
	if  scene1.id == scene2.id &&
		scene1.icon == scene2.icon &&
		scene1.name == scene2.name {
			return true
	}
	return false
}

/**情景中的设备描述*/
class HRDevInScene: HRDevice {
	/**设备绑定的操作，占4个字节*/
	var actBinds: [Byte] = [0xFF, 0xFF, 0xFF, 0xFF]
	/**延时码，占4个字节*/
	var delayCode: [Byte] = [0, 0, 0, 0]
	
	/***/
	var device: HRDevice?
	
	override func copyWithZone(zone: NSZone) -> AnyObject {
		let dis = super.copyWithZone(zone) as! HRDevInScene
        dis.devType   = self.devType
        dis.name      = self.name
        dis.devAddr   = self.devAddr
        dis.hostAddr  = self.hostAddr
        dis.actBinds  = self.actBinds
        dis.delayCode = self.delayCode
        dis.device    = self.device
		
		return dis
	}
	
	//红外码描述
	var infraredDecription: String {
		let key = actBinds[0]
		guard let appDevType = (device as? HRApplianceApplyDev)?.appDevType else {
			return "设备"
		}
		if appDevType == HRAppDeviceType.AirCtrl.rawValue {
			switch key {
			case HRAirKeyCode.PowerOff.rawValue:
				return "空调: 关闭电源"
			case HRAirKeyCode.PowerOn.rawValue:
				return "空调: 打开电源"
			case HRAirKeyCode.ModeAuto.rawValue:
				return "空调: 自动模式"
			case HRAirKeyCode.ModeCooling.rawValue:
				return "空调: 制冷模式"
			case HRAirKeyCode.ModeDrying.rawValue:
				return "空调: 除湿模式"
			case HRAirKeyCode.ModeVenting.rawValue:
				return "空调: 送风模式"
			case HRAirKeyCode.ModeHeating.rawValue:
				return "空调: 制热模式"
			case HRAirKeyCode.SwingAuto.rawValue:
				return "空调: 自动摆风"
			case HRAirKeyCode.SwingHand.rawValue:
				return "空调: 手动摆风"
			case HRAirKeyCode.SpeedAuto.rawValue:
				return "空调: 自动风速"
			case HRAirKeyCode.SpeedLow.rawValue:
				return "空调: 一级风速"
			case HRAirKeyCode.SpeedMiddle.rawValue:
				return "空调: 二级风速"
			case HRAirKeyCode.SpeedHigh.rawValue:
				return "空调: 三级风速"
			case HRAirKeyCode.Celsius16.rawValue...HRAirKeyCode.Celsius30.rawValue:
				let temp = key - HRAirKeyCode.Celsius16.rawValue + 16
				return "空调: \(temp)℃"
			default:
				return "空调: (无效按键)"
			}
		} else if appDevType == HRAppDeviceType.TV.rawValue {
			switch key {
			case HRTVKeyCode.Mute.rawValue:
				return "遥控器: 静音"
			case HRTVKeyCode.StandBy.rawValue:
				return "遥控器: 待机"
			case HRTVKeyCode.Menu.rawValue:
				return "遥控器: 菜单"
			case HRTVKeyCode.Return.rawValue:
				return "遥控器: 返回"
			case HRTVKeyCode.SingleAndDouble.rawValue:
				return "遥控器: -/--"
			case HRTVKeyCode.VolumeAdd.rawValue:
				return "遥控器: 音量+"
			case HRTVKeyCode.VolumeSub.rawValue:
				return "遥控器: 音量-"
			case HRTVKeyCode.ChannelAdd.rawValue:
				return "遥控器: 频道+"
			case HRTVKeyCode.ChannelSub.rawValue:
				return "遥控器: 频道-"
			case HRTVKeyCode.DpadUp.rawValue:
				return "遥控器: 方向上"
			case HRTVKeyCode.DpadDown.rawValue:
				return "遥控器: 方向下"
			case HRTVKeyCode.DpadLeft.rawValue:
				return "遥控器: 方向左"
			case HRTVKeyCode.DpadRight.rawValue:
				return "遥控器: 方向右"
			case HRTVKeyCode.DpadOk.rawValue:
				return "遥控器: OK"
			case HRTVKeyCode.NumZero.rawValue...HRTVKeyCode.NumNine.rawValue:
				return "遥控器: 数字\(key)"
			default:
				return "遥控器: (无效按键)"
			}
		}
		return "按键值：\(key)"
	}

	var rgbDescription: String? {
		if actBinds.count < 4 { return nil }
		let mode = actBinds[0]
		switch mode {
		case 0x02: return "照明模式"
			
		case 0x03: return "起夜模式"
			
		case 0x04 where actBinds[1] == 1: return "渐变模式（慢）"
		case 0x04 where actBinds[1] == 2: return "渐变模式（中）"
		case 0x04 where actBinds[1] == 3: return "渐变模式（快）"
			
		case 0x05 where actBinds[1] == 1: return "跳变模式（慢）"
		case 0x05 where actBinds[1] == 2: return "跳变模式（中）"
		case 0x05 where actBinds[1] == 3: return "跳变模式（快）"
			
		case 0x06 where actBinds[1] == 1: return "彩虹模式（慢）"
		case 0x06 where actBinds[1] == 2: return "彩虹模式（中）"
		case 0x06 where actBinds[1] == 3: return "彩虹模式（快）"
			
		default: return nil
		}
	}
}

