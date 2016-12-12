//
//  HostInfoViewController.swift
//  huarui
//
//  Created by sswukang on 15/11/30.
//  Copyright © 2015年 huarui. All rights reserved.
//

import UIKit

/// 设置 - 主机信息
class HostInfoViewController: UITableViewController, UIAlertViewDelegate{

	private var master: HRMaster?
	
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
	
	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		self.title = "主机信息"
		tableView.backgroundColor = UIColor.tableBackgroundColor()
		tableView.separatorColor = UIColor.tableSeparatorColor()
		if let _master = HRDatabase.shareInstance().master {
			self.master = _master
		} else {
			HRDatabase.shareInstance().addObserver(self, forKeyPath: "master", options: .New, context: nil)
		}
    }
	
	override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
		if keyPath == "master" {
			runOnMainQueue({
				self.master = HRDatabase.shareInstance().master
				self.tableView.reloadData()
			})
			HRDatabase.shareInstance().removeObserver(self, forKeyPath: "master")
		}
	}
    
    override func viewWillAppear(animated: Bool) {
        
        HR8000Service.shareInstance().queryDevice(.Master, devAddr: HRDatabase.shareInstance().server.hostAddr)
        
        self.tableView.reloadData()

        
    }
    
    
	override func viewDidAppear(animated: Bool) {
		if self.master == nil {
            
            
        
    HR8000Service.shareInstance().queryDevice(.Master, devAddr: HRDatabase.shareInstance().server.hostAddr)
		}
        
        
     	}
	
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 4
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
		case 0: return 1
		case 1: return 3
		case 2: return 3
		case 3: return 1
		default: return 0
		}
	}
	
	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		switch section {
		case 1: return "运行信息"
		case 2: return "通信版本"
		default: return nil
		}
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		var cell = tableView.dequeueReusableCellWithIdentifier("cell")
		if cell == nil {
			cell = UITableViewCell(style: .Value1, reuseIdentifier: "cell")
		}
		switch indexPath.section {
		case 0:
			cell?.textLabel?.text = "设备和情景数量"
			cell?.accessoryType = .DisclosureIndicator
		case 1 where indexPath.row == 0:
			cell?.textLabel?.text = "IP地址"
		case 1 where indexPath.row == 1:
			cell?.textLabel?.text = "MAC地址"
		case 1 where indexPath.row == 2:
			cell?.textLabel?.text = "固件版本"
		case 2 where indexPath.row == 0:
			cell?.textLabel?.text = "信道"
		case 2 where indexPath.row == 1:
			cell?.textLabel?.text = "地址码"
		case 2 where indexPath.row == 2:
			cell?.textLabel?.text = "版本"
		case 3:
			cell?.textLabel?.text = "检查新固件"
			cell?.accessoryType = .DisclosureIndicator
		default: break
		}
		
		if let _master = master {
			switch indexPath.section {
			case 1 where indexPath.row == 0:
                
               
                
				cell?.detailTextLabel?.text = _master.IPAddrString
                
     
                
               // cell?.detailTextLabel?.text = "192.168.0.11:19"

			case 1 where indexPath.row == 1:
				cell?.detailTextLabel?.text = _master.macAddrString
			case 1 where indexPath.row == 2:
				cell?.detailTextLabel?.text = _master.version.toString
                //cell?.detailTextLabel?.text = "2.3.9.452"

			case 2 where indexPath.row == 0:
				cell?.detailTextLabel?.text = "\(_master.channel)"
               // cell?.detailTextLabel?.text = "2"

			case 2 where indexPath.row == 1:
				cell?.detailTextLabel?.text = "\(_master.RFAddr)"
                
               // cell?.detailTextLabel?.text = "146"

			case 2 where indexPath.row == 2:
				cell?.detailTextLabel?.text = _master.RFVersionString
			default: break
			}
		}
		
		return cell!
	}
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
		switch indexPath.section {
		case 0:
			self.navigationController?.pushViewController(DevicesAndScenesTableViewController(), animated: true)
		case 3:	//检测新固件
            self.navigationController?.pushViewController(CheckFirmwareViewController(), animated: true)
            
		default: break
		}
	}
    
}
    

