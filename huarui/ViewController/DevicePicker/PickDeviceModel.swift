//
//  DevicePickerModel.swift
//  huarui
//
//  Created by sswukang on 16/2/25.
//  Copyright © 2016年 huarui. All rights reserved.
//

import Foundation

enum PickDeviceType {
	/// 继电器
	case Relay
	/// 电机
	case Motor
	/// 应用设备
	case Apply
	/// 情景
	case Scene
	/// RGB灯
	case RGB
	
	var description: String {
		switch self {
		case .Relay: return "继电器"
		case .Motor: return "电机"
		case .Apply: return "应用设备"
		case .Scene: return "情景"
		case .RGB:	 return "RGB灯"
		}
	}
	
	static var allTypes: [PickDeviceType] {
		return [.Relay, .Motor, .Apply, .Scene, .RGB]
	}
	
	var hrDeviceTypes: [HRDeviceType] {
		switch self {
		case .Relay: return [.RelayControlBox, .SwitchPanel, .SocketPanel, .LiveWireSwitch]
		case .Motor: return [.CurtainControlUnit, .Manipulator]
		case .Apply: return [.ApplyDevice]
		case .Scene: return [.Scene]
		case .RGB:	 return [.RGBLamp]
		}
	}
}

class PickDeviceModel {
	
	var type: PickDeviceType
	var selected: Bool = false
	var device: HRDevice
	/**设备绑定的操作，占4个字节*/
	var actBinds: [Byte] = [0xFF, 0xFF, 0xFF, 0xFF]
	
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

	var devInScene: HRDevInScene {
		let dev = HRDevInScene()
		dev.device = self.device
        dev.hostAddr = self.device.hostAddr
        dev.devType  = self.device.devType
        dev.devAddr  = self.device.devAddr
        dev.actBinds = self.actBinds
		switch device {	//继电器和电机类型的设备要给个初始状态
		case let relay as HRRelayInBox:
			dev.actBinds[Int(relay.relaySeq)] = relay.state.rawValue
		case let motor as HRMotorCtrlDev:
			dev.actBinds[0] = motor.status.rawValue
		default: break
		}
		return dev
	}
	
	init(type: PickDeviceType, device: HRDevice) {
		self.type = type
		self.device = device
	}
	
}