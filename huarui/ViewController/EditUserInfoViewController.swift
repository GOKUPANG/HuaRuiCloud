//
//  EditUserInfoViewController.swift
//  huarui
//
//  Created by sswukang on 15/11/30.
//  Copyright © 2015年 huarui. All rights reserved.
//

import UIKit

/// 设置 - 用户管理 - 编辑用户信息
class EditUserInfoViewController: UITableViewController, UIAlertViewDelegate {

	var user: HRUserInfo?
	
	///修改密码
    private var isEditingPasswd = false
	private var newUser: HRUserInfo!
	
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
		
		if user == nil {
			self.title = "创建用户"
			newUser = HRUserInfo()
            newUser.insFloorID = 0xFF
            newUser.insRoomID  = 0xFF
		} else {
			self.title = "编辑用户信息"
			newUser = user!.copy() as! HRUserInfo
		}
		if HRDatabase.isAdminUser && newUser.isAdministrator {
			self.isEditingPasswd = true
		}
		let header = UIView(frame: CGRectMake(0, 0, self.tableView.frame.width, 120))
		let imgView = UIImageView(frame: CGRectMake(0, 0, 80, 80))
		imgView.center = CGPointMake(header.bounds.midX, header.bounds.midY)
		imgView.image = UIImage(named: newUser.isAdministrator ? "ico_user":"ico_user_normal")
		imgView.backgroundColor = UIColor.whiteColor()
        //剪切变成圆形 斌注释
		imgView.layer.cornerRadius = imgView.bounds.width/2
		imgView.contentMode = UIViewContentMode.ScaleAspectFit
		header.addSubview(imgView)
		
		tableView.tableHeaderView = header
		
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: #selector(EditUserInfoViewController.tapSaveBarButton))
    }
	
	override func viewDidAppear(animated: Bool) {

	}

	//MARK: - tableView
	
	private var passwd0TextField: UITextField?
	private var passwd1TextField: UITextField?
	private var passwd2TextField: UITextField?
	
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		if newUser.isAdministrator || user == nil { return 3 }
		if HRDatabase.isEditPermission { return 4 }
		return 3
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
		case 0: return 1
		case 1: return 2
		case 2 where user != nil && !isEditingPasswd: return 2
		case 2 where user != nil && isEditingPasswd: return 4
		case 2 where user == nil: return 2
		case 3: return 1
		default: return 0
		}
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		var cell = tableView.dequeueReusableCellWithIdentifier("section_\(indexPath.section)")
		if cell == nil {
			cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "section_\(indexPath.section)")
		}
		switch indexPath.section {
		case 0 where indexPath.row == 0:
			if let textField = cell!.viewWithTag(88) as? UITextField {
                textField.text    = newUser.name
                textField.enabled = !newUser.isAdministrator || HRDatabase.isSuperUser
			} else {
				let textField = UITextField(frame: CGRectMake(0, 0, tableView.bounds.width, cell!.bounds.height))
				textField.tag = 88
                textField.textAlignment = .Center
                textField.placeholder   = "用户名"
                textField.text          = newUser.name
                textField.enabled       = !newUser.isAdministrator || HRDatabase.isSuperUser
				textField.returnKeyType = .Done
				textField.clearButtonMode = .WhileEditing
				cell!.addSubview(textField)
				textField.addTarget(self, action: #selector(EditUserInfoViewController.textFieldTextChanged(_:)), forControlEvents: .EditingChanged)
				textField.addTarget(self, action: #selector(EditUserInfoViewController.textFieldEditEnd(_:)), forControlEvents: .EditingDidEndOnExit)
			}
		case 1 where indexPath.row == 0:
			cell?.textLabel?.text = "可控楼层"
			cell?.accessoryType = .DisclosureIndicator
			if newUser.isAdministrator {
				cell?.detailTextLabel?.text = "全部楼层"
				cell?.accessoryType = .None
			} else if newUser.insFloorID == 0xFF {
				cell?.detailTextLabel?.text = "全部楼层"
			} else if let floorName = newUser.insFloorName {
				cell?.detailTextLabel?.text = floorName
			}
		case 1 where indexPath.row == 1:
			cell?.textLabel?.text = "可控房间"
			cell?.accessoryType = .DisclosureIndicator
			if newUser.isAdministrator {
				cell?.detailTextLabel?.text = "全部房间"
				cell?.accessoryType = .None
			} else if newUser.insRoomID == 0xFF {
				cell?.detailTextLabel?.text = "全部房间"
			} else if let roomName = newUser.insRoomName {
				cell?.detailTextLabel?.text = roomName
			}
		case 2 where indexPath.row == 0 && user != nil:
			cell?.textLabel?.text = nil
			if passwd0TextField == nil {
				passwd0TextField = UITextField(frame: CGRectMake(15, 0, tableView.bounds.width - 20, cell!.bounds.height))
                passwd0TextField?.clearButtonMode = .WhileEditing
                passwd0TextField?.secureTextEntry = true
                passwd0TextField?.returnKeyType   = .Next
                passwd0TextField?.placeholder     = "用户密码"
				passwd0TextField?.addTarget(self, action: #selector(EditUserInfoViewController.passwdTextFieldEditingEnd(_:)), forControlEvents: .EditingDidEndOnExit)
			}
			cell!.addSubview(passwd0TextField!)
		case 2 where indexPath.row == 1 && user != nil && !isEditingPasswd:
			cell?.textLabel?.text = "修改密码"
			cell?.textLabel?.textColor = self.view.tintColor
		case 2 where (user == nil && indexPath.row == 0) || (isEditingPasswd && indexPath.row == 1): //创建用户之添加密码、当前用户修改密码
			cell?.textLabel?.text = nil
			if passwd1TextField == nil {
				passwd1TextField = UITextField(frame: CGRectMake(15, 0, tableView.bounds.width - 20, cell!.bounds.height))
                passwd1TextField?.secureTextEntry = true
                passwd1TextField?.clearButtonMode = .WhileEditing
                passwd1TextField?.placeholder     = "新密码"
                passwd1TextField?.returnKeyType   = .Next
				passwd1TextField?.addTarget(self, action: #selector(EditUserInfoViewController.passwdTextFieldEditingEnd(_:)), forControlEvents: .EditingDidEndOnExit)
			}
			cell!.addSubview(passwd1TextField!)
		case 2 where (user == nil && indexPath.row == 1) || (isEditingPasswd && indexPath.row == 2): //创建用户之重复密码、当前用户修改密码
			cell?.textLabel?.text = nil
			if passwd2TextField == nil {
				passwd2TextField = UITextField(frame: CGRectMake(15, 0, tableView.bounds.width - 20, cell!.bounds.height))
                passwd2TextField?.clearButtonMode = .WhileEditing
                passwd2TextField?.secureTextEntry = true
                passwd2TextField?.placeholder     = "重复新密码"
                passwd2TextField?.returnKeyType   = .Done
				passwd2TextField?.addTarget(self, action: #selector(EditUserInfoViewController.passwdTextFieldEditingEnd(_:)), forControlEvents: .EditingDidEndOnExit)
			}
			cell!.addSubview(passwd2TextField!)
		case 2 where indexPath.row == 3:
			cell?.textLabel?.text = "取消修改密码"
			cell?.textLabel?.textColor = self.view.tintColor
		case 3 where indexPath.row == 0:
			if let label = cell!.viewWithTag(777) as? UILabel {
				label.text    = "删除用户"
			} else {
				let label = UILabel(frame: CGRectMake(0, 0, tableView.bounds.width, cell!.bounds.height))
				label.tag = 777
				label.textAlignment = .Center
				label.text          = "删除用户"
				label.textColor = UIColor(R: 217, G: 82, B: 87, alpha: 1)
				cell!.addSubview(label)
			}
		default: break
		}
		
		return cell!
	}
	
	//MARK: - UI事件
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
		if indexPath.section == 1 && newUser.isAdministrator {
			return
		}
		switch indexPath.section {
		case 1 where indexPath.row == 0:
			var row = -1
			var floorNames = [String]()
			var floorIds = [UInt16]()
			if let floors = HRDatabase.shareInstance().getDevicesOfType(.FloorInfo) as? [HRFloorInfo] {
				for (index, floor) in floors.enumerate() {
					if floor.id == newUser.insFloorID {
						row = index
					}
					floorNames.append(floor.name)
					floorIds.append(floor.id)
				}
			}
			floorNames.insert("全部楼层", atIndex: 0)
			floorIds.insert(0xFF, atIndex: 0)
			row += 1
			ValuePickerActionView(
				title: "可控楼层",
				values: floorNames,
				currentRow: row,
				delegate: nil
				).showWithHandler({ name, index in
					if self.newUser.insFloorID != UInt16(floorIds[index]){
                        self.newUser.insFloorID = UInt16(floorIds[index])
						self.newUser.insRoomID  = 0xFF
						self.tableView.reloadData()
					}
				})
		case 1 where indexPath.row == 1:
			var row = -1
			var roomNames = [String]()
			var roomIds = [UInt16]()
			var rooms: [HRRoomInfo]! = HRDatabase.shareInstance().getRooms(newUser.insFloorID)
			if rooms == nil {
				rooms = [HRRoomInfo]()
			}
			for i in 0..<rooms.count  {
				if rooms[i].id == newUser.insRoomID {
					row = i
				}
				roomNames.append(rooms[i].name)
				roomIds.append(rooms[i].id)
			}
			roomNames.insert("全部房间", atIndex: 0)
			roomIds.insert(0xFF, atIndex: 0)
			row += 1
			ValuePickerActionView(
				title: "可控房间",
				values: roomNames,
				currentRow: row,
				delegate: nil
				).showWithHandler({ name, index in
					
					self.newUser.insRoomID = roomIds[index]
					tableView.reloadData()
				})
		case 2 where indexPath.row == 1 && !isEditingPasswd && user != nil:
			isEditingPasswd = true
			tableView.reloadSections(NSIndexSet(index: 2), withRowAnimation: UITableViewRowAnimation.Fade)
		case 2 where indexPath.row == 3:
			isEditingPasswd = false
			tableView.reloadSections(NSIndexSet(index: 2), withRowAnimation: UITableViewRowAnimation.Fade)
		case 3 where indexPath.row == 0:
			UIAlertView(title: "您确定要删除“\(user!.name)”吗？", message: "", delegate: self, cancelButtonTitle: "取消", otherButtonTitles: "删除").show()
		default: break
		}
		
	}
	
	@objc private func textFieldTextChanged(textField: UITextField) {
		guard let text = textField.text else {
			return
		}
		newUser.name = text
	}
	
	@objc private func textFieldEditEnd(textField: UITextField) {
		textField.resignFirstResponder()
	}

	@objc private func passwdTextFieldEditingEnd(textField: UITextField) {
		if textField === passwd0TextField && !isEditingPasswd {
			textField.resignFirstResponder()
		} else if textField === passwd0TextField && isEditingPasswd {
			passwd1TextField?.becomeFirstResponder()
		} else if textField === passwd1TextField {
			passwd2TextField?.becomeFirstResponder()
		} else if textField == passwd2TextField {
			passwd2TextField?.resignFirstResponder()
		}
	}
	
	@objc private func tapSaveBarButton() {
		var error: NSError?
		if user?.name != newUser.name {
			error = newUser.illegalNameError
		} else {
			error = HRDatabase.shareInstance().checkName(newUser.devType, name: newUser.name, allowDuplication: true)
		}
		if let err = error {
			UIAlertView(title: err.localizedDescription, message: nil, delegate: nil, cancelButtonTitle: "明白").show()
			return
		}
		
		if user == nil { //创建用户
			if passwd1TextField!.text!.isEmpty || passwd2TextField!.text!.isEmpty {
				UIAlertView(title: "密码不能为空！", message: nil, delegate: nil, cancelButtonTitle: "确定").show()
				return
			}
			if !passwd1TextField!.text!.isPassword {
				UIAlertView(title: "密码不能少于6个字符！", message: nil, delegate: nil, cancelButtonTitle: "确定").show()
				return
			}
			if passwd1TextField!.text! != passwd2TextField!.text! {
				UIAlertView(title: "两次输入的密码不一致！", message: nil, delegate: nil, cancelButtonTitle: "确定").show()
				return
			}
			KVNProgress.showWithStatus("正在保存...")
			HR8000Service.shareInstance().createUser(newUser, newPasswd: passwd1TextField!.text!, result: { error in
				if let err = error {
					KVNProgress.showErrorWithStatus(err.domain)
				} else {
					KVNProgress.showSuccessWithStatus("创建成功！")
					runOnMainQueueDelay(500, block: {
						self.navigationController?.popViewControllerAnimated(true)
					})
				}
			})
			return
		}
		//修改用户信息
		var newPasswd: String!
		var origPasswd: String!
		if isEditingPasswd {
			if passwd0TextField!.text!.isEmpty || passwd1TextField!.text!.isEmpty || passwd2TextField!.text!.isEmpty {
				UIAlertView(title: "密码不能为空！", message: nil, delegate: nil, cancelButtonTitle: "确定").show()
				return
			}
			if !passwd1TextField!.text!.isPassword {
				UIAlertView(title: "密码不能少于6个字符！", message: nil, delegate: nil, cancelButtonTitle: "确定").show()
				return
			}
			if passwd1TextField!.text != passwd2TextField!.text! {
				UIAlertView(title: "两次输入的密码不一致！", message: nil, delegate: nil, cancelButtonTitle: "确定").show()
				return
			}
			newPasswd = passwd1TextField!.text!
			origPasswd = passwd0TextField!.text!
		} else {
			if passwd0TextField!.text!.isEmpty {
				UIAlertView(title: "密码不能为空！", message: nil, delegate: nil, cancelButtonTitle: "确定").show()
				return
			}
			newPasswd = passwd0TextField!.text!
			origPasswd = passwd0TextField!.text!
		}
		KVNProgress.showWithStatus("正在保存...")
		HR8000Service.shareInstance().editUserInfo(newUser, newPasswd: newPasswd, origUserName: user!.name, origPasswd: origPasswd, result: { error in
			if let err = error {
				KVNProgress.showErrorWithStatus(err.domain)
			} else {
				KVNProgress.showSuccessWithStatus("保存成功！")
				runOnMainQueueDelay(500, block: {
					self.navigationController?.popViewControllerAnimated(true)
				})
			}
		})
	}
	
	func alertView(alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
		if buttonIndex != alertView.cancelButtonIndex {
			KVNProgress.showWithStatus("正在删除...")
			HR8000Service.shareInstance().deleteUser(newUser, result: { error in
				if let err = error {
					KVNProgress.showErrorWithStatus(err.domain)
				} else {
					KVNProgress.showSuccessWithStatus("删除成功！")
					runOnMainQueueDelay(500, block: {
						self.navigationController?.popViewControllerAnimated(true)
					})
				}
			})
		}
	}
}
