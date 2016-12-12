//
//  SetRFParameterDetailViewController.swift
//  huarui
//
//  Created by sswukang on 15/12/10.
//  Copyright © 2015年 huarui. All rights reserved.
//

import UIKit

class SetRFParameterViewController: UITableViewController {

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
		tableView.backgroundColor = UIColor.tableBackgroundColor()
		tableView.separatorColor = UIColor.tableSeparatorColor()
		
        self.navigationItem.leftBarButtonItem  = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: #selector(SetRFParameterViewController.tapCancelButton))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(SetRFParameterViewController.tapDoneButton))
		
		if let navBar = self.navigationController?.navigationBar {
			//设置navBar样式
			navBar.barTintColor = APP.param.themeColor
			navBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
			navBar.tintColor = UIColor.whiteColor()
		}
		self.title = "参数设置"
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return "首次使用，需要手动设置系统参数才能继续！"
	}
	
	private var channelTextField: UITextField!
	private var RFAddrTextField: UITextField!
	
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		var cell: UITableViewCell! = tableView.dequeueReusableCellWithIdentifier("cell")
		
		if cell == nil {
			cell = UITableViewCell(style: .Default, reuseIdentifier: "cell")
		}
		switch indexPath.row {
		case 0:
			if channelTextField == nil {
				channelTextField = UITextField(frame: CGRectMake(tableView.bounds.width*0.3, 0, tableView.bounds.width*0.7, cell.bounds.height))
				channelTextField.placeholder = "整数，范围：1~8"
				channelTextField.keyboardType = .NumberPad
				channelTextField.returnKeyType = .Next
				channelTextField.clearButtonMode = .WhileEditing
				channelTextField.addTarget(self, action: #selector(SetRFParameterViewController.channelTextFieldEditEndExit(_:)), forControlEvents: .EditingDidEndOnExit)
			}
			cell.textLabel?.text = "信道"
			channelTextField.removeFromSuperview()
			cell.addSubview(channelTextField)
		case 1:
			if RFAddrTextField == nil {
				RFAddrTextField = UITextField(frame: CGRectMake(tableView.bounds.width*0.3, 0, tableView.bounds.width*0.7, cell.bounds.height))
				RFAddrTextField.placeholder = "整数，范围：1~255"
				RFAddrTextField.keyboardType = .NumberPad
				RFAddrTextField.returnKeyType = .Done
				RFAddrTextField.clearButtonMode = .WhileEditing
				RFAddrTextField.addTarget(self, action: #selector(SetRFParameterViewController.RFAddrTextFieldEditEndExit(_:)), forControlEvents: .EditingDidEndOnExit)
			}
			cell.textLabel?.text = "RF地址码"
			RFAddrTextField.removeFromSuperview()
			cell.addSubview(RFAddrTextField)
		default: break
		}

        return cell
	}
	
	@objc private func channelTextFieldEditEndExit(textField: UITextField) {
		RFAddrTextField.becomeFirstResponder()
	}
	
	@objc private func RFAddrTextFieldEditEndExit(textField: UITextField) {
		tapDoneButton()
	}
	
	@objc private func tapCancelButton() {
		let rootVC = (UIApplication.sharedApplication().delegate as! AppDelegate).window?.rootViewController as? UINavigationController
		rootVC?.popToRootViewControllerAnimated(false)
		self.dismissViewControllerAnimated(true, completion: nil)
	}

	@objc private func tapDoneButton() {
		let channelNum = NSString(string: channelTextField.text! ).integerValue
		if channelNum < 1 || channelNum > 8 {
			channelTextField.becomeFirstResponder()
			return
		}
		let rfAddrNum = NSString(string: RFAddrTextField.text! ).integerValue
		if rfAddrNum < 1 || rfAddrNum > 255 {
			RFAddrTextField.becomeFirstResponder()
			return
		}
		
		KVNProgress.showWithStatus("正在处理...")
		HR8000Service.shareInstance().setSystemParameter(HRDatabase.shareInstance().server.hostAddr, channel: Byte(channelNum), RFAddr: Byte(rfAddrNum), result: { error in
			if let err = error {
				KVNProgress.showErrorWithStatus(err.domain)
			} else {
				HRDatabase.shareInstance().acount.haveSetRFParameter = true
				KVNProgress.showSuccessWithStatus("设置成功")
				runOnMainQueueDelay(500, block: {
					self.dismissViewControllerAnimated(true, completion: nil)
				})
			}
		})
	}
}
