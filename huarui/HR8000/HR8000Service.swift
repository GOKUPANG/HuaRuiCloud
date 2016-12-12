//
//  HR8000Service.swift
//  huarui
//
//  Created by sswukang on 15/1/23.
//  Copyright (c) 2015年 huarui. All rights reserved.
//


import Foundation

/// HR8000服务，向UI提供接口
class HR8000Service {
    
    private var base: ServiceBase
    
    ///是否已经登录
    var isLogin : Bool {
		return self.workMode == HRWorkMode.Online
    }
	
///MARK: - 初始化
    
    private init() {
        base = ServiceBase()
    }
    
    
    /**获取HR8000Helper共享对象(单例模式)*/
    class func shareInstance() -> HR8000Service {
        struct Singleton{
            static var predicate: dispatch_once_t   = 0
            static var instance: HR8000Service?      = nil
        }
        dispatch_once(&Singleton.predicate, {
            Singleton.instance = HR8000Service()
        })
        return Singleton.instance!
    }

//MARK: - 管理连接
    
    
    ///当前工作状态
    var workMode   : HRWorkMode     { return base.workMode }
    ///当前网络状况
    var networkType: HRNetworkType  { return base.networkType }
    
    
    ///登陆主机，如果要知道登陆结果，请实现HR
    func login(userName: String, password: String, result: ((NSError?)->Void)?) {
		if reachChecker!.currentReachabilityStatus == .NotReachable {
			result?(NSError(domain: "无网络连接", code: HRErrorCode.NoConnection.rawValue, userInfo: nil))
			return
		}
		
        base.doLogin(userName, password: password, result: {
            (error) in
            if error == nil {   //登陆成功
                HRDatabase.shareInstance().shouldOnline = true
            } else {
                HRDatabase.shareInstance().shouldOnline = false
            }
            result?(error)
        })
    }
    
    ///后台的方式登陆主机，UI层请勿调用本方法
    func loginBackground(userName: String, password: String, result: ((NSError?)->Void)?) {
        base.doLogin(userName, password: password, result: result)
    }
	
	///注销
    func logout() {
        HRDatabase.shareInstance().deleteAll()
        HRDatabase.shareInstance().shouldOnline = false
        base.logout()
    }
    
    ///后台方式注销登陆，UI层请勿调用本方法
    func logoutBackgoround() {
        HRDatabase.shareInstance().shouldOnline = false
        base.logout()
        
    }
	
	/**
	发送心跳包
	
	- parameter result: 结果
	*/
	func heartbeat(result: (NSError?)->Void) {
		runOnGlobalQueue({
			self.base.doHeartbeat(result)
		})
	}

//MARK: - 操作控制设备
    
    ///启动情景
    ///
    ///- parameter callback:: 结果的闭包类型，第一个参数是是否成功启动情景，第二个是失败的描述（失败时才会有值）
    ///
    func startScene(scene: HRScene, callback: (NSError?)->Void) {
		runOnGlobalQueue({
			self.base.doStartScene(scene, callback: callback)
		})
    }
    
    ///操作继电器、智能开关、智能插座
    ///
    ///- parameter actionType: 控制类型，比如开、关、翻转、无效；
    ///- parameter relay: 继电器类型（注意：是继电器控制盒的某一路，不是继电器控制盒）
    ///- parameter tag: 可以传递一个tag来标记，当接收到返回的时候就可以通过这个tag来判断是不是对应发送的响应帧， 注意参数的最高位0表示APP发起，1表示主机发起，应该用低7位来判断是否相等。
    ///- parameter callback: 结果回调
    func operateRelay(actionType type: HRRelayOperateType, relay: HRRelayInBox, callback: (NSError?)->Void){
        operateRelayDelay(actionType: type, relay: relay, delay: 0, callback: callback)
    }
    
    ///操作继电器、智能开关、智能插座(带延时)
    ///
    ///- parameter actionType: 控制类型，比如开、关、翻转、无效；
    ///- parameter relay: 继电器类型（注意：是继电器控制盒的某一路，不是继电器控制盒）
    ///- parameter tag: 可以传递一个tag来标记，当接收到返回的时候就可以通过这个tag来判断是不是对应发送的响应帧， 注意参数的最高位0表示APP发起，1表示主机发起，应该用低7位来判断是否相等。
    ///- parameter delay:    延时码，单位为秒
    ///- parameter callback: 结果回调
    func operateRelayDelay(actionType type: HRRelayOperateType, relay: HRRelayInBox, delay: Byte, callback: (NSError?)->Void) {
		runOnGlobalQueue({
			self.base.doOperateRelay(actionType: type, relay: relay, delay: delay, callback: callback)
		})
    }
    
    ///操作窗帘等电机设备
    ///
    ///- parameter actionType: 操作类型，使用HRMotorOperateType枚举，有开、关、停等方式
    ///- parameter tag: tag 可以传递一个tag来标记，当接收到返回的时候就可以通过这个tag来判断是不是对应发送的响应帧， 注意参数的最高位0表示APP发起，1表示主机发起，应该用低7位来判断是否相等。
    ///- parameter callback: 结果回调
    func operateCurtain(actionType type: HRMotorOperateType, motor: HRMotorCtrlDev, callback:(NSError?)->Void){
		runOnGlobalQueue({
			self.base.doOperateMotorDev(type, motor: motor, delay: 0, callback: callback)
		})
    }
	
	///红外转发操作/遥控应用设备
	///
	///- parameter apply:       应用设备
	///- parameter ctrlType:    操作类型，HRInfraredCtrlType， 默认为.NormalCtrl(正常操作)
	///- parameter infraredKey: 红外码，InfraredKey
	///- parameter tag:         标记
	///- parameter callback:    结果回调
	func operateInfrared(apply: HRApplianceApplyDev, ctrlType: HRInfraredCtrlType = .NormalCtrl, infraredKey: HRInfraredKey, tag: Byte, callback: ((NSError?)->Void)?){
		runOnGlobalQueue({
			//操作红外转发器，infraredType填0x02代表正常操作
			self.base.doOperateInfrared(apply, infraredType: ctrlType.rawValue, infraredKey: infraredKey, tag: tag, delay: 0, callback: callback)
		})
    }
    
    ///初始化空调遥控器
    func initAirCtrl(apply: HRApplianceApplyDev, completion: ((NSError?)->Void)?) {
		runOnGlobalQueue({
			if apply.learnKeys.count == 0 {
				completion?(NSError(domain: "没有学习红外码", code: -1, userInfo: nil))
				return
			}
			let tag = Byte(arc4random() % 128)
			self.base.doOperateInfrared(apply, infraredType: 0x00, infraredKey: apply.learnKeys[0], tag: tag, delay: 0, callback: completion)
		})
    }
    
    ///开锁，开锁之后约5秒之后关锁
    ///
    ///- parameter door: 智能门锁对象
    ///- parameter passwd: 门锁密码
    func unlockDoor(door: HRDoorLock, passwd: String, callback: (NSError?)->Void) {
        var passwdData = ContentHelper.decodeGbkData(passwd)
        if passwdData.count < 16{
            passwdData += [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
        }
        passwdData = Array(passwdData[0...15])
        base.doUnlockDoor(door, passwd: passwdData, stateCode: 0x24, tag: 36, callback: callback)
    }
    
    
    //门锁相关  高盾锁的开锁方法  新增的方法
    
    ///
    ///- parameter door: 高盾门锁对象
    ///- parameter passwd: 门锁密码
    
    
    func unlockSmartDoor(door: HRSmartDoor, passwd: String, callback: (NSError?)->Void)
    {
        
        // 很重要 异或加密 门锁相关 
          var keyByte =  door.devAddr.getBytes()
        
        var passwdData = ContentHelper.decodeGbkData(passwd)
        
         for i in 0...passwdData.count-1
         {
            passwdData[i] = passwdData[i] ^ keyByte[i%4]
        }
        if passwdData.count < 12{
            passwdData += [0,0,0,0,0,0,0,0,0,0,0,0]
        }
        passwdData = Array(passwdData[0...11])
        
        base.doUnlockSmartDoor(door, passwd: passwdData, stateCode: 0x24, tag: 37, callback: callback)
        
        
    }
    
    
    
    
    
    
    
    
    
    
    ///控制机械手
    ///
    /// - parameter manip:    机械手对象
    /// - parameter action:   动作，开关停
    /// - parameter delaySec:   延时，单位为秒
    /// - parameter callback: 结果回调
    func operateManipulator(manip: HRManipulator, action: HRMotorOperateType, delaySec: Byte, callback: ((NSError?)->Void)?) {
		runOnGlobalQueue({
			self.base.doOperateMotorDev(action, motor: manip, delay: delaySec, callback: callback)
		})
    }
    
    ///控制智能床
    ///
    /// - parameter headPos:       床头位置，正值表示上升；负值表示下降。可选
    /// - parameter tailPos:       床尾位置，正值表示上升；负值表示下降。可选
    /// - parameter headMassage:   床头震动，0~3四种状态。可选
    /// - parameter tailMassage:   床尾震动，0~3四种状态。可选
    /// - parameter light:         灯光状态, 0x00或bSmartBedLightOff表示关灯；0x01或bSmartBedLightOn开灯。 可选
    func operateSmartBed(bed: HRSmartBed, headPos: Byte? = nil, tailPos: Byte? = nil, headMassage: Byte? = nil, tailMassage: Byte? = nil, light: Byte? = nil) {
        let tag: Byte = 62
        
        if headPos != nil && tailPos == nil
        && headMassage == nil && tailMassage == nil
        && light == nil{        //床头升降
            var content = [Byte]()
            content.append(0x01)
            content.append(headPos!)
            base.doOperateSmartBed(bed, action: 0x01, content: content, tag: tag)
        }
        else if headPos == nil && tailPos != nil
            && headMassage == nil && tailMassage == nil
            && light == nil{    //床尾升降
            var content = [Byte]()
            content.append(0x02)
            content.append(tailPos!)
            base.doOperateSmartBed(bed, action: 0x01, content: content, tag: tag)
                
        }
        else if headPos == nil && tailPos == nil
            && headMassage != nil && tailMassage == nil
            && light == nil{    //床头震动
            var content = [Byte]()
            content.append(0x01)
            content.append(headMassage!)
            base.doOperateSmartBed(bed, action: 0x02, content: content, tag: tag)
        }
        else if headPos == nil && tailPos == nil
            && headMassage == nil && tailMassage != nil
            && light == nil{    //床尾震动
            var content = [Byte]()
            content.append(0x02)
            content.append(tailMassage!)
            base.doOperateSmartBed(bed, action: 0x02, content: content, tag: tag)
        }
        else if headPos == nil && tailPos == nil
            && headMassage == nil && tailMassage == nil
            && light != nil{    //控制灯光
            var content = [Byte]()
            content.append(0x03)
            content.append(light!)
            base.doOperateSmartBed(bed, action: 0x03, content: content, tag: tag)
        }
        else {                  //多种操作
            var content = [Byte]()
            let tmpHeadPos = headPos == nil ? 0xFF : headPos!
            let tmpTailPos = tailPos == nil ? 0xFF : tailPos!
            let tmpHeadMsg = headMassage == nil ? 0xFF : headMassage!
            let tmpTailMsg = tailMassage == nil ? 0xFF : tailMassage!
            let tmpLight   = light == nil ? 0xFF : light!
            content.append(tmpHeadPos)
            content.append(tmpTailPos)
            content.append(tmpHeadMsg)
            content.append(tmpTailMsg)
            content.append(tmpLight)
            base.doOperateSmartBed(bed, action: 0xFF, content: content, tag: tag)
        }
    }
	
	/**
	控制RGB灯
	- parameter rgbLamp:  RGB灯对象
	- parameter mode:     模式`HRRGBCtrlMode`
	- parameter rgbValues:  RGB值数组，长度不能小于3。当mode为RGB时，不能为空，其他模式该参数无效
	- parameter speed:    速度，范围1~3，分别对应慢中快。当mode为Gradient、Step、Rainbow这三种模式时，该参数不能为空，其他模式该参数无效
	- parameter duration: 循环时间，范围0~7200秒。当mode为Gradient、Step、Rainbow这三种模式时，该参数不能为空，其他模式该参数无效
	- parameter result:   控制返回的结果。
	*/
	func doOperateRGBLamp(rgbLamp: HRRGBLamp, mode: HRRGBCtrlMode, rgbValues: [Byte]?, speed: Byte?, duration: UInt16?, result: ((NSError?)->Void)?) {
		runOnGlobalQueue({
			self.base.doOperateRGBLamp(rgbLamp, mode: mode, rgbValues: rgbValues, speed: speed, duration: duration, delay: 0, result: result)
		})
	}

// MARK: - 添加设备
    
    ///进入注册状态，开始注册设备。注册流程1
    func registerDeviceStart() {
		runOnGlobalQueue({
			self.base.doRegisterDeviceStart()
		})
    }
    
    ///允许设备注册到主机中。注册流程3
    func registerDeviceAllow(devType: Byte, devAddr: UInt32, name: String, room: String, floor: String) {
		runOnGlobalQueue({
			let floorId: UInt16
			let roomId: UInt16
			if let id = HRDatabase.shareInstance().getRoomID(floor, roomName: room) {
				roomId = id
			} else {
				roomId = 0
			}
			if let id = HRDatabase.shareInstance().getFloorID(floor) {
				floorId = UInt16(id)
			} else {
				floorId = 0
			}
			self.base.doRegisterDeviceAllow(devType, devAddr: devAddr, name: name, insRoomId: roomId, insFloorId: floorId)
		})
    }
	
    ///结束注册设备，0x04
    func registerDeviceEnd() {
        base.doRegisterDeviceEnd()
    }
	
	///添加或创建情景
	///
	///- parameter scene: 情景对象
	///- parameter isCreate: 是否是创建新情景，如果创建新情景填true，编辑情景填false
	///- parameter result: 结果回调
	func createOrModifyScene(scene: HRScene, isCreate: Bool, result: (NSError?)->Void) {
		if HRDatabase.shareInstance().acount.permission != 2 && HRDatabase.shareInstance().acount.permission != 3 {
			result(NSError(domain: "没有权限", code: HRErrorCode.PermissionDinied.rawValue, userInfo: nil))
			return
		}
		runOnGlobalQueue({
			self.base.doCreateOrModifyScene(scene, isCreate: isCreate, result: result)
		})
	}
	
	///添加或创建定时任务
	///
	///- parameter task: 定时任务对象
	///- parameter isCreate: 是否是创建新定时任务，如果创建新定时任务填true，编辑则填false
	///- parameter result: 结果回调
	func createOrModifyTask(task: HRTask, isCreate: Bool, result: (NSError?)->Void) {
		if !HRDatabase.isEditPermission {
			result(NSError(domain: "没有权限", code: HRErrorCode.PermissionDinied.rawValue, userInfo: nil))
			return
		}
		runOnGlobalQueue({
			self.base.doCreateOrModifyTask(task, isCreate: isCreate, result: result)
		})
	}
	

	///创建应用设备
	///
	///- parameter hostAddr:        主机地址
	///- parameter appType :        应用设备类型，见HRAppDeviceType
	///- parameter name:            应用设备名字
	///- parameter floorId:         应用设备安装的楼层ID
	///- parameter roomId:          应用设备安装的房间ID
	///- parameter InfraredDevAddr: 红外转发器的设备地址
	///- parameter result:          结果回调
	func createApplyDevice(hostAddr: UInt32, appType: Byte, name: String, floorId: UInt16, roomId: UInt16, InfraredDevAddr: UInt32, result: ((NSError?)->Void)?) {
		if !HRDatabase.isEditPermission {
			result?(NSError(domain: "没有权限", code: HRErrorCode.PermissionDinied.rawValue, userInfo: nil))
			return
		}
		runOnGlobalQueue({
			self.base.doCreateOrModifyApplyDevice(
				hostAddr,
				permission: HRDatabase.shareInstance().acount.permission,
				actionType: 1,
				appType: appType,
				appId: 0xFF,
				name: name,
				floorId: floorId,
				roomId: roomId,
				infraredDevAddr: InfraredDevAddr,
				result: result
			)
		})
		
	}
	
	///创建一个用户
	func createUser(user: HRUserInfo, newPasswd: String, result: ((NSError?)->Void)?) {
		if !HRDatabase.isEditPermission {
			result?(NSError(domain: "没有权限", code: HRErrorCode.PermissionDinied.rawValue, userInfo: nil))
			return
		}
		runOnGlobalQueue({
			self.base.doUserManage(user, action: .CreateNewUser, newPasswd: newPasswd, origUserName: nil, origPasswd: nil, result: result)
		})
	}
	
	///创建楼层
	func createFloor(floor: HRFloorInfo, result: ((NSError?)->Void)?) {
		if !HRDatabase.isEditPermission {
			result?(NSError(domain: "没有权限", code: HRErrorCode.PermissionDinied.rawValue, userInfo: nil))
			return
		}
		runOnGlobalQueue({
			self.base.doCreateOrEditFloor(.CreateNewFloor, floor: floor, room: nil, result: result)
		})
	}
	
	///创建房间
	///
	/// - parameter room:	房间
	/// - parameter inFloor: 楼层（必须是已经存在的）
	/// - parameter result: 结果
	func createRoom(room: HRRoomInfo, inFloor: HRFloorInfo, result:  ((NSError?)->Void)?) {
		if !HRDatabase.isEditPermission {
			result?(NSError(domain: "没有权限", code: HRErrorCode.PermissionDinied.rawValue, userInfo: nil))
			return
		}
		runOnGlobalQueue({
			self.base.doCreateOrEditFloor(.CreateNewRoom, floor: inFloor, room: room, result: result)
		})
	}
	
	//MARK: - 红外学习
	
	///红外学习 - 开始学习
	func learningInfraredStart(appDevice: HRApplianceApplyDev, result: ((NSError?)->Void)?) {
		if !HRDatabase.isEditPermission {
			result?(NSError(domain: "没有权限", code: HRErrorCode.PermissionDinied.rawValue, userInfo: nil))
			return
		}
		runOnGlobalQueue({
			self.base.doLearningInfraredStart(appDevice, result: result)
		})
	}
	
	///红外学习 - 记录按键
	func learningInfraredRecordKey(appDevice: HRApplianceApplyDev, keyCode: Byte, result: ((NSError?)->Void)?) {
		if !HRDatabase.isEditPermission {
			result?(NSError(domain: "没有权限", code: HRErrorCode.PermissionDinied.rawValue, userInfo: nil))
			return
		}
		runOnGlobalQueue({
			self.base.doLearningInfraredRecordKey(appDevice, keyCode: keyCode, result: result)
		})
	}
	
	///红外学习 - 结束学习
	func learningInfraredStop(appDevice: HRApplianceApplyDev, result: ((NSError?)->Void)?) {
		if !HRDatabase.isEditPermission {
			result?(NSError(domain: "没有权限", code: HRErrorCode.PermissionDinied.rawValue, userInfo: nil))
			return
		}
		runOnGlobalQueue({
			self.base.doLearningInfraredStop(appDevice, result: result)
		})
	}
	
	///红外学习，使用匹配的码库, 学习流程0x04
	///
	func learningInfraredUseLibrary(appDevice: HRApplianceApplyDev, codeLibIndex: UInt16, result: ((NSError?)->Void)?) {
		if !HRDatabase.isEditPermission {
			result?(NSError(domain: "没有权限", code: HRErrorCode.PermissionDinied.rawValue, userInfo: nil))
			return
		}
		runOnGlobalQueue({
			self.base.doLearningInfraredUseLibrary(appDevice, codeLibIndex: codeLibIndex, result: result)
		})
	}
	
	
//MARK: - 编辑设备
	
	/**
	设置系统参数
	- parameter hostAddr: 主机地址
	- parameter channel:  信道
	- parameter RFAddr:   RF地址
	- parameter result:   结果
	*/
	func setSystemParameter(hostAddr: UInt32, channel: Byte, RFAddr: Byte, result: ((NSError?)->Void)?) {
		if !HRDatabase.isEditPermission {
			result?(NSError(domain: "没有权限", code: HRErrorCode.PermissionDinied.rawValue, userInfo: nil))
			return
		}
		runOnGlobalQueue({
			self.base.doSetSystemParameter(hostAddr, channel: channel, RFAddr: RFAddr, result: result)
		})
	}
	
	/**
	绑定继电器负载
	
	- parameter relayBox: 继电器控制盒。绑定是按该参数对象的relays属性中有多少个relay就绑多少个。
	- parameter result:   结果回调
	*/
	func bindRelayLoads(relayBox: HRRelayCtrlBox, result: (NSError?)->Void) {
		if !HRDatabase.isEditPermission {
			result(NSError(domain: "没有权限", code: HRErrorCode.PermissionDinied.rawValue, userInfo: nil))
			return
		}
		runOnGlobalQueue({
			self.base.doBindRelayLoads(relayBox, result: result)
		})
	}
	
	///编辑设备的基本信息
	func editDeviceInfo(device: HRDevice, result: ((NSError?)->Void)?) {
		if !HRDatabase.isEditPermission {
			result?(NSError(domain: "没有权限", code: HRErrorCode.PermissionDinied.rawValue, userInfo: nil))
			return
		}
		runOnGlobalQueue({
			self.base.doEditDeviceInfo(device, result: result)
		})
	}
	
	
	///修改应用设备信息
	///
	/// - parameter appDev: 应用设备对象
	/// - parameter result: 结果回调
	func modifyApplyDevice(appDev: HRApplianceApplyDev, result: ((NSError?)->Void)?) {
		let permission = HRDatabase.shareInstance().acount.permission
		if permission != 2 && permission != 3 {
			result?(NSError(domain: "没有权限", code: HRErrorCode.PermissionDinied.rawValue, userInfo: nil))
			return
		}
		runOnGlobalQueue({
			self.base.doCreateOrModifyApplyDevice(appDev.hostAddr, permission: permission, actionType: 2, appType: appDev.appDevType, appId: UInt16(appDev.appDevID), name: appDev.name, floorId: appDev.insFloorID, roomId: appDev.insRoomID, infraredDevAddr: appDev.infraredUnitAddr, result: result)
		})

	}
	
	///修改情景面板绑定的按键动作
	/// - parameter scenePanel: 情景面板对象
	/// - parameter result: 结果回调
	func editScenePanelBindings(scenePanel: HRScenePanel, result:((NSError?)->Void)?) {
		if !HRDatabase.isEditPermission {
			result?(NSError(domain: "没有权限", code: HRErrorCode.PermissionDinied.rawValue, userInfo: nil))
			return
		}
		runOnGlobalQueue({
			self.base.doEditScenePanelBindings(scenePanel, result: result)
		})
	}
	
	///编辑用户信息
	func editUserInfo(user: HRUserInfo, newPasswd: String, origUserName: String?, origPasswd: String?, result:((NSError?)->Void)?) {
		if !HRDatabase.isEditPermission && user.isAdministrator {
			//登陆的不是管理员却要编辑管理员，这是禁止的，所以提示“没有权限”
			result?(NSError(domain: "没有权限", code: HRErrorCode.PermissionDinied.rawValue, userInfo: nil))
			return
		}
		runOnGlobalQueue({
			self.base.doUserManage(user, action: HRUserManagerAction.EditUserInfo, newPasswd: newPasswd, origUserName: origUserName, origPasswd: origPasswd, result: result)
		})
	}
	
	///编辑楼层信息
	func editFloorInfo(floor: HRFloorInfo, result: ((NSError?)->Void)?) {
		if !HRDatabase.isEditPermission {
			result?(NSError(domain: "没有权限", code: HRErrorCode.PermissionDinied.rawValue, userInfo: nil))
			return
		}
		runOnGlobalQueue({
			self.base.doCreateOrEditFloor(.EditFloorName, floor: floor, room: nil, result: result)
		})
	}
	
	///编辑房间信息
	func editRoomInfo(room: HRRoomInfo, inFloor: HRFloorInfo, result: ((NSError?)->Void)?) {
		if !HRDatabase.isEditPermission {
			result?(NSError(domain: "没有权限", code: HRErrorCode.PermissionDinied.rawValue, userInfo: nil))
			return
		}
		runOnGlobalQueue({
			self.base.doCreateOrEditFloor(.EditRoomName, floor: inFloor, room: room, result: result)
		})
	}
	
	///修改门锁密码
	///
	/// - parameter passwordForAdminstrator: 管理员密码
	/// - parameter passwordForOpen: 开锁密码
	func changeDoorLockPassword(doorLock: HRDoorLock, passwordForAdminstrator adminPasswd: String, passwordForOpen openPasswd: String, result: ((NSError?)->Void)?) {
		if !HRDatabase.isEditPermission {
			result?(NSError(domain: "没有权限", code: HRErrorCode.PermissionDinied.rawValue, userInfo: nil))
			return
		}
		runOnGlobalQueue({
			self.base.doChangeDoorLockPassword(doorLock, passwordForAdminstrator: adminPasswd, passwordForOpen: openPasswd, result: result)
		})
	}
	
	///设置传感器的联动动作值
	func setSensorActionValue(sensor: HRSensor, result: ((NSError?)->Void)?) {
		if !HRDatabase.isEditPermission {
			result?(NSError(domain: "没有权限", code: HRErrorCode.PermissionDinied.rawValue, userInfo: nil))
			return
		}
		runOnGlobalQueue({
			self.base.doSetSensorActionValue(sensor, result: result)
		})
	}
	
	///传感器联动绑定
	func bindSensorAction(sensor: HRSensor, bind: HRSensorBind, operateType: BindSensorOperateType, result: ((NSError?)->Void)?) {
		if !HRDatabase.isEditPermission {
			result?(NSError(domain: "没有权限", code: HRErrorCode.PermissionDinied.rawValue, userInfo: nil))
			return
		}
		//设备数量不能超过15个
		if bind.devInScenes.count > 15 {
			result?(NSError(domain: "最多只能绑定15个设备或情景", code: HRErrorCode.SensorBindTooMuchDevices.rawValue, userInfo: nil))
			return
		}
		runOnGlobalQueue({
			self.base.doBindSensorAction(sensor, bind: bind, operateType: operateType, result: result)
		})
	}
	
// MARK: - 删除设备
	
	/**删除本地设备*/
	func deleteLocalDevice(device: HRDevice){
		switch device.devType {
		case HRDeviceType.SmartBed.rawValue:
			let bed = device as! HRSmartBed
			if var smartBeds = HRDatabase.shareInstance().getDevicesOfType(HRDeviceType.SmartBed) {
				for (index, smartBed) in smartBeds.enumerate()
					where bed.name == smartBed.name
						&& bed.insRoomID == smartBed.insRoomID
						&& bed.insFloorID == smartBed.insFloorID{
					smartBeds.removeAtIndex(index)
				}
			}
		default:
			break
		}
	}
	
	/**删除远程设备*/
	func deleteRemoteDevice(devices: [HRDevice], result: ((NSError?)->Void)?){
		if HRDatabase.shareInstance().acount.permission != 2 && HRDatabase.shareInstance().acount.permission != 3 {
			result?(NSError(domain: "没有权限", code: HRErrorCode.PermissionDinied.rawValue, userInfo: nil))
			return
		}
		if devices.count == 0 {
			result?(NSError(domain: "没有指定要删除的设备", code: HRErrorCode.Other.rawValue, userInfo: nil))
			return
		}
		runOnGlobalQueue({
			self.base.doDeleteRemoteDevice(devices, result: result)
		})
	}
	
	///删除应用设备
	func deleteApplyDevice(appDevice: HRApplianceApplyDev, result: ((NSError?)->Void)?) {
		if HRDatabase.shareInstance().acount.permission != 2 && HRDatabase.shareInstance().acount.permission != 3 {
			result?(NSError(domain: "没有权限", code: HRErrorCode.PermissionDinied.rawValue, userInfo: nil))
			return
		}
		runOnGlobalQueue({
			self.base.doDeleteApplyDevice(appDevice, result: result)
		})
	}
	
	///删除情景
	///
	func removeScene(scene: HRScene, result: ((NSError?)->Void)?) {
		if HRDatabase.shareInstance().acount.permission != 2 && HRDatabase.shareInstance().acount.permission != 3 {
			result?(NSError(domain: "没有权限", code: HRErrorCode.PermissionDinied.rawValue, userInfo: nil))
			return
		}
		runOnGlobalQueue({
			self.base.doRemoveScene(scene, result: result)
		})
	}
	
	///删除情景
	///
	func removeScene(scene: HRScene) {
		removeScene(scene, result: nil)
	}
	
	///删除定时任务
	func removeTask(task: HRTask, result: ((NSError?)->Void)?) {
		if !HRDatabase.isEditPermission {
			result?(NSError(domain: "没有权限", code: HRErrorCode.PermissionDinied.rawValue, userInfo: nil))
			return
		}
		runOnGlobalQueue({
			self.base.doRemoveTask(task, result: result)
		})
	}
	
	///删除用户
	func deleteUser(user: HRUserInfo, result:((NSError?)->Void)?) {
		if !HRDatabase.isEditPermission{
			result?(NSError(domain: "没有权限", code: HRErrorCode.PermissionDinied.rawValue, userInfo: nil))
			return
		}
		runOnGlobalQueue({
			self.base.doUserManage(user, action: HRUserManagerAction.DeleteUser, newPasswd: "", origUserName: "", origPasswd: "", result: result)
		})
	}
	
	///删除楼层
	func deleteFloor(floor: HRFloorInfo, result: ((NSError?)->Void)?) {
		if !HRDatabase.isEditPermission{
			result?(NSError(domain: "没有权限", code: HRErrorCode.PermissionDinied.rawValue, userInfo: nil))
			return
		}
		runOnGlobalQueue({
			self.base.doDeleteFloor(floor, result: result)
		})
	}
	
	///删除房间
	func deleteRoom(room: HRRoomInfo, inFloor: HRFloorInfo, result: ((NSError?)->Void)?) {
		if !HRDatabase.isEditPermission{
			result?(NSError(domain: "没有权限", code: HRErrorCode.PermissionDinied.rawValue, userInfo: nil))
			return
		}
		runOnGlobalQueue({
			self.base.doCreateOrEditFloor(HRFloorManageActon.DeleteRoom, floor: inFloor, room: room, result: result)
		})
	}
	
	
//MARK: - 获取设备信息
    /**查询所有设备*/
    func queryAllDevice() {
        //开始查询
        queryDevice(HRDeviceType.Braodcast)
    }
	
	///获取设备信息
	///
	///- parameter type:: 设备类型
	///- parameter devAddr:: 要查询的设备的地址，如果是查询用户信息则填0xffffffff，如果查询楼层信息则填楼层ID
	///- parameter remove:: 是否要清空该种设备类型原有的所有数据（指本地缓存，非远程主机）
	func queryDevice(devType: HRDeviceType, devAddr: UInt32=0xFFFF_FFFF, remove: Bool=false) {
		queryDevice(devType.rawValue, devAddr: devAddr, remove: remove)
	}
	
	///获取设备信息
	///
	///- parameter type:: 设备类型
	///- parameter devAddr:: 要查询的设备的地址，如果是查询用户信息则填0xffffffff，如果查询楼层信息则填楼层ID
	///- parameter remove:: 是否要清空该种设备类型原有的所有数据（指本地缓存，非远程主机）
	func queryDevice(devType: Byte, devAddr: UInt32=0xFFFF_FFFF, remove: Bool=false) {
		if remove {
			if let type = HRDeviceType(rawValue: devType) {
				HRDatabase.shareInstance().remove(type)
			}
		}
		runOnGlobalQueue({
			self.base.queryDevice(devType, devAddr: devAddr)
		})
	}
    
    ///查询光照、燃气、温湿度空气、湿敏探测器的值，查询结果请会在HRSensorValuesDelegate中返回
    ///
    ///- parameter sensor: 传感器设备，支持
    func querySensorValue(sensor: HRDevice){
        if sensor.devType == HRDeviceType.SolarSensor.rawValue
            || sensor.devType == HRDeviceType.AirQualitySensor.rawValue
            || sensor.devType == HRDeviceType.GasSensor.rawValue
            || sensor.devType == HRDeviceType.HumiditySensor.rawValue{
            runOnGlobalQueue({
                self.base.doQuerySensorValue(sensor)
            })
        } else {
            Log.warn("querySensorValue:不支持查询设备\(sensor.devType)")
        }
    }
	
    
    ///检查更新主机固件版本-APP发送请求帧
    ///- parameter timeout: 超时时间,单位为秒
    func checkFirmwareVersion(timeout: Double, result: ((NSError?) -> Void)?) {
		runOnGlobalQueue({
            self.base.doCheckFirmwareVersion(timeout, result: result)
		})
	}
    ///发送一帧数据给主机表示要请求更新设备 - APP请求更新固件
    func UpDataVersion(timeout: Double, result: ((NSError?)->Void)?) {
        runOnGlobalQueue { () -> Void in
            self.base.doUpDataVersion(timeout, result: result)
        }
    }
}

