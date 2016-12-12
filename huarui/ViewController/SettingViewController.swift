//
//  SettingViewController.swift
//  huarui
//
//  Created by sswukang on 15/4/14.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import UIKit

/// 设置主界面
class SettingViewController: UITableViewController, HR8000HelperDelegate, UIAlertViewDelegate {
    //主机版本
    private var hostVersion: String = "--"
    
    
    
    
    
    private var master : HRMaster?
    
    
    
    
	
	private var hostVerLabel: UILabel!
    
    
    
    override func viewWillAppear(animated: Bool) {
        HR8000Service.shareInstance().queryDevice(.Master, devAddr: HRDatabase.shareInstance().server.hostAddr)
        
        
    print("\(self.master?.version.toString)")
    }
	
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "设置"
        
        
		tableView.backgroundColor = UIColor.tableBackgroundColor()
		tableView.separatorColor = UIColor.tableSeparatorColor()
        //显示tableView的头部视图 去掉或者有self.都一样可以运行成功   斌注释
    // tableView.tableHeaderView = getHeaderView()
        
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

    
    
    
    
	
    func getHeaderView() -> UIView{
        let container = UIView(frame: CGRectMake(0, 0, self.view.frame.width, self.view.frame.width*0.4))
        var y: CGFloat = 0
        if UIScreen.mainScreen().bounds.height != 960 { //如果是iPhone4/4s，则不显示图标
            let imageView = UIImageView(frame: CGRectMake(0, 20, container.frame.width/2, container.frame.height*0.4))
            imageView.center.x = container.frame.width/2
            imageView.image = UIImage(named: "华睿云中文")
            imageView.contentMode = UIViewContentMode.ScaleAspectFit
            container.addSubview(imageView)
            y = imageView.frame.maxY
        }
		
        let verLabel = UILabel(frame: CGRectMake(0, y+10, container.frame.width, 20))
        verLabel.center.x = container.frame.width/2
        verLabel.textAlignment = .Center
        verLabel.font = UIFont.systemFontOfSize(UIFont.systemFontSize())
        verLabel.text = "软件版本：" + appVersionStr
        container.addSubview(verLabel)
        container.frame = CGRectMake(0, 0, container.frame.width, verLabel.frame.maxY + 20)
        
		
		
		hostVerLabel = UILabel(frame: CGRectMake(0, verLabel.frame.maxY, verLabel.frame.width, verLabel.frame.height))
		hostVerLabel.center.x = container.frame.width/2
		hostVerLabel.textAlignment = .Center
		hostVerLabel.font = UIFont.systemFontOfSize(UIFont.systemFontSize())
        
        
        
        //HRDatabase
//        
//       print( HRDatabase.shareInstance().server.getHostIPAddrString())
//        print("主机的mac地址\(HRDatabase.shareInstance().server.macAddr)")
        
        
        
       // 主机版本的坑 斌注释
        hostVersion = NSString(format: "%d", HRMaster.version()) as String
       // HRDatabase.shareInstance().master?.version
        
         //let _master = self.master
        
        
        
    
        
//      print(HRDatabase.shareInstance().master?.version.build)
//        
//        
//        print(hostVersion)
//        
//        
//        
//        
//        print(HRDatabase.shareInstance().master?.version.toString
        
    
//)
        
        
		hostVerLabel?.text = "caonimabi "
        //主机版本 斌修改
      //  hostVerLabel.text = "主机版本：2.3.9.452"
		container.addSubview(hostVerLabel)
		
		container.frame = CGRectMake(0, 0, container.frame.width, hostVerLabel.frame.maxY + 20)
        return container
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if section == 0 { return 4 }
		//if section == 1 { return 2 }
        //本来是两行的 删除了版本号剩下了一行
        if section == 1 { return 1 }

        return 1
    }
    
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "settingCell")
		cell.textLabel?.textColor = UIColor.tableTextColor()
        switch indexPath.section {
		case 0 where indexPath.row == 0:
			cell.textLabel?.text = "用户管理"
			cell.accessoryType = .DisclosureIndicator
		case 0 where indexPath.row == 1:
			cell.textLabel?.text = "楼层管理"
			cell.accessoryType = .DisclosureIndicator
		case 0 where indexPath.row == 2:
			cell.textLabel?.text = "设备管理"
			cell.accessoryType = .DisclosureIndicator
		case 0 where indexPath.row == 3:
			cell.textLabel?.text = "主机信息"
			cell.accessoryType = .DisclosureIndicator
		case 0 where indexPath.row == 4:
			cell.textLabel?.text = "语音设置"
			cell.accessoryType = .DisclosureIndicator
		case 1 where indexPath.row == 0:
			cell.textLabel?.text = "关于"
			cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            
            //斌注释 因为苹果拒绝在app内显示app版本信息 所以这里
//		case 1 where indexPath.row == 1:
//			cell.textLabel?.text = "软件版本"
//			cell.detailTextLabel?.text = appVersionStr
		case 2 where indexPath.row == 0:
			if logoutLabel == nil {
				logoutLabel = UILabel(frame: CGRectMake(0, 0, tableView.bounds.width, cell.bounds.height))
				logoutLabel.text = "注销"
				logoutLabel.textAlignment = .Center
				//logoutLabel.textColor = UIColor(R: 217, G: 82, B: 87, alpha: 1)
                logoutLabel.textColor=UIColor(R: 217, G: 82, B: 87, alpha: 1)
                
			}
			cell.addSubview(logoutLabel)
        default: break
        }
        
        return cell
    }
	
	private var logoutLabel: UILabel!
    
	
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
        switch indexPath.row {
        case 0 where indexPath.section == 1:
			performSegueWithIdentifier("showAboutUsViewController", sender: nil)
		case 0 where indexPath.section == 2:
			UIAlertView(title: "您确定要注销吗？", message: "", delegate: self, cancelButtonTitle: "取消", otherButtonTitles: "注销") .show()
		case 0 where indexPath.section == 0:
			navigationController?.pushViewController(UserManagerViewController(), animated: true)
		case 1 where indexPath.section == 0:
			navigationController?.pushViewController(FloorManagerViewController(), animated: true)
		case 2 where indexPath.section == 0:
			navigationController?.pushViewController(DeviceManagerViewController(), animated: true)
		case 3 where indexPath.section == 0:
			navigationController?.pushViewController(HostInfoViewController(), animated: true)
		case 4 where indexPath.section == 0:
			navigationController?.pushViewController(VoiceSettingsViewController(), animated: true)
        default: break
        }
    }
	
    
//MARK: - 注销
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
		guard let title = alertView.buttonTitleAtIndex(buttonIndex) else {
			return
		}
        switch title {
        case "注销" :
			self.navigationController?.popToRootViewControllerAnimated(true)
            HR8000Service.shareInstance().logout()
            //退出这个界面回到根视图同时HR8000登出 斌注释
        default: break
        }
        
    }
    

}
