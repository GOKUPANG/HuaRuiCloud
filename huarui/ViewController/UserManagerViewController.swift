//
//  UserManagerViewController.swift
//  huarui
//
//  Created by sswukang on 15/11/30.
//  Copyright © 2015年 huarui. All rights reserved.
//

import UIKit



/// 设置 - 用户管理
class UserManagerViewController: UITableViewController, HR8000HelperDelegate {

	var users: [HRUserInfo]!
	
	///管理员用户
	private var adminUsers: [HRUserInfo]!
	///普通用户
	private var normalUsers: [HRUserInfo]!
	
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
		self.title = "用户管理"
        //这两个方法是用分类去实现的 给UIColor添加新的分类 斌注释
		tableView.backgroundColor = UIColor.tableBackgroundColor()
		tableView.separatorColor = UIColor.tableSeparatorColor()
		if HRDatabase.isEditPermission {
			self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(UserManagerViewController.tapAddBarButton))
		}
        
        //让这个控制器成为HR8000HelperDelegate的代理 斌注释
		HRProcessCenter.shareInstance().delegates.hr8000HelperDelegate = self
    }
	
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		if let users =
            //HRdataBase获得的单例HRDatabase通过getDevicesOfType获取设备类型得到HRdevice类 HRdevice有一个UserInfo的方法可以获取到设备的用户信息 斌 门锁相关
        /**用户信息,0xF8*/
       // case UserInfo               = 0xF8

            HRDatabase.shareInstance().getDevicesOfType(.UserInfo) as? [HRUserInfo] {
			self.users = users
		} else {
			self.users = [HRUserInfo]()
		}
		adminUsers  = [HRUserInfo]()
		normalUsers = [HRUserInfo]()
		for user in self.users {
            
            //print(user.isAdministrator)
            
			if user.isAdministrator {
				adminUsers.append(user)
			} else {
				normalUsers.append(user)
			}
		}
		return 2
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if section == 0 { return adminUsers.count }
		return normalUsers.count
		
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		var cell = tableView.dequeueReusableCellWithIdentifier("cell")
		if cell == nil {
			cell = UITableViewCell(style: .Value1, reuseIdentifier: "cell")
		}
		let user: HRUserInfo
		if indexPath.section == 0 {
			user = adminUsers[indexPath.row]
			cell!.textLabel?.text = user.name
			cell!.imageView?.image = UIImage(named: "ico_user")
		} else {
			user = normalUsers[indexPath.row]
			cell!.textLabel?.text = user.name
			cell!.imageView?.image = UIImage(named: "ico_user_normal")
		}
		if HRDatabase.isEditPermission || HRDatabase.shareInstance().acount.userName == user.name {
			cell!.accessoryType = .DisclosureIndicator
		}
		return cell!
	}
	
	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if section == 0 { return adminUsers.count > 0 ? "管理员":"" }
		return normalUsers.count > 0 ? "普通用户":""
	}
	
	override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
		return true
	}
	
	override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
		if indexPath.row == 1 { return UITableViewCellEditingStyle.Delete }
		return .None
	}
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
		let cell = tableView.cellForRowAtIndexPath(indexPath)
		
		if cell?.accessoryType != .DisclosureIndicator {
			return
		}
		
		let vc = EditUserInfoViewController()
		if indexPath.section == 0 {
			vc.user = adminUsers[indexPath.row]
		} else {
			vc.user = normalUsers[indexPath.row]
		}
		
		self.navigationController?.pushViewController(vc, animated: true)
	}

	@objc private func tapAddBarButton() {
		self.navigationController?.pushViewController(EditUserInfoViewController(), animated: true)
	}
	
    //的确已经删除了设备，就回调 斌注释
	func hr8000Helper(didDeleteDevice device: HRDevice) {
		if device.devType == HRDeviceType.UserInfo.rawValue {
			tableView.reloadData()
		}
	}
	
	func hr8000Helper(finishedQueryDeviceInfo finish: Bool) {
		tableView.reloadData()
	}
}
