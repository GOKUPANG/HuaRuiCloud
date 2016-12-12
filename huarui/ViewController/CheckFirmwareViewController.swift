//
//  CheckFirmwareViewController.swift
//  huarui
//
//  Created by 海波 on 16/3/24.
//  Copyright © 2016年 huarui. All rights reserved.
//

import UIKit

class CheckFirmwareViewController: UITableViewController, HR8000HelperDelegate {

    ///检查固件有新版本- 0x01表示有新版本 - 属性
    private var version: String?
    private var message: String?
    private var size: String?
    private var date: String?
    
    private var firmwareCell: CheckFirmwareCell?
    ///无新版本或更新失败
    private var newCode: Byte?
    ///无新版本或更新失败
    private var newMessage: String?
    
    ///无法更新信息
    private var upDataCode: Byte?
    ///无法更新信息
    private var upDataMessage: String?
    
	var tipsView: TipsView!
    private var checkLabel: UILabel?
    private var checkActivity: UIActivityIndicatorView?
    
    init() {
        super.init(style: .Grouped)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    //请勿删除此init方法，否则在iOS8中会报“use of unimplemented initializer 'init(nibName:bundle:)'”异常.
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "更新固件信息"
        tableView.backgroundColor = UIColor.tableBackgroundColor()
        tableView.separatorColor = UIColor.tableSeparatorColor()
        tipsView = TipsView(frame: CGRectMake(0, 0, self.view.bounds.width, 30))
        
        self.view.addSubview(tipsView)
        
        HRProcessCenter.shareInstance().delegates.hr8000HelperDelegate = self
        //check new version, 10s timeout
        HR8000Service.shareInstance().checkFirmwareVersion(30.0, result: { (error) -> Void in
            Log.debug("------------")
            if let err = error {//如果error为空  就执行以下代码
                Log.error("错误:\(err.domain)\(err.code)")
                self.checkLabel?.text = "\(err.domain)(\(err.code))"
                self.checkLabel?.sizeToFit()
                self.checkActivity?.stopAnimating()
                self.checkActivity!.hidesWhenStopped = true
            }
        })
        
	self.tableView.registerNib(UINib(nibName: "CheckFirmwareCell", bundle: nil), forCellReuseIdentifier: "CheckFirmwareCell")
        
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        if version == nil {
            if checkLabel == nil {
                showIndicator("正在检查...")
            }
            return 0
            
        }
        
        checkLabel?.removeFromSuperview()
        checkActivity?.removeFromSuperview()
        checkLabel = nil
        checkActivity = nil
        
        if  self.newCode != nil {//假如更新失败
            if checkLabel == nil {
                showIndicator("\(self.newCode!)\(self.newMessage!)")
            }
            return 1
            
        }
        checkLabel?.removeFromSuperview()
        checkActivity?.removeFromSuperview()
        checkLabel = nil
        checkActivity = nil

        
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        if indexPath.section == 0 {
        
            if self.newCode == nil{
            let cell = tableView.dequeueReusableCellWithIdentifier("CheckFirmwareCell") as! CheckFirmwareCell
            cell.versionLabel.text = "版本号:\t\(version!)"
            cell.sizeLabel.text = "大  \t 小:\t\(size!)"
            cell.descriptionLabel.text = "\(message!)"
            cell.dateLabel.text = "日  \t 期:\t\(date!)"
            cell.userInteractionEnabled = false
            return cell
                
            }else{
                var cell = tableView.dequeueReusableCellWithIdentifier("cell")
                if cell == nil {
                    cell = UITableViewCell(style: .Value1, reuseIdentifier: "cell")
                    
                    cell?.tintColor = UIColor.blueColor()
                    cell?.hidden = true
                }
                return cell!
            }
        }else{
            
            var cell = tableView.dequeueReusableCellWithIdentifier("cell")
            
            if cell == nil {
                cell = UITableViewCell(style: .Value1, reuseIdentifier: "cell")
            }
            cell?.textLabel?.text = "安装新固件"
            cell?.textLabel?.textColor = tableView.tintColor
            return cell!
        }
        
    }
    
    private var isClick = false
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if isClick { return }
        
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        cell?.textLabel?.textColor = tableView.tintColor.colorWithAlphaComponent(0.2)
        cell?.userInteractionEnabled = false
        switch indexPath.section {
        case 1://///发送一帧数据给主机表示要请求更新设备- APP请求更新固件- 闭包回调请求结果
            isClick = true
            self.tipsView.show("正在安装,请勿断电!", duration: 30.0)
            HR8000Service.shareInstance().UpDataVersion(30.0, result: { (error) -> Void in

                if let err = error {
                    Log.error("错误:\(err.domain)\(err.code)")
                    self.tipsView.show("\(err.domain)(\(err.code))", duration: 5.0, tipsViewColor: UIColor.redColor())
					runOnMainQueueDelay(4000, block: {
						self.tipsView.dismiss()
					})
                    self.isClick = false
                    cell?.textLabel?.textColor = tableView.tintColor
                    cell?.userInteractionEnabled = true
                }else{
					
                    if self.upDataCode == nil && self.newCode == nil {
                        //定时4s后跳转到登录界面
						self.tipsView.dismiss()
                        KVNProgress.showWithStatus("更新成功,正在跳转到登录界面")
                        
                        runOnMainQueueDelay(2000, block: { () -> Void in
                            
                            KVNProgress.dismiss()
                            
                            (UIApplication.sharedApplication().keyWindow?.rootViewController as? UINavigationController)?.popToRootViewControllerAnimated(true)
                            
                        })
                        
                        Log.debug("定时2s后跳转到登录界面")
                        
                    }else{
						
						self.tipsView.dismiss()
                        KVNProgress.showErrorWithStatus("\(self.upDataCode!)\(self.upDataMessage!)")
                        
                    }
                }
                
            })
        default: break
            
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 {
            
            return 250
            
        }else {
            return self.tableView.rowHeight
        }
    }
 
    private func showIndicator(text: String) {
        
        checkLabel?.hidden = false
        checkActivity?.hidden = false
        let text = text
        checkLabel = UILabel()
        let size = NSString(string: text).sizeWithAttributes([NSFontAttributeName: checkLabel!.font])
        checkLabel!.frame = CGRectMake(0, view.bounds.height * 0.35, size.width, size.height)
        checkLabel!.center.x = view.bounds.midX
        checkLabel!.text = text
        checkLabel!.textColor = UIColor.tableTextColor()
        
        
        checkActivity = UIActivityIndicatorView()
        checkActivity!.frame = CGRectMake(checkLabel!.frame.maxX, checkLabel!.frame.minY, checkLabel!.bounds.height, checkLabel!.bounds.height)
        checkActivity!.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.White
        checkActivity!.color = UIColor.tableTextColor()
        self.view.addSubview(checkLabel!)
        self.view.addSubview(checkActivity!)
        checkActivity!.startAnimating()
        if self.newCode != nil {//假如更新失败
            checkActivity?.removeFromSuperview()
        }
    }
    
    
    //MARK: - checkFirmwaredelegate
    ///检查固件有新版本- 0x01表示有新版本
    func checkFirmware(hasNewVersion version: String, size: String, date: String, description: String) {
        self.version = version
        self.message = description
        self.size = size
        self.date = date
        
        if let master = HRDatabase.shareInstance().master {
            if master.version.toString.compare(version) == .OrderedAscending {
                self.tableView.reloadData()
            } else {
                self.checkLabel?.text = "当前为最新版本"
                self.checkLabel?.sizeToFit()
                self.checkLabel?.center.x = self.view.bounds.midX
                self.checkActivity?.stopAnimating()
            }
        }
        
    }
    
    ///检查更新设备失败或没有新版本- 0x00表示无新版本或更新失败
    func checkFirmware(noNewVersion code: Byte, message: String) {
        
        self.checkActivity?.hidesWhenStopped = true
        self.checkActivity?.stopAnimating()
        self.newCode = code
        self.newMessage = message
        
        Log.debug("\(code)失败原因:\(message)")
    }
    
     //MARK: - upDataFirmwaredelegate
    
     ///无法更新新版本- 0x03：表示请求更新之 - 0x00表示无法更新
    func upDataFirmware(noUpDataVersion code: Byte, message: String) {
        
        self.upDataCode = code
        self.upDataMessage = message
         Log.debug("\(code)失败原因:\(message)")
    }
}
