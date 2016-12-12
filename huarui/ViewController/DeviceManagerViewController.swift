//
//  DeviceManagerViewController.swift
//  huarui
//
//  Created by sswukang on 15/11/30.
//  Copyright © 2015年 huarui. All rights reserved.
//

import UIKit

/** deviceModel的数据结构
类型：[[String: AnyObject]]!
[
	{
		"title": "(type name or floor name)",
		"devices": [
			{device_obj},
			{device_obj},
			{device_obj}
		]
	},
]
*/

/// 设置 - 设备管理
class DeviceManagerViewController: UITableViewController, DeviceManagerActionSheetDelegate, UIAlertViewDelegate {
	
	
	/// 身份验证
	private let TAG_VERIFICATION = 100
	private let TAG_DELETE = 101
	
	private let KEY_TITLE = "title"
	private let KEY_DEVICES = "devices"
	
	private var deviceModel:[[String: AnyObject]]!
	private var currentIndexPath: NSIndexPath?
	private var groupType: DeviceManagerGroupType = .None
	
	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		self.title = "设备管理"
		tableView.backgroundColor = UIColor.tableBackgroundColor()
		tableView.separatorColor = UIColor.tableSeparatorColor()
		groupType = DeviceManagerGroupType(rawValue: NSUserDefaults.standardUserDefaults().integerForKey("deviceManagerGroupType")) ?? .None
		deviceModel = getDevices()
		
		initNavBar()
		tableView.registerNib(UINib(nibName: "DeviceManagerCell", bundle: nil), forCellReuseIdentifier: "cell")
		tableView.tableFooterView = UIView()
		/*注册通知*/
		//
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DeviceManagerViewController.hr8000DidFinishedQuery), name: kNotificationQueryDone, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DeviceManagerViewController.notificationUserDidLogined), name: kNotificationUserDidLogined, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DeviceManagerViewController.notificationDeviceDidDeleted(_:)), name: kNotificationDeviceDidDeleted, object: nil)
    }
	
	private func initNavBar() {
		self.navigationItem.rightBarButtonItems = [
			UIBarButtonItem(image: UIImage(named: "ico_group"), style: UIBarButtonItemStyle.Plain, target: self, action: #selector(DeviceManagerViewController.tapSortBarButton)),
		]
		if HRDatabase.isEditPermission {
			self.navigationItem.rightBarButtonItems?.append(
				UIBarButtonItem(barButtonSystemItem: .Trash, target: self, action: #selector(DeviceManagerViewController.tapDeleteBarButton)))
		}
	}
	
	///用户登录的通知响应
	@objc private func notificationUserDidLogined() {
		runOnMainQueue({
			self.initNavBar()
		})
	}
	
	//MARK: - tableView
	
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return deviceModel.count
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return (deviceModel[section][KEY_DEVICES] as! [HRDevice]).count
	}
	
//	override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
//		return true
//	}
	
	override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
		if HRDatabase.isEditPermission && tableView.editing {
			return .Delete
		}
		return .None
	}
	
	override func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String? {
		return "删除"
	}
	
//	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//		return deviceModel[section]["title"] as? String
//	}
	
	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return 56
	}
	
	override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 30
	}
	
	override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		var header = tableView.dequeueReusableHeaderFooterViewWithIdentifier("header")
		if header == nil {
			header = UITableViewHeaderFooterView(reuseIdentifier: "header")
			header!.textLabel?.textColor = UIColor.lightGrayColor()
		}
		header!.textLabel?.text = deviceModel[section][KEY_TITLE] as? String
		
		return header
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		var cell = tableView.dequeueReusableCellWithIdentifier("cell") as? DeviceManagerCell
		
		if cell == nil {
			cell = DeviceManagerCell(style: .Default, reuseIdentifier: "cell")
		}
		let device = (deviceModel[indexPath.section][KEY_DEVICES] as! [HRDevice])[indexPath.row]
		
		var floorRoomText = ""
		if let floorName = device.insFloorName {
			floorRoomText += floorName + "-"
		} else {
			floorRoomText += "(未知楼层)-"
		}
		if let roomName = device.insRoomName {
			floorRoomText += roomName
		} else {
			floorRoomText += "(未知房间)"
		}
		
		cell?.devImageView.image = UIImage(named: device.iconName)?.imageWithRenderingMode(.AlwaysTemplate)
		cell?.devImageView.tintColor = APP.param.themeColor
		cell?.titleLabel.text = device.name
		cell?.subTitleLabel.text = floorRoomText
		switch device.devType {
		case HRDeviceType.relayTypes():
			cell?.accessoryType = .DetailButton
		default:
			cell?.accessoryType = .None
			
		}
		
		
		return cell!
		
	}
	
	override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
		cell.separatorInset = UIEdgeInsetsZero
	}
	
	//MARK: - UI事件
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
		
		let device = (deviceModel[indexPath.section][KEY_DEVICES] as! [HRDevice])[indexPath.row]
		
		switch device.devType {
		case HRDeviceType.relayTypes():
			let vc = EditRelayBoxViewController()
			let box = device as! HRRelayComplexes
			vc.relayBox = box
			vc.routerEnable = [
				box.states & 0b0000_0011 != 0b0000_0011,
				box.states & 0b0000_1100 != 0b0000_1100,
				box.states & 0b0011_0000 != 0b0011_0000,
				box.states & 0b1100_0000 != 0b1100_0000,
			]
			self.navigationController?.pushViewController(vc, animated: true)
		case HRDeviceType.ScenePanel.rawValue:
			let vc = EditScenePanelViewController()
			vc.scenePanel = device as! HRScenePanel
			self.navigationController?.pushViewController(vc, animated: true)
		case HRDeviceType.ApplyDevice.rawValue:
			let vc = CreateEditAppDeviceViewController()
			vc.appDevice = device as! HRApplianceApplyDev
			vc.isCreate = false
			self.navigationController?.pushViewController(vc, animated: true)
		default:
			let vc = EditDeviceInfoViewController()
			vc.device = device
			self.navigationController?.pushViewController(vc, animated: true)
		}
	}
	
	override func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
		
		let device = (deviceModel[indexPath.section][KEY_DEVICES] as! [HRDevice])[indexPath.row]
		
		let vc = EditDeviceInfoViewController()
		vc.device = device
		self.navigationController?.pushViewController(vc, animated: true)
	}
	
	
	override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
		let device = (deviceModel[indexPath.section][KEY_DEVICES] as! [HRDevice])[indexPath.row]
		currentIndexPath = indexPath
		let alert = UIAlertView(title: "要删除“\(device.name)”吗", message: "", delegate: self, cancelButtonTitle: "取消", otherButtonTitles: "删除")
		alert.tag = TAG_DELETE
		alert.show()
	}

	func alertView(alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
		switch alertView.tag {
		case TAG_DELETE where buttonIndex != alertView.cancelButtonIndex:
			KVNProgress.showWithStatus("正在删除...")
			let device = (deviceModel[currentIndexPath!.section]["devices"] as! [HRDevice])[currentIndexPath!.row]
			device.deleteFromRemote({ error in
				if let err = error {
					KVNProgress.showErrorWithStatus(err.domain)
				} else {
					KVNProgress.showSuccessWithStatus("“\(device.name)”已成功删除！")
				}
			})
		case TAG_VERIFICATION where buttonIndex != alertView.cancelButtonIndex:
			alertView.textFieldAtIndex(0)?.resignFirstResponder()
			guard let passwd = alertView.textFieldAtIndex(0)?.text else {
				UIAlertView(title: "验证失败！", message: nil, delegate: nil, cancelButtonTitle: "确定").show()
				break
			}
			if passwd == HRDatabase.shareInstance().acount.password {
				tableView.setEditing(true, animated: true)
				self.navigationItem.rightBarButtonItems![1] = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(DeviceManagerViewController.tapDeleteBarButton))
				break
			} else {
				UIAlertView(title: "密码错误！", message: nil, delegate: nil, cancelButtonTitle: "确定").show()
			}
		default: break
		}
	}
	
	///点击编辑按钮
	@objc private func tapDeleteBarButton() {
		if tableView.editing {
			self.navigationItem.rightBarButtonItems![1] = UIBarButtonItem(barButtonSystemItem: .Trash, target: self, action: #selector(DeviceManagerViewController.tapDeleteBarButton))
			tableView.setEditing(false, animated: true)
		} else {
			//身份验证
			let alert = UIAlertView(title: "管理员身份验证", message: "", delegate: self, cancelButtonTitle: "取消", otherButtonTitles: "验证")
			alert.tag = TAG_VERIFICATION
			alert.alertViewStyle = .SecureTextInput
			alert.textFieldAtIndex(0)?.placeholder = "请输入管理员密码"
			alert.show()
		}
		
		
	}
	
	///点击分组/排序按钮
	@objc private func tapSortBarButton() {
		let sheet = DeviceManagerActionSheet(title: "分组方式", delegate: self)
		sheet.tintColor = APP.param.themeColor
		sheet.groupType = groupType
		sheet.show()
	}
	
	func deviceManagerActionSheet(sheet: DeviceManagerActionSheet, dismissWithGroupType groupType: DeviceManagerGroupType) {
		if self.groupType != groupType {
			NSUserDefaults.standardUserDefaults().setInteger(groupType.rawValue, forKey: "deviceManagerGroupType")
			self.groupType = groupType
			deviceModel = getDevices()
			self.tableView.reloadData()
		}
	}
	
	//MARK: - 设备数据
	
	private func getDevices() -> [[String: AnyObject]] {
		let database = HRDatabase.shareInstance()
		var model = [[String: AnyObject]]()
		
		///需要显示的设备类型
		let devicesMask: [HRDeviceType] = [
			.RelayControlBox,
			.SocketPanel,
			.SwitchPanel,
			.LiveWireSwitch,
			.ScenePanel,
			.CurtainControlUnit,
			.Manipulator,
			.BluetoothControlUnit,
			.InfraredTransmitUnit,
			.ApplyDevice,
			.DoorLock,
			.GasSensor,
			.HumiditySensor,
			.AirQualitySensor,
			.SolarSensor,
			.RGBLamp,
			.SmartBed,
			.DoorBell,
			.GaoDunDoor,
			.DoorMagCard,
			.InfraredDetectorUnit,
			
		]
		/* 开始 */
		if self.groupType == .None {
			var devGroup = [String: AnyObject]()
			let devices = database.getDevicesOfTypes(devicesMask)
            devGroup[KEY_TITLE]   = "设备"
            devGroup[KEY_DEVICES] = devices.sort(sortMethod)
			model.append(devGroup)
		} else if self.groupType == .ByDeviceType {	//按类型排序
			for type in devicesMask {
				let devices = database.getDevicesOfTypes([type])
				if devices.count > 0 {
					var devGroup = [String: AnyObject]()
					devGroup[KEY_TITLE] = type.description
					devGroup[KEY_DEVICES] = devices.sort(sortMethod)
					model.append(devGroup)
				}
			}
		} else {	//通过楼层分组
			var allDevices = [HRDevice]()
			for type in devicesMask {
				allDevices += database.getDevicesOfTypes([type])
			}
			let floors: [HRFloorInfo]
			if let _floors = HRDatabase.shareInstance().getDevicesOfType(.FloorInfo) as? [HRFloorInfo] {
				floors = _floors
			} else {
				floors = [HRFloorInfo]()
			}
			
			/*指定了楼层的设备*/
			for floor in floors {
				let devices = allDevices.filter({$0.insFloorID == floor.id})
				if devices.count > 0 {
					var devGroup = [String: AnyObject]()
                    devGroup[KEY_TITLE]   = floor.name
                    devGroup[KEY_DEVICES] = devices.sort(sortMethod)
					model.append(devGroup)
				}
			}
			/*没有指定楼层的设备*/
			let floorIds = floors.map({$0.id})
			let noFloorDevs = allDevices.filter({!floorIds.contains($0.insFloorID)})
			if noFloorDevs.count > 0 {
				var noFloorGroup = [String: AnyObject]()
				noFloorGroup[KEY_TITLE] = "（未知楼层）"
				noFloorGroup[KEY_DEVICES] = noFloorDevs.sort(sortMethod)
				model.append(noFloorGroup)
			}
		}
		return model
	}
	
	private func sortMethod(dev1: HRDevice, dev2: HRDevice) -> Bool {
		return dev1.name.localizedStandardCompare(dev2.name) == .OrderedAscending
	}
	
	@objc private func hr8000DidFinishedQuery() {
		runOnMainQueue({
			self.deviceModel = self.getDevices()
			self.tableView.reloadData()
		})
	}
	
	///删除设备成功的通知
	@objc private func notificationDeviceDidDeleted(notification: NSNotification) {
		runOnMainQueue({
			self.deviceModel = self.getDevices()
			self.tableView.reloadData()
		})
	}
	
}
