//
//  ContentHelper.swift
//  huarui
//
//  Created by sswukang on 15/1/13.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import Foundation

//MARK: - 本地变量

///本地IP
//UInt32 32位无符号整型
var hrLocalIPAddr: UInt32 = 0x00

/**帧序号的D7位：0表示主动发起通信，1表示反馈, 所以只能使用7位，最大值不超过128*/
enum HRFrameSn: Byte {
    ///登陆
    case LOGIN       = 10
    ///查询设备
    case QueryDevice = 11
    ///控制继电器控制盒、智能开关、智能插座
    case RelayBase   = 12
    ///删除情景
    case DeleteScene = 13
    ///启动情景
    case StartScene  = 14
    ///查询光照、可燃气、温湿度、湿敏等传感器的值
    case QuerySensorValue = 15
	///控制电机类型，如窗帘，开窗器
	case CtrlMotor	 = 16
	///红外转发
	case InfraredTransmit = 17
	///控制机械手
	case CtrlManipulator = 18
	///智能床
	case SmartBed		= 19
	///创建情景
	case CreateNewScene = 20
	///绑定继电器负载
	case BindLoadsToRelay = 21
	///删除设备
	case DeleteDevices = 22
}

//MARK: - 命令控制码
/**命令控制码*/
enum HRCommand: Byte{
    /**设备初始化，恢复出厂设置*/
    case ResetDevice            = 0x00
    /**确认接收成功*/
    case ACK                    = 0x01
    /**设备主动上传状态*/
    case CommitDeviceState      = 0x02
    /**设备信息查询：设备地址、设备类型、信道、版本*/
    case QueryDeviceInfo        = 0x03
    /**注册设备*/
    case RegisterDevice         = 0x04
    /**删除设备*/
    case DeleteDevice           = 0x05
    /**情景面板绑定*/
    case ScenePanelBinding      = 0x06
    /**情景面板解绑*/
    case ScenePanelUnbinding    = 0x07
    /**创建或修改情景*/
    case CreateOrModifyScene    = 0x08
    /**删除情景*/
    case DeleteScene            = 0x09
    /**设置系统参数：如信道、RF地址、IP*/
    case SetSystemParameter     = 0x0A
    /**查询系统参数：如信道、RF地址、IP*/
    case QuerySystemParameter   = 0x0B
    /**编辑设备用户信息：如设备名称、位置*/
    case EditDevUserInfo        = 0x0C
    /**登陆主机*/
    case Longin                 = 0x0D
    /**远程注册主机*/
    case RemoteRegisterHost     = 0x0E
    /**远程删除主机*/
    case RemoteDeleteHost       = 0x0F
    /**用户管理*/
    case UserManage             = 0x10
    /**继电器绑定负载*/
    case BindLoadToRelay        = 0x11
    /**添加/编辑应用设备*/
    case AddOrEditApplyDev      = 0x12
    /**删除应用设备*/
    case DeleteApplyDev         = 0x13
    /**红外学习*/
    case InfraredLearning       = 0x14
    /**设置门锁密码*/
    case SetDoorLockPassword    = 0x15
    /**安防联动绑定*/
    case SecurityBindState      = 0x16
    /**主机登陆到服务器*/
    case HostLoginToServer      = 0x17
    /**心跳*/
    case KeepAlive              = 0x18
    /**创建/编辑楼层*/
    case CreateOrEditFloorInfo  = 0x19
    /**删除楼层*/
    case DeleteFloor            = 0x1A
    /**从机登陆到主主机*/
    case SlaveLoginToHost       = 0x1B
    /**主机从机信息同步*/
    case HostAndSlaveSync       = 0x1C
    /**远程升级*/
    case RemoteUpgrade          = 0x1D
    /**控制智能开关的继电器(带延时)*/
    case OperateSwitchPanel     = 0x1E
    /**启动情景*/
    case StartScene             = 0x1F
    /**控制继电器控制盒*/
    case OperateRelayCtrlBox    = 0x20
    /**控制智能插座*/
    case OprateSocketPanel      = 0x21
    /**控制RGB灯*/
    case OprateRGBLamp          = 0x22
    /**蓝牙遥控制器*/
    case BluetoothCtrl          = 0x23
    /**红外转发*/
    case InfraredTransmit       = 0x24
    /**窗帘控制器*/
    case MotorCtrl              = 0x25
    /**红外入侵探测器*/
    case InfraredDetector       = 0x26
    /**智能门磁*/
    case DoorMagCard            = 0x27
    /**智能门锁*/
    case DoorLock               = 0x28
    /**智能门铃*/
    case DoorBell               = 0x29
    /**查询光照/燃气/温湿度空气/湿敏探测器*/
    case QuerySensorValue       = 0x2A
    ///校准光照探测器（0x2b）
    case AdjustSolarSensor      = 0x2B
    ///设置光照/燃气/温湿度空气探测器联动动作值（0x2c）
    case SetSensorBindValue     = 0x2C
    ///光照/燃气/温湿度空气/湿敏探测器联动绑定（0x2d）
    case SensorBindDevice       = 0x2D
    /**机械手*/
	case Manipulator            = 0x2E
	///智能床, 0x30
	case SmartBed               = 0x30
    
    
    
	///控制单火开关, 0x32
	case LiveWireSwitch         = 0x32
	///升级智能主机固件
	case UpdateFirmware         = 0x33
    //斌 门锁相关 这里将要添加一个高顿锁的控制码 0x34

    case GaoDunDoor             = 0x34
    ///设置/编辑定时任务（0x5e）
    case SetOrEditAlarmTask     = 0x5E
    ///删除定时任务（0x5f）
    case DeleteAlarmTask        = 0x5F
    ///添加/编辑摄像头（0x5c）
    case AddOrEditCamera        = 0x5C
    ///删除摄像头（0x5d）
    case DeleteCamera           = 0x5D
    /**APP广播查找主机*/
    case BraodcastSearchHost    = 0x5A
    /**未知命令*/
    case Unknow                 = 0xFF
}

//MARK: - 设备类型
/**设备类型*/
enum HRDeviceType: Byte {
    /**智能控制主机,0x00*/
    case Master                 = 0x00
    /**智能开关面板,0x01*/
    case SwitchPanel            = 0x01
    /**情景面板,0x02*/
    case ScenePanel             = 0x02
    /**智能插座,0x03*/
    case SocketPanel            = 0x03
    /**继电器控制盒,0x04*/
    case RelayControlBox        = 0x04
    /**RGB灯,0x05*/
    case RGBLamp                = 0x05
    /**蓝牙遥控器,0x06*/
    case BluetoothControlUnit   = 0x06
    /**红外转发器,0x07*/
    case InfraredTransmitUnit   = 0x07
    /**窗帘控制器,0x08*/
    case CurtainControlUnit     = 0x08
    /**红外入侵探测器,0x09*/
    case InfraredDetectorUnit   = 0x09
    /**智能门磁,0x0a*/
    case DoorMagCard            = 0x0a
    /**智能门锁,0x0b*/
    case DoorLock               = 0x0b
    /**智能门铃,0x0c*/
    case DoorBell               = 0x0c
    /**光照传感器,0x0d*/
    case SolarSensor            = 0x0d
    /**可燃气探测器,0x0e*/
    case GasSensor              = 0x0e
    /**温湿度空气质量探测器,0x0f*/
    case AirQualitySensor       = 0x0f
    /**湿敏探测器,0x10*/
    case HumiditySensor         = 0x10
    /**机械手,0x11*/
    case Manipulator            = 0x11
    /**智能床,0x12*/
    case SmartBed               = 0x12
	/// 调光灯, 0x13
	case AdjustableLight		= 0x13
	/// 单火开关 (Live Wire Switch), 0x14
	case LiveWireSwitch			= 0x14
    
    //斌 门锁相关 在这里添加一个 设备类型 0x15 还是 0x34 高盾门锁
    
    case GaoDunDoor             = 0x15
    
    //...
    /**用户信息,0xF8*/
    case UserInfo               = 0xF8
    /**楼层信息,0xF9*/
    case FloorInfo              = 0xF9
    /**应用设备。如用户的电视、空调、机顶盒、摄像头,0xFA*/
    case ApplyDevice            = 0xFA
    /**服务器,0xFB*/
    case Server                 = 0xFB
    /**定时任务0xFC*/
    case Task                   = 0xFC
    /**情景,0xFD*/
    case Scene                  = 0xFD
    /**App应用程序,0xFE*/
    case Application            = 0xFE
    /**广播专用，亦指所有设备类型,0xFF*/
    case Braodcast              = 0xFF
	
	///设备类型的文字描述
	var description: String {
		return ContentHelper.deviceNameString(self.rawValue)
	}
	
	///获得所有类型，返回到一个数组中
	static var allTypes: [HRDeviceType] {
		var types = [HRDeviceType]()
        
        //斌注释  装逼用法 意思其实就是从第 0 个到 第254 个
		for i in Byte(0).stride(to: Byte(255), by: 1) {
			if let type = HRDeviceType(rawValue: i) {
				types.append(type)
			}
		}
		return types
	}
	
	/**
	获取所有继电器类型的type
	
	- returns: types
	*/
	static func relayTypes() -> [Byte] {
		return [
			HRDeviceType.RelayControlBox.rawValue,
			HRDeviceType.SwitchPanel.rawValue,
			HRDeviceType.SocketPanel.rawValue,
			HRDeviceType.LiveWireSwitch.rawValue
		]
	}
	
	///电机类型
	static func motorTypes() -> [Byte] {
		return [
			HRDeviceType.CurtainControlUnit.rawValue,
			HRDeviceType.Manipulator.rawValue
		]
	}
	
	///传感器类型
	static func sensorTypes() -> [Byte] {
		return [
			HRDeviceType.GasSensor.rawValue,
			HRDeviceType.SolarSensor.rawValue,
			HRDeviceType.AirQualitySensor.rawValue,
			HRDeviceType.HumiditySensor.rawValue
		]
	}
}

enum HRHostPermission : Byte{
	///用户名或密码错误
	case AuthDenied          = 0x00
	///低级权限只能查看控制
	case Low                 = 0x01
	///高级权限可以添加、删除、修改等操作
	case High                = 0x02
	///超级权限
	case Super               = 0x03
	///主机没有注册到服务器上
	case HostNotRegistration = 0x04
	///主机不在线
	case HostOffline         = 0x05
}

// MARK: - 协议

///网络传输帧，即带有0xAA开头，0x55结尾的完整帧，详细参考协议
class HRFrame: NSObject {
    ///帧长度
    var lenght: UInt16 = 0
    ///目标地址
    var destAddr : UInt32 = 0
    ///源地址
    var srcAddr  : UInt32 = 0
    ///传输原因，传输方向，0x01表示由智能主机发起，0x03表示由APP发起
    var direction: Byte   = 0x03
    ///命令序号
    var sn : Byte         = 0
    ///控制码
    var command : Byte    = 0
    ///数据域
    var data : [Byte]     = Array()
    ///校验码
    var checksum :Byte    = 0
    
// 计算属性
    ///是否是异常帧，如果是异常帧则返回异常信息，否则返回nil
    var exception: NSError? {
        get {
            if (command >> 7) != 0x01 { //没有异常
                return nil
            }
            if data.count == 0 {
                return NSError(domain: "未知异常", code: HRErrorCode.FrameErrorUnknow.rawValue, userInfo: nil)
            }
            var msg: String
            switch data[0] {
            case 0x00:
                msg = "本次命令请求正常响应"
            case 0x01:
                msg = "帧长度不正确"
            case 0x02:
                msg = "帧校验不正确"
            case 0x03:
                msg = "目标主机地址不存在"
            case 0x04:
                msg = "源地址不存在"
            case 0x05:
                msg = "设备类型未定义"
            case 0x06:
                msg = "控制码未定义"
            case 0x07:
                msg = "权限不够"
            case 0x08:
                msg = "数据内容非法"
            case 0x09:
                msg = "设备响应超时"
            case 0x0a:
                msg = "其它错误"
            case 0x0b:
                msg = "传输原因错误"
            case 0x0c:
                msg = "操作正在进行，操作拒绝"
            case 0x0d:
                msg = "主机名字重复"
            default:
                msg = "其他异常"
            }
            return NSError(domain: msg, code: HRErrorCode.FrameError.rawValue + Int(data[0]), userInfo: nil)
        }
    }
	
	/// 返回控制码，该控制码已忽略异常，即去除第7位。
	var commandIgnoreException: Byte {
		return command & 0b0111_1111
	}
	
	//是否是异常帧
	var isExceptionFrame: Bool {
		return command & 0b1000_0000 != 0
	}

//方法
		
    override init() {}
	
	/**
	HRFrame
	- parameter destAddr: 目标地址
	- parameter sn:       命令序号，<128
	- parameter command:  控制码
	- parameter data:     数据域
	
	- returns: 返回HRFrame对象
	*/
    init(destAddr: UInt32, sn: Byte, command: Byte, data: [Byte]){
        self.destAddr = destAddr
        self.srcAddr  = hrLocalIPAddr
        self.sn = sn
        self.command  = command
        self.data = data
    }
	
	/**
	HRFrame
	- parameter destAddr: 目标地址
	- parameter sn:       命令序号，<128
	- parameter command:  控制码
	- parameter data:     数据域
	
	- returns: 返回HRFrame对象
	*/
    convenience init(destAddr: UInt32, sn: Byte, command: HRCommand, data: [Byte]){
        self.init(destAddr: destAddr, sn: sn, command: command.rawValue, data: data)
    }
	
	/**
	HRFrame
	- parameter destAddr: 目标地址
	- parameter sn:       命令序号，<128
	- parameter command:  控制码
	- parameter data:     数据域
	
	- returns: 返回HRFrame对象
	*/
    convenience init(destAddr: UInt32, sn: HRFrameSn, command: HRCommand, data: [Byte]) {
        self.init(destAddr: destAddr, sn: sn.rawValue, command: command.rawValue, data: data)
    }
    
    
    class func initWithData(data: [Byte]) -> HRFrame? {
        //读帧头
        if data[0] != 0xAA {
           return nil
        }
        //读帧长度
        if data.count < 3 {
            return nil
        }
        let frameLen = Int(data[1]) + Int(data[2]) << 8
        
        if frameLen + 5 > DATA_FRAME_MAX{    //超过最大长度，说明读错了
            return nil
        }
        //读结束符
        if data.count < 3 + frameLen + 2{
            return nil
        }
        let endByte = data[frameLen+3+1]
        if endByte != 0x55{
            return nil
        }
        //data就是符合以0xAA开头，0x55结尾等条件的协议帧
        let frame = HRFrame()
        frame.lenght = UInt16(frameLen)
        frame.destAddr = UInt32(fourBytes: Array(data[3...6]))
        frame.srcAddr = UInt32(fourBytes: Array(data[7...10]))
        frame.direction = data[11]
        frame.sn = data[12] & 0b0111_1111
        frame.command = data[13]
		if data.count-3 >= 14 {
			//没有数据域，这种情况出现在确认帧返回时，就会有可能没有数据域
			frame.data = Array(data[14...data.count-3])
		} else {
			frame.data = [Byte]()
		}
        frame.checksum = data[data.count-2]
        return frame
    }
    
    ///转换成网络传输帧，即带有0xAA开头，0x55结尾的完整帧，详细参考协议
    ///
    ///- returns: 如果帧长度超过最大值，则返回nil，其他情况返回非nil数据
    func toTransmitFrame() -> [Byte]?{
        let len = 3 + (data.count + 11) + 1 + 1
        if len > DATA_FRAME_MAX {
            Log.warn("数据包超过最大长度, 最大值为: \(DATA_FRAME_MAX) bytes!!!")
            return nil
        }
        var buffer: [Byte] = [Byte]()
        
        //帧起始符
        buffer.append(0xAA)
        //帧长度低8位
        buffer.append(Byte((data.count + 11) & 0xFF))
        //帧长度高8位
        buffer.append(Byte(UInt32((data.count + 11)) >> 8))
        //目标地址（主机地址）
        buffer += destAddr.getBytes()[0...3]
        //App地址（手机地址）
        buffer += srcAddr.getBytes()[0...3]
        //传输原因
        buffer.append(direction)   //App发起
        //帧序号
        buffer.append(sn)
        //控制码
        buffer.append(command)
        //数据域
        buffer += data
        //校验码
        var ccb: Byte = 0
        for i in 3..<3+11+data.count {
            ccb = ccb &+ buffer[i]
        }
        buffer.append(ccb)
        //帧结束符
        buffer.append(0x55)
        
        
        return buffer
    }
    
    //转换成字符串描述
    func toString() -> String{
        var str = "字节\t 描述\t\t\t  值\n"
        str += "1\t帧起始符\t\t0xAA\n"
        let lenStr = NSString(format: "0x%X", lenght)
        str += "2\t帧长度\t\t\(lenStr)\n"
        str += "4\t目标地址\t\t\(destAddr.getBytes())\n"
        str += "4\t源地址\t\t\(srcAddr.getBytes())\n"
        str += "1\t传输原因\t\t\(direction)  (1表示主机发起，3表示APP发起)\n"
        str += "1\t命令序号\t\t\(sn)\n"
        let cmdStr = NSString(format: "0x%X", command)
        str += "1\t控制码\t\t\(cmdStr)\n"
        str += "\(data.count)\t数据域\t\t\(data)\n"
        str += "1\t校验码\t\t\(checksum)\n"
        str += "1\t帧结束符\t\t0x55\n"
        return str
    }
}



//////////////////////////////////////////////////////////////////////////
//MARK: - 扩展方法

/**扩展UInt32的两个属性方法*/
extension UInt32{
    /**返回一个Byte数组，数组元素低位是UInt32值的低8位，即UInt32值由低位到高位顺序对应数组由低到高顺序*/
    func getBytes() -> [Byte]{
        let B0:Byte = Byte((UInt32(self) &       0xFF))
        let B1:Byte = Byte((UInt32(self) &     0xFF00) >> 8)
        let B2:Byte = Byte((UInt32(self) &   0xFF0000) >> 16)
        let B3:Byte = Byte((UInt32(self) & 0xFF000000) >> 24)
        
        return [B0, B1, B2, B3]
    }
    /**初始化方法，使用Byte数组赋值，与getBytes相反，注意：Byte数组应该有且只有4个元素*/
    init(fourBytes bytes: [Byte]) {
        var temp:UInt32 = 0
        if bytes.count <= 4 {
            for i in 0...bytes.count-1 {
                temp += UInt32(bytes[i]) << UInt32(8 * i)
            }
        } else {
            for i in 0...3 {
                temp += UInt32(bytes[i]) << UInt32(8 * i)
            }
        }
        self.init(temp)
    }
}

/**扩展UInt16的两个属性方法*/
extension UInt16{
    /**返回一个Byte数组，数组元素低位是UInt16值的低8位，即UInt16值由低位到高位顺序对应数组由低到高顺序*/
    func getBytes() -> [Byte]{
        let B0:Byte = Byte((UInt16(self) &       0xFF))
        let B1:Byte = Byte((UInt16(self) &     0xFF00) >> 8)
        
        return [B0, B1]
    }
    /**初始化方法，使用Byte数组赋值，与getBytes相反，注意：Byte数组应该有且只有2个元素*/
    init(twoBytes bytes: [Byte]) {
        var temp:UInt16 = UInt16(bytes[0])
        temp += UInt16(bytes[1]) << 8
        
        self.init(temp)
    }
}

extension String {
	///判断字符串是否符合设备命名规则。设备名只能包含字母、数字和中文字符、下划线或空格
	///
	///- returns: 如果符合则返回true，否则返回false
	var isDeviceName: Bool {
		do {
			let expression = try NSRegularExpression(pattern: "^[A-Za-z0-9_\\u0020\\u4E00-\\u9FA5]+$", options: .CaseInsensitive)
			
			let matchs = expression.matchesInString(self, options: [], range: NSMakeRange(0, self.characters.count))
			
			return matchs.count > 0
		} catch _ {
			return false
		}
	}
	
	///判断字符串是否符合用户名命名规则。用户名只能包含字母、数字和中文字符或下划线
	///
	///- returns: 如果符合则返回true，否则返回false
	var isUserName: Bool {
		do {
			let expression = try NSRegularExpression(pattern: "^[A-Za-z0-9_\\u4E00-\\u9FA5]+$", options: .CaseInsensitive)
			
			let matchs = expression.matchesInString(self, options: [], range: NSMakeRange(0, self.characters.count))
			
			return matchs.count > 0
		} catch _ {
			return false
		}
	}
	
    
    //只有密码长度为6的密码才能修改成功  斌注释
	var isPassword: Bool {
		//return self.characters.count >= 6 && self.characters.count <= 16
        
        return self.characters.count == 6
	}
	
	///获取字符串的gbk解码的字节数组
	///
	/// - parameter keepLen: 保持返回数组的长度
	/// - returns: 返回一个字节数组，如果keepLen不为nil，则返回数组的长度为keepLen，keepLen为nil则返回字符串的实际长度
	func getBytesUsingGBK(keepLen: Int? = nil) -> [Byte] {
		//0x0632代表是GBK编码
		let enc = CFStringConvertEncodingToNSStringEncoding(0x0632)
		let data = self.dataUsingEncoding(enc, allowLossyConversion: false)
		var bytes  = [Byte]()
		var tmp:Byte = 0
		for i in 0..<data!.length {
			data!.getBytes(&tmp, range: NSRange(location: i, length: 1))
			bytes.append(tmp)
		}
		if let len = keepLen {
			bytes += [Byte](count: len, repeatedValue: 0)
			return Array(bytes[0..<len])
		}
		return bytes
	}
}

//MARK: - ContentHelper

/**
* 本类用于包装发送的帧或解析接收的帧
*/
class ContentHelper{
	
    /**从NSData对象中提取Byte数组*/
    class func NSdataToBytes(data: NSData!) -> [Byte]? {
        let len      = data.length
        //[Byte]是一个数组
        var retData  = [Byte]()
        var tmp:Byte = 0
        
        for i in 0..<len {
            data.getBytes(&tmp, range: NSRange(location: i, length: 1))
            retData.append(tmp)
        }
        return retData
    }
    
    /**
    * 将字符串形式的IP地址转换成为Byte类型的数组
    */
    class func hostStringToArry(ipStr: String) -> [Byte]? {
        var ipAddr = [Byte]()
		
        //使用正则表达式提取IP地址
        do {
			let expression = try NSRegularExpression(pattern: "\\d{1,3}", options: .CaseInsensitive)
			let matchs:[NSTextCheckingResult] = expression.matchesInString(ipStr, options: [], range: NSMakeRange(0, ipStr.characters.count))
			if matchs.count < 4 {
				return nil
			}
			for item in matchs {
				let tmp = (ipStr as NSString).substringWithRange(item.range)
				ipAddr.append(Byte(Int(tmp)!))
			}
			return ipAddr
        } catch _ {
            return nil
        }
    }
    
    ///判断字符串是否符合设备命名规则。设备名只能是字母、数字和中文字符或三种的组合
    ///
    ///- parameter test: 要测试的字符串
    ///- returns: 如果符合则返回true，否则返回false
    class func isDeviceName(test: String) -> Bool {
		
		do {
			let expression = try NSRegularExpression(pattern: "^[A-Za-z0-9\\u0020\\u4E00-\\u9FA5]+$", options: .CaseInsensitive)
        
			let matchs = expression.matchesInString(test, options: [], range: NSMakeRange(0, test.characters.count))
			return matchs.count > 0
		} catch _ as NSError {
			return false
		}
    }
	
	/**
	数据转字符串，使用GBK编码
	
	- parameter data: byte数组
	- returns: 字符串
	*/
    class func encodeGbkData(data: [Byte]) -> String?{
        //0x0632代表是GBK编码
        let enc = CFStringConvertEncodingToNSStringEncoding(0x0632)
        
        let nsstr = NSString(bytes: data, length: data.count, encoding: enc)
        if nsstr == nil {
            return nil
        }
        let str = String(nsstr!)
        //删除后面的\u0000
        var i = 0
        for char in str.characters {
            if char == Character("\0") {
                
                //str.startIndex.advancedBy(i) 是获得字符串str第i个元素的字符
                let index = str.startIndex.advancedBy(i)
                return str.substringToIndex(index)
            }
            i += 1
        }
        return str
    }
	
	/**
	字符串转字节数组，使用GBK编码
	- parameter str: 字符串
	- returns: 字节数组
	*/
    class func decodeGbkData(str: String!) -> [Byte]{
        //0x0632代表是GBK编码
        let enc = CFStringConvertEncodingToNSStringEncoding(0x0632)
        let data = str.dataUsingEncoding(enc, allowLossyConversion: false)
        return NSdataToBytes(data)!
    }
	
	
	/// 获取设备的图标
	class func getIconName(devType: Byte) -> String {
		let device = HRDevice()
		device.devType = devType
		return device.iconName
	}
	
	///设备名字的描述，比如传入继电器控制盒的设备类型0x04，返回字符串“继电器控制盒”
	///
	///- parameter devType: 设备类型
	///returns: 设备的名称描述
	class func deviceNameString(devType: Byte) -> String {
		let type = HRDeviceType(rawValue: devType)
		if type == nil {
			return NSLocalizedString("hr_dev_name_unknow")
		}
		switch type! {
		case .Master:
			return NSLocalizedString("hr_dev_name_host")
		case .SwitchPanel:
			return NSLocalizedString("hr_dev_name_switch")
		case .ScenePanel:
			return NSLocalizedString("hr_dev_name_scene_panel")
		case .SocketPanel:
			return NSLocalizedString("hr_dev_name_socket")
		case .RelayControlBox:
			return NSLocalizedString("hr_dev_name_relaybox")
		case .RGBLamp:
			return NSLocalizedString("hr_dev_name_rgb_lamp")
		case .BluetoothControlUnit:
			return NSLocalizedString("hr_dev_name_bluetooth_unit")
		case .InfraredTransmitUnit:
			return NSLocalizedString("hr_dev_name_infrared_unit")
		case .CurtainControlUnit:
			return NSLocalizedString("hr_dev_name_motor_ctrler")
		case .InfraredDetectorUnit:
			return NSLocalizedString("hr_dev_name_infrared_detector")
		case .DoorMagCard:
			return NSLocalizedString("hr_dev_name_mag_card")
		case .DoorLock:
			return NSLocalizedString("hr_dev_name_door_lock")
            
            
            //斌 门锁相关
        case .GaoDunDoor:
            
            return NSLocalizedString("hr_dev_name_door_smartlock")
            
		case .DoorBell:
			return NSLocalizedString("hr_dev_name_door_bell")
		case .SolarSensor:
			return NSLocalizedString("hr_dev_name_solar_sensor")
		case .GasSensor:
			return NSLocalizedString("hr_dev_name_gas_sensor")
		case .AirQualitySensor:
			return NSLocalizedString("hr_dev_name_tmp_hum_sensor")
		case .HumiditySensor:
			return NSLocalizedString("hr_dev_name_humidty_sensor")
		case .Manipulator:
			return NSLocalizedString("hr_dev_name_manipulator")
		case .SmartBed:
			return NSLocalizedString("hr_dev_name_smart_bed")
		case .AdjustableLight:
			return NSLocalizedString("hr_dev_name_adjustableLight")
		case .LiveWireSwitch:
			return NSLocalizedString("hr_dev_name_livewireswitch")
		case .ApplyDevice:
			return NSLocalizedString("hr_dev_name_apply")
		case .Scene:
			return NSLocalizedString("hr_dev_name_scene")
		case .Task:
			return NSLocalizedString("hr_dev_name_task")
		default:
			return NSLocalizedString("hr_dev_name_unknow")
		}
	}
}


extension HRDevice {
	
	var iconName: String  {
		switch self.devType {
		case HRDeviceType.relayTypes():
			if self is HRRelayInBox{
				switch (self as! HRRelayInBox).state {
				case .ON:
					return "设备图标-继电器-点击"
				default:
					break
				}
			}
			return "设备图标-继电器"
			
		case HRDeviceType.CurtainControlUnit.rawValue:
			return "设备图标-电机"
			
		case HRDeviceType.ApplyDevice.rawValue:
			switch (self as! HRApplianceApplyDev).appDevType {
			case HRAppDeviceType.TV.rawValue:
				return "设备图标-电视机"
			case HRAppDeviceType.AirCtrl.rawValue:
				return "设备图标-空调"
			default:
				break
			}
			return "设备图标-未知设备"
			
		case HRDeviceType.DoorLock.rawValue:
			return "设备图标-智能门锁"
            
         //门锁相关 斌 设备图标还是与原来的锁的图标一样
            
        case HRDeviceType.GaoDunDoor.rawValue:
            return "设备图标-智能门锁"

			
		case HRDeviceType.SolarSensor.rawValue:
			return "设备图标-光照传感器"
		case HRDeviceType.GasSensor.rawValue:
			return "设备图标-可燃气体传感器"
		case HRDeviceType.Manipulator.rawValue:
			return "设备图标-机械手"
		case HRDeviceType.SmartBed.rawValue:
			return "设备图标-床"
		case HRDeviceType.HumiditySensor.rawValue:
			return "设备图标-湿敏探测器"
		case HRDeviceType.AirQualitySensor.rawValue:
			return "设备图标-空气质量传感器"
		case HRDeviceType.Task.rawValue:
			return "设备图标-定时任务"
		case HRDeviceType.ScenePanel.rawValue:
			if let panel = self as? HRScenePanel {
				if panel.enableKeys == 0 {
					//enableKeys的没两位代表一路，这两位为0则该路按键有效， 为3则无效，所以enableKeys等于0说明四路都有效
					return "设备图标-情景面板-4键"
				}
				return "设备图标-情景面板-2键"
			}
			return "设备图标-未知设备"
		case HRDeviceType.Scene.rawValue:
			if let scene = self as? HRScene {
				var name = ""
				switch scene.icon {
				case 1:
					name = "ico_scene_athome"
				case 2:
					name = "ico_scene_leavehome"
				case 3:
					name = "ico_scene_gettingup"
				case 4:
					name = "ico_scene_sleeping"
				case 5:
					name = "ico_scene_curtainopen"
				case 6:
					name = "ico_scene_curtainclose"
				case 7:
					name = "ico_scene_curtainstop"
				case 8:
					name = "ico_scene_repast"
				case 9:
					name = "ico_scene_media"
				case 10:
					name = "ico_scene_birthday"
				case 11:
					name = "ico_scene_recreation"
				case 12:
					name = "ico_scene_romance"
				case 13:
					name = "ico_scene_relaxation"
				case 14:
					name = "ico_scene_sports"
				case 15:
					name = "ico_scene_reading"
				case 16:
					name = "ico_scene_working"
				case 17:
					name = "ico_scene_meeting"
				case 18:
					name = "ico_scene_receive"
				default:
					name = "icon_scene_unknow"
				}
				return name
			} else {
				return "ico_scene_unknow"
			}
		case HRDeviceType.RGBLamp.rawValue:
			return "设备图标-RGB"
		default:
			return "设备图标-未知设备"
		}
	}
}
