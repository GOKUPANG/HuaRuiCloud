//
//  ScenePanelViewModel.swift
//  huarui
//
//  Created by sswukang on 15/10/29.
//  Copyright © 2015年 huarui. All rights reserved.
//

import Foundation

class ScenePanelViewModel {
	
	var scenePanel: HRScenePanel
	
	var name: String {
		get { return scenePanel.name }
		set { scenePanel.name = newValue }
	}
	
	///面板的有效按键数量
	var numberOfValidKeys: Int {
		return scenePanel.enableKeysCount
	}
	
	var insRoomName: String = "" {
		didSet {
			if let roomId = HRDatabase.shareInstance().getRoomID(insFloorName, roomName: insRoomName) {
				self.scenePanel.insRoomID = roomId
			}
		}
	}
	
	var insFloorName: String = "" {
		didSet {
			if let floorId = HRDatabase.shareInstance().getFloorID(insFloorName) {
				self.scenePanel.insFloorID = UInt16(floorId)
			}
		}
	}
	
	var floorNames: [String] {
		return HRDatabase.shareInstance().floorNames
	}
	
	var roomNames: [String] {
		if let names = HRDatabase.shareInstance().roomNames[insFloorName]{
			return names
		}
		return [String]()
	}
	
	init(scenePanel: HRScenePanel) {
		self.scenePanel = HRScenePanel()
        self.scenePanel.devType       = scenePanel.devType
        self.scenePanel.devAddr       = scenePanel.devAddr
        self.scenePanel.hostAddr      = scenePanel.hostAddr
        self.scenePanel.name          = scenePanel.name
        self.scenePanel.channel       = scenePanel.channel
        self.scenePanel.RFAddr        = scenePanel.RFAddr
        self.scenePanel.RFVersion     = scenePanel.RFVersion
        self.scenePanel.insRoomID     = scenePanel.insRoomID
        self.scenePanel.insFloorID    = scenePanel.insFloorID
        self.scenePanel.resever       = scenePanel.resever
        self.scenePanel.enableKeys    = scenePanel.enableKeys
		for keyState in scenePanel.keyStatusBind {
			let newState = HRScenePanelBindStates()
            newState.devType   = keyState.devType
            newState.hostAddr  = keyState.hostAddr
            newState.devAddr   = keyState.devAddr
            newState.operation = keyState.operation
			newState.description = getBindStateDescription(keyState)
			self.scenePanel.keyStatusBind.append(newState)
		}
		
		if let floors = HRDatabase.shareInstance().getDevicesOfType(.FloorInfo) as? [HRFloorInfo] {
			for floor in floors where floor.id == self.scenePanel.insFloorID {
				insFloorName = floor.name
				for room in floor.roomInfos where room.id == scenePanel.insRoomID {
					insRoomName = room.name
					break
				}
				break
			}
		}
	}
	
	private func getBindStateDescription(bindState: HRScenePanelBindStates) -> String {
		switch bindState.devType {
		case HRDeviceType.relayTypes():
			for relayBox in HRDatabase.shareInstance().getAllRelayBoxs()
				where bindState.devAddr == relayBox.devAddr {
					return relayBox.name
			}
		case HRDeviceType.motorTypes():
			for motor in HRDatabase.shareInstance().getAllMotorDev()
				where motor.devAddr == bindState.devAddr {
					return motor.name
			}
		case HRDeviceType.Scene.rawValue:
			if let scene = HRDatabase.shareInstance().getScene(sceneId: Byte(bindState.devAddr)) {
				return scene.name
			}
		case 0x00:
			return "未绑定"
		default: break
		}
		Log.warn("getBindStateDescription: 未知设备(\(bindState.devType))")
		return "未知设备"
	}
	
	func getKeyDescription(key: Int) -> String? {
		if key < scenePanel.keyStatusBind.count {
			return scenePanel.keyStatusBind[key].description
		}
		return nil
	}
	
	func setKeyBindState(route: Int, bindDevice: HRDevice?, state: UInt32?){
		if route < 0 || route >= scenePanel.keyStatusBind.count { return }
		
		guard let device = bindDevice else {
			if route < scenePanel.keyStatusBind.count {
				scenePanel.keyStatusBind[route].devType = 0x00
				scenePanel.keyStatusBind[route].devAddr = 0x00
				scenePanel.keyStatusBind[route].hostAddr = 0x00
				scenePanel.keyStatusBind[route].operation = 0xFF
				scenePanel.keyStatusBind[route].description = getBindStateDescription(scenePanel.keyStatusBind[route])
			}
			return
		}
		scenePanel.keyStatusBind[route].devType = device.devType
		scenePanel.keyStatusBind[route].devAddr = device.devAddr
		scenePanel.keyStatusBind[route].hostAddr = device.hostAddr
		scenePanel.keyStatusBind[route].operation = state == nil ? 0xFF:state!
		scenePanel.keyStatusBind[route].description = getBindStateDescription(scenePanel.keyStatusBind[route])
	}
	
	func setKeyBindState(route: Int, newState: HRScenePanelBindStates) {
		if route < 0 || route >= scenePanel.keyStatusBind.count { return }
		newState.description = getBindStateDescription(newState)
		scenePanel.keyStatusBind[route] = newState
	}
	
}