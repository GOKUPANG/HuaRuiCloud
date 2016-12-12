//
//  HRProcessCenter.swift
//  SmartBed
//
//  Created by sswukang on 15/7/10.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import Foundation


/**
协议帧处理中心，所有网络接收到的帧都会进入到本处理中心里，这些帧将在此处理之后通过注册的代理分发到各个对象中。
- 当接到`kNotificationDidSocketConnected`即Socket连接成功的通知时，处理中心就会自动启动并绑定当前socket,同时结束上一次(如果存在)绑定的Socket；
- 当绑定的socket断开连接之后（通过delegate而不是通知来得知连接断开了），处理暂停。
*/
class HRProcessCenter: NSObject, HRSocketConnectionDelegate {
     struct Delegates {
        ///继电器设备代理
        weak var relayBaseDeviceDelegate	: HRRelayBaseDeviceDelegate?
        ///情景代理
        weak var sceneUpdateDelegate		: HRSceneUpdateDelegate?
        weak var hr8000HelperDelegate	: HR8000HelperDelegate?
        ///传感器返回值
        weak var sensorValuesDelegate	: HRSensorValuesDelegate?
		///红外转发代理
		weak var infraredDelegate	: HRInfraredDelegate?
		///注册设备代理
		weak var registerDevicesDelegate : HRRegisterDevicesDelegate?
		///红外学习代理
		weak var infraredLearningDelegate: HRInfraredLearningDelegate?
		///红外学习代理
		weak var rgbLampDelegate: HRRGBLampDelegate?
    }
//MARK: - 公开属性
    var delegates  : Delegates
 
//MARK: - 私有属性
    private var _tag: Int?
    private var _process_queue: dispatch_queue_t
    private var _tcpConn: HRSocketConnection? {
        didSet {
            _tcpConn?.delegate = self
        }
    }
    

    private override init(){
        self.delegates     = Delegates()
		//创建一个处理线程队列，该队列是Serial类型，目的是防止写DeviceDatabase时竞争
        self._process_queue = dispatch_queue_create("com.huarui.hr8000process", DISPATCH_QUEUE_SERIAL)
		super.init()
		
		//注册网络连接通知
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HRProcessCenter.didSocketConnected(_:)), name: kNotificationDidSocketConnected, object: nil)
    }
	
	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}
    
    class func shareInstance() -> HRProcessCenter {
        struct Singleton{
            static var predicate: dispatch_once_t  = 0
            static var instance: HRProcessCenter?   = nil
        }
        dispatch_once(&Singleton.predicate, {
            Singleton.instance = HRProcessCenter()
        })
        return Singleton.instance!
    }
    
	
	///Socket连接了
	@objc private func didSocketConnected(notification: NSNotification) {
		if let tcpConn = notification.object as? HRSocketConnection {
			self.startProcess(tcpConn)
		}
	}
	
	
//MARK: - 控制方法
    
    ///开始工作
    func startProcess(connection: HRSocketConnection) {
		if self._tcpConn != nil {
			stopProcess()
		}
        self._tcpConn = connection
        self._tag = connection.receive(noTimeout: {
            (rcvFrame) in
			//Log.verbose("接收到一帧数据：\n\(rcvFrame.toTransmitFrame()!)")
            dispatch_async(self._process_queue, {
                self.process(rcvFrame)
            })
        })
        Log.info("HRProcessCenter startProcess.")
    }
    
    
    ///停止工作
    func stopProcess() {
        if let tag = self._tag {
            self._tcpConn?.unregisterReceive(tag)
        }
		_tag = nil
        Log.info("HRProcessCenter stopProcess.")
    }
    
    ///手动添加一帧数据
    func addFrame(frame: HRFrame) {
		dispatch_async(self._process_queue, {
			self.process(frame)
		})
    }

//MARK: - Socket代理方法
    ///正在尝试重连
    private var tryingRelogin = false
	
	///Socket连接了
	func socketConnection(socketDidConnected tcpConn: HRSocketConnection) {
		
	}
	
	/// Socket断开了
	func socketConnection(socketDidDisconnected tcpConn: HRSocketConnection) {
		self.stopProcess()
	}
	
	//网络可用
	func socketConnection(networkAvailable tcpConn: HRSocketConnection, type: Reachability.NetworkStatus) {
		if !self.tryingRelogin {
			self.tryingRelogin = true
			reLogin()
		}
	}
    
    ///重新登陆，只要不是用户主动注销的，该方法就会隔3秒钟调用一次
    private func reLogin() {
        if !HRDatabase.shareInstance().shouldOnline {
            Log.debug("shouldOnline = false")
            return
        }
        runOnGlobalQueue({
            let userName = HRDatabase.shareInstance().acount.userName
            let password = HRDatabase.shareInstance().acount.password
            HR8000Service.shareInstance().loginBackground(userName, password: password, result: {
                (error) in
                runOnGlobalQueue({
                    if error != nil {
                        Log.debug("重新登陆失败：\(error!.domain):\(error!.code)")
                        sleep(3)    //睡眠3秒
                        if self.tryingRelogin {
                            self.reLogin()
                        }
                    } else {
                        self.tryingRelogin = false
                        HR8000Service.shareInstance().queryAllDevice()
                    }
                })
            })
        })
    }
    
//MARK: - 方法
    
    ///本类的主角 查询设备信息
    private func process(frame: HRFrame) {
        
        switch frame.command {
        case HRCommand.ACK.rawValue:
            //确认接收成功
            Log.debug("————————————————ACK.(0x01)————————————————")
            Log.debug("——————————————————————————————————————————\n")
        case HRCommand.CommitDeviceState.rawValue:
            //设备主动上传状态
            Log.debug("————————Commit Device State.(0x02)————————")
			self.commitDeviceState(frame)
            Log.debug("——————————————————————————————————————————\n")
        case HRCommand.QueryDeviceInfo.rawValue:
            //设备信息查询：设备地址、设备类型、信道、版本
            Log.debug("——————————————查询设备信息.(0x03)—————————————")
            self.queryDeviceInfo(frame)
            Log.debug("————————————————————————————————————————————\n")
        case HRCommand.RegisterDevice.rawValue:
            //注册设备
            Log.debug("———————————————注册设备.(0x04)———————————————")
			registerDevices(frame)
            Log.debug("——————————————————————————————————————————\n")
        case HRCommand.DeleteDevice.rawValue:
            //删除设备
            Log.debug("——————————Delete Device.(0x05)————————————")
			deleteDevice(frame)
            Log.debug("——————————————————————————————————————————\n")
        case HRCommand.ScenePanelBinding.rawValue:
            //情景面板绑定设备
            Log.debug("————————Scene Panel Binding.(0x06)————————")
			self.editScenePanelBindings(frame)
            Log.debug("——————————————————————————————————————————\n")
        case HRCommand.ScenePanelUnbinding.rawValue:
            //情景面板解绑
            Log.debug("———————Scene Panel Unbinding.(0x07)———————")
            Log.debug("——————————————————————————————————————————\n")
        case HRCommand.CreateOrModifyScene.rawValue:
            //创建或修改情景
            Log.debug("———————Create or Modify Scene.(0x08)——————")
            self.modifyScene(frame)
            Log.debug("——————————————————————————————————————————\n")
        case HRCommand.DeleteScene.rawValue:
            //删除情景
            Log.debug("——————————Delete Scene.(0x09)—————————————")
            self.deleteScene(frame)
            Log.debug("——————————————————————————————————————————\n")
        case HRCommand.SetSystemParameter.rawValue:
            //设置系统参数：如信道、RF地址、IP
            Log.debug("———————Set System Parameter.(0x0A)————————")
            Log.debug("——————————————————————————————————————————\n")
        case HRCommand.QuerySystemParameter.rawValue:
            //查询系统参数：如信道、RF地址、IP
            Log.debug("——————Query System Parameter.(0x0B)———————")
            Log.debug("——————————————————————————————————————————\n")
        case HRCommand.EditDevUserInfo.rawValue:
            //编辑设备用户信息：如设备名称、位置
            Log.debug("——————Edit Device or User Info.(0x0C)———————")
			self.editDevOrUserInfo(frame)
            Log.debug("————————————————————————————————————————————\n")
        case HRCommand.Longin.rawValue:
            //登陆主机
            Log.debug("——————————————Login.(0x0D)————————————————")
            self.login(frame)
            Log.debug("——————————————————————————————————————————\n")
        case HRCommand.RemoteRegisterHost.rawValue:
            //远程注册主机
            Log.debug("———————Remote Register Host.(0x0E)—————————")
            Log.debug("———————————————————————————————————————————\n")
        case HRCommand.RemoteDeleteHost.rawValue:
            //远程删除主机
            Log.debug("———————Remote Delete Host.(0x0F)———————————")
            Log.debug("———————————————————————————————————————————\n")
        case HRCommand.UserManage.rawValue:
            //用户管理
            Log.debug("———————————User Manage.(0x10)——————————————")
			self.userManage(frame)
            Log.debug("———————————————————————————————————————————\n")
        case HRCommand.BindLoadToRelay.rawValue:
            //继电器绑定负载
            Log.debug("—————————————继电器绑定负载.(0x11)————————————————")
			self.relayBindLoad(frame)
            Log.debug("——————————————————————————————————————————————\n")
        case HRCommand.AddOrEditApplyDev.rawValue:
            //添加/编辑应用设备
            Log.debug("——————————添加/编辑应用设备.(0x12)—————————————")
			createOrModifyApplyDevice(frame)
            Log.debug("———————————————————————————————————————————\n")
        case HRCommand.DeleteApplyDev.rawValue:
            //删除应用设备
            Log.debug("—————————————删除应用设备.(0x13)——————————————")
			deleteApplyDevice(frame)
            Log.debug("———————————————————————————————————————————\n")
        case HRCommand.InfraredLearning.rawValue:
            //红外学习
            Log.debug("———————————————红外学习.(0x14)———————————————")
			self.infraredLearning(frame)
            Log.debug("———————————————————————————————————————————\n")
        case HRCommand.SetDoorLockPassword.rawValue:
            //设置门锁密码
            Log.debug("—————————————设置门锁密码.(0x15)——————————————")
            Log.debug("———————————————————————————————————————————\n")
        case HRCommand.SecurityBindState.rawValue:
            //安防联动绑定
            Log.debug("—————————————安防联动绑定.(0x16)—————————————")
            Log.debug("———————————————————————————————————————————\n")
        case HRCommand.HostLoginToServer.rawValue:
            //主机登陆到服务器
            Log.debug("———————————主机登陆到服务器.(0x17)————————————")
            Log.debug("———————————————————————————————————————————\n")
        case HRCommand.KeepAlive.rawValue:
            //心跳
            Log.debug("———————————————心跳.(0x18)——————————————————")
            Log.debug("———————————————————————————————————————————\n")
        case HRCommand.CreateOrEditFloorInfo.rawValue:
            //创建/编辑楼层
            Log.debug("—————————————创建/编辑楼层.(0x19)—————————————")
			self.createOrEditFloor(frame)
            Log.debug("———————————————————————————————————————————\n")
        case HRCommand.DeleteFloor.rawValue:
            //删除楼层
            Log.debug("———————————————删除楼层.(0x1A)———————————————")
			self.deleteFloor(frame)
            Log.debug("———————————————————————————————————————————\n")
        case HRCommand.SlaveLoginToHost.rawValue:
            //从机登陆到主主机
            Log.debug("———————————从机登陆到主主机.(0x1B)—————————————")
            Log.debug("———————————————————————————————————————————\n")
        case HRCommand.HostAndSlaveSync.rawValue:
            //主机从机信息同步
            Log.debug("————————————主机从机信息同步.(0x1C)————————————")
            Log.debug("———————————————————————————————————————————\n")
        case HRCommand.RemoteUpgrade.rawValue:
            //远程升级
            Log.debug("———————————————远程升级.(0x1D)——————————————")
            Log.debug("———————————————————————————————————————————\n")
        case HRCommand.OperateSwitchPanel.rawValue:
            //控制智能开关的继电器(带延时)
            Log.debug("——————————控制智能开关的继电器.(0x1E)—————————")
			operateRelay(frame)
            Log.debug("———————————————————————————————————————————\n")
        case HRCommand.StartScene.rawValue:
            //启动情景
            Log.debug("——————————————启动情景.(0x1F)———————————————")
            Log.debug("———————————————————————————————————————————\n")
        case HRCommand.OperateRelayCtrlBox.rawValue:
            //控制继电器控制盒
            Log.debug("——————————控制继电器控制盒.(0x20)————————————")
            self.operateRelay(frame)
            Log.debug("——————————————————————————————————————————\n")
        case HRCommand.OprateSocketPanel.rawValue:
            //控制智能插座
            Log.debug("————————————控制智能插座.(0x21)—————————————")
			self.operateRelay(frame)
            Log.debug("——————————————————————————————————————————\n")
        case HRCommand.OprateRGBLamp.rawValue:
            //控制RGB灯
            Log.debug("—————————————控制RGB灯.(0x22)——————————————")
			self.operateRGBLamp(frame)
            Log.debug("——————————————————————————————————————————\n")
        case HRCommand.BluetoothCtrl.rawValue:
            //蓝牙遥控制器
            Log.debug("————————————蓝牙遥控制器.(0x23)—————————————")
            Log.debug("——————————————————————————————————————————\n")
        case HRCommand.InfraredTransmit.rawValue:
            //红外转发
            Log.debug("—————————————红外转发.(0x24)————————————————")
			self.infTransmitUnit(frame)
            Log.debug("———————————————————————————————————————————\n")
        case HRCommand.MotorCtrl.rawValue:
            //窗帘控制器
            Log.debug("—————————————窗帘控制器.(0x25)——————————————")
            Log.debug("——————————————————————————————————————————\n")
        case HRCommand.InfraredDetector.rawValue:
            //红外入侵探测器
            Log.debug("————————————红外入侵探测器.(0x26)————————————")
            Log.debug("———————————————————————————————————————————\n")
        case HRCommand.DoorMagCard.rawValue:
            //智能门磁
            Log.debug("——————————————智能门磁.(0x27)———————————————")
            Log.debug("———————————————————————————————————————————\n")
        case HRCommand.DoorLock.rawValue:
            //智能门锁
            Log.debug("——————————————智能门锁.(0x28)———————————————")
            Log.debug("———————————————————————————————————————————\n")
        case HRCommand.DoorBell.rawValue:
            //智能门铃
            Log.debug("——————————————智能门铃.(0x29)———————————————")
            Log.debug("———————————————————————————————————————————\n")
        case HRCommand.QuerySensorValue.rawValue:
            //查询光照/燃气/温湿度空气/湿敏探测器
            Log.debug("————查询光照/燃气/温湿度空气/湿敏探测器.(0x2A)—————")
            self.querySensorValue(frame)
            Log.debug("——————————————————————————————————————————————\n")
        case HRCommand.AdjustSolarSensor.rawValue:
            //校准光照探测器（0x2b）
            Log.debug("————————————校准光照探测器.(0x2B)————————————")
            Log.debug("———————————————————————————————————————————\n")
        case HRCommand.SetSensorBindValue.rawValue:
            //设置光照/燃气/温湿度空气探测器联动动作值（0x2c）
            Log.debug("————设置光照/燃气/温湿度空气探测器联动动作值.(0x2C)———")
			self.setSensorActionValue(frame)
            Log.debug("———————————————————————————————————————————————\n")
        case HRCommand.SensorBindDevice.rawValue:
            //光照/燃气/温湿度空气/湿敏探测器联动绑定（0x2d）
            Log.debug("————光照/燃气/温湿度空气/湿敏探测器联动绑定.(0x2D)———")
			self.sensorBindDevices(frame)
            Log.debug("——————————————————————————————————————————————\n")
        case HRCommand.Manipulator.rawValue:    //机械手
            //机械手
            Log.debug("——————————————控制机械手.(0x2E)—————————————")
			Log.debug("————————————————————————————————————————\n")
		case HRCommand.SmartBed.rawValue:
			//智能床
			Log.debug("——————————————控制智能床.(0x30)—————————————")
			Log.debug("————————————————————————————————————————\n")
		case HRCommand.LiveWireSwitch.rawValue:
			//单火开关
			Log.debug("——————————————控制单火开关.(0x32)—————————————")
			self.operateLiveFireSwitch(frame)
			Log.debug("————————————————————————————————————————\n")
        case HRCommand.UpdateFirmware.rawValue:
            //升级智能主机固件
            Log.debug("—————————————升级智能主机固件.(0x33)————————————\n")
            
            
        case HRCommand.GaoDunDoor.rawValue:
            
            Log.debug("——————————————控制高盾智能锁.(0x34)—————————————")
            Log.debug("————————————————————————————————————————\n")
            //无论是否有更新存在，主机都要将结果告诉APP(接收主机数据)
            self.operateUpdateFirmware(frame)
            Log.debug("—————————————————————————————————————————————\n")
        case HRCommand.BraodcastSearchHost.rawValue:
            //APP广播查找主机
            Log.debug("—————————————APP广播查找主机.(0x5A)—————————————")
            Log.debug("—————————————————————————————————————————————\n")
        case HRCommand.AddOrEditCamera.rawValue:
            //添加/编辑摄像头（0x5c）
            Log.debug("—————————————添加/编辑摄像头.(0x5C)———————————")
            Log.debug("——————————————————————————————————————————\n")
        case HRCommand.DeleteCamera.rawValue:
            //删除摄像头（0x5d）
            Log.debug("———————————————删除摄像头.(0x5D)—————————————")
            Log.debug("——————————————————————————————————————————\n")
        case HRCommand.SetOrEditAlarmTask.rawValue:
            //设置/编辑定时任务（0x5e）
            Log.debug("——————————设置/编辑定时任务.(0x5E)————————————")
			self.setOrEditTask(frame)
            Log.debug("—————————————————————————————————————————\n")
        case HRCommand.DeleteAlarmTask.rawValue:
            //删除定时任务（0x5f）
            Log.debug("—————————————删除定时任务.(0x5F)—————————————")
			self.deleteTask(frame)
            Log.debug("—————————————————————————————————————————\n")
            
        case let cmd where cmd >= 128:    //异常帧
			Log.debug("—————————————异常帧.(\(frame.command))—————————————")
			Log.debug("—————————————————————————————————————————\n")
            if let exception = frame.exception {
                Log.warn("接收到异常帧：\(exception.domain)(\(exception.code))")
                runOnMainQueue({
                    self.delegates.hr8000HelperDelegate?.hr8000Helper?(receiveExceptionFrame: frame, exception: exception)
                })
            }
        default:
            Log.debug("——————————————未知控制码\(frame.command)—————————————")
            Log.debug("———————————————————————————————————————\n")
        }
    }
    
    
//MARK: - 数据处理
	
	//MARK: - 0x02 主机主动上送设备状态
	private func commitDeviceState(frame: HRFrame){
		parseDataThatUploadFromHost(frame.srcAddr, data: frame.data)
	}
	
	/**
	解析主机主动上送设备的数据
	
	- parameter hostAddr: 主机地址
	- parameter data:     数据域, 第0字节为设备类型，第1到第3字节为设备地址，剩余字节，参考协议。
	*/
	private func parseDataThatUploadFromHost(hostAddr: UInt32, data: [Byte]) {
		let devType = data[0]
		let devAddr = UInt32(fourBytes: Array(data[1...4]))
		let device = HRDatabase.shareInstance().getDevice(devType, devAddr: devAddr)
		
		switch device {
		case let relayBox as HRRelayComplexes:
			relayBox.states = data[5]
//		case HRDeviceType.RGBLamp.rawValue:
			
		case let curtain as HRCurtainCtrlDev:
			curtain.setState(data[5])
		case let manipulator as HRManipulator:
			manipulator.setState(data[5])
		case let detector as HRInfraredDetector:
			detector.protectStatus = data[5]
			detector.status = data[6]
//		case let magCard as HRDoorMagCard:
//			magCard.protectStatus = data[5]
//			magCard.status = data[6]
		case let lock as HRDoorLock:
			lock.protectStatus = data[5]
			lock.status = data[6]
            
          //斌添加 门锁相关 这里设置 布防码和状态码
            
        case let smartLock as HRSmartDoor:
            
            smartLock.protectStatus = data[5]
            smartLock.status = data[6]
            
            
		case let bell as HRDoorBell:
			bell.protectStatus = data[5]
			bell.status = data[6]
		case is HRSolarSensor:
			runOnMainQueue({
				self.delegates.sensorValuesDelegate?.sensorValues?(SolarValueResult: devAddr, lux: UInt16(twoBytes: Array(data[5...6])), tag: 0)
			})
		case is HRGasSensor:
			runOnMainQueue({
				let value = UInt16(twoBytes: Array(data[5...6]))
				self.delegates.sensorValuesDelegate?.sensorValues?(gasLELValueResult: devAddr, lel: Float(value)/10, tag: 0)
			})
		default:
			Log.warn("找不到对应设备，或设备未支持, 类型：(\(devType))")
			return
		}
		if let dev = device {
			runOnMainQueue({
				self.delegates.hr8000HelperDelegate?.hr8000Helper?(commitDeviceState: dev)
			})
		}
	}
	
    
    
    //斌  返回的帧 查询设备
    //MARK: - 0x03 查询设备信息
    private func queryDeviceInfo(frame: HRFrame) {
        var data = frame.data
        Log.debug("设备个数啊哈哈：\(data[0])")
        
        
        
        if data[0] == 0 {
            //查询结束
			//发送广播
			NSNotificationCenter.defaultCenter().postNotificationName(kNotificationQueryDone, object: nil)
			//代理
            runOnMainQueue({
                self.delegates.hr8000HelperDelegate?.hr8000Helper?(finishedQueryDeviceInfo: true)
            })
            return
        }
        let deviceDatas = HRDatabase.shareInstance()
        let devCount = data.removeAtIndex(0) //取出设备数量的字节
        let hostAddr = frame.srcAddr
        var device : HRDevice?
        var devices: [HRDevice]?
        var index  : Int?
        for _ in 0..<devCount {
            switch data[0] {
				//智能主机类型，0x00
            case HRDeviceType.Master.rawValue:
				let (master, len) = HRMaster.initWithDataFrame(hostAddr, frame: data)
				deviceDatas.master = master
                index   = 0
                devices = [master]
                device  = master
				data.removeRange(0..<len)
              //  print("获取到得主机设备的帧是\(data)")
                
				//智能开关，0x01
			case HRDeviceType.SwitchPanel.rawValue:
				let (switchPanel, len) = HRSwitchPanel.initWithDataFrame(hostAddr, dataFrame: data)
				let ret = HRDatabase.shareInstance().saveDevice(switchPanel)
                devices = ret.0
                index   = ret.1
                device  = switchPanel
				data.removeRange(0..<len)
                
                
				//情景面板,0x02
			case HRDeviceType.ScenePanel.rawValue:
				let (panel, len) = HRScenePanel.ininWithDataFrame(hostAddr, dataFrame: data)
				let ret = HRDatabase.shareInstance().saveDevice(panel)
				devices = ret.0
				index   = ret.1
				device  = panel
				data.removeRange(0..<len)
                //智能插座,0x03
            case HRDeviceType.SocketPanel.rawValue:
                let (socketPanel, len) = HRSocketPanel.initWithDataFrame(hostAddr, dataFrame: data)
				let ret = HRDatabase.shareInstance().saveDevice(socketPanel)
				devices = ret.0
				index   = ret.1
                device  = socketPanel
				data.removeRange(0..<len)
				//继电器控制盒,0x04
			case HRDeviceType.RelayControlBox.rawValue:
				let (relayBox, len) = HRRelayCtrlBox.initWithDataFrame(hostAddr, dataFrame: data)
				let ret = HRDatabase.shareInstance().saveDevice(relayBox)
				devices = ret.0
				index   = ret.1
				device  = relayBox
				data.removeRange(0..<len)
			case HRDeviceType.RGBLamp.rawValue:
				let (lamp, len) = HRRGBLamp.initWithDataFrame(hostAddr, dataFrame: data)
				let ret = HRDatabase.shareInstance().saveDevice(lamp)
				devices = ret.0
				index   = ret.1
				device  = lamp
				data.removeRange(0..<len)
				//蓝牙遥控器,0x06
			case HRDeviceType.BluetoothControlUnit.rawValue:
				let (unit, len) = HRBluetoothCtrlUnit.initWithDataFrame(hostAddr, dataFrame: data)
				let ret = HRDatabase.shareInstance().saveDevice(unit)
				devices = ret.0
				index   = ret.1
				device  = unit
				data.removeRange(0..<len)
                //红外转发器,0x07
            case HRDeviceType.InfraredTransmitUnit.rawValue:
                let (unit, len) = HRInfraredTransmitUnit.initWithDataFrame(hostAddr, dataFrame: data)
				let ret = HRDatabase.shareInstance().saveDevice(unit)
				devices = ret.0
				index   = ret.1
                device  = unit
                data.removeRange(0..<len)
				//窗帘控制器,0x08
			case HRDeviceType.CurtainControlUnit.rawValue:
				let (curtain, len) = HRCurtainCtrlDev.initWithDataFrame(hostAddr, dataFrame: data)
				let ret = HRDatabase.shareInstance().saveDevice(curtain)
				devices = ret.0
				index   = ret.1
				device  = curtain
				data.removeRange(0..<len)
				//红外入侵探测器,0x09
			case HRDeviceType.InfraredDetectorUnit.rawValue:
				let (detector, len) = HRInfraredDetector.initWithDataFrame(HRDeviceType.InfraredDetectorUnit.rawValue, hostAddr: hostAddr, frame: data)
				let ret = HRDatabase.shareInstance().saveDevice(detector)
				devices = ret.0
				index   = ret.1
				device  = detector
				data.removeRange(0..<len)
				//智能门磁,0x0A
			case HRDeviceType.DoorMagCard.rawValue:
				let (magCard, len) = HRDoorMagCard.initWithDataFrame(HRDeviceType.DoorMagCard.rawValue, hostAddr: hostAddr, frame: data)
				let ret = HRDatabase.shareInstance().saveDevice(magCard)
				devices = ret.0
				index   = ret.1
				device  = magCard
				data.removeRange(0..<len)
				//智能门锁,0x0B
			case HRDeviceType.DoorLock.rawValue:
				let (lock, len) = HRDoorLock.initWithDataFrame(HRDeviceType.DoorLock.rawValue, hostAddr: hostAddr, frame: data)
				let ret = HRDatabase.shareInstance().saveDevice(lock)
				devices = ret.0
				index   = ret.1
				device  = lock
				data.removeRange(0..<len)
                
                
                //斌 门锁相关 查询设备返回的高盾锁的个数以及锁的信息
                
            case HRDeviceType.GaoDunDoor.rawValue:
                let (GaoDunDoor,len) = HRSmartDoor.initWithDataFrame(HRDeviceType.GaoDunDoor.rawValue, hostAddr: hostAddr, frame: data)
                let ret = HRDatabase.shareInstance().saveDevice(GaoDunDoor)
                
                devices = ret.0
                
                //下标 表示第几个锁
                
                index = ret.1
                device = GaoDunDoor
                
                data.removeRange(0..<len)

                

                
                
                
				//智能门铃,0x0C
			case HRDeviceType.DoorBell.rawValue:
				let (bell, len) = HRDoorBell.initWithDataFrame(HRDeviceType.DoorBell.rawValue, hostAddr: hostAddr, frame: data)
				let ret = HRDatabase.shareInstance().saveDevice(bell)
				devices = ret.0
				index   = ret.1
				device  = bell
				data.removeRange(0..<len)
				//光照传感器,0x0d
			case HRDeviceType.SolarSensor.rawValue:
				let (solar, len) = HRSolarSensor.initWithDataFrame(hostAddr, dataFrame: data)
				let ret = HRDatabase.shareInstance().saveDevice(solar)
				devices = ret.0
				index   = ret.1
				device  = solar
				data.removeRange(0..<len)
				//可燃气探测器,0x0e
			case HRDeviceType.GasSensor.rawValue:
				let (gas, len) = HRGasSensor.initWithDataFrame(hostAddr, dataFrame: data)
				let ret = HRDatabase.shareInstance().saveDevice(gas)
				devices = ret.0
				index   = ret.1
				device  = gas
				data.removeRange(0..<len)
				//温湿度空气质量探测器,0x0f
			case HRDeviceType.AirQualitySensor.rawValue:
				let (aqs, len) = HRAirQualitySensor.initWithDataFrame(hostAddr, dataFrame: data)
				let ret = HRDatabase.shareInstance().saveDevice(aqs)
				devices = ret.0
				index   = ret.1
				device  = aqs
				data.removeRange(0..<len)
				//湿敏探测器,0x10
			case HRDeviceType.HumiditySensor.rawValue:
				let (hum, len) = HRHumiditySensor.initWithDataFrame(hostAddr, dataFrame: data)
				let ret = HRDatabase.shareInstance().saveDevice(hum)
				devices = ret.0
				index   = ret.1
				device  = hum
				data.removeRange(0..<len)
				//机械手,0x11
			case HRDeviceType.Manipulator.rawValue:
				let (manip, len) = HRManipulator.initWithDataFrame(hostAddr, dataFrame: data)
				let ret = HRDatabase.shareInstance().saveDevice(manip)
				devices = ret.0
				index   = ret.1
				device  = manip
				data.removeRange(0..<len)
				//智能床，0x12
			case HRDeviceType.SmartBed.rawValue:
				let (bed, len) = HRSmartBed.initWithDataFrame(hostAddr, dataFrame: data)
				let ret = HRDatabase.shareInstance().saveDevice(bed)
				devices = ret.0
				index   = ret.1
				device  = bed
				data.removeRange(0..<len)
				//单火开关
			case HRDeviceType.LiveWireSwitch.rawValue:
				let (swh, len) = HRLiveWireSwitch.initWithDataFrame(hostAddr, dataFrame: data)
				let ret = HRDatabase.shareInstance().saveDevice(swh)
				devices = ret.0
				index   = ret.1
				device  = swh
				data.removeRange(0..<len)
                
                
                
                
                
                
                
                
                
                
                
                
                
                //用户信息,0xF8
            case HRDeviceType.UserInfo.rawValue:
                let (user, len) = HRUserInfo.initWithDataFrame(dataFrame: data)
				let ret = HRDatabase.shareInstance().saveDevice(user)
				devices = ret.0
				index   = ret.1
                device  = user
                data.removeRange(0..<len)
                //楼层信息,0xF9
            case HRDeviceType.FloorInfo.rawValue:
                let (floor, len) = HRFloorInfo.initWithDataFrame(dataFrame: data)
				let ret = HRDatabase.shareInstance().saveDevice(floor)
				devices = ret.0
				index   = ret.1
                device  = floor
                data.removeRange(0..<len)
                //应用设备。如用户的电视、空调、机顶盒、摄像头,0xFA
            case HRDeviceType.ApplyDevice.rawValue:
                let (apply, len) = HRApplianceApplyDev.initWithDataFrame(hostAddr, dataFrame: data)
				let ret = HRDatabase.shareInstance().saveDevice(apply)
				devices = ret.0
				index   = ret.1
                device  = apply
                data.removeRange(0..<len)
				//定时任务，0xFC
			case HRDeviceType.Task.rawValue:
				let (task, len) = HRTask.initWithDataFrame(hostAddr, dataFrame: data)
				let ret = HRDatabase.shareInstance().saveDevice(task)
				devices = ret.0
				index   = ret.1
				device  = task
				data.removeRange(0..<len)
				//情景,0xFD
			case HRDeviceType.Scene.rawValue:
				let (scene, len) = HRScene.initWithDataFrame(HRCommand.QueryDeviceInfo.rawValue, hostAddr: hostAddr, dataFrame: data)
				if let scene = scene {
					let ret = HRDatabase.shareInstance().saveDevice(scene)
					devices = ret.0
					index   = ret.1
					device  = scene
					data.removeRange(0..<len!)
				}
            default:
				let typestr = NSString(format: "0x%X", data[0])
                Log.warn("未支持的设备，类型：\(typestr)。放弃解析！")
            }
            if device != nil && devices != nil && index != nil {
                runOnMainQueue({
                    self.delegates.hr8000HelperDelegate?.hr8000Helper?(queryDeviceInfo: device!, indexOfDatabase: index!, devices: devices!)
                })
            }
        }
    }
	//MARK: - 0x04 注册设备
	private func registerDevices(frame: HRFrame) {
		let registerCode = frame.data[0]
//		Log.debug("注册返回状态：\(registerCode)")
		Log.info("\n↓↓↓↓ 主机返回注册状态：（0x0\(registerCode)）， 帧数据：\n\(frame.toString())")
		if registerCode == 0x02 && frame.data.count >= 6{
			let devType = frame.data[1]
			let devAddr = UInt32(fourBytes: Array(frame.data[2...5]))
			runOnMainQueue({
				self.delegates.registerDevicesDelegate?.registerDevices(devType, hostAddr: frame.srcAddr, deviceInfo: devAddr)
			})
		} else if registerCode == 0x03 && frame.data.count >= 6 {
			let devType = frame.data[1]
			let devAddr = UInt32(fourBytes: Array(frame.data[2...5]))
			parseDataThatUploadFromHost(frame.srcAddr, data: Array(frame.data[1..<frame.data.count]))
			//查询设备， 因为有可能是别的手机注册的，所以有必要查询
			if let type = HRDeviceType(rawValue: devType) {
				HR8000Service.shareInstance().queryDevice(type, devAddr: devAddr, remove: false)
			}
			let device = HRDevice()
			device.devType = devType
			device.devAddr = devAddr
			device.hostAddr = frame.srcAddr
			runOnMainQueue({
				self.delegates.registerDevicesDelegate?.registerDevices(devType, newDevice: device, data: frame.data)
			})
		} else if registerCode == 0x04 {
			runOnMainQueue({
				self.delegates.registerDevicesDelegate?.registerDevices(true)
			})
		}
	}
	//MARK: - 0x05 删除设备
	private func deleteDevice(frame: HRFrame) {
		let devAddr = UInt32(fourBytes: Array(frame.data[1...4]))
		
		if let type = HRDeviceType(rawValue: frame.data[0]) {
			if let device = HRDatabase.shareInstance().removeDevice(type, devAddr: devAddr) {
				NSNotificationCenter.defaultCenter().postNotificationName(kNotificationDeviceDidDeleted, object: device)
				runOnMainQueue({
					self.delegates.hr8000HelperDelegate?.hr8000Helper?(didDeleteDevice: device)
				})
				runOnGlobalQueue({
					DeviceUseFrequency.removeDevice(
						HRDatabase.shareInstance().acount.userName,
						device: device
					)
				})
			}
		}
		
	}
	
	//MARK: - 0x06 情景面板绑定设备
	private func editScenePanelBindings(frame: HRFrame) {
		if frame.data.count > 4 {
			let devAddr = UInt32(fourBytes: Array(frame.data[0...3]))
			HR8000Service.shareInstance().queryDevice(HRDeviceType.ScenePanel, devAddr: devAddr, remove: false)
		}
	}
	
    //MARK: - 0x08 创建或修改情景
    private func modifyScene(frame: HRFrame) {
        let (newSceneRet, _) = HRScene.initWithDataFrame(frame.command, hostAddr: frame.srcAddr, dataFrame: frame.data)
        if let newScene = newSceneRet {
            //判断该情景是否存在数组中
			if let _ = HRDatabase.shareInstance().getScene(sceneId: newScene.id) {
				Log.verbose("修改了情景：\(newScene.name)")
				let (newScenes, idx) = HRDatabase.shareInstance().saveDevice(newScene)
				if let sceneUpdateDelegate = self.delegates.sceneUpdateDelegate where newScenes is [HRScene] {
					runOnMainQueue({
						sceneUpdateDelegate.sceneUpdate?(sceneByModify: newScene, indexOfDatabase: idx, newScenes: newScenes as! [HRScene])
					})
				}
				return
			}
            //不存在，说明newScene是新创建的
            Log.verbose("创建了情景：\(newScene.name)")
			HRDatabase.shareInstance().saveDevice(newScene)
			if let scenes = HRDatabase.shareInstance().getDevicesOfType(.Scene) as? [HRScene] {
				runOnMainQueue({
					self.delegates.sceneUpdateDelegate?.sceneUpdate?(sceneByCreate: newScene, newScenes: scenes)
				})
			}
            return
        }
    }

    //MARK: - 0x09 删除情景
    private func deleteScene(frame: HRFrame) {
        let sceneId = frame.data[0]
		if let sceneByRm = HRDatabase.shareInstance().removeScene(id: sceneId) {
			NSNotificationCenter.defaultCenter().postNotificationName(kNotificationDeviceDidDeleted, object: sceneByRm.0)
			if let scenes = HRDatabase.shareInstance().getDevicesOfType(.Scene) as? [HRScene] {
				runOnMainQueue({
					self.delegates.sceneUpdateDelegate?.sceneUpdate?(sceneByDelete: sceneByRm.0, indexOfDatabase: sceneByRm.1, newScenes: scenes)
				})
			}
			return
		}
    }
	
	//MARK: - 0x0C 编辑设备或用户信息
	private func editDevOrUserInfo(frame: HRFrame) {
		if frame.data.count < 6 {
			Log.error("editDevOrUserInfo：数据域不足6，无法解析")
			return
		}
		let devType = frame.data[1]
		let devAddr = UInt32(fourBytes: Array(frame.data[2...5]))
		HR8000Service.shareInstance().queryDevice(devType, devAddr: devAddr, remove: false)
	}
    
    //MARK: - 0x0D 登陆主机
    private func login(frame: HRFrame) {
        if let acount = HRAcount.initWithDataFrame(frameData: frame.data) {
            HRDatabase.shareInstance().acount = acount
            if let _ = acount.loginSuccessful() {
//                self.delegates.hr8000HelperDelegate?.hr8000Helper?(userLoginFailure: error)
            } else {
                self.delegates.hr8000HelperDelegate?.hr8000Helper?(didUserLogin: acount)
				NSNotificationCenter.defaultCenter().postNotificationName(kNotificationUserDidLogined, object: acount)
            }
        } else {
//            let error = NSError(domain: "数据异常", code: HRErrorCode.DataError.rawValue, userInfo: nil)
//            self.delegates.hr8000Helper?.hr8000Helper?(userLoginFailure: error)
        }
    }
	
	//MARK: - 0x10 用户管理
	private func userManage(frame: HRFrame) {
		if frame.data.count < 2 { return }
		let success = frame.data.last! == 0x00
		switch frame.data[0] {
		case 0x01 where success:
			HR8000Service.shareInstance().queryDevice(HRDeviceType.UserInfo)
		case 0x02, 0x04  where success:
			if frame.data.count < 98 {
				HR8000Service.shareInstance().queryDevice(HRDeviceType.UserInfo)
				return
			}
			//检查更改的是否是当前用户
			var localUser: HRUserInfo?  //当前登陆的用户
			if let users = HRDatabase.shareInstance().getDevicesOfType(.UserInfo) as? [HRUserInfo] {
				for user in users where user.name == HRDatabase.shareInstance().acount.userName {
					localUser = user
				}
			}
			
			//被更改用户的原本名字
			let origName = ContentHelper.encodeGbkData(Array(frame.data[2...33]))
			if let locUser = localUser where origName == locUser.name {
				//更改的是当前登陆的用户，则进一步判断是否修改了名字或密码
                let newName  = ContentHelper.encodeGbkData(Array(frame.data[51...82]))
				let newPasswd = ContentHelper.encodeGbkData(Array(frame.data[83...98]))
				Log.debug("origName:\(origName), newName:\(newName), newPasswd:\(newPasswd)")
				if origName != newName || newPasswd != HRDatabase.shareInstance().acount.password {
					//要求用户重新登陆
					Log.error("当前用户信息更改，必须重新登陆！")
					runOnMainQueue({
						(UIApplication.sharedApplication().delegate as! AppDelegate).mustPopToRootViewController("当前用户信息已更改，必须重新登陆！")
					})
					return
				}
			}
			HR8000Service.shareInstance().queryDevice(HRDeviceType.UserInfo)
		case 0x03 where success:		//删除用户
			let userID = frame.data[1]
			if let user = HRDatabase.shareInstance().removeDevice(HRDeviceType.UserInfo, devAddr: UInt32(userID)) {
                
                
              //  print("删除用户“\(user.name)”, id:\(userID)")
                
                
				Log.info("删除用户“\(user.name)”, id:\(userID)")
				runOnMainQueue({
					self.delegates.hr8000HelperDelegate?.hr8000Helper?(didDeleteDevice: user)
					
					if user.name == HRDatabase.shareInstance().acount.userName{
						(UIApplication.sharedApplication().delegate as! AppDelegate).mustPopToRootViewController("当前用户已被删除，请使用其他账号登陆")
					}
				})
			}
		default: break
		}
	}
	
	
	//MARK: - 0x11 继电器绑定负载
	
	private func relayBindLoad(frame: HRFrame) {
		let devType = frame.data[0]
		let devAddr = UInt32(fourBytes: Array(frame.data[1...4]))
		//查询设备信息
		HR8000Service.shareInstance().queryDevice(devType, devAddr: devAddr, remove: false)
	}
	
	//MARK: - 0x12 添加/编辑应用设备
	private func createOrModifyApplyDevice(frame: HRFrame) {
		//查询设备信息
		HR8000Service.shareInstance().queryDevice(HRDeviceType.ApplyDevice, remove: false)
	}
	
	//MARK: - 0x13 删除应用设备
	private func deleteApplyDevice(frame: HRFrame) {
		if frame.data.count < 4 {
			Log.error("deleteApplyDevice：frame数据域小于4")
			return
		}
		let success = frame.data[0] == 0x01 ? false : true
		let appDevType = frame.data[1]
		let appDevId = UInt32(UInt16(twoBytes: Array(frame.data[2...3])))
		if let appDevice = HRDatabase.shareInstance().removeApplyDevice(appDevType, id: appDevId) {
			let result = success ? "成功" : "失败"
			Log.info("删除【\(appDevice.name)】: \(result)")
			if success {
				NSNotificationCenter.defaultCenter().postNotificationName(kNotificationDeviceDidDeleted, object: appDevice)
				runOnMainQueue({
					self.delegates.hr8000HelperDelegate?.hr8000Helper?(didDeleteDevice: appDevice)
				})
				runOnGlobalQueue({
					DeviceUseFrequency.removeDevice(
						HRDatabase.shareInstance().acount.userName,
						device: appDevice
					)
				})
			}
		}
	}
	
	//MARK: - 0x14 红外学习
	private func infraredLearning(frame: HRFrame) {
		if frame.data.count < 1 {
			Log.error("接收的帧数据域长度不足(\(frame.data.count))！")
			return
		}
		switch frame.data[0] {
		case 0x00:
			if frame.data.count >= 9 {
				let appDevType = frame.data[1]
				let appDevID   = UInt16(twoBytes: Array(frame.data[2...3]))
				let hostAddr   = UInt32(fourBytes: Array(frame.data[4...7]))
				let success    = frame.data[8] == 0x00
				runOnMainQueue({
					self.delegates.infraredLearningDelegate?.infraredLearning?(learningClone: appDevType, appDevID: appDevID, hostAddr: hostAddr, success: success)
				})
			} else {
				Log.error("处理红外学习时流程0的数据域长度不对，len=\(frame.data.count)")
			}
		case 0x01:	//请求开始学习
			if frame.data.count >= 2 {
				runOnMainQueue({
					self.delegates.infraredLearningDelegate?.infraredLearning?(learningStart: frame.data[1] == 0x00)
				})
			} else {
				Log.error("处理红外学习时流程1的数据域长度不对，len=\(frame.data.count)")
			}
		case 0x02:	//请求按键学习
			if frame.data.count >= 10 {
				let appDevType = frame.data[1]
				let appDevID   = UInt16(twoBytes: Array(frame.data[2...3]))
				let keyCode    = frame.data[4]
				let success    = frame.data[9] == 0x00
				runOnMainQueue({
					self.delegates.infraredLearningDelegate?.infraredLearning?(recordKey: appDevType, appDevID: appDevID, keyCode: keyCode, success: success)
				})
			} else {
				Log.error("处理红外学习时流程2的数据域长度不对，len=\(frame.data.count)")
			}
		case 0x03:	//请求结束学习
			if frame.data.count >= 4 {
				let appDevType = frame.data[1]
				let appDevID   = UInt16(twoBytes: Array(frame.data[2...3]))
				runOnMainQueue({
					self.delegates.infraredLearningDelegate?.infraredLearning?(learningStop: appDevType, apDevID: appDevID)
				})
				//查询设备
				HR8000Service.shareInstance().queryDevice(
					HRDeviceType.ApplyDevice,
					devAddr: UInt32(appDevID)
				)
			} else {
				Log.error("处理红外学习时流程3的数据域长度不对，len=\(frame.data.count)")
			}
		case 0x04:	//使用码库匹配
			if frame.data.count >= 10 {
				//查询设备
				HR8000Service.shareInstance().queryDevice(
					HRDeviceType.ApplyDevice,
					devAddr: UInt32(fourBytes: [frame.data[2], frame.data[3], 0, 0])
				)
			} else {
				Log.error("处理红外学习时流程4的数据域长度不对，len=\(frame.data.count)")
			}
		default:
			Log.warn("未知操作类型：" + String(format: "0x%.2X", frame.data[0]))
		}
	}
	
	//MARK: - 0x19 创建/编辑楼层
	private func createOrEditFloor(frame: HRFrame) {
//		if frame.data.count < 2 { return }
//		let floorId = UInt16(twoBytes: Array(frame.data[0...1]))
		
		HR8000Service.shareInstance().queryDevice(HRDeviceType.FloorInfo)
	}
	
	//MARK: - 0x1A 删除楼层
	private func deleteFloor(frame: HRFrame) {
		if frame.data.count < 3 { return }
		let success = frame.data[2] == 0x00
		if !success { return }
		let floorID = UInt16(twoBytes: Array(frame.data[0...1]))
		if let floor = HRDatabase.shareInstance().removeDevice(HRDeviceType.FloorInfo, devAddr: UInt32(floorID)) {
			Log.info("删除楼层“\(floor.name)”.")
			NSNotificationCenter.defaultCenter().postNotificationName(kNotificationDeviceDidDeleted, object: floor)
			runOnMainQueue({
				self.delegates.hr8000HelperDelegate?.hr8000Helper?(didDeleteDevice: floor)
			})
		} else {
			Log.info("删除楼层(id=\(floorID))，本地未找到该楼层.")
		}
	}
	
    //MARK: - 0x20操作继电器控制盒、0x21智能插座、0x1E智能开关
    private func operateRelay(frame: HRFrame) {
        let devType = frame.data[0]
        let devAddr = UInt32(fourBytes: Array(frame.data[1...4]))
        let states  = frame.data[5]
		if let relayBox = HRDatabase.shareInstance().getDevice(devType, devAddr: devAddr) as? HRRelayComplexes {
			relayBox.states = states
			runOnMainQueue({
				self.delegates.relayBaseDeviceDelegate?.relayBaseDevice(relayBox)
			})
		}
	}
	
	//MARK: - 0x22 控制RGB灯
	private func operateRGBLamp(frame: HRFrame) {
		if let delegate = self.delegates.rgbLampDelegate {
			if frame.data.count < 9 {
				Log.error("控制RGB灯：返回未知帧，无法解析！")
				return
			}
			guard let mode = HRRGBCtrlMode(rawValue: frame.data[5]) else {
				Log.error("未知模式：\(frame.data[5])")
				return
			}
			let devAddr = UInt32(fourBytes: Array(frame.data[1...4]))
			let R = frame.data[6]
			let G = frame.data[7]
			let B = frame.data[8]
			if let lamp = HRDatabase.shareInstance().getDevice(.RGBLamp, devAddr: devAddr) as? HRRGBLamp {
				let oldMode = HRRGBCtrlMode(rawValue: lamp.mode) ?? .RGB
				let oldRGB  = lamp.rgbValue
				lamp.mode = mode.rawValue
				lamp.rgbValue = HRRGBValue(r: R, g: G, b: B)
				runOnMainQueue({
					delegate.rgbLampDelegate(lamp, valueChanged: oldMode, oldRGB: oldRGB)
				})
				return
			}
			Log.warn("本地未找到该RGB灯，请刷新设备数据！")
		}
	}
	
	
	//MARK: - 0x24 红外转发
	private func infTransmitUnit(frame: HRFrame) {
		if self.delegates.infraredDelegate == nil {
			return
		}
		let devType = frame.data[1]
		let appID   = UInt16(twoBytes: Array(frame.data[2...3]))
		let keyCode = frame.data[4]
		let result  = frame.data[frame.data.count-1] == 0x00
		if frame.data[0] == 0x00{
			runOnMainQueue({
				self.delegates.infraredDelegate?.infraredTransmit?(initInfrared: appID, devType: devType, tag:frame.sn, result: result)
			})
			return
		}
		else if frame.data[0] == 0x01 {
			let codeIndex = UInt32(fourBytes: Array(frame.data[5...8]))
			runOnMainQueue({
				self.delegates.infraredDelegate?.infraredTransmit?(codeMatching: appID, devType: devType, tag:frame.sn, keyCode: keyCode, codeIndex: codeIndex, result: result)
			})
			return
		}
		else if frame.data[0] == 0x02 {
			let codeIndex = UInt32(fourBytes: Array(frame.data[5...8]))
			runOnMainQueue({
				self.delegates.infraredDelegate?.infraredTransmit?(normalOperated: appID, devType: devType, tag:frame.sn, keyCode: keyCode, codeIndex: codeIndex, result: result)
			})
			return
		} else {
			Log.warn("红外转发操作内容未支持：\(frame.data[0]).")
		}
	}
	
    //MARK: - 0x2A 查询传感器值
    private func querySensorValue(frame: HRFrame) {
        let devAddr = UInt32(fourBytes: Array(frame.data[1...4]))
        //探测类型：0x01光照，0x02可燃气爆炸下限指数(LEL)，0x03可燃气浓度，0x04温湿度空气质量
        let detectType = frame.data[5]
        switch detectType{
        case 0x01:
            let lux = UInt16(twoBytes: Array(frame.data[6...7]))
            self.delegates.sensorValuesDelegate?.sensorValues?(SolarValueResult: devAddr, lux: lux, tag: frame.sn)
        case 0x02:
            let lel = Float(UInt16(twoBytes: Array(frame.data[6...7])))/100.0
            self.delegates.sensorValuesDelegate?.sensorValues?(gasLELValueResult: devAddr, lel: lel, tag: frame.sn)
        case 0x03:
            let dens = UInt16(twoBytes: Array(frame.data[6...7]))
            self.delegates.sensorValuesDelegate?.sensorValues?(gasDensValueResult: devAddr, dens: dens, tag: frame.sn)
        case 0x04:
            let temp = Int16(frame.data[6]) | (Int16(frame.data[7]) << 8)
            let humidity = UInt16(twoBytes: Array(frame.data[8...9]))
            let quality  = UInt16(twoBytes: Array(frame.data[10...11]))
            self.delegates.sensorValuesDelegate?.sensorValues?(tempAirValueResult: devAddr, temperature: temp, humidity: humidity, airQuality: quality, tag: frame.sn)
        default:
            Log.warn("接收到不支持的传感器(类型：\(detectType))返回值")
            break
        }
    }
	
	//MARK: - 0x2C 设置传感器联动动作值
	private func setSensorActionValue(frame: HRFrame) {
		if frame.data.count < 5 { return }
		let devType = frame.data[0]
		let devAddr = UInt32(fourBytes: Array(frame.data[1...4]))
		HR8000Service.shareInstance().queryDevice(devType, devAddr: devAddr)
	}
	
	//MARK: - 0x2D 传感器联动绑定
	private func sensorBindDevices(frame: HRFrame) {
		if frame.data.count < 5 { return }
		let devType = frame.data[0]
		let devAddr = UInt32(fourBytes: Array(frame.data[1...4]))
		HR8000Service.shareInstance().queryDevice(devType, devAddr: devAddr)
	}
	
	//MARK: - 0x32 控制单火开关
	private func operateLiveFireSwitch(frame: HRFrame) {
		self.operateRelay(frame)
	}
    //MARK: - 0x33 升级智能主机固件
    
    //无论是否有更新存在，主机都要将结果告诉APP
    private func operateUpdateFirmware(frame: HRFrame){
        let todoData = frame.data[0]
        
        if todoData == 0x02 {//0x02：表示反馈检查结果
            let resultData = frame.data[1]
            if resultData == 0x00 {//0x00表示无新版本或更新失败
                var message:String
                switch frame.data[2]{
                case 0x00:
                    message = "无新版本"
                    
                case 0x01:
                    message = "缺少描述文件"
                    
                case 0x02:
                    message = "没有通过校验"
                    
                case 0x03:
                    message = "下载失败"
                    
                case 0x04:
                    message = "其他原因"
                default:
                    return
                }
                Log.debug("无新版本/更新失败: \(message)")
                runOnMainQueue { () -> Void in
                    self.delegates.hr8000HelperDelegate?.checkFirmware?(noNewVersion: frame.data[2], message: message)
                }
            }else if resultData == 0x01 && frame.data.count >= 306{//0x01表示有新版本
                //结果为0x01的情况
                let version = ContentHelper.encodeGbkData(Array(frame.data[2..<2+16]))
                let size = ContentHelper.encodeGbkData(Array(frame.data[18..<18+16]))
                let date = ContentHelper.encodeGbkData(Array(frame.data[34..<34+16]))
                let description = ContentHelper.encodeGbkData(Array(frame.data[50..<50+256]))
                runOnMainQueue { () -> Void in
                    self.delegates.hr8000HelperDelegate?.checkFirmware?(hasNewVersion:version!, size: size!, date: date!, description: description!)
                }
                Log.debug("反馈检查更新结果: version:\(version!)\nsize:\(size)\ndate\(date!)\ndescription:\(description!)")
            }
        }else if todoData == 0x03 {//0x03：表示请求更新
            let upData = frame.data[1]
            if upData == 0x00 {//0x00表示无法更新
                var description:String
                switch frame.data[2]{
                case 0x00:
                    description = "无新版本"
                    
                case 0x01:
                    description = "缺少描述文件"
                    
                case 0x02:
                    description = "没有通过校验"
                    
                case 0x03:
                    description = "下载失败"
                    
                case 0x04:
                    description = "其他原因"
                default:
                    return
                }
                Log.debug("无新版本/更新失败: \(description)")
                runOnMainQueue { () -> Void in
                  self.delegates.hr8000HelperDelegate?.upDataFirmware!(noUpDataVersion: frame.data[2], message: description)
                }
            }else if upData == 0x01 {//0x01表示开始更新
                
                Log.debug("开始更新")
                
            }
            
        }
    
    }
	
	//MARK: - 0x5E 设置或编辑定时任务
	private func setOrEditTask(frame: HRFrame) {
		HR8000Service.shareInstance().queryDevice(HRDeviceType.Task, devAddr: UInt32(frame.data[0]))
	}
	
	//MARK: - 0x5F 删除定时任务
	private func deleteTask(frame: HRFrame) {
		if frame.data.count >= 1 {
			if let task = HRDatabase.shareInstance().removeDevice(.Task, devAddr: UInt32(frame.data[0])) {
				NSNotificationCenter.defaultCenter().postNotificationName(kNotificationDeviceDidDeleted, object: task)
				runOnMainQueue({
					self.delegates.hr8000HelperDelegate?.hr8000Helper?(didDeleteDevice: task)
				})
			}
		} else {
			Log.error("deleteTask: 数据域长度为0")
		}
	}
	
}




