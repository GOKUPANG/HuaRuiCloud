//
//  SearchLocalHost.swift
//  SmartBed
//
//  Created by sswukang on 15/7/11.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import Foundation


/// 搜索本地主机
class HRSearchLocalHost {
    var userName: String
    var password: String
    var addr: String
    var port: UInt16
    
    private var _socket : UDPServer!
    private var _isSearching = false
    
    init(userName: String, password: String, addr:String=BROADCAST_ADDRESS, port: UInt16=UDP_HOST_PORT) {
        self.userName = userName
        self.password = password
        self.port     = port
        self.addr     = addr
        self._socket  = UDPServer(port: port)
    }
	
	/**
	搜索主机
	
	- parameter result:      结果闭包
	- parameter timeout:     超时时间，ms
	- parameter searchTimes: 搜索次数
	*/
    func search(result: (((HRServerHost?, NSError?)->Void)), timeout: Int32 = BROADCAST_TIME_OUT, searchTimes: Int = SEND_BROADCAST_TIMES) {
		
		if reachChecker?.currentReachabilityStatus != .ReachableViaWiFi {
			result(nil, NSError(domain: "使用WWAN中", code: HRErrorCode.SearchLocalServerWithoutWifiStatus.rawValue, userInfo: nil))
			self.closeSocket()
			return
		}
        runOnGlobalQueue({
            if self._socket == nil {
                self._socket = UDPServer(port: self.port)
            }
            ///构造数据域，数据域由32字节的用户名和16字节的密码组成
            var data = [Byte]()
            let nameData = ContentHelper.decodeGbkData(self.userName)
            if nameData.count >= 32 {
                data += nameData[0...31]
            } else {
                data += nameData
                data += [Byte](count: 32-nameData.count, repeatedValue: 0)
            }
            let passwdData = ContentHelper.decodeGbkData(self.password)
            if passwdData.count >= 16 {
                data += passwdData[0...15]
            } else {
                data += passwdData
                data += [Byte](count: 16-passwdData.count, repeatedValue: 0)
            }
            let frameData = HRFrame(destAddr: 0xFFFF_FFFF, sn: 0xA, command: HRCommand.BraodcastSearchHost.rawValue, data: data).toTransmitFrame()!
            var currentTimes = 0
            
            //开始循环发送
            Log.debug("################### 开始搜索主机 ###################")
            self._isSearching = true
            while(self._isSearching && currentTimes <= searchTimes) {
				currentTimes += 1
                self._socket.send(self.addr, data: frameData)
                Log.debug("第\(currentTimes)次发送广播包。监听中...")
                self._socket.setRcvTimeout(timeout)
                
                let (host, error) = self.receive()
                if host == nil && currentTimes == searchTimes {
                    self.closeSocket()
                    result(nil, error)
                    return
                } else if host == nil && currentTimes < searchTimes {
                    continue
                } else if host != nil {
                    self.closeSocket()
                    result(host, error)
                    return
                }
            }
            self.closeSocket()
            result(nil, NSError(domain: "搜索主机超时", code: HRErrorCode.SearchHostTimeout.rawValue, userInfo: nil))
            
        })
    }
    
    private func receive() -> (HRServerHost?, NSError?){
        let (rcvData, rcvAddr, rcvPort) = self._socket.recv(120)
        if rcvData == nil {
            return (nil, NSError(domain: rcvAddr, code: rcvPort, userInfo: nil))
        } else {
            if let frame = HRFrame.initWithData(rcvData!) {
                ///如果不是由智能主机发起的，则重新接收
                if frame.direction != 0x01 {
                    if let ipBytes = ContentHelper.hostStringToArry(rcvAddr) {
                        hrLocalIPAddr = UInt32(fourBytes: Array(ipBytes.reverse()))
                    }
                    return receive()
                }
                if let host = HRServerHost.initWithUDPFrame(frame) {
					//有时候主机会莫名其妙的在数据返回IP是0.0.0.0，认为搜索失败
					if host.IPAddr != 0 {
						return (host, nil)
					}
                }
            }
            return (nil, NSError(domain: "数据出错", code: HRErrorCode.LoginRcvDataError.rawValue, userInfo: nil))
        }
    }
    
    func stopSearch() {
        self._isSearching = false
    }
    
    private func closeSocket() {
        self._socket.close()
        self._socket = nil
    }
    
}