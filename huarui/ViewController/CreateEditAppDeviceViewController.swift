//
//  CreateAppDeviceViewController.swift
//  huarui
//
//  Created by sswukang on 15/9/14.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import UIKit

///创建或编辑应用设备，包括空调、电视机等应用设备
class CreateEditAppDeviceViewController: UITableViewController, SelectListTableViewControllerDelegate, UIAlertViewDelegate, HR8000HelperDelegate {
	
	/// 应用设备对象，不管是创建还是修改，都要设置该属性
	var appDevice: HRApplianceApplyDev!
	/// 是否是创建新的应用设备
	var isCreate = true
	
	private var floor: HRFloorInfo?
	private var room : HRRoomInfo?
	private var infraredUnit: HRInfraredTransmitUnit?
	
	/// 是否可以编辑
	private var editable = true
	/// 数据是否更改，用于退出编辑时的提示
	private var isDataChanged = false

	init() {
		super.init(style: UITableViewStyle.Grouped)
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	//请勿删除此init方法，否则在iOS8中会报“use of unimplemented initializer 'init(nibName:bundle:)'”异常.
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
	}
	
//MARK: - UIViewController
	
    override func viewDidLoad() {
		super.viewDidLoad()
		self.tableView.backgroundColor = UIColor.tableBackgroundColor()
		self.tableView.separatorColor = UIColor.tableSeparatorColor()
		self.tableView.registerClass(UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "cell").classForCoder, forCellReuseIdentifier: "cell")
		if appDevice == nil {
			return
		}
		
		editable = HRDatabase.isEditPermission
		if editable {
//			navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: "onBackBarButtonClicked:")
			navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Save, target: self, action: #selector(CreateEditAppDeviceViewController.onSaveBarButtonClicked(_:)))
		}
		let devImg: UIImage?
		if appDevice.appDevType == HRAppDeviceType.TV.rawValue {
			devImg = UIImage(named: "设备图标-电视机")
		} else if appDevice.appDevType == HRAppDeviceType.AirCtrl.rawValue {
			devImg = UIImage(named: "设备图标-空调")
		} else {
			devImg = UIImage(named: "设备图标-未知设备")
		}
		if let img = devImg {
			let header = UIView(frame: CGRectMake(0, 0, self.tableView.frame.width, 100))
			let imgView = UIImageView(frame: CGRectMake(0, 0, header.frame.width, 80))
			imgView.center.y = header.frame.height/2
			imgView.image = img
			imgView.contentMode = UIViewContentMode.ScaleAspectFit
			header.addSubview(imgView)
			
			tableView.tableHeaderView = header
		}
		
		//设置应用设备属性
		if !isCreate {
			//红外转发器
			for inf in HRDatabase.shareInstance().infrareds {
				if inf.devAddr == appDevice.infraredUnitAddr {
					self.infraredUnit = inf
					break
				}
			}
			//楼层名
			for floor in HRDatabase.shareInstance().floors {
				if floor.id == appDevice.insFloorID {
					self.floor = floor
					for room in floor.roomInfos {
						if room.id == appDevice.insRoomID {
							self.room = room
							break
						}
					}
				}
			}
		}
		
		
		switch appDevice.appDevType {
		case HRAppDeviceType.TV.rawValue where isCreate:
			self.title = "添加电视机"
		case HRAppDeviceType.AirCtrl.rawValue where isCreate:
			self.title = "添加空调"
		case _ where !isCreate:
			self.title = "编辑\(appDevice.name)"
		default: break
		}
    }
	
	override func viewDidAppear(animated: Bool) {
		if appDevice == nil {
			Log.error("appDevice属性为空，无法进行编辑！")
			self.navigationController?.popViewControllerAnimated(true)
			return
		}
	}
	
//MARK: - Delegate & Datasource
	
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		if appDevice == nil { return 0 }
		return 3
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
		case 0:
			return 1
		case 1:
			return 3
		case 2:
			return 1
		default: return 0
		}
	}
	
	private var nameTextField: UITextField?
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		var cell: UITableViewCell! = tableView.dequeueReusableCellWithIdentifier("cell_\(indexPath)")
		
		if cell == nil {
			cell = UITableViewCell(style: .Value1, reuseIdentifier: "cell_\(indexPath)")
			if indexPath.section == 0 && indexPath.row == 0 {
				nameTextField = UITextField(frame: CGRectMake(0, 0, tableView.frame.width, cell.frame.height))
                nameTextField!.text            = appDevice.name ?? ""
                nameTextField!.enabled         = editable
                nameTextField!.placeholder     = "输入设备名称"
                nameTextField!.clearButtonMode = .WhileEditing
                nameTextField!.textAlignment   = .Center
                nameTextField!.returnKeyType   = UIReturnKeyType.Done
				nameTextField!.addTarget(self, action: #selector(CreateEditAppDeviceViewController.textFieldOnExit(_:)), forControlEvents: UIControlEvents.EditingDidEndOnExit)
				cell.contentView.addSubview(nameTextField!)
			}
		}
		switch indexPath.row {
		case 0 where indexPath.section == 1:
			cell.textLabel?.text = "楼层"
			cell.accessoryType = editable ? .DisclosureIndicator:.None
			cell.detailTextLabel?.text = floor?.name ?? ""
		case 1 where indexPath.section == 1:
			cell.textLabel?.text = "房间"
			cell.accessoryType = editable ? .DisclosureIndicator:.None
			cell.detailTextLabel?.text = room?.name ?? ""
		case 2 where indexPath.section == 1:
			cell.textLabel?.text = "红外转发器"
			cell.accessoryType = editable ? .DisclosureIndicator:.None
			cell.detailTextLabel?.text = infraredUnit?.name ?? ""
		case 0 where indexPath.section == 2:
			cell.textLabel?.text = "红外学习"
			cell.detailTextLabel?.text = appDevice.learnKeys.count == 0 ? "未学习" : "已学\(appDevice.learnKeys.count)个按键"
		default: break
		}
		return cell
	}

//MARK: - UI事件
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
		if !editable { return }
		if indexPath.section == 0 { return }
		nameTextField?.resignFirstResponder()
		switch indexPath.row {
		case 0 where indexPath.section == 1:
			let floors = HRDatabase.shareInstance().floors
			var currentRow = 0
			for (i, floor) in floors.enumerate() where floor === self.floor {
				currentRow = i
			}
			let picker = ValuePickerActionView(title: "选择楼层", values: floors.map{$0.name}, currentRow: currentRow, delegate: nil)
			picker.showWithHandler({ (title, index) -> Void in
				if self.floor !== floors[index] {
					self.floor = floors[index]
					self.isDataChanged = true
					tableView.reloadData()
				}
			})
		case 1 where indexPath.section == 1:
			if let floor = self.floor {
				let rooms = floor.roomInfos
				var currentRow = 0
				for (i, room) in rooms.enumerate() where room === self.room {
					currentRow = i
				}
				ValuePickerActionView(title: "选择房间", values: rooms.map{$0.name}, currentRow: currentRow, delegate: nil).showWithHandler({ (title, index) -> Void in
					if self.room !== rooms[index] {
						self.room = rooms[index]
						self.isDataChanged = true
						tableView.reloadData()
					}
				})
				
			}
		case 2 where indexPath.section == 1:
            var enableNames  = [String]()
            var disableNames = [String]()
			let currentHostAddr = HRDatabase.shareInstance().server.hostAddr
			let selectVC = SelectListTableViewController(style: UITableViewStyle.Grouped)
			selectVC.delegate = self
			for (index, inf) in HRDatabase.shareInstance().infrareds.enumerate() {
				if inf.hostAddr == currentHostAddr {
					enableNames.append(inf.name)
				} else {
					disableNames.append(inf.name)
				}
				if inf === self.infraredUnit {
					selectVC.selectedIndex = index
				}
			}
			selectVC.disableTextList = disableNames
			selectVC.enableTitleInfo = "可选的红外转发器(当前主机)"
			selectVC.disableTitleInfo = "不可选的红外转发器(其它主机)"
			selectVC.textList = enableNames
			selectVC.title = "选择红外转发器"
			navigationController?.pushViewController(selectVC, animated: true)
		default: return
		} 
	}
	
	//SelectListTableViewController 的代理
	func selectList(didSelectRow: Int, textList: [String]!) {
		let infrareds = HRDatabase.shareInstance().infrareds
		if didSelectRow >= infrareds.count { return }
		isDataChanged = infraredUnit !== infrareds[didSelectRow]
		infraredUnit  = infrareds[didSelectRow]
		tableView.reloadData()
	}
	
	func textFieldOnExit(textField: UITextField) {
		textField.resignFirstResponder()
	}
	
	//点击保存
	func onSaveBarButtonClicked(button: UIBarButtonItem) {
		//判断数据的完整
		if nameTextField == nil || nameTextField!.text == nil || nameTextField!.text!.isEmpty
			|| floor == nil || floor!.name.isEmpty
			|| room == nil || room!.name.isEmpty
			|| infraredUnit == nil || infraredUnit!.name.isEmpty {
			UIAlertView(title: "提示", message: "设备信息没有填写完整！", delegate: nil, cancelButtonTitle: "确定").show()
			return
		}
		if !nameTextField!.text!.isDeviceName {
			UIAlertView(title: "提示", message: "设备名称不能有非法字符！", delegate: nil, cancelButtonTitle: "确定").show()
			return
		}
		
//		检查名字重复
//		for app in HRDatabase.shareInstance().applyDevcies {
//			if self.appDevName == app.name
//			&& self.appDevice.appDevType == app.appDevType
//			&& self.appDevice.appDevID != app.appDevID {
//				UIAlertView(title: "提示", message: "\"\(app.name)\"已经存在，不能重复！", delegate: nil, cancelButtonTitle: "取消").show()
//				return
//			}
//		}
		
		let newAppDev: HRApplianceApplyDev
		if !isCreate {
			newAppDev = HRApplianceApplyDev()
			newAppDev.hostAddr = self.appDevice.hostAddr
			newAppDev.devType  = self.appDevice.devType
			newAppDev.devAddr  = self.appDevice.devAddr
			newAppDev.appDevID = self.appDevice.appDevID
		} else {
			newAppDev = self.appDevice
		}
		newAppDev.name = nameTextField!.text!
		newAppDev.insRoomID = room!.id
		newAppDev.insFloorID = floor!.id
		newAppDev.infraredUnitAddr = infraredUnit!.devAddr
		
		KVNProgress.showWithStatus("正在保存...")
		newAppDev.saveToRemote(isCreate, result: { (error) in
			if let err = error {
				KVNProgress.showErrorWithStatus("失败：\(err.domain)")
				Log.error("添加应用设备失败：\(err.domain)，错误码：\(err.code)")
			} else {
				KVNProgress.showSuccessWithStatus("成功！")
				runOnMainQueueDelay(500, block: {
					self.navigationController?.popViewControllerAnimated(true)
				})
			}
		})
	}
	
	//点击返回
	func onBackBarButtonClicked(button: UIBarButtonItem) {
		if isDataChanged {
			let alert = UIAlertView(title: "提示", message: "设备信息未保存，您确定要退出吗？", delegate: self, cancelButtonTitle: "取消", otherButtonTitles: "确定")
			alert.tag = 54321
			alert.show()
			return
		}
		self.navigationController?.popViewControllerAnimated(true)
	}
	
	func alertView(alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
		if alertView.tag == 54321 && alertView.cancelButtonIndex != buttonIndex {
			self.navigationController?.popViewControllerAnimated(true)
		}
	}
	
	
}
