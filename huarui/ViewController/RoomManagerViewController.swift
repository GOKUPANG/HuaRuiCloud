//
//  RoomManagerViewController.swift
//  huarui
//
//  Created by sswukang on 15/11/30.
//  Copyright © 2015年 huarui. All rights reserved.
//

import UIKit

/// 设置 - 楼层管理 - 房间管理
class RoomManagerViewController: UITableViewController, UIAlertViewDelegate, UIActionSheetDelegate, HR8000HelperDelegate {
	
	private let TAG_ADD    = 100
	private let TAG_DELETE = 101
	private let TAG_EDIT   = 102
	private let TAG_EXIT   = 103
	/// 添加弹出的警告
	private let TAG_ADD_WARN = 103
	///编辑弹出的警告
	private let TAG_EDIT_WARN = 104
	
	var floor: HRFloorInfo! {
		didSet{
			self.title = floor.name
			self.rooms = floor.roomInfos
		}
	}
	
	private var rooms: [HRRoomInfo]!
	private var editable = false
	private var currentPos: Int?
	
	init() {
		super.init(style: UITableViewStyle.Grouped)
	}

	required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
	//请勿删除此init方法，否则在iOS8中会报“use of unimplemented initializer 'init(nibName:bundle:)'”异常.
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
	}
	
    override func viewDidLoad() {
		super.viewDidLoad()
		tableView.backgroundColor = UIColor.tableBackgroundColor()
		tableView.separatorColor = UIColor.tableSeparatorColor()
		editable = HRDatabase.isEditPermission
		if editable {
			navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(RoomManagerViewController.tapAddBarButton))
		}
		if floor == nil { return }
		
		HRProcessCenter.shareInstance().delegates.hr8000HelperDelegate = self
    }

	override func viewDidAppear(animated: Bool) {
		if floor == nil {
			self.navigationController?.popViewControllerAnimated(true)
		}
	}

	
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return rooms.count
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		var cell = tableView.dequeueReusableCellWithIdentifier("cell")
		if cell == nil {
			cell = UITableViewCell(style: .Value1, reuseIdentifier: "cell")
		}
		cell!.textLabel?.text = rooms[indexPath.row].name
		cell!.accessoryType = HRDatabase.isEditPermission ? .DisclosureIndicator:.None
		
		return cell!
	}
	
	//MARK: - UI事件
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
		if !HRDatabase.isEditPermission { return }
		self.currentPos = indexPath.row
		let sheet = UIActionSheet(title: rooms[indexPath.row].name, delegate: self, cancelButtonTitle: nil, destructiveButtonTitle: nil)
		sheet.addButtonWithTitle("重命名")
		sheet.addButtonWithTitle("删除")
		sheet.addButtonWithTitle("取消")
		sheet.destructiveButtonIndex = 1
		sheet.cancelButtonIndex = 2
		sheet.showInView(self.view)
	}
	
	@objc private func tapAddBarButton() {
		let alert = UIAlertView(title: "新房间名称", message: "名称只能是中文、字母、数字、下划线或空格，不能含有其他标点符号", delegate: self, cancelButtonTitle: "取消", otherButtonTitles: "添加")
		alert.tag = TAG_ADD
		alert.alertViewStyle = .PlainTextInput
		alert.show()
	}
	
	func actionSheet(actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) {
		switch buttonIndex {
		case 0:	//重命名
			let alert = UIAlertView(title: "修改房间名称", message: "名称只能是中文、字母、数字、下划线或空格，不能含有其他标点符号", delegate: self, cancelButtonTitle: "取消", otherButtonTitles: "修改")
			alert.tag = TAG_EDIT
			alert.alertViewStyle = .PlainTextInput
			alert.textFieldAtIndex(0)?.text = rooms[currentPos!].name
			alert.show()
		case 1: //删除
			let  alert = UIAlertView(title: "删除“\(rooms[currentPos!].name)”房间?", message: "该房间的设备不会被删除，仍会保留", delegate: self, cancelButtonTitle: "取消", otherButtonTitles: "删除")
			alert.tag = TAG_DELETE
			alert.show()
		default: break
		}
	}
	
	func alertView(alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
		let isTapCancel = buttonIndex == alertView.cancelButtonIndex
		switch alertView.tag {
		case TAG_ADD where !isTapCancel:
			let name = alertView.textFieldAtIndex(0)?.text ?? ""
			if let error = checkRoomName(name) {
				let alert = UIAlertView(title: error.localizedDescription , message: nil, delegate: self, cancelButtonTitle: "明白")
				alert.tag = TAG_ADD_WARN
				alert.show()
				break
			}
			let room = HRRoomInfo()
            room.name     = name
            room.hostAddr = HRDatabase.shareInstance().server.hostAddr
			KVNProgress.showWithStatus("正在加载...")
			HR8000Service.shareInstance().createRoom(room, inFloor: floor, result: {
				error in
				if let err = error {
					KVNProgress.showErrorWithStatus(err.domain)
				} else {
					KVNProgress.showSuccessWithStatus("添加成功！")
				}
			})
			
		case TAG_DELETE where !isTapCancel:
			KVNProgress.showWithStatus("正在删除...")
			HR8000Service.shareInstance().deleteRoom(rooms[currentPos!], inFloor: floor, result: {
				error in
				if let err = error {
					KVNProgress.showErrorWithStatus(err.domain)
				} else {
					KVNProgress.showSuccessWithStatus("删除成功！")
				}
			})
		case TAG_ADD_WARN:
			tapAddBarButton()
		case TAG_EDIT_WARN:
			let alert = UIAlertView(title: "修改房间名称", message: "名称只能是中文、字母、数字、下划线或空格，不能含有其他标点符号", delegate: self, cancelButtonTitle: "取消", otherButtonTitles: "修改")
			alert.tag            = TAG_EDIT
			alert.alertViewStyle = .PlainTextInput
			if let pos = currentPos {
				alert.textFieldAtIndex(0)?.text = rooms[pos].name
			}
			alert.show()
			break
		case TAG_EDIT where !isTapCancel: //重命名
			let name = alertView.textFieldAtIndex(0)?.text ?? ""
			if let error = checkRoomName(name) {
				let alert = UIAlertView(title: error.localizedDescription , message: nil, delegate: self, cancelButtonTitle: "明白")
				alert.tag = TAG_EDIT_WARN
				alert.show()
				break
			}
			let room = HRRoomInfo()
            room.name     = name
            room.id       = rooms[currentPos!].id
            room.hostAddr = rooms[currentPos!].hostAddr
			KVNProgress.showWithStatus("正在保存...")
			HR8000Service.shareInstance().editRoomInfo(room, inFloor: floor, result: {
				error in
				if let err = error {
					KVNProgress.showErrorWithStatus(err.domain)
				} else {
					KVNProgress.showSuccessWithStatus("修改成功！")
				}
			})
		case TAG_EXIT:
			self.navigationController?.popViewControllerAnimated(true)
		default: break
		}
	}
	
	//MARK: - 处理方法

	///检查房间名字
	private func checkRoomName(name: String) -> NSError? {
		if name.isEmpty {
			return NSError(code: HRErrorCode.Other, description: "房间名称不能为空")
		}
		if !name.isDeviceName {
			return NSError(code: .UseIllegalChar)
		}
		for room in rooms where room.name == name {
			return NSError(code: .DuplicateName, description: "\"\(name)\"已被使用，请另取其他名称")
		}
		return nil
	}
	
	//MARK: - delegate
	
	func hr8000Helper(didDeleteDevice device: HRDevice) {
		if let floorByDel = device as? HRFloorInfo where floorByDel.id == self.floor.id {
			runOnMainQueue({
				let alert = UIAlertView(title: "该楼层已经被删除，返回到楼层管理页面", message: nil, delegate: self, cancelButtonTitle: "确定")
				alert.tag = self.TAG_EXIT
				alert.show()
			})
		}
	}
	
	func hr8000Helper(finishedQueryDeviceInfo finish: Bool) {
		if let _floor = HRDatabase.shareInstance().getDevice(.FloorInfo, devAddr: UInt32(floor.id)) as? HRFloorInfo {
			runOnMainQueue({
				self.floor = _floor
				self.tableView.reloadData()
			})
		}
	}
	
}
