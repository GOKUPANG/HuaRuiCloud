//
//  EditDeviceInfoViewController.swift
//  huarui
//
//  Created by sswukang on 15/11/5.
//  Copyright © 2015年 huarui. All rights reserved.
//

import UIKit

class EditDeviceInfoViewController: UITableViewController {
	
	var device: HRDevice!
	
	private var editable: Bool = false
	
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
		if device != nil {
			self.device = device.copy() as! HRDevice
			addViews()
		}
    }
	
	override func viewDidAppear(animated: Bool) {
		if device == nil {
			self.navigationController?.popViewControllerAnimated(true)
		}
	}

	
	private func addViews() {
		self.title = device.name
		if editable {
			navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Save, target: self, action: #selector(EditDeviceInfoViewController.onSaveBarButtonClicked(_:)))
		}
		let header = UIView(frame: CGRectMake(0, 0, self.tableView.frame.width, 120))
		let imgView = UIImageView(frame: CGRectMake(0, 0, header.frame.width, 80))
		imgView.center.y = header.frame.height/2
		imgView.image = UIImage(named: device.iconName)
		imgView.contentMode = UIViewContentMode.ScaleAspectFit
		header.addSubview(imgView)
		
		tableView.tableHeaderView = header
	}
	
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		if device == nil { return 0 }
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if section == 0 { return 1 }
        return 2
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		
		var cell: UITableViewCell! = tableView.dequeueReusableCellWithIdentifier("section_\(indexPath.section)")
		if cell == nil {
			if indexPath.section == 0 {
				cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "section_\(indexPath.section)")
				let nameTextField = UITextField(frame: CGRectMake(0, 0, tableView.bounds.width, cell.bounds.height))
				nameTextField.placeholder = "请输入设备名称"
				nameTextField.clearButtonMode = .WhileEditing
				nameTextField.enabled = editable
				nameTextField.textAlignment = .Center
				nameTextField.text = device.name
				nameTextField.addTarget(self, action: #selector(EditDeviceInfoViewController.onNameTextFieldEditingChanged(_:)), forControlEvents: UIControlEvents.EditingChanged)
				nameTextField.addTarget(self, action: #selector(EditDeviceInfoViewController.onNameTextFieldEditingDidEnd(_:)), forControlEvents: UIControlEvents.EditingDidEndOnExit)
				cell.contentView.addSubview(nameTextField)
			} else  {
				cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "section_\(indexPath.section)")
			}
		}
		
		switch indexPath.section {
		case 1 where indexPath.row == 0:
			cell.textLabel?.text = "楼层名"
			cell.accessoryType = .DisclosureIndicator
			if let name = device.floorName {
				cell.detailTextLabel?.text = name
			}
		case 1 where indexPath.row == 1:
			cell.textLabel?.text = "房间名"
			cell.accessoryType = .DisclosureIndicator
			if let name = device.roomName {
				cell.detailTextLabel?.text = name
			}
		default: break
			
		}
		
        return cell
    }
	
	//MARK: - UI事件
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
		if !editable { return }
		if indexPath.section == 1 && indexPath.row == 0 { //点击楼层
			var row = 0
			var floorNames = [String]()
			var floorIds = [UInt16]()
			let floors = HRDatabase.shareInstance().floors
			for i in 0..<floors.count  {
				if floors[i].id == device.insFloorID {
					row = i
				}
				floorNames.append(floors[i].name)
				floorIds.append(floors[i].id)
			}
			ValuePickerActionView(
				title: "选择楼层",
				values: floorNames,
				currentRow: row,
				delegate: nil
				).showWithHandler({ name, index in
				self.device.insFloorID = UInt16(floorIds[index])
				tableView.reloadData()
			})
		} else if indexPath.section == 1 && indexPath.row == 1 {	//点击房间
			var row = 0
			var roomNames = [String]()
			var roomIds = [UInt16]()
			var rooms = [HRRoomInfo]()
			for floor in HRDatabase.shareInstance().floors
				where floor.id == device.insFloorID {
					rooms = floor.roomInfos
			}
			for i in 0..<rooms.count  {
				if rooms[i].id == device.insRoomID {
					row = i
				}
				roomNames.append(rooms[i].name)
				roomIds.append(rooms[i].id)
			}
			ValuePickerActionView(
				title: "选择房间",
				values: roomNames,
				currentRow: row,
				delegate: nil
				).showWithHandler({ name, index in
					self.device.insRoomID = roomIds[index]
					tableView.reloadData()
				})
		}
	}
	
	
	@objc private func onSaveBarButtonClicked(button: UIBarButtonItem) {
		if device.name.isEmpty || !device.name.isDeviceName {
			UIAlertView(title: "提示", message: "设备名称为空或含有非法字符！", delegate: nil, cancelButtonTitle: "确定").show()
			return
		}
		if device.floorName == nil {
			UIAlertView(title: "提示", message: "楼层名无效！", delegate: nil, cancelButtonTitle: "确定").show()
			return
		}
		if device.roomName == nil {
			UIAlertView(title: "提示", message: "房间名无效！", delegate: nil, cancelButtonTitle: "确定").show()
			return
		}
		
		KVNProgress.showWithStatus("正在保存...")
		HR8000Service.shareInstance().editDeviceInfo(device, result: { error in
			if let err = error {
				KVNProgress.showErrorWithStatus("失败：\(err.domain)！")
			} else {
				KVNProgress.showSuccessWithStatus("保存成功！")
				runOnMainQueueDelay(500, block: {
					self.navigationController?.popViewControllerAnimated(true)
				})
			}
		})
	}
	
	@objc private func onNameTextFieldEditingChanged(textField: UITextField ) {
		guard let text = textField.text else {
			return
		}
		device.name = text
	}
	
	@objc private func onNameTextFieldEditingDidEnd(textField: UITextField ) {
		textField.resignFirstResponder()
	}
	
	
	
}
