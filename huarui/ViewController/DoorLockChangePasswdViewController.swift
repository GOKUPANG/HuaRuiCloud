//
//  DoorLockChangePasswdViewController.swift
//  huarui
//
//  Created by sswukang on 15/12/5.
//  Copyright © 2015年 huarui. All rights reserved.
//

import UIKit

/// 修改门锁密码
class DoorLockChangePasswdViewController: UITableViewController,UITextFieldDelegate {

	var lock: HRDoorLock!
	
	private var passwd0TextField: UITextField!
	private var passwd1TextField: UITextField!
	private var passwd2TextField: UITextField!
	
	init() {
		super.init(style: .Grouped)
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
		if lock == nil { return }
		self.title = "修改门锁密码"
		tableView.backgroundColor = UIColor.tableBackgroundColor()
		tableView.separatorColor = UIColor.tableSeparatorColor()
		
		if HRDatabase.isEditPermission {
			navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: #selector(tapSaveBarButton))
		}
		
    }

	override func viewDidAppear(animated: Bool) {
		if self.lock == nil {
			self.navigationController?.popViewControllerAnimated(true)
		}
	}
	
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
 //头部视图文字 斌
	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return lock!.name
	}
	//尾部视图文字 斌
	override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		return "注意：APP设置的密码与门锁自身的密码相互独立，所以在此修改的密码不会改变门锁自身的密码。"
	}
	
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("cell_\(indexPath.row)")
		
		if cell == nil {
			cell = UITableViewCell(style: .Default, reuseIdentifier: "cell_\(indexPath.row)")
		}
		
		switch indexPath.row {
		case 0:
			if passwd0TextField == nil {
				passwd0TextField = UITextField(frame: CGRectMake(15,0,tableView.bounds.width - 15, cell!.bounds.height))
				passwd0TextField.placeholder     = "管理员密码"
                passwd0TextField.secureTextEntry = true
                passwd0TextField.clearButtonMode = .WhileEditing
                passwd0TextField.returnKeyType   = .Next
				passwd0TextField.addTarget(self, action: #selector(textFieldDidEditEndOnExit(_:)), forControlEvents: UIControlEvents.EditingDidEndOnExit)
			}
			cell!.addSubview(passwd0TextField)
		case 1:
			if passwd1TextField == nil {
				passwd1TextField = UITextField(frame: CGRectMake(15,0,tableView.bounds.width - 15, cell!.bounds.height))
                passwd1TextField.placeholder     = "新密码，密码规格为6个数字"
                passwd1TextField.secureTextEntry = true
                passwd1TextField.clearButtonMode = .WhileEditing
                passwd1TextField.returnKeyType   = .Next
				passwd1TextField.addTarget(self, action: #selector(textFieldDidEditEndOnExit(_:)), forControlEvents: UIControlEvents.EditingDidEndOnExit)
			}
			cell!.addSubview(passwd1TextField)
		case 2:
			if passwd2TextField == nil {
				passwd2TextField = UITextField(frame: CGRectMake(15,0,tableView.bounds.width - 15, cell!.bounds.height))
                passwd2TextField.placeholder     = "重复新密码，密码规格为6个数字"
                passwd2TextField.secureTextEntry = true
                passwd2TextField.clearButtonMode = .WhileEditing
                passwd2TextField.returnKeyType   = .Done
                
               // passwd0TextField.text
				passwd2TextField.addTarget(self, action: #selector(textFieldDidEditEndOnExit(_:)), forControlEvents: UIControlEvents.EditingDidEndOnExit)
			}
			cell!.addSubview(passwd2TextField)
		default: break
		}

        return cell!
    }

    
    
    
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
	}
	
	@objc private func textFieldDidEditEndOnExit(textField: UITextField) {
		if textField === passwd0TextField {
			passwd1TextField.becomeFirstResponder()
		} else if textField === passwd1TextField {
			passwd2TextField.becomeFirstResponder()
		} else if textField === passwd2TextField {
			textField.resignFirstResponder()
		}
	}
	
	@objc private func tapSaveBarButton() {
		if passwd0TextField.text!.isEmpty {
			passwd0TextField.becomeFirstResponder()
			return
		}
		if passwd1TextField.text!.isEmpty {
			passwd1TextField.becomeFirstResponder()
			return
		}
		if passwd1TextField.text!.isEmpty {
			passwd1TextField.becomeFirstResponder()
			return
		}
		if !passwd1TextField.text!.isPassword {
			UIAlertView(title: "密码长度不符合规定！", message: nil, delegate: nil, cancelButtonTitle: "确定").show()
			return
		}
		if passwd1TextField.text != passwd2TextField.text {
			UIAlertView(title: "输入的新密码不相等！", message: nil, delegate: nil, cancelButtonTitle: "确定").show()
			return
		}
		KVNProgress.showWithStatus("正在保存...")
        
        
        HR8000Service.shareInstance().changeDoorLockPassword(self.lock!, passwordForAdminstrator: passwd0TextField.text!, passwordForOpen: passwd1TextField.text!, result: { error in
			if let err = error {
				KVNProgress.showErrorWithStatus(err.domain)
			} else {
				KVNProgress.showSuccessWithStatus("修改成功")
				runOnMainQueueDelay(500, block: {
					self.navigationController?.popViewControllerAnimated(true)
				})
			}
		})
	}
}
