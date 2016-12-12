//
//  ServiceBase.swift
//  SmartBed
//
//  Created by sswukang on 15/7/10.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import Foundation

/**网络模式*/
enum HRWorkMode {
    /**在线，Socket已连接，也已经登录*/
    case Online
    /**离线。Socket已连接，但是没有登录*/
    case Offline
    /**没有连接，也没有登录。初始化状态*/
    case Disconnet
    /**正在搜索服务器中*/
    case Searching
    /**正在连接中*/
    case Connecting
    /**正在登录中*/
    case Loginning
}

enum HRNetworkType {
    /**本地局域网*/
    case Local
    /**互联网,*/
    case WWAN
    /**使用和主机不再同一个局域网的网络*/
    case InternetWithWiFi
    /**离线*/
    case Offline
}

enum HRUserManagerAction: Byte {
	///添加新用户
    case CreateNewUser = 0x01
	///修改用户信息（包括用户名、密码、权限等级）
    case EditUserInfo  = 0x02
	///删除用户
    case DeleteUser    = 0x03
	///修改主机信息（包括主机名、密码、权限等级）
    case EditHostInfo  = 0x04
}

enum HRFloorManageActon: Byte {
	///新添加一个楼层
	case CreateNewFloor = 0x01
	///添加一个房间到楼层中
	case CreateNewRoom  = 0x02
	///从楼层中删除一个房间
	case DeleteRoom		= 0x03
	///编辑楼层名称
	case EditFloorName	= 0x04
	///编辑房间名称
	case EditRoomName	= 0x05
}

///传感器联动绑定时的操作类型
enum BindSensorOperateType: Byte {
	///光照联动
    case Solar          = 0x01
	///燃气联动
    case Gas            = 0x02
	///温度联动
    case Temperature    = 0x03
	///湿度联动
    case Humidity       = 0x04
	///空气质量联动
    case AirQuality     = 0x05
	///湿敏联动
    case HumiditySensor = 0x06
}

enum HRRGBCtrlMode: Byte {
    /// 依据RGB输出
    case RGB      = 0x01
    /// 照明模式
    case Lighting = 0x02
	/// 起夜模式
    case Night    = 0x03
	/// 循环渐变模式
    case Gradient = 0x04
	/// 跳变模式
    case Step     = 0x05
	/// 彩虹模式
    case Rainbow  = 0x06
}

class ServiceBase {
    
    private var tcpConn: HRSocketConnection?
    
    /**当前的模式*/
    var workMode = HRWorkMode.Disconnet
    /**当前网络状况*/
    var networkType = HRNetworkType.Offline
	
	//MARK: - functions
	
	init() {
        
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ServiceBase.socketConnected(_:)), name: kNotificationDidSocketConnected, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ServiceBase.socketDisconnected(_:)), name: kNotificationDidSocketDisconnected, object: nil)
	}
	
	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}
	
	@objc private func socketConnected(notification: NSNotification) {
		self.workMode = .Offline
	}
	
	@objc private func socketDisconnected(notification: NSNotification) {
		self.workMode = .Disconnet
	}
	
    
    //代理方法已经登录
	func doLogin(userName: String, password: String, result: ((NSError?)->Void)?) {
		let searcher = HRSearchLocalHost(userName: userName, password: password)
		self.workMode = HRWorkMode.Searching
		Log.debug("当前账号【\(userName)】，开始搜索主机...")
		searcher.search({ (hostObj, error) -> Void in
			let host: HRServerHost!
			if hostObj != nil {	//搜索到主机
				host = hostObj
				//保存host到数据库中
				HRDatabase.shareInstance().server = host
				self.networkType = .Local
				Log.debug("成功搜索到主机!")
             //   print("成功搜索到主机")
			} else {		//没有搜索到主机
				host = HRServerHost.newServerHost()
				HRDatabase.shareInstance().server = host
				self.networkType = HRNetworkType.InternetWithWiFi
                
             //   print("没有搜到主机，登陆到服务器.")
				Log.debug("没有搜到主机，登陆到服务器.")
			}
			Log.debug("开始连接...")
			
			//连接主机/服务器
			self.tcpConnectServer(host, result: {
				(connError) in
				if let error = connError {
                    
                    //手机没网的时候返回的东西 斌注释
					self.workMode = .Offline
					Log.debug("连接失败:\(error.domain)(\(error.code))")
                    
                   // print("连接失败:\(error.domain)(\(error.code))")
                    
                    
					self.logout()
					runOnMainQueue({
						result?(error)
					})
				} else {
					Log.debug("连接成功！")
					Log.debug("开始登陆...")
                    
                   // print("链接成功开始登陆")
					self.workMode = .Loginning
                    
					self.tcpSendLogin(userName, password: password, result: {
						(acount, loginError) in
						if var error = loginError{
							if error.code == HRErrorCode.Timeout.rawValue {
                                
                              //  print("登陆超时")
								error = NSError(domain: "登陆超时", code: HRErrorCode.LoginTimeout.rawValue, userInfo: nil)
							}
							Log.debug("登陆失败：\(error.domain)(\(error.code))")
							self.workMode = .Offline
							//注销
							self.logout()
							runOnMainQueue({
								result?(error)
							})
                            
                            
//                            if error.code==HRErrorCode.LoginTimeout.rawValue{
//                                print("1009发送登陆帧时超时没有响应")
//                            }

						}
                                                else {
                            
                           // print("登陆成功")
							Log.debug("登陆成功！")
							self.workMode = .Online
							HRDatabase.shareInstance().server.hostAddr = acount!.hostAddr
							runOnMainQueue({
								result?(nil)
							})
						}
					})
				}
			})
			
			
		})
	}
	
	func tcpConnectServer(host: HRServerHost, result: ((NSError?)->Void)?) {
		self.workMode = .Connecting
		
		let hostAddr = HRDatabase.shareInstance().server.getHostIPAddrString()
		let hostPort = HRDatabase.shareInstance().server.port
		Log.debug("连接 -> \(hostAddr):\(hostPort)")
		//初始化HRProcessCenter
		HRProcessCenter.shareInstance()
		self.tcpConn = HRSocketConnection(hostAddr: hostAddr, hostPort: hostPort)
		self.tcpConn!.connectServer(TCP_CNCT_TIMEOUT, result: result)
	}
	
	
	
    private func tcpSendLogin(userName: String, password: String, result: ((HRAcount?, NSError?)->Void)? ) {
        self.workMode = HRWorkMode.Loginning
        var data = [Byte]()
        let nameData = ContentHelper.decodeGbkData(userName)
        if nameData.count >= 32 {
            data += nameData[0...31]
        } else {
            data += nameData
            data += [Byte](count: 32-nameData.count, repeatedValue: 0)
        }
        let passwdData = ContentHelper.decodeGbkData(password)
        if passwdData.count >= 16 {
            data += passwdData[0...15]
        } else {
            data += passwdData
            data += [Byte](count: 16-passwdData.count, repeatedValue: 0)
        }
        let destAddr = HRDatabase.shareInstance().server.hostAddr
        let frame = HRFrame(destAddr: destAddr, sn: HRFrameSn.LOGIN.rawValue, command: HRCommand.Longin.rawValue, data: data)
        
       // print("正在发送登陆帧")
        Log.debug("发送登陆帧(\(frame.toTransmitFrame()!.count)):\n\(frame.toTransmitFrame()!)")
        //print("发送登陆帧(\(frame.toTransmitFrame()!.count)):\n\(frame.toTransmitFrame()!)")
        
        if let err = tcpConn!.send(frame) {
            result?(nil, err)
        } else {
            tcpConn!.receive(Double(LOGIN_TIME_OUT)/1000,
                filter: { (rcvFrame) in
                    if rcvFrame.command == HRCommand.Longin.rawValue {
                        return true
                        
                        
                    }
                    return false
                }, receive: { (rcvFrame, error) in
                    if rcvFrame == nil {
                        result?(nil, error)
                        return
                    }
					guard let acount = HRAcount.initWithDataFrame(frameData:  rcvFrame!.data) else {
                        result?(nil, NSError(domain: "数据异常", code: HRErrorCode.LoginRcvDataError.rawValue, userInfo: nil))
						return
					}
					HRDatabase.shareInstance().acount = acount
                    
                    
                    switch acount.permission {
                    case HRHostPermission.AuthDenied.rawValue:
                        result?(acount, NSError(domain: "用户名或密码错误", code: HRErrorCode.AuthDenied.rawValue, userInfo: nil))
                    case HRHostPermission.HostNotRegistration.rawValue:
                        result?(acount, NSError(domain: "主机没有注册到服务器上", code: HRErrorCode.HostNoRegistration.rawValue, userInfo: nil))
                    case HRHostPermission.HostOffline.rawValue:
                        result?(acount, NSError(domain: "主机不在线", code: HRErrorCode.HostOffline.rawValue, userInfo: nil))
                        
                       
                        
                    default:    //登陆成功
                        
                        
                        self.workMode = HRWorkMode.Online
                        result?(acount, nil)
                    }
                
            })
        }
        
    }
    
    /**注销*/
    func logout(){
        //将工作模式选为离线模式
        workMode = .Offline
        tcpConn?.disconnect()
        
    }
 
    
    //MARK: - 注册/添加设备

	/**
	心跳
	
	- parameter result: <#result description#>
	*/
	func doHeartbeat(result: (NSError?)->Void) {
		let data = [Byte]()
		let frame = HRFrame(destAddr: HRDatabase.shareInstance().server.hostAddr, sn: 0x33, command: HRCommand.KeepAlive, data: data)
		
		tcpConn?.sendAndReceive(frame, filter: { (rcvFrame) -> Bool in
			if rcvFrame.sn != 0x33 { return false}
			if rcvFrame.commandIgnoreException == frame.command { return true }
			return false
			}, receive: { (rcvFrame, error) -> Void in
				if let exception = rcvFrame?.exception {
					runOnMainQueue({
						result(exception)
					})
					return
				}
				runOnMainQueue({
					result(error)
				})
		})
	}
	
    ///开始注册设备，0x01
    func doRegisterDeviceStart(){
        var data = [Byte]()
        data.append(HRDatabase.shareInstance().acount.permission)
        data.append(0x01)
        let frame = HRFrame(destAddr: HRDatabase.shareInstance().server.hostAddr, sn: 41, command: HRCommand.RegisterDevice, data: data)
        Log.info("\n↑↑↑↑ 发送注册开始（0x01），帧数据：\n\(frame.toString())")
        tcpConn?.send(frame)
    }
    
    
    ///允许设备注册到主机中，注册流程0x03
    func doRegisterDeviceAllow(devType: Byte, devAddr: UInt32, name: String, insRoomId: UInt16, insFloorId: UInt16) {
		
        var data = [Byte]()
        data.append(HRDatabase.shareInstance().acount.permission)
        data.append(0x03)
        data.append(devType)
        data += devAddr.getBytes()
        var name = ContentHelper.decodeGbkData(name)
        if name.count >= 32{
            data += name[0...31]
        } else {
            data += name
            for _ in 0...31-name.count {
                data.append(0)
            }
        }
        data += insRoomId.getBytes()
        data += insFloorId.getBytes()
        for _ in 0...27 {
            data.append(0)
        }
        let frame = HRFrame(destAddr: HRDatabase.shareInstance().server.hostAddr, sn: 43, command: HRCommand.RegisterDevice, data: data)
		
		Log.info("\n↑↑↑↑ 发送允许设备注册（0x03），帧数据：\n\(frame.toString())")
        tcpConn?.send(frame)
	}
    
    ///结束注册设备，0x04
    func doRegisterDeviceEnd() {
        var data = [Byte]()
        data.append(HRDatabase.shareInstance().acount.permission)
        data.append(0x04)
        let frame = HRFrame(destAddr: HRDatabase.shareInstance().server.hostAddr, sn: 44, command: HRCommand.RegisterDevice, data: data)
		
		Log.info("\n↑↑↑↑ 发送结束设备注册（0x04），帧数据：\n\(frame.toString())")
        tcpConn?.send(frame)
    }
	
	///添加或创建情景
	///
	///- parameter scene: 情景对象
	///- parameter isCreate: 是否是创建新情景，如果创建新情景填true，编辑情景填false
	///- parameter result: 结果回调
	func doCreateOrModifyScene(scene: HRScene, isCreate: Bool, result: (NSError?)->Void) {
		var data = [Byte]()
		data.append(HRDatabase.shareInstance().acount.permission)
		if isCreate {
			data.append(0x01)
			data.append(0xFF)
		} else {
			data.append(0x05)
			data.append(scene.id)
		}
		data.append(scene.icon)
		let nameData = ContentHelper.decodeGbkData(scene.name)
		if nameData.count >= 32 {
			data += nameData[0...31]
		} else {
			data += nameData
			data += [Byte](count: 32-nameData.count, repeatedValue: 0)
		}
		data.append(scene.devCount)
		for dev in scene.devices {
			data += dev.hostAddr.getBytes()
			data.append(dev.devType)
			data += dev.devAddr.getBytes()
			data += dev.actBinds
			data.append(dev.delayCode[0])
		}
		let randSn = Byte(arc4random_uniform(128))
		let frame = HRFrame(destAddr: HRDatabase.shareInstance().server.hostAddr, sn: randSn, command: HRCommand.CreateOrModifyScene, data: data)
		
		tcpConn?.sendAndReceive(frame, filter: { (rcvFrame) in
				if rcvFrame.sn != randSn {
					return false
				}
				if rcvFrame.commandIgnoreException == HRCommand.CreateOrModifyScene.rawValue {
					return true
				}
				return false
			}, receive: { (rcvFrame, error) in
				if let err = rcvFrame?.exception {
					runOnMainQueue({
						result(NSError(domain: "异常", code: err.code, userInfo: nil))
						return
					})
				} else {
					runOnMainQueue({
						result(error)
						return
					})
				}
		})
	}
	
	///添加或编辑定时任务
	///
	///- parameter task: 定时任务对象
	///- parameter isCreate: 是否是创建新定时任务，如果创建新定时任务填true，编辑则填false
	///- parameter result: 结果回调
	func doCreateOrModifyTask(task: HRTask, isCreate: Bool, result: (NSError?)->Void) {
		var data = [Byte]()
		data.append(HRDatabase.shareInstance().acount.permission)
		if isCreate {
			data.append(0x01)
			data.append(0xFF)
		} else {
			data.append(0x05)
			data.append(task.id)
		}
		//图标
		data.append(task.icon)
		//名字
		data += task.name.getBytesUsingGBK(32)
		//时间
		data += [task.time.hour, task.time.min, task.time.sec]
		//周期
		data.append(task.repeation)
		//设备数量
		data.append(Byte(task.devsInTask.count))
		//设备
		for dev in task.devsInTask {
			data += dev.hostAddr.getBytes()
			data.append(dev.devType)
			data += dev.devAddr.getBytes()
			data += dev.actBinds
			data += dev.delayCode
		}
		//有效标志
		data.append(task.enable ? 0x01 : 0x00)
		let randSn = Byte(arc4random_uniform(128))
		let frame = HRFrame(destAddr: task.hostAddr, sn: randSn, command: HRCommand.SetOrEditAlarmTask, data: data)
		
		tcpConn?.sendAndReceive(frame, filter: { (rcvFrame) in
			if rcvFrame.sn != randSn { return false }
			if rcvFrame.commandIgnoreException == HRCommand.SetOrEditAlarmTask.rawValue { return true }
			return false
			}, receive: { (rcvFrame, error) in
				if let err = rcvFrame?.exception {
					runOnMainQueue({
						result(NSError(domain: "异常", code: err.code, userInfo: nil))
						return
					})
					return
				}
				runOnMainQueue({
					result(error)
					return
				})
		})
	}
	

	///创建或修改应用设备
	///
	/// - parameter hostAddr:	主机地址
	/// - parameter permission:	权限
	/// - parameter actionType:	操作类型，创建新的应用设备填1， 修改应用设备填2, 其他无效
	/// - parameter appType:		应用设备类型，见HRAppDeviceType
	/// - parameter appId:		应用设备ID，如果是创建应用设备，则该参数填0xFF
	/// - parameter name:		应用设备名字
	/// - parameter floorId:		应用设备安装的楼层ID
	/// - parameter roomId:		应用设备安装的房间ID
	/// - parameter infraredDevAddr:		红外转发器的设备地址
	/// - parameter result:		结果回调
	func doCreateOrModifyApplyDevice(hostAddr: UInt32,permission: Byte, actionType: Byte, appType: Byte, appId: UInt16, name: String, floorId: UInt16, roomId: UInt16, infraredDevAddr: UInt32, result: ((NSError?)->Void)?) {
		var data = [Byte]()
		data.append(permission)
		data.append(actionType)
		data.append(appType)
		if actionType == 1 {
			data += [0xFF, 0xFF]
		} else {
			data += appId.getBytes()
		}
		data += name.getBytesUsingGBK(32)
		data += roomId.getBytes()
		data += floorId.getBytes()
		data += [Byte](count: 28, repeatedValue: 0)
		data += infraredDevAddr.getBytes()
		let randSn = Byte(arc4random() % 128)
		let frame = HRFrame(destAddr: hostAddr, sn: randSn, command: HRCommand.AddOrEditApplyDev, data: data)
		
		self.tcpConn?.sendAndReceive(frame, filter: { (rcvFrame) -> Bool in
			if rcvFrame.sn != randSn { return false }
			if rcvFrame.commandIgnoreException == frame.command { return true }
			return false
		}, receive: { (rcvFrame, error) -> Void in
			if let exception = rcvFrame?.exception {
				runOnMainQueue({
					result?(exception)
					return
				})
			}
			if let rFrame = rcvFrame {
				if rFrame.data.count >= 1 && rFrame.data[0] == 0x01 {
					runOnMainQueue({
						result?(NSError(domain: "操作失败", code: HRErrorCode.CreateEditDeleteAppDevFail.rawValue, userInfo: nil))
					})
					return
				}
			}
			runOnMainQueue({
				result?(error)
			})
		})
	}
	
	///用户管理，控制码0x10
	///
	/// - parameter user:		用户信息
	/// - parameter action:		操作类型
	/// - parameter newPasswd:	新密码
	/// - parameter origUserName: 原始用户名，修改用户信息的时候该参数不能为空，
	/// - parameter origPasswd:	原始密码，修改用户信息的时候该参数不能为空
	/// - parameter result:		结果
	func doUserManage(user: HRUserInfo, action:HRUserManagerAction, newPasswd: String, origUserName: String?, origPasswd: String?, result: ((NSError?)->Void)?) {
		var data = [Byte]()
        //确认权限 一个字节长度  斌注释
		data.append(HRDatabase.shareInstance().acount.permission)
      
        //操作类型 一个字节  0x01 添加新用户
        //0x02 修改用户信息   0x03删除用户   0x04 修改主机信息  斌注释
		data.append(action.rawValue)
        //用switch来确认操作类型是什么 斌注释
		switch action {
            //1.如果这个操作类型是增加新用户 斌注释
		case .CreateNewUser:
			data.append(0xFF)//???为什么要加0xff
            //解析因为操作内容是52个字节
            //用户id（1）：填0xff，由主机分配
            //用户名（32）按字符串顺序传输
            //密码（16）按字符串顺序传输
            //权限等级(1)------0x01
            //楼层id(1)-------0xff代表所有楼层 ，0-254代表具体的楼层
            //房间id(1)-------0xff代表所有楼层 ，0-254代表具体的房间
            //斌注释
            //把user.name这个字符串反解码成为二进制数字 拿来组帧 斌注释
			data += user.name.getBytesUsingGBK(32)
			data += newPasswd.getBytesUsingGBK(16)
			data.append(0x01)
			data.append(Byte(user.insFloorID & 0xFF))
			data.append(Byte(user.insRoomID & 0xFF))
		case .EditHostInfo, .EditUserInfo:
			if origUserName == nil || origPasswd == nil {
				runOnMainQueue({
					result?(NSError(domain: "密码和用户名不能为空!", code: 0, userInfo: nil))
				})
				return
			}
			data.append(Byte(user.id & 0xFF))
			data += origUserName!.getBytesUsingGBK(32)
			data += origPasswd!.getBytesUsingGBK(16)
			data.append(user.permission)
			data += user.name.getBytesUsingGBK(32)
			data += newPasswd.getBytesUsingGBK(16)
			data.append(user.permission)
			data.append(Byte(user.insFloorID & 0xFF))
			data.append(Byte(user.insRoomID & 0xFF))
		case .DeleteUser:
			//data.append(Byte(user.id & 0xFF))
            print(user.id)
            
            data.append(Byte(user.id))
            
            
			data += user.name.getBytesUsingGBK(32)
            //print("你要删除的用户名是\(user.name)")
            
           // print("数据域的二进制码结构\(data)")
           // print("正在删除用户")
		}
		
		let randSn = Byte(arc4random_uniform(128))
		let frame = HRFrame(destAddr: HRDatabase.shareInstance().server.hostAddr, sn: randSn, command: HRCommand.UserManage, data: data)
		tcpConn?.sendAndReceive(frame, filter: { (rcvFrame) -> Bool in
			if rcvFrame.sn != randSn { return false }
			if rcvFrame.commandIgnoreException != frame.command { return false }
			return true
			}, receive: { (rcvFrame, error) -> Void in
				if let exception = rcvFrame?.exception {
					runOnMainQueue({
						result?(exception)
                        
					})
					return
				}
				if rcvFrame?.data.last == 0x00 {
					runOnMainQueue({
                        
                        //print("操作成功")
						result?(nil)
					})
					return
				} else if rcvFrame?.data.last == 0x01 {
					runOnMainQueue({
                        
                        
                       // print("a,来到操作失败这里了")
						result?(NSError(domain: "操作失败", code: HRErrorCode.UserManageFailed.rawValue, userInfo: nil))
                        
                       // print(HRErrorCode.UserManageFailed.rawValue)
					})
					return
				}
				runOnMainQueue({
					result?(error)
				})
		})
	}
	
	///创建或编辑楼层、房间
	///
	/// - parameter action: 操作类型，HRFloorManageActon
	/// - parameter floor:	楼层对象
	/// - parameter room:	房间对象，如果是添加新房间、修改房间名或删除房间，该参数不能为空
	/// - parameter result: 结果
	func doCreateOrEditFloor(action: HRFloorManageActon, floor: HRFloorInfo, room: HRRoomInfo?, result: ((NSError?)->Void)?) {
		switch action {
		case .CreateNewRoom, .EditRoomName, .DeleteRoom :
			if  room == nil {
				runOnMainQueue({
					result?(NSError(domain: "房间不能为空", code: HRErrorCode.UnknowError.rawValue, userInfo: nil))
				})
				return
			}
		default: break
		}
		var data = [Byte]()
		data.append(HRDatabase.shareInstance().acount.permission)
		data.append(action.rawValue)
		if action == .CreateNewFloor {
			data += [0xFF, 0xFF]
		} else {
			data += UInt16(floor.id).getBytes()
		}
		data += floor.name.getBytesUsingGBK(32)
		//加房间ID
		switch action {
		case .CreateNewFloor, .CreateNewRoom, .EditFloorName:
			data += [0xFF, 0xFF]
		default:
			data += room!.id.getBytes()
		}
		switch action {
		case .CreateNewFloor, .EditFloorName:
			data += [Byte](count: 32, repeatedValue: 0x00)
		default:
			data += room!.name.getBytesUsingGBK(32)
		}
		
		let hostAddr: UInt32
		switch action {
		case .EditFloorName, .DeleteRoom, .EditRoomName, .CreateNewRoom:
			hostAddr = floor.hostAddr
		default:
			hostAddr = HRDatabase.shareInstance().server.hostAddr
		}
		
		let randSn = Byte(arc4random_uniform(128))
		let frame = HRFrame(destAddr: hostAddr, sn: randSn, command: HRCommand.CreateOrEditFloorInfo, data: data)
		tcpConn?.sendAndReceive(frame, filter: { (rcvFrame) -> Bool in
			if rcvFrame.sn != randSn { return false }
			if rcvFrame.commandIgnoreException != frame.command { return false }
			return true
			}, receive: { (rcvFrame, error) -> Void in
				if let exception = rcvFrame?.exception {
					runOnMainQueue({
						result?(exception)
					})
					return
				}
				if rcvFrame?.data.last == 0x00 {
					runOnMainQueue({
						result?(nil)
					})
					return
				} else if rcvFrame?.data.last == 0x01 {
					runOnMainQueue({
						result?(NSError(domain: "操作失败", code: HRErrorCode.CreateOrEditFloorReturnFailed.rawValue, userInfo: nil))
					})
					return
				}
				runOnMainQueue({
					result?(error)
				})
		})
	}
	
	///修改门锁密码
	func doChangeDoorLockPassword(doorLock: HRDoorLock, passwordForAdminstrator adminPasswd: String, passwordForOpen openPasswd: String, result: ((NSError?)->Void)?){
		var data = [Byte]()
        //权限(1)
		data.append(HRDatabase.shareInstance().acount.permission)
        //设备类型（1）
		data.append(doorLock.devType)
        //设备地址（4）
		data += doorLock.devAddr.getBytes()
        //管理员密码（16）
		data += adminPasswd.getBytesUsingGBK(16)
        //操作类型(1):0x01添加开门密码 , 0x02修改开门密码 , 0x03修改管理员密码
		data.append(0x02)	//修改门锁密码
        //密码ID(1)1字节， 由1-9可选
		data.append(0x00)	//密码ID，填0 ，写死！！！ 因为安卓写的是0 所以我们也写 0  斌注释
        
		data += openPasswd.getBytesUsingGBK(16)
		
		let randSn = Byte(arc4random_uniform(128))
		let frame = HRFrame(destAddr: doorLock.hostAddr, sn: randSn, command: HRCommand.SetDoorLockPassword, data: data)
        
		//print( frame.toString())
        //rcvFrame是指主机的响应帧 斌
		self.tcpConn?.sendAndReceive(frame, filter: { (rcvFrame) -> Bool in
			if rcvFrame.sn != randSn { return false }
			if rcvFrame.commandIgnoreException != frame.command { return false }
			return true
			}, receive: { (rcvFrame, error) -> Void in
                
                //rcvFrame?.exception指的是获取到异常帧 斌
				if let exception = rcvFrame?.exception {
					runOnMainQueue({
						result?(exception)
					})
				}
                //数据域数组的最后一个元素(字节)代表操作结果
                //0x00表示操作成功,0x01表示管理员密码错误。0x02代表该设备不存在
				if rcvFrame?.data.last == 0x00 {
					runOnMainQueue({
                        
                        print("操作成功，密码已经修改")
						result?(nil)
					})
					return
				} else if rcvFrame?.data.last == 0x01 {
					runOnMainQueue({
						result?(NSError(domain: "管理员密码错误", code: HRErrorCode.ChangeDoorLockPasswdRetFailed.rawValue, userInfo: nil))
					})
					return
				} else if rcvFrame?.data.last == 0x02 {
					runOnMainQueue({
						result?(NSError(domain: "该设备不存在", code: HRErrorCode.ChangeDoorLockPasswdRetFailed.rawValue, userInfo: nil))
					})
					return
				}
				runOnMainQueue({
					result?(error)
				})
		})
	}
	
	///设置传感器的联动动作值
	func doSetSensorActionValue(sensor: HRSensor, result: ((NSError?)->Void)?) {
		var data = [Byte]()
		data.append(HRDatabase.shareInstance().acount.permission)
		data.append(sensor.devType)
		data += sensor.devAddr.getBytes()
		switch sensor.devType {
		case HRDeviceType.SolarSensor.rawValue:
			if let solar = sensor as? HRSolarSensor {
				data.append(0x01)
				data.append(solar.linkMark)
				data += solar.linkLowerValue.getBytes()
				data += solar.linkUpperValue.getBytes()
			} else {
				fallthrough
			}
		case HRDeviceType.GasSensor.rawValue:
			if let gas = sensor as? HRGasSensor {
				data.append(0x02)
				data.append(gas.linkMark)
				data += UInt16(gas.linkLowerValue * 100).getBytes()
				data += UInt16(gas.linkUpperValue * 100).getBytes()
			} else {
				fallthrough
			}
		case HRDeviceType.HumiditySensor.rawValue:
			if let hum = sensor as? HRHumiditySensor {
				data.append(0x06)
				data.append(hum.linkMark)
				data += [0x00, 0x00]
				data += [0x00, 0x00]
			} else {
				fallthrough
			}
		case HRDeviceType.AirQualitySensor.rawValue:
			if let aqs = sensor as? HRAirQualitySensor {
				//分开三帧发送
				//data为温度帧数据
				
				///湿度帧数据
				var data2 = data
				///空气质量帧数据
				var data3 = data
				
				data.append(0x03)
				data.append(aqs.linkMarkTemp)
				data += UInt16(aqs.linkLowerValueTemp * 10).getBytes()
				data += UInt16(aqs.linkUpperValueTemp * 10).getBytes()
				
				data2.append(0x04)
				data2.append(aqs.linkMarkHumid)
				data2 += UInt16(aqs.linkLowerValueHumid * 10).getBytes()
				data2 += UInt16(aqs.linkUpperValueHumid * 10).getBytes()
				
				data3.append(0x05)
				data3.append(aqs.linkMarkAir)
				data3 += UInt16(aqs.linkLowerValueAir * 10).getBytes()
				data3 += UInt16(aqs.linkUpperValueAir * 10).getBytes()
				
				let frame2 = HRFrame(destAddr: aqs.hostAddr, sn: 0, command: .SetSensorBindValue, data: data2)
				let frame3 = HRFrame(destAddr: aqs.hostAddr, sn: 0, command: .SetSensorBindValue, data: data3)
				self.tcpConn?.send(frame2)
				self.tcpConn?.send(frame3)
			} else {
				fallthrough
			}
		default:
			runOnMainQueue({
				result?(NSError(domain: "暂不支持该类型的传感器", code: HRErrorCode.SensorNotSupport.rawValue, userInfo: nil))
			})
			return
		}
		
		let randSn = Byte(arc4random_uniform(128))
		let frame = HRFrame(destAddr: sensor.hostAddr, sn: randSn, command: HRCommand.SetSensorBindValue, data: data)
		
		self.tcpConn?.sendAndReceive(frame, filter: { (rcvFrame) -> Bool in
			if rcvFrame.sn != randSn { return false }
			if rcvFrame.commandIgnoreException != frame.command { return false }
			return true
			}, receive: { (rcvFrame, error) -> Void in
				if let exception = rcvFrame?.exception {
					runOnMainQueue({
						result?(exception)
					})
					return
				}
				runOnMainQueue({
					result?(error)
				})
		})
		
	}
	
	/**
	传感器联动绑定
	
	- parameter sensor:      传感器
	- parameter bind:        传感器的绑定
	- parameter operateType: 操作类型
	- parameter result:      结果
	*/
	func doBindSensorAction(sensor: HRSensor, bind: HRSensorBind, operateType: BindSensorOperateType, result: ((NSError?)->Void)?) {
		var data = [Byte]()
		data.append(HRDatabase.shareInstance().acount.permission)
		data.append(sensor.devType)
		data += sensor.devAddr.getBytes()
		data.append(operateType.rawValue)
		data.append(Byte(bind.level))
		data.append(Byte(bind.devInScenes.count))
		for devInScene in bind.devInScenes {
			data += devInScene.hostAddr.getBytes()
			data.append(devInScene.devType)
			data += devInScene.devAddr.getBytes()
			data += devInScene.actBinds
			data += devInScene.delayCode
		}
		
		let randSn = Byte(arc4random_uniform(128))
		let frame = HRFrame(destAddr: sensor.hostAddr, sn: randSn, command: .SensorBindDevice, data: data)
		self.tcpConn?.sendAndReceive(frame, filter: { (rcvFrame) -> Bool in
			if rcvFrame.sn != randSn { return false }
			if rcvFrame.commandIgnoreException != frame.command { return false }
			return true
			}, receive: { (rcvFrame, error) -> Void in
				if let exception = rcvFrame?.exception {
					runOnMainQueue({
						result?(exception)
					})
					return
				}
				runOnMainQueue({
					result?(error)
				})
		})
	}
	
	//MARK: - 查询设备
    
    ///获取设备信息
    ///
    ///- parameter type:: 设备类型
    ///- parameter devAddr:: 要查询的设备的地址，如果是查询用户信息则填0xffffffff，如果查询楼层信息则填楼层ID
    func queryDevice(type: Byte, devAddr: UInt32 = 0xFFFF_FFFF){
        var data = [Byte]()
        data.append(type)
        data += devAddr.getBytes()
        let frame = HRFrame(destAddr: HRDatabase.shareInstance().server.hostAddr, sn: HRFrameSn.QueryDevice.rawValue, command: HRCommand.QueryDeviceInfo, data: data)
        tcpConn?.send(frame)
        Log.verbose("发送查询设备(\(type))的数据包:\n\(frame.toString())")
        
      //  print("发送查询设备(\(type))的数据包:\n\(frame.toString())")
        
        
    }
	
    
    
    ///查询光照、燃气、温湿度空气、湿敏探测器的值，查询结果请会在HRSensorValueDelegate中返回
    func doQuerySensorValue(sensor: HRDevice){
        var data = [Byte]()
        data.append(sensor.devType)
        data += sensor.devAddr.getBytes()
        let frame = HRFrame(destAddr: sensor.hostAddr, sn: HRFrameSn.QuerySensorValue, command: HRCommand.QuerySensorValue, data: data)
        tcpConn?.send(frame)
    }
	
    //MARK: - 检查新固件版本
    ///检查更新主机固件版本-APP发送请求帧
    ///- parameter timeout: 超时时间,单位为秒
    func doCheckFirmwareVersion(timeout: Double, result: ((NSError?)->Void)?) {
		var data = [Byte]()
		data.append(HRDatabase.shareInstance().acount.permission)
		data.append(0x01)	//请求更新
		let randSn = Byte(arc4random_uniform(128))
		let sendFrame = HRFrame(destAddr: HRDatabase.shareInstance().server.hostAddr, sn: randSn, command: HRCommand.UpdateFirmware, data: data)
		
		self.tcpConn?.sendAndReceive(timeout, frame: sendFrame, filter: { (revFrame) -> Bool in
            if revFrame.sn != randSn { return false }
            return revFrame.commandIgnoreException == HRCommand.ACK.rawValue
            
            }, receive: { (rcvFrame, error) -> Void in//APP收到主机发送的数据 //error可能为空
                Log.debug("@\(rcvFrame?.data),@\(error?.code)")
                if let exception = rcvFrame?.exception {
                    runOnMainQueue({
                        result?(exception)
                    })
                    return
                }
                runOnMainQueue({
                    result?(error)
                })
        })
    }
    
    ///发送一帧数据给主机表示要请求更新设备- APP请求更新固件
    func doUpDataVersion(timeout: Double, result: ((NSError?)->Void)?) {
        var data = [Byte]()
        data.append(HRDatabase.shareInstance().acount.permission)
        data.append(0x03)	//请求更新
        let randSn = Byte(arc4random_uniform(128))
        let sendFrame = HRFrame(destAddr: HRDatabase.shareInstance().server.hostAddr, sn: randSn, command: HRCommand.UpdateFirmware, data: data)
        
        self.tcpConn?.sendAndReceive(timeout, frame: sendFrame, filter: { (revFrame) -> Bool in
            if revFrame.sn != randSn { return false }
            return revFrame.commandIgnoreException == HRCommand.UpdateFirmware.rawValue
            
            }, receive: { (rcvFrame, error) -> Void in
                
                if let exception = rcvFrame?.exception {
                    runOnMainQueue({
                        result?(exception)
                    })
                    return
                }
                runOnMainQueue({
                    result?(error)
                })
        })	}
	
    ///检查更新主机固件版本-APP请求更新固件
    
//MARK: - 编辑设备
	
	/**
	设置系统参数
	
	- parameter hostAddr: 主机地址
	- parameter channel:  信道
	- parameter RFAddr:   RF地址
	- parameter result:   结果
	*/
	func doSetSystemParameter(hostAddr: UInt32, channel: Byte, RFAddr: Byte, result: ((NSError?)->Void)?) {
		var data = [Byte]()
		data.append(HRDatabase.shareInstance().acount.permission)
		data.append(HRDeviceType.Master.rawValue)
		data += hostAddr.getBytes()
		data.append(channel)
		data.append(RFAddr)
		data += [0xFF, 0xFF, 0xFF, 0xFF]
		data += [0xFF, 0xFF]
		
		let randSn = Byte(arc4random_uniform(128))
		let frame = HRFrame(destAddr: hostAddr, sn: randSn, command: HRCommand.SetSystemParameter, data: data)
		
		self.tcpConn?.sendAndReceive(frame, filter: { (rcvFrame) -> Bool in
				if rcvFrame.sn != randSn { return false }
				if rcvFrame.commandIgnoreException != frame.command { return false }
				return true
			}, receive: { (rcvFrame, error) -> Void in
				if let exception = rcvFrame?.exception {
					runOnMainQueue({
						result?(exception)
					})
					return
				}
				runOnMainQueue({
					result?(error)
				})
		}) 
	}
	
	///绑定继电器负载
	///
	/// - parameter relayBox: 继电器控制盒
	/// - parameter result: 结果回调
	func doBindRelayLoads(relayBox: HRRelayCtrlBox, result: (NSError?)->Void) {
		if relayBox.relays.count == 0 {
			runOnMainQueue({
				result(NSError(domain: "数据异常", code: HRErrorCode.DataError.rawValue, userInfo: nil))
			})
			return
		}
		var data = [Byte]()
		data.append(HRDatabase.shareInstance().acount.permission)
		data.append(relayBox.devType)
		data += relayBox.devAddr.getBytes()
		data.append(Byte(relayBox.relays.count))
		for relay in relayBox.relays {
			data.append(relay.relaySeq)
			data.append(0x01)
			data += relay.name.getBytesUsingGBK(32)
			data += relay.insRoomID.getBytes()
			data += relay.insFloorID.getBytes()
			data += [Byte](count: 28, repeatedValue: 0)
		}
		//随机sn
		let randSn = Byte(arc4random() % 128)
		let sendframe = HRFrame(destAddr: relayBox.hostAddr, sn: randSn, command: HRCommand.BindLoadToRelay, data: data)
		
		tcpConn?.sendAndReceive(sendframe,
			filter: { (rcvFrame) -> Bool in
			if rcvFrame.sn == randSn {
				if rcvFrame.isExceptionFrame &&
				rcvFrame.commandIgnoreException == HRCommand.BindLoadToRelay.rawValue {
					return true
				} else if rcvFrame.commandIgnoreException == HRCommand.BindLoadToRelay.rawValue {
					return true
				}
			}
			return false
		}, receive: { (rcvFrame, error) -> Void in
			if let frame = rcvFrame {
				runOnMainQueue({
					result(frame.exception)
				})
			} else {
				runOnMainQueue({
					result(error)
				})
			}
		})
		
	}
	
	///修改情景面板绑定的动作
	func doEditScenePanelBindings(scenePanel: HRScenePanel, result: ((NSError?)->Void)? ) {
		var data = [Byte]()
		data.append(HRDatabase.shareInstance().acount.permission)
		data += scenePanel.devAddr.getBytes()
		data.append(Byte(scenePanel.keyStatusBind.count))
		for i in 1...scenePanel.keyStatusBind.count {
			let bindState = scenePanel.keyStatusBind[i-1]
			data.append(Byte(i))
			data.append(bindState.devType)
			data += bindState.hostAddr.getBytes()
			data.append(bindState.devType)
			data += bindState.devAddr.getBytes()
			data += bindState.operation.getBytes()
		}
		
		let randSn = Byte(arc4random_uniform(128))
		let frame = HRFrame(destAddr: scenePanel.hostAddr, sn: randSn, command: HRCommand.ScenePanelBinding, data: data)
		self.tcpConn?.sendAndReceive(frame, filter: { rcvFrame in
			if rcvFrame.sn != randSn { return false }
			if rcvFrame.commandIgnoreException == frame.command { return true }
			return false
			}, receive: { rcvFrame, error in
				if let exception = rcvFrame?.exception {
					runOnMainQueue({
						result?(exception)
					})
					return
				}
				runOnMainQueue({
					result?(error)
				})
				return
		})
		
	}
	
	///编辑设备的基本信息（名称、安装的房间和楼层）
	func doEditDeviceInfo(device: HRDevice, result:((NSError?)->Void)?) {
		var data = [Byte]()
		data.append(HRDatabase.shareInstance().acount.permission)
		data.append(0xFF)
		data.append(device.devType)
		data += device.devAddr.getBytes()
		data += device.name.getBytesUsingGBK(32)
		data += device.insRoomID.getBytes() + device.insFloorID.getBytes()
		data += [Byte](count: 28, repeatedValue: 0)
		
		let randSn = Byte(arc4random_uniform(128))
		let frame = HRFrame(destAddr: device.hostAddr, sn: randSn, command: HRCommand.EditDevUserInfo, data: data)
		self.tcpConn?.sendAndReceive(frame, filter: { rcvFrame in
			if rcvFrame.sn != randSn { return false }
			if rcvFrame.commandIgnoreException == frame.command { return true }
			return false
			}, receive: { rcvFrame, error in
				if let exception = rcvFrame?.exception {
					runOnMainQueue({
						result?(exception)
					})
					return
				}
				runOnMainQueue({
					result?(error)
				})
				return
		})
	}
	


//MARK: - 删除设备
	

	///删除设备，支持同时删除多台主机的设备
	///
	/// - parameter devices: 设备列表，可以为不同主机的设备
	/// - parameter result:	结果回调
	func doDeleteRemoteDevice(devices: [HRDevice], result: ((NSError?)->Void)?) {
		if devices.count == 0 {
			result?(NSError(domain: "没有指定要删除的设备", code: HRErrorCode.Other.rawValue, userInfo: nil))
			return
		}
		/// 设备分组，按照不同主机进行分组
		var devsGroups = [[HRDevice]]()
		for dev in devices {
			var devIsAdded = false
			let groupCount = devsGroups.count
			for gi in 0..<groupCount {
				var group = devsGroups[gi]
				if group.count > 0 && group[0].hostAddr == dev.hostAddr {
					group.append(dev)
					devIsAdded = true
				}
			}
			if !devIsAdded {
				var group = [HRDevice]()
				group.append(dev)
				devsGroups.append(group)
			}
		}
		
		var firstFrame = true
		
		for group in devsGroups {
			var data = [Byte]()
			data.append(HRDatabase.shareInstance().acount.permission)
			data.append(Byte(group.count))
			for dev in group {
				data.append(dev.devType)
				data += dev.devAddr.getBytes()
			}
			let sn = Byte(arc4random() % 128)
			let frame = HRFrame(destAddr: group[0].hostAddr, sn: sn, command: HRCommand.DeleteDevice, data: data)
			if !firstFrame {
				self.tcpConn?.send(frame)
				firstFrame = false
			} else {
				self.tcpConn?.sendAndReceive(frame, filter: { (rcvFrame) in
					if rcvFrame.sn != sn {
						return false
					}
					if rcvFrame.commandIgnoreException == frame.command {
						return true
					}
					return false
				}, receive: { (rcvFrame, error) in
					if let exception = rcvFrame?.exception {
						runOnMainQueue({
							result?(exception)
						})
						return
					}
					runOnMainQueue({
						result?(error)
					})
				})
			}
		}
	}
	

	///删除应用设备
	///
	/// - parameter appDevice: 应用设备对象
	/// - parameter result:    结果回调
	func doDeleteApplyDevice(appDevice: HRApplianceApplyDev, result: ((NSError?)->Void)?){
		var data = [Byte]()
		data.append(HRDatabase.shareInstance().acount.permission)
		data.append(appDevice.appDevType)
		data += UInt16(appDevice.appDevID).getBytes()
		let randSn = Byte(arc4random() % 128)
		
		let frame = HRFrame(destAddr: appDevice.hostAddr, sn: randSn, command: HRCommand.DeleteApplyDev, data: data)
		
		self.tcpConn?.sendAndReceive(frame, filter: { (rcvFrame) in
			if rcvFrame.sn != randSn {
				return false
			}
			if rcvFrame.commandIgnoreException == frame.command {
				return true
			}
			return false
			}, receive: { (rcvFrame, error) in
				if let exception = rcvFrame?.exception {
					runOnMainQueue({
						result?(exception)
					})
					return
				}
				if let rFrame = rcvFrame {
					if rFrame.data.count >= 1 && rFrame.data[0] == 0x01 { //删除失败
						runOnMainQueue({
							result?(NSError(domain: "0x01", code: HRErrorCode.CreateEditDeleteAppDevFail.rawValue, userInfo: nil))
						})
						return
					}
				}
				runOnMainQueue({
					result?(error)
				})
		})
	}
	
	///删除情景
	func doRemoveScene(scene: HRScene, result: ((NSError?)->Void)?) {
		var data = [Byte]()
		data.append(HRDatabase.shareInstance().acount.permission)
		data.append(scene.id)
		let randSn = Byte(arc4random() % 128)
		let frame = HRFrame(destAddr: scene.hostAddr, sn: randSn, command: .DeleteScene, data: data)
		
		self.tcpConn?.sendAndReceive(frame, filter: { (rcvFrame) in
			if rcvFrame.sn != randSn {
				return false
			}
			if rcvFrame.commandIgnoreException == HRCommand.DeleteScene.rawValue {
				return true
			}
			return false
			}, receive: { (rcvFrame, error) in
				if let exception = rcvFrame?.exception {
					runOnMainQueue({
						result?(NSError(domain: "异常", code: exception.code, userInfo: nil))
					})
					return
				}
				runOnMainQueue({
					result?(error)
				})
		})
	}
	
	///删除定时任务
	func doRemoveTask(task: HRTask, result: ((NSError?)->Void)?) {
		var data = [Byte]()
		data.append(HRDatabase.shareInstance().acount.permission)
		data.append(task.id)
		let randSn = Byte(arc4random() % 128)
		let frame = HRFrame(destAddr: task.hostAddr, sn: randSn, command: HRCommand.DeleteAlarmTask, data: data)
		
		self.tcpConn?.sendAndReceive(frame, filter: { (rcvFrame) in
			if rcvFrame.sn != randSn { return false }
			return rcvFrame.commandIgnoreException == HRCommand.DeleteAlarmTask.rawValue
			}, receive: { (rcvFrame, error) in
				if let exception = rcvFrame?.exception {
					runOnMainQueue({
						result?(NSError(domain: "异常", code: exception.code, userInfo: nil))
					})
					return
				}
				runOnMainQueue({
					result?(error)
				})
		})
	}
	
	///删除楼层
	///
	/// - parameter floor: 楼层
	func doDeleteFloor(floor: HRFloorInfo, result:((NSError?)->Void)?) {
		var data = [Byte]()
		data.append(HRDatabase.shareInstance().acount.permission)
		data += UInt16(floor.id).getBytes()
		
		let randSn = Byte(arc4random_uniform(128))
		let frame = HRFrame(destAddr: floor.hostAddr, sn: randSn, command: HRCommand.DeleteFloor, data: data)
		tcpConn?.sendAndReceive(frame, filter: { (rcvFrame) -> Bool in
			if rcvFrame.sn != randSn { return false }
			if rcvFrame.commandIgnoreException != frame.command { return false }
			return true
			}, receive: { (rcvFrame, error) -> Void in
				if let exception = rcvFrame?.exception {
					runOnMainQueue({
						result?(exception)
					})
					return
				}
				runOnMainQueue({
					result?(error)
				})
		})
	}

	
	
//MARK: - 操作设备
	
    ///启动情景
    ///
    ///- parameter sceneId:  情景ID
    ///- parameter callback: 闭包回调，不管情景启动成功与否，都会调用一次该回调。
    func doStartScene(scene: HRScene, callback: (NSError?)->Void){
        var data = [Byte]()
        data.append(scene.id)
        let frame = HRFrame(destAddr: scene.hostAddr, sn: HRFrameSn.StartScene.rawValue, command: HRCommand.StartScene, data: data)
        
        tcpConn?.sendAndReceive(frame, filter: {
            (rcvFrame) in
            if rcvFrame.sn != HRFrameSn.StartScene.rawValue {
                return false
            }
            return rcvFrame.command == HRCommand.StartScene.rawValue
                && rcvFrame.data[0] == scene.id
        }, receive: {
            (retFrame, error) in
			runOnMainQueue({
				callback(error)
			})
        })
    }
	
    
    ///操作继电器、智能开关和智能插座
    ///
    ///- parameter actionType:   操作方式：开、关、翻转或保持不变，使用HRRelayOperateType枚举
    ///- parameter relay:        继电器对象
    ///- parameter delay:        延迟码，该延迟码是发送给主机的，以秒为单位
    ///- parameter callback:     结果回调，不管操作成功与否，都会调用一次该回调
    func doOperateRelay(actionType type: HRRelayOperateType, relay: HRRelayInBox, delay: Byte, callback: (NSError?)->Void){
        //这里是最底层，构造数据帧 通过socket发送出去给主机
        
        //print("这里是最底层，构造数据帧 通过socket发送出去给主机 ")
        let command: Byte
        switch relay.devType {
        case HRDeviceType.SwitchPanel.rawValue:
            command = HRCommand.OperateSwitchPanel.rawValue
			
        case HRDeviceType.RelayControlBox.rawValue:
            command = HRCommand.OperateRelayCtrlBox.rawValue
			
        case HRDeviceType.SocketPanel.rawValue:
            command = HRCommand.OprateSocketPanel.rawValue
			
		case HRDeviceType.LiveWireSwitch.rawValue:
			command = HRCommand.LiveWireSwitch.rawValue
			
        default: command = HRCommand.OperateRelayCtrlBox.rawValue
        }
        var data = [Byte]()
        data.append(relay.devType)
        data += relay.devAddr.getBytes()
        data.append(delay)
        var state = 0b1111_1100 + type.rawValue
        state = (state << (2 * relay.relaySeq)) + (1<<(2 * relay.relaySeq)-1)
        data.append(state)
		
        let randSn = Byte(arc4random_uniform(128))
		
        let frame = HRFrame(destAddr: relay.hostAddr, sn: randSn, command: command, data: data)
        
       // print(frame.lenght)
       // print(relay.name)
       // print(frame.toString())
		Log.verbose("控制“\(relay.name)”,发送数据：\(frame.toString())")
        tcpConn?.sendAndReceive(frame,
            filter: { (rcvFrame) in
				//控制单火开关时，发出去的帧序号和接收的可能不一致，所以对帧序号的判断可以忽略
                if relay.devType != HRDeviceType.LiveWireSwitch.rawValue
					&& rcvFrame.sn != randSn{  return false  }
				if rcvFrame.data.count < 5 { return false }
				
				let devType = rcvFrame.data[0]
				let devAddr = UInt32(fourBytes: Array(rcvFrame.data[1...4]))
				//如果带延时码，则接受到的应该是0x01命令的响应帧
				if delay != 0 && rcvFrame.commandIgnoreException == HRCommand.ACK.rawValue{
					if devAddr == relay.devAddr && devType == relay.devType {
						return true
					}
					return false
				}
				if rcvFrame.commandIgnoreException != frame.command { return false }
                if devType == relay.devType && devAddr != relay.devAddr {
                    return false
                }
                return true
            }, receive: { (rcvFrame, error) in
				if let exception = rcvFrame?.exception {
					runOnMainQueue({
						callback(exception)
					})
					return
				}
                runOnMainQueue({
                    if rcvFrame == nil {
                        callback(error)
                        return
                    }
                    callback(nil)
                    return
                })
        })
    }
	
	///操作电机类设备， 包括窗帘，机械手
	///
	/// - parameter action: 操作类型，HRMotorOperateType
	/// - parameter motor:	电机对象, 可以是窗帘或机械手对象
	/// - parameter delay:	延迟，
	/// - parameter callback: 结果回调
    func doOperateMotorDev(action: HRMotorOperateType, motor: HRMotorCtrlDev, delay: Byte, callback:((NSError?)->Void)?){
		
		var data = [Byte]()
		data.append(motor.devType)
		data += motor.devAddr.getBytes()
		data.append(delay)
		data.append(action.rawValue)
		
		let randSn = Byte(arc4random_uniform(128))
		let frame: HRFrame
		if motor is HRCurtainCtrlDev {
			frame = HRFrame(destAddr: motor.hostAddr, sn: randSn, command: HRCommand.MotorCtrl, data: data)
		} else if motor is HRManipulator {
			frame = HRFrame(destAddr: motor.hostAddr, sn: randSn, command: HRCommand.Manipulator, data: data)
		} else {
			Log.error("doOperateMotorDev: 不支持的电机类设备\(motor.devType)")
			return
		}
		
        tcpConn?.sendAndReceive(frame, filter: {
            (rcvFrame) in
				//判断帧序号
				if randSn != frame.sn { return false }
				//判断控制码是否一致
				if frame.commandIgnoreException == frame.command { return true }
				return false
            }, receive: {
                (rcvFrame, error) in
				if let exception = rcvFrame?.exception {
					runOnMainQueue({
						callback?(exception)
					})
					return
				}
				runOnMainQueue({
					callback?(error)
				})
        })
    }
    
    ///操作/遥控红外转发器
    ///
    ///- parameter apply:        应用设备对象
    ///- parameter infraredType: 操作类型:0x00表示初始化，0x01表示码库匹配,0x02表示正常操作
    ///- parameter infraredKey:  操作的按键码对象，每个红外转发器都有很多个红外码，InfraredKey是一个红外码的描述类型
	///- parameter tag:			帧标记
    ///- parameter delay:        延时码
    ///- parameter callback:     结果（闭包）
    func doOperateInfrared(apply: HRApplianceApplyDev, infraredType: Byte, infraredKey: HRInfraredKey, tag: Byte, delay: Byte, callback: ((NSError?)->Void)?) {
		
		var data = [Byte]()
		data.append(delay)
		data.append(infraredType)  //0x00表示初始化，0x01表示码库匹配,0x02表示正常操作
		data.append(apply.appDevType) //设备类型
		data += apply.appDevID.getBytes()[0...1]   //应用设备ID
		if infraredType == 0x00 {
			//以下三个属性构成码库索引
			data.append(infraredKey.codeLibType)
			data += infraredKey.codeLibIndex.getBytes().reverse()
			data += [0x01, 0x03, 0x1A, 0x08, 0x0B]
		} else {
			//按键编码
			data.append(infraredKey.keyCode)
			//以下三个属性构成码库索引
			data.append(infraredKey.codeLibType)
			data += infraredKey.codeLibIndex.getBytes().reverse()
			data.append(infraredKey.operateCode)
		}
		let frame = HRFrame(destAddr: apply.hostAddr, sn: tag, command: HRCommand.InfraredTransmit, data: data)
		if callback == nil {
			tcpConn?.send(frame)
			return
		}
		
        tcpConn?.sendAndReceive(frame, filter: { (rcvFrame) in
				if rcvFrame.sn != tag { return false }
				return rcvFrame.commandIgnoreException == HRCommand.InfraredTransmit.rawValue
            }, receive: {  (rcvFrame, error) in
				if let exception = rcvFrame?.exception {
					runOnMainQueue({
						callback?(exception)
					})
				}
				runOnMainQueue({
					callback?(error)
				})
        })
    }
    
    ///开锁。执行开锁操作时，主机先后会有两个帧回复：第一个是确认收到帧，命令码0x01；第二个是状态帧，即上送门锁状态，命令码0x02。
    ///
    ///- parameter door: 智能门锁对象
    ///- parameter passwd: 开锁密码
    ///- parameter stateCode: 设备控制的状态码
    ///- parameter callback: 结果回调
    func doUnlockDoor(door: HRDoorLock, passwd:[Byte], stateCode: Byte, tag: Byte, callback:(NSError?)->Void) {
		
		var data = [Byte]()
		data.append(door.devType)
		data += door.devAddr.getBytes()
		data += passwd
		data.append(stateCode)
		let frame = HRFrame(destAddr: door.hostAddr, sn: tag, command: HRCommand.DoorLock, data: data)
		
        tcpConn?.sendAndReceive(frame, filter: {
            (rcvFrame) in
			
				if let _ = rcvFrame.exception { //异常帧
					if tag == rcvFrame.sn &&
						rcvFrame.command == HRCommand.DoorLock.rawValue + 128{
							return true
					}
					return false
				}
				//先判断控制码是否为CommitDeviceState，即上送设备状态，并且设备类型和设备地址都要一致
				if ( rcvFrame.command == HRCommand.CommitDeviceState.rawValue ) {
					let devType = rcvFrame.data[0]
					let devAddr = UInt32(fourBytes: Array(rcvFrame.data[1...4]))
					if devType == door.devType && devAddr == door.devAddr{
						return true
					}
					return false
				}
				return false
			
            }, receive: {
                (rcvFrame, error) in
				if rcvFrame == nil {
					runOnMainQueue({
						callback(error)
					})
					return
				}
				
				if let err = rcvFrame!.exception {
					//异常的异常码为7代表权限不过，在操作门锁时就是密码错误的意思
					if err.code == HRErrorCode.FrameError.rawValue + 7 {
						runOnMainQueue({
							callback(NSError(domain: "密码错误", code: HRErrorCode.FrameError.rawValue + 7, userInfo: nil))
						})
						return
					}
					runOnMainQueue({
						callback(err)
					})
					return
				}
				/*
				对于智能门锁，
				frame   大小      描述
				0       1       设备类型
				1-4     4       设备地址
				5       1       布防状态
				6       1       状态
				对于frame[6]，即门锁状态，八位中：
				D0 == 0 :   关锁
				DO == 1 :   开锁
				D1 == 0 :   电池电量正常
				D1 == 1 :   电池电量不足
				*/
				if rcvFrame!.data[6] & 0x01 == 1 {
					runOnMainQueue({
						callback(nil)
					})
				} else{
					runOnMainQueue({
						callback(NSError(domain: "打开失败", code: -1, userInfo: nil))
					})
				}
				if rcvFrame!.data[5] & 0x03 != 0{
					runOnMainQueue({
						callback(NSError(domain: "电池电量不足", code: HRErrorCode.BatteryLowPower.rawValue, userInfo: nil))
					})
				}
				return
        })
        
    }
    
    
    
    
    //添加的新方法 高盾锁的开锁帧  门锁相关
    
    func doUnlockSmartDoor(door: HRSmartDoor, passwd:[Byte], stateCode: Byte, tag: Byte, callback:(NSError?)->Void) {
        
        
        var data = [Byte]()
        //设备类型
        data.append(door.devType)
        //设备地址 门锁通信盒子rf地址
        data += door.devAddr.getBytes()
        //0x03开锁请求
        data.append(0x03)
        //身份ID
       data.append(0x00)
        data.append(0x00)
        
       // passwd
        
        //

        data += passwd
      
        
        
        print("密码\(passwd)")
    
        
        
       let frame = HRFrame(destAddr: door.hostAddr, sn: tag, command: HRCommand.GaoDunDoor, data: data)

        
        
        
        tcpConn?.sendAndReceive(frame, filter: {
            (rcvFrame) in
            
          //  print("开锁状态\(rcvFrame.data[8])")
            
            
            if rcvFrame.command == HRCommand.GaoDunDoor.rawValue
            {
                
                print("高盾返回的")
                return true
            }
            
         
            return false
            
            }, receive: {
                (rcvFrame, error) in
                if rcvFrame == nil {
                    runOnMainQueue({
                        callback(error)
                    })
                    return
                }
                
                /*
                 对于智能门锁，
                 frame   大小      描述
                 0       1       设备类型
                 1-4     4       设备地址
                 5       1       布防状态
                 6       1       状态
                 对于frame[6]，即门锁状态，八位中：
                 D0 == 0 :   关锁
                 DO == 1 :   开锁
                 D1 == 0 :   电池电量正常
                 D1 == 1 :   电池电量不足
                 */
                
                print("开锁状态啊啊啊啊啊啊啊啊啊啊\(rcvFrame!.data[8])")
                if rcvFrame!.data[8]==0x03 {
                    runOnMainQueue({
                        callback(nil)
                    })
                }
                
                
                else if rcvFrame!.data[8]==0x04{
                    
                    runOnMainQueue({
                        callback(NSError(domain: "密码错误", code: -1, userInfo: nil))
                    })
                    
                }
                    
                    
                    
                else if rcvFrame!.data[8]==0x05{
                    
                    runOnMainQueue({
                        callback(NSError(domain: "密钥错误", code: -1, userInfo: nil))
                    })
                    
                }
                    
                    
                    
                else if rcvFrame!.data[8]==0x06{
                    
                    runOnMainQueue({
                        callback(NSError(domain: "非法用户", code: -1, userInfo: nil))
                    })
                    
                }
                    
                else if rcvFrame!.data[8]==0x07{
                    
                    runOnMainQueue({
                        callback(NSError(domain: "授权失败", code: -1, userInfo: nil))
                    })
                    
                }
                    
                else if rcvFrame!.data[8]==0x08{
                    
                    runOnMainQueue({
                        callback(NSError(domain: "操作失败", code: -1, userInfo: nil))
                    })
                    
                }
                    
                else if rcvFrame!.data[8]==0x09{
                    
                    runOnMainQueue({
                        callback(NSError(domain: "未配对", code: -1, userInfo: nil))
                    })
                    
                }
                
                
                else{
                    runOnMainQueue({
                        callback(NSError(domain: "打开失败", code: -1, userInfo: nil))
                    })
                }
                if rcvFrame!.data[5] & 0x03 != 0{
                    runOnMainQueue({
                        callback(NSError(domain: "电池电量不足", code: HRErrorCode.BatteryLowPower.rawValue, userInfo: nil))
                    })
                }
                return
        })

        
        
        
    }
    
    
	
    ///控制智能床
	///
    func doOperateSmartBed(bed: HRSmartBed, action: Byte, content: [Byte], tag: Byte) {
		
		var data = [Byte]()
		data.append(bed.devType)
		data += bed.devAddr.getBytes()
		data.append(action)
		data += content
		let frame = HRFrame(destAddr: bed.hostAddr, sn: HRFrameSn.SmartBed, command: HRCommand.SmartBed, data: data)
		tcpConn?.send(frame)
    }
	
	/**
	控制RGB灯
	- parameter rgbLamp:  RGB灯对象
	- parameter mode:     模式`HRRGBCtrlMode`
	- parameter rgbValues:  RGB值数组，长度不能小于3。当mode为RGB时，不能为空，其他模式该参数无效
	- parameter speed:    速度，范围1~3，分别对应慢中快。当mode为Gradient、Step、Rainbow这三种模式时，该参数不能为空，其他模式该参数无效
	- parameter duration: 循环时间，范围0~7200秒。当mode为Gradient、Step、Rainbow这三种模式时，该参数不能为空，其他模式该参数无效
	- parameter delay:	  延时, 范围0~250，0表示不延时。单位为秒
	- parameter result:   控制返回的结果。
	*/
	func doOperateRGBLamp(rgbLamp: HRRGBLamp, mode: HRRGBCtrlMode, rgbValues: [Byte]?, speed: Byte?, duration: UInt16?, delay: Byte, result: ((NSError?)->Void)?) {
		var data = [Byte]()
		data.append(HRDeviceType.RGBLamp.rawValue)
		data += rgbLamp.devAddr.getBytes()
		data.append(delay)
		data.append(mode.rawValue)
		switch mode {
		case .RGB:
			if rgbValues == nil || rgbValues!.count < 3 {
				runOnMainQueue({
					result?(NSError(domain: "rgbVars参数为空或长度不足3", code: HRErrorCode.OperateRGBLampFailed.rawValue, userInfo: nil))
				})
				return
			}
			data += rgbValues![0...2]
		case .Gradient, .Step, .Rainbow:
			if speed == nil || duration == nil {
				runOnMainQueue({
					result?(NSError(domain: "未设置速度或循环时间", code: HRErrorCode.OperateRGBLampFailed.rawValue, userInfo: nil))
				})
				return
			}
			data.append(speed!)
			data += duration!.getBytes()
		case .Night:
			data += [0x44, 0x44, 0x44]
		case .Lighting:
			data += [0xCC, 0xCC, 0xCC]
		}
		
		let randSn = Byte(arc4random_uniform(128))
		let frame = HRFrame(destAddr: rgbLamp.hostAddr, sn: randSn, command: HRCommand.OprateRGBLamp, data: data)
		
		tcpConn?.sendAndReceive(frame, filter: { (rcvFrame) -> Bool in
			if rcvFrame.sn != randSn { return false }
			if rcvFrame.commandIgnoreException == HRCommand.ACK.rawValue && delay != 0 { return true }
			if rcvFrame.commandIgnoreException == frame.command { return true }
			return false
			}, receive: { (rcvFrame, error) -> Void in
				if let err = rcvFrame?.exception {
					runOnMainQueue({
						result?(err)
					})
					return
				}
				runOnMainQueue({
					result?(error)
				})
		})
		
	}
	
	//MARK: - 红外学习
	
	///红外学习-请求开始学习，流程0x01
	func doLearningInfraredStart(appDevice: HRApplianceApplyDev, result: ((NSError?)->Void)?) {
		var data = [Byte]()
		data.append(HRDatabase.shareInstance().acount.permission)
		data.append(0x01)
		data.append(appDevice.appDevType)
		data += UInt16(appDevice.appDevID).getBytes()
		
		let randSn = Byte(arc4random_uniform(128))
		let frame = HRFrame(destAddr: appDevice.hostAddr, sn: randSn, command: HRCommand.InfraredLearning, data: data)
		
		self.tcpConn?.sendAndReceive(frame, filter: { (rcvFrame) in
			if rcvFrame.sn != randSn { return false }
			if rcvFrame.commandIgnoreException != frame.command { return false }
			if rcvFrame.isExceptionFrame { return true }
			return rcvFrame.data.count > 0 && rcvFrame.data[0] == 0x01
			}, receive: { (rcvFrame, error) in
				if let exception = rcvFrame?.exception {
					runOnMainQueue({
						if exception.code == 1021 {
							result?(NSError(domain: "其他客户端正在学习!", code: exception.code, userInfo: nil))
						} else  {
							result?(exception)
						}
					})
					return
				}
				if rcvFrame != nil && rcvFrame!.data[1] == 0x01 { //请求失败
					runOnMainQueue({
						result?(NSError(domain: "当前不可学习", code: HRErrorCode.InfraredLearnRequestFailure.rawValue, userInfo: nil))
					})
					return
				}
				runOnMainQueue({
					result?(error)
				})
		})
		
	}
	
	///红外学习-请求按键学习，流程0x02
	///
	///- parameter appDevice 应用设备
	///- parameter keyCode 按键编码
	///- parameter result 结果回调
	func doLearningInfraredRecordKey(appDevice: HRApplianceApplyDev, keyCode: Byte, result: ((NSError?)->Void)?) {
		var data = [Byte]()
		data.append(HRDatabase.shareInstance().acount.permission)
		data.append(0x02)
		data.append(appDevice.appDevType)
		data += UInt16(appDevice.appDevID).getBytes()
		data.append(keyCode)
		data += [0xFF, 0x00, 0x00, keyCode]
		
		let randSn = Byte(arc4random() % 128)
		let frame = HRFrame(destAddr: appDevice.hostAddr, sn: randSn, command: HRCommand.InfraredLearning, data: data)
		tcpConn?.sendAndReceive(frame, filter: { (rcvFrame) in
			if rcvFrame.sn != randSn { return false }
			if rcvFrame.commandIgnoreException != frame.command { return false }
			if rcvFrame.isExceptionFrame { return true }
			return rcvFrame.data.count > 0 && rcvFrame.data[0] == 0x02
			}, receive: { (rcvFrame, error) in
				if let exception = rcvFrame?.exception {
					runOnMainQueue({
						result?(exception)
					})
					return
				}
				runOnMainQueue({
					result?(error)
				})
		})
		
	}
	
	///红外学习-请求停止学习，流程0x03
	func doLearningInfraredStop(appDevice: HRApplianceApplyDev, result: ((NSError?)->Void)?) {
		var data = [Byte]()
		data.append(HRDatabase.shareInstance().acount.permission)
		data.append(0x03)
		data.append(appDevice.appDevType)
		data += UInt16(appDevice.appDevID).getBytes()
		
		let randSn = Byte(arc4random() % 128)
		let frame = HRFrame(destAddr: appDevice.hostAddr, sn: randSn, command: HRCommand.InfraredLearning, data: data)
		
		self.tcpConn?.sendAndReceive(frame, filter: { (rcvFrame) in
			if rcvFrame.sn != randSn { return false }
			if rcvFrame.commandIgnoreException != frame.command { return false }
			if rcvFrame.isExceptionFrame { return true }
			return rcvFrame.data.count > 0 && rcvFrame.data[0] == 0x03
			}, receive: { (rcvFrame, error) in
				if let exception = rcvFrame?.exception {
					runOnMainQueue({
						result?(exception)
					})
					return
				}
				runOnMainQueue({
					result?(error)
				})
		})
	}
	
	
	///使用红外码库手动进行匹配，操作类型0x04
	func doLearningInfraredUseLibrary(appDevice: HRApplianceApplyDev, codeLibIndex: UInt16, result: ((NSError?)->Void)?) {
		var data = [Byte]()
		data.append(HRDatabase.shareInstance().acount.permission)
		data.append(0x04)
		data.append(appDevice.appDevType)
		data += UInt16(appDevice.appDevID).getBytes()
		data.append(0xFF)
		//以下4个字节填红外码库索引
		data.append(HRInfraredKeyCodeLibType.AirCtrl.rawValue)
		data += codeLibIndex.getBytes().reverse()
		data.append(0xFF)
		let randSn = Byte(arc4random() % 128)
		let frame = HRFrame(destAddr: HRDatabase.shareInstance().server.hostAddr, sn: randSn, command: HRCommand.InfraredLearning, data: data)
		self.tcpConn?.sendAndReceive(frame, filter: { rcvFrame in
			if rcvFrame.sn != randSn { return false }
			if rcvFrame.commandIgnoreException != frame.command { return false }
			if rcvFrame.isExceptionFrame { return true }
			return rcvFrame.data.count > 0 && rcvFrame.data[0] == 0x04
			}, receive: { (rcvFrame, error) in
				if let exception = rcvFrame?.exception {
					runOnMainQueue({
						result?(exception)
					})
					return
				}
				guard let _frame = rcvFrame else {
					runOnMainQueue({
						result?(error)
					})
					return
				}
				//判断数据域长度
				if _frame.data.count < 10 {
					runOnMainQueue({
						result?(NSError(domain: "数据异常", code: HRErrorCode.InfraredLearnRetDataTooSmall.rawValue, userInfo: nil))
					})
					return
				}
				//判断数据域的最后一位，也就是学习的结果成功与否，0x00成功
				if _frame.data[9] == 0x00 {
					runOnMainQueue({
						result?(nil)
					})
				} else {
					runOnMainQueue({
						result?(NSError(domain: "学习失败", code: HRErrorCode.InfraredLearnFailure.rawValue, userInfo: nil))
					})
				}
		})
	}
	

}
