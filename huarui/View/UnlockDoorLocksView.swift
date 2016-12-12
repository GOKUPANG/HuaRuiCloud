//
//  UnlockDoorLocksView.swift
//  huarui
//
//  Created by sswukang on 15/12/16.
//  Copyright © 2015年 huarui. All rights reserved.
//

import UIKit

/// 开门锁的view
class UnlockDoorLocksView: UIView, UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate {
	
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var cancelButton: UIButton!
	
	var backgroundView: UIView?
	private var realFrame: CGRect!
	private var locks: [HRDoorLock]!
    private var testLocks: [HRDevice]!

	
	override func awakeFromNib() {
        
        
        
        let GaodunArray   = getMyLockFormDatabase(HRDeviceType.GaoDunDoor)
        
        let oldArray      = getMyLockFormDatabase(HRDeviceType.DoorLock)
        
        
        let allLockArray = GaodunArray + oldArray
        
        testLocks = allLockArray
        
		if let locks = HRDatabase.shareInstance().getDevicesOfType(.DoorLock) as? [HRDoorLock]{
			self.locks = locks
		} else {
			self.locks = [HRDoorLock]()
		}
        self.tintColor          = .whiteColor()
        tableView.delegate             = self
        tableView.dataSource           = self
        tableView.separatorInset       = UIEdgeInsetsMake(0, 15, 0, 15)
        titleLabel.text                = "智能门锁"
        titleLabel.textColor           = self.tintColor
        cancelButton.layer.borderColor = self.tintColor.CGColor
		cancelButton.setTitleColor(self.tintColor, forState: .Normal)
	}
	
	override func drawRect(rect: CGRect) {
		if let _backgroundView = backgroundView {
			self.superview?.insertSubview(_backgroundView, belowSubview: self)
		}
	}
	
    
    
    
    private func getMyLockFormDatabase(type:HRDeviceType) -> [HRDevice]{
        
        let locks = HRDatabase.shareInstance().getDevicesOfType(type)
        
        
        print(locks)
        
        return locks!
        
        
        
    }

    
    
    
    
    
	
	///使用动画方式显示View
	func showInView(inView: UIView) {
		inView.addSubview(self)
        self.realFrame = self.frame
        self.center.y  = inView.frame.minY - self.bounds.height
		
		UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveLinear, animations: {
				self.frame = self.realFrame
			}, completion: nil)
	}
	
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        
        return testLocks.count
        
        
		//return locks.count
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		var cell: UITableViewCell! = tableView.dequeueReusableCellWithIdentifier("cell")
		if cell == nil {
			cell = UITableViewCell(style: .Subtitle, reuseIdentifier: "cell")
		}
		var floorName = "(未知楼层)"
		var roomName  = "(未知房间)"
        if let name = testLocks[indexPath.row].insFloorName {
            floorName = name
        }
        if let name = testLocks[indexPath.row].insRoomName {
            roomName = name
        }

        
        
//		if let name = locks[indexPath.row].insFloorName {
//			floorName = name
//		}
//		if let name = locks[indexPath.row].insRoomName {
//			roomName = name
//		}
		cell.selectionStyle = .Blue
		cell.imageView?.image      = UIImage(named: "ic_ctl_lock_on.png")?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        
        cell.textLabel?.text       = testLocks[indexPath.row].name

	//	cell.textLabel?.text       = locks[indexPath.row].name
        cell.detailTextLabel?.text = "\(floorName) - \(roomName)"
		cell.backgroundColor       = .clearColor()
        cell.textLabel?.textColor       = self.tintColor
        cell.detailTextLabel?.textColor = self.tintColor
		
		return cell
	}
	
	func tableView(tableView: UITableView, didEndDisplayingCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
		cell.separatorInset = UIEdgeInsetsMake(0, 15, 0, 15)
	}
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
		
		//let alert = UIAlertView(title: locks[indexPath.row].name, message: "请输开锁密码：", delegate: self, cancelButtonTitle: "取消", otherButtonTitles: "开锁")
        
        
        let alert = UIAlertView(title: testLocks[indexPath.row].name, message: "请输开锁密码：", delegate: self, cancelButtonTitle: "取消", otherButtonTitles: "开锁")
        
		alert.alertViewStyle = UIAlertViewStyle.SecureTextInput
		alert.tag = indexPath.row
		alert.show()
	}
	
	@IBAction func tapCancelButton(sender: UIButton) {
		UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
				self.center.y = self.superview!.bounds.height + self.bounds.midY + 2
			}, completion: { _ in
				self.removeFromSuperview()
				self.backgroundView?.removeFromSuperview()
		})
		
	}
	
	func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
		if buttonIndex == alertView.cancelButtonIndex { return }
		guard let passwd = alertView.textFieldAtIndex(0)?.text where !passwd.isEmpty else {
			tableView(tableView, didSelectRowAtIndexPath: NSIndexPath(forRow: alertView.tag, inSection: 0))
			return
		}
        
        
        
        
        
        let device  = testLocks[alertView.tag]
        
        
        switch device.devType {
        case HRDeviceType.DoorLock.rawValue:
            
            
            
            		KVNProgress.showWithStatus("正在开锁...")
            
            
            		HR8000Service.shareInstance().unlockDoor(device as! HRDoorLock, passwd: passwd, callback: {
            			(error) in
            			runOnMainQueue({
            				if let err = error{
            					if err.code == HRErrorCode.BatteryLowPower.rawValue{
            						Log.verbose("电池电量不足")
            						return
            					}
            					KVNProgress.showErrorWithStatus("智能门锁打开失败:\(err.domain)")
            				}else {
            					KVNProgress.showSuccessWithStatus("智能门锁已打开")
            				}
            			})
            		})

            
            
            break
            
            
            
        case HRDeviceType.GaoDunDoor.rawValue:
            
            
            
            KVNProgress.showWithStatus("开锁")
            (device as! HRSmartDoor).unlockSmartDoor(passwd, result: {
                (error) in
                
                
                
                if let err = error{
                    
                    
                    
                    print("错误码\(err.code)")
                    
                    
                    if err.code == HRErrorCode.Timeout.rawValue{
                        //                    self.tipsView.show("\(err.domain)", duration: 5.0)
                        KVNProgress.showErrorWithStatus("\(err.domain)")
                        
                        
                    } else {
                        KVNProgress.showErrorWithStatus("\(err.domain)")
                    }
                }
                    
                    
                else {
                    KVNProgress.showSuccessWithStatus("智能门锁已打开")
                }
                
            })
            
            
            
            
            
            
            
            break
            
        default:
            break
        }
        
        
        
        
        
        
        
        
//		KVNProgress.showWithStatus("正在开锁...")
//        
//        
//		HR8000Service.shareInstance().unlockDoor(locks[alertView.tag], passwd: passwd, callback: {
//			(error) in
//			runOnMainQueue({
//				if let err = error{
//					if err.code == HRErrorCode.BatteryLowPower.rawValue{
//						Log.verbose("电池电量不足")
//						return
//					}
//					KVNProgress.showErrorWithStatus("智能门锁打开失败:\(err.domain)")
//				}else {
//					KVNProgress.showSuccessWithStatus("智能门锁已打开")
//				}
//			})
//		})
	}
    
    
    
    
    
  }











