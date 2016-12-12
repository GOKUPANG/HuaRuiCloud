//
//  HRDelegates.swift
//  huarui
//
//  Created by sswukang on 16/3/21.
//  Copyright © 2016年 huarui. All rights reserved.
//

import Foundation



// MARK: - HR800代理
@objc protocol HR8000HelperDelegate {
	///用户登录成功
	optional func hr8000Helper(didUserLogin login: HRAcount);
	///用户登陆失败
	//    optional func hr8000Helper(userLoginFailure error: NSError);
	///用户注销登录
	optional func hr8000Helper(didUserLogout logout: HRAcount);
	///查询设备信息，
	///
	///- parameter device: 查询的设备，注意：该方法调用时，已经将设备保存在HRDatabase中了。
	optional func hr8000Helper(queryDeviceInfo device: HRDevice, indexOfDatabase index: Int, devices: [HRDevice]);
	
	///查询设备信息完成
	optional func hr8000Helper(finishedQueryDeviceInfo finish: Bool);
	
	///接收到异常帧
	optional func hr8000Helper(receiveExceptionFrame frame: HRFrame, exception: NSError);
	///删除设备
	optional func hr8000Helper(didDeleteDevice device: HRDevice);
	
	/**
	主机上传设备信息，一般实体按键面板按下时会上传。
	
	- parameter device: 设备对象
	*/
	optional func hr8000Helper(commitDeviceState device: HRDevice)
    
    
    
    //-----------------------0x02：表示反馈检查结果start-----------------------
    ///检查固件有新版本- 0x01表示有新版本
    optional func checkFirmware(hasNewVersion version: String, size: String, date: String, description: String)
    
    ///检查更新设备失败或没有新版本- 0x00表示无新版本或更新失败
    optional func checkFirmware(noNewVersion code:Byte, message: String)
    //-----------------------0x02：表示反馈检查结果end-----------------------
    
    
    ///无法更新新版本- 0x03：表示请求更新之 - 0x00表示无法更新
    optional func upDataFirmware(noUpDataVersion code:Byte, message: String)
}



//MARK: - 继电器设备代理协议

/**远程设备数据的增删改都会导致本代理回调调用*/
@objc protocol HRRelayBaseDeviceDelegate {
	
	///操作继电器控制盒、开关面板、智能插座、单火开关
	func relayBaseDevice(relayBaseDevice: HRRelayComplexes)
	
}

//MARK: - 情景代理协议

/**远程情景数据的增删改都会导致本代理回调调用*/
@objc protocol HRSceneUpdateDelegate {
	
	///远程情景数据的被修改了。注意：调用该方法时数据库HRDatabase的情景数据已经更新了
	///
	///- parameter sceneByModify: 被修改了的情景
	///- parameter indexOfDatabase:  被删除的情景在原来数组的索引位置
	///- parameter newScenes:    新的Scene数组
	optional func sceneUpdate(sceneByModify scene: HRScene, indexOfDatabase index: Int, newScenes: [HRScene]);
	
	
	///创建一个情景，新情景会增加到数组的最后位置。注意：调用该方法时数据库HRDatabase的情景数据已经更新了
	///
	///- parameter sceneByCreate: 新创建出的情景
	///- parameter newScenes:    新的Scene数组
	optional func sceneUpdate(sceneByCreate scene: HRScene, newScenes: [HRScene]);
	
	///远程删除了情景的回调。注意：调用该方法时已经将该情景从数据库HRDatabase中删除了
	///
	///- parameter sceneByDelete: 被删除的情景
	///- parameter indexOfDatabase:  被删除的情景在原来数组的索引位置
	///- parameter newScenes:    新的Scene数组
	optional func sceneUpdate(sceneByDelete scene: HRScene, indexOfDatabase index: Int, newScenes: [HRScene]);
}

//MARK: - 红外设备代理协议

@objc protocol HRInfraredDelegate {
	
	///初始化
	///
	///- parameter appDevID: 应用设备ID
	///- parameter devType:  设备类型
	///- parameter tag:		帧标记
	///- parameter result:   结果： 0x00正常， 0x01异常
	optional func infraredTransmit(initInfrared appDevID: UInt16, devType: Byte, tag: Byte,  result: Bool);
	
	///码库匹配
	///
	///- parameter appDevID: 应用设备ID
	///- parameter devType:  设备类型
	///- parameter tag:		帧标记
	///- parameter keyCode:  按键编码
	///- parameter codeIndex: 码库索引
	///- parameter result:   结果： 0x00正常， 0x01异常
	optional func infraredTransmit(codeMatching appDevID: UInt16, devType: Byte, tag: Byte,  keyCode: Byte, codeIndex: UInt32, result: Bool);
	
	///正常操作
	///
	///- parameter appDevID: 应用设备ID
	///- parameter devType:  设备类型
	///- parameter tag:		帧标记
	///- parameter keyCode:  按键编码
	///- parameter codeIndex: 码库索引
	///- parameter result:   结果： 0x00正常， 0x01异常
	optional func infraredTransmit(normalOperated appDevID: UInt16, devType: Byte, tag: Byte,  keyCode: Byte, codeIndex: UInt32, result: Bool);
}

//MARK: - 机械手代理
/**机械手代理*/
protocol HRManipulatorDelegate{
	func manipulatorResut(newManip: HRManipulator, tag: Byte)
}

//MARK: - RGB灯代理
protocol HRRGBLampDelegate: class {
	/**
	RGB灯状态改变
	
	- parameter lamp: RGB灯对象
	- parameter oldMode: 之前的模式
	- parameter oldRGB:    之前的RGB值
	*/
	func rgbLampDelegate(lamp: HRRGBLamp, valueChanged oldMode: HRRGBCtrlMode, oldRGB: HRRGBValue)
}

//MARK: - 传感器代理
@objc protocol HRSensorValuesDelegate{
	
	///光照值
	///
	///- parameter devAddr:  设备地址
	///- parameter lux:      光照值（0~4000lux）
	optional func sensorValues(SolarValueResult devAddr: UInt32, lux: UInt16, tag: Byte);
	
	///可燃气浓度值
	///
	///- parameter devAddr:  设备地址
	///- parameter dens:     燃气浓度（0~65535ppm）
	optional func sensorValues(gasDensValueResult devAddr: UInt32, dens: UInt16, tag: Byte);
	
	///可燃气爆炸下限(LEL)指数
	///
	///- parameter devAddr:  设备地址
	///- parameter lel:      爆炸下限指数（0.00~100.00%）
	optional func sensorValues(gasLELValueResult devAddr: UInt32, lel: Float, tag: Byte);
	
	///温湿度空气质量
	///
	///- parameter devAddr:      设备地址
	///- parameter temperature:  温度
	///- parameter humidity:     湿度
	///- parameter airQuality:   空气质量
	optional func sensorValues(tempAirValueResult devAddr: UInt32, temperature: Int16, humidity: UInt16, airQuality: UInt16, tag: Byte);
	
}

// MARK: - 注册设备代理
protocol HRRegisterDevicesDelegate: class {
	
	/**
	注册流程2， 表示邀请设备注册
	
	- parameter devType:  设备类型
	- parameter hostAddr: 主机地址
	- parameter devAddr:  设备地址
	*/
	func registerDevices(devType: Byte, hostAddr: UInt32, deviceInfo devAddr: UInt32);
	
	/**
	注册流程3， 表示新设备已经注册完成
	
	- parameter devType:  设备类型
	- parameter device:  设备数据
	- parameter data:  HRFrame的数据域，具体内容参考协议
	*/
	func registerDevices(devType: Byte, newDevice device: HRDevice, data: [Byte]);
	
	/**
	注册的流程4，表示退出设备注册状态
	
	- parameter didEndRegister: 完成设备注册
	*/
	func registerDevices(didEndRegister: Bool);
}

//MARK: - 智能床代理
protocol HRSmartBedDelegate{
	///控制智能床
	func smartBedControl(devAddr: UInt32, headPos: Byte, tailPos: Byte, headMassage: Byte, tailMassage: Byte, lightState: Byte);
}

//MARK: - 红外学习代理
@objc protocol HRInfraredLearningDelegate {
	///红外学习-克隆学习，流程0x00
	///
	///- parameter appDevType	应用设备类型
	///- parameter appDevID		应用设备ID
	///- parameter hostAddr		设备所属主机
	///- parameter success		学习结果
	optional func infraredLearning(learningClone appDevType: Byte, appDevID: UInt16, hostAddr: UInt32, success: Bool)
	
	
	///红外学习-请求开始学习，流程0x01
	///
	///- parameter start 是否可以开始
	optional func infraredLearning(learningStart start: Bool)
	
	
	///红外学习-请求按键学习，流程0x02
	///
	///- parameter appDevType	应用设备类型
	///- parameter appDevID		应用设备ID
	///- parameter keyCode		设备按键编码
	///- parameter success		学习结果
	optional func infraredLearning(recordKey appDevType: Byte, appDevID: UInt16, keyCode: Byte, success: Bool)
	
	///红外学习-请求结束学习，流程0x03
	///
	///- parameter appDevType	应用设备类型
	///- parameter appDevID		应用设备ID
	optional func infraredLearning(learningStop appDevType: Byte, apDevID: UInt16)
	
	
}