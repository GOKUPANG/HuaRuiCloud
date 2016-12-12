//
//  EditSensorBindDetailsViewController.swift
//  huarui
//
//  Created by sswukang on 15/12/9.
//  Copyright © 2015年 huarui. All rights reserved.
//

import UIKit

/// 编辑传感器绑定的设备列表界面
class EditSensorBindDetailsViewController: UIViewController, PickDeviceViewControllerDelegate, SceneBindContainerViewDelegate {
	private enum Todo {
		case View
		case Edit
		case Create
	}

	var editable = false
	
	private let deviceTypes: [PickDeviceType] = [.Relay, .Motor, .Scene, .Apply, .RGB]
	private var deviceDatas: [PickDeviceType: [HRDevInScene]]!
	private var sensor: HRSensor!
	private var sensorBind: HRSensorBind!
	private var operateType: BindSensorOperateType!
	
    private let bottomBarHeight: CGFloat = 50
	
	private var todo = Todo.View
	private var bindContainerView: SceneBindsContainerView!
	private var bottomActionBar: BottomActionBar?
	
	init(sensor: HRSensor, sensorBind: HRSensorBind, operateType: BindSensorOperateType) {
		super.init(nibName: nil, bundle: nil)
        self.sensor      = sensor
        self.sensorBind  = sensorBind.copySensorbind()
        self.operateType = operateType
	}

	required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		if sensorBind == nil { return }
		editable = HRDatabase.isEditPermission
		initDatas()
		addViews()
    }
	
	override func viewDidAppear(animated: Bool) {
		if sensorBind == nil {
			self.navigationController?.popViewControllerAnimated(true)
		}
	}

	private func initDatas() {
		if sensorBind == nil { return }
		deviceDatas = [PickDeviceType:[HRDevInScene]]()
		for type in deviceTypes {
			deviceDatas[type] = [HRDevInScene]()
		}
		for devInScene in sensorBind.devInScenes {
			//数据库中查找设备
			guard let devInDatabase = HRDatabase.shareInstance().getDevice(devInScene.devType, devAddr: devInScene.devAddr) else {
				continue
			}
			switch devInScene.devType {
			case HRDeviceType.relayTypes():
				if let relayComplexes = devInDatabase as? HRRelayComplexes{
					for relay in relayComplexes.relays {
						if Int(relay.relaySeq) < devInScene.actBinds.count && devInScene.actBinds[Int(relay.relaySeq)] < 0x03 {
							devInScene.device = relay
							deviceDatas[.Relay]?.append(devInScene)
						}
					}
				}
			default:
				devInScene.device = devInDatabase
				for ptype in PickDeviceType.allTypes {
					if let hrtype = HRDeviceType(rawValue: devInScene.devType) where ptype.hrDeviceTypes.contains(hrtype) {
						deviceDatas[ptype]?.append(devInScene)
					}
				}
			}
		}
	}
	
	private func addViews() {
		if editable {
			let barSaveButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Save, target: self, action: #selector(EditSensorBindDetailsViewController.tapBarSaveButton))
			barSaveButton.tintColor = UIColor.whiteColor()
			self.navigationItem.rightBarButtonItem = barSaveButton
			
			let barCancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: #selector(EditSensorBindDetailsViewController.tapBarCancelButton))
			barCancelButton.tintColor = UIColor.whiteColor()
			self.navigationItem.leftBarButtonItem = barCancelButton
		}
		let navBarHeight = self.navigationController!.navigationBar.frame.height + UIApplication.sharedApplication().statusBarFrame.height
		self.view.frame = CGRectMake(0, 0, self.view.frame.width, self.view.frame.height - navBarHeight)
		
		
		bindContainerView = SceneBindsContainerView(frame: self.view.bounds)
        bindContainerView.enable      = editable
        bindContainerView.delegate    = self
        bindContainerView.deviceTypes = self.deviceTypes
        bindContainerView.deviceDatas = self.deviceDatas
        bindContainerView.tintColor   = APP.param.themeColor
		self.view.addSubview(bindContainerView)
		//Action Bar
		if editable {
			let toolbar = UIToolbar(frame: CGRectMake(0, view.bounds.height - bottomBarHeight, view.bounds.width, bottomBarHeight))
			bottomActionBar = BottomActionBar(frame: toolbar.bounds)
			bottomActionBar?.tintColor = APP.param.themeColor
			bottomActionBar?.addButton.addTarget(self, action: #selector(EditSensorBindDetailsViewController.tapBottomAddButton), forControlEvents: .TouchUpInside)
			bottomActionBar?.editButton.addTarget(self, action: #selector(EditSensorBindDetailsViewController.tapBottomEditButton), forControlEvents: .TouchUpInside)
			bottomActionBar?.doneButton.addTarget(self, action: #selector(EditSensorBindDetailsViewController.tapBottomDoneButton), forControlEvents: .TouchUpInside)
			toolbar.addSubview(bottomActionBar!)
			self.view.addSubview(toolbar)
            bindContainerView.tableView.contentInset.bottom   = bottomBarHeight
            bindContainerView.tableView.scrollIndicatorInsets.bottom = bottomBarHeight
		}
	}
	
	
	//MARK: - 保存与取消
	@objc private func tapBarSaveButton() {
		KVNProgress.showWithStatus("正在保存...")
		//转换数据
		self.sensorBind.devInScenes = [HRDevInScene]()
		for (_, devs) in bindContainerView.deviceDatas {
			self.sensorBind.devInScenes += devs
		}
		
		HR8000Service.shareInstance().bindSensorAction(sensor, bind: self.sensorBind, operateType: operateType, result: {
			error in
			if let err = error {
				KVNProgress.showErrorWithStatus(err.domain)
			} else {
				KVNProgress.showSuccessWithStatus("保存成功")
				runOnMainQueueDelay(500, block: {
					self.navigationController?.popViewControllerAnimated(true)
				})
			}
		})
	}
	
	@objc private func tapBarCancelButton() {
		self.navigationController?.popViewControllerAnimated(true)
	}
	
	@objc private func tapBottomAddButton() {
		PickDeviceViewController.show(self, delegate: self)
	}
	
	@objc private func tapBottomEditButton() {
		bindContainerView.tableView.setEditing(true, animated: true)
	}
	
	@objc private func tapBottomDoneButton() {
		bindContainerView.tableView.setEditing(false, animated: true)
		//延迟500ms刷新tableView
		runOnMainQueueDelay(500, block: {
			self.bindContainerView.tableView.reloadData()
		})
	}
	
	func bindsContainerView(containerView: SceneBindsContainerView, didChangedDeviceDatas deviceDatas: [PickDeviceType : [HRDevInScene]]) {
		self.deviceDatas = deviceDatas
	}
	
	func pickDeviceVC(shouldShowDeviceTypes vc: PickDeviceViewController) -> [PickDeviceType] {
		return self.deviceTypes
	}
	
	func pickDeviceVC(vc: PickDeviceViewController, type: PickDeviceType, devices: [HRDevInScene]) {
		self.deviceDatas[type]! += devices
		self.bindContainerView.deviceDatas = self.deviceDatas
		self.bindContainerView.tableView.reloadData()
	}
	
}
