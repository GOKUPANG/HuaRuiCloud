//
//  BaseManagerViewController.swift
//  huarui
//
//  Created by sswukang on 15/1/23.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import UIKit

class BaseManagerViewController: UIViewController, SlipMenuAddDeviceViewDelegate,UIActionSheetDelegate {
	
	
	private var isMenuShow = false
	
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
	
	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //设置背景图片
        self.view.layer.contents = UIImage(named: APP.param.backgroundImgName)?.CGImage
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BaseManagerViewController.socketDisconnected), name: kNotificationDidSocketDisconnected, object: nil)
    }
	
	
	override func viewWillAppear(animated: Bool) {
		if HRDatabase.isEditPermission && HR8000Service.shareInstance().isLogin {
            
           
			let addButton = UIButton(frame: CGRectMake(0, 0, 30, 30))
			addButton.setBackgroundImage(UIImage(named: "ico_add"), forState: .Normal)
			addButton.addTarget(self, action: #selector(BaseManagerViewController.onAddButtonClicked(_:)), forControlEvents: UIControlEvents.TouchUpInside)
			addButton.showsTouchWhenHighlighted = true
			self.parentViewController?.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: addButton)
		}
		if !HR8000Service.shareInstance().isLogin {
			self.parentViewController?.title = "(未连接)"
		} else {
			self.parentViewController?.title = self.title
		}
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BaseManagerViewController.userDidLogined(_:)), name: kNotificationUserDidLogined, object: nil)
	}
	
	override func viewDidDisappear(animated: Bool) {
		self.slipMenu?.dismiss(nil)
		self.isMenuShow = false
		NSNotificationCenter.defaultCenter().removeObserver(self, name: kNotificationUserDidLogined, object: nil)
	}
	
	//登陆成功
	@objc private func userDidLogined(notification: NSNotification) {
		runOnMainQueue({
            
            
            
    
			if let acount = notification.object as? HRAcount {
				if acount.permission != 2 && acount.permission != 3 {
					self.parentViewController?.navigationItem.rightBarButtonItem = nil
				} else if self.parentViewController?.navigationItem.rightBarButtonItem == nil {
					//显示“+”按钮
					let addButton = UIButton(frame: CGRectMake(0, 0, 30, 30))
					addButton.setBackgroundImage(UIImage(named: "ico_add"), forState: .Normal)
					addButton.addTarget(self, action: #selector(BaseManagerViewController.onAddButtonClicked(_:)), forControlEvents: UIControlEvents.TouchUpInside)
					addButton.showsTouchWhenHighlighted = true
					self.parentViewController?.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: addButton)
				}
			}
			
			self.parentViewController?.title = self.title
		})
	}
	
	@objc private func socketDisconnected() {
		runOnMainQueue({
			self.parentViewController?.title = "(未连接)"
			self.parentViewController?.navigationItem.rightBarButtonItem = nil
		})
	}
	
	var slipMenu: SlipMenuAddDeviceView?
	
	func onAddButtonClicked(button: UIButton) {
		if self is SceneViewController {
			let controller = CreateSceneViewController()
			navigationController?.pushViewController(controller, animated: true)
		} else if self is TimerTaskViewController {
			let controller = CreateEditTaskViewController()
			self.navigationController?.pushViewController(controller, animated: true)
		} else if self is ScenePanelViewController {
			let controller = RegisterDeviceViewController()
			self.navigationController?.pushViewController(controller, animated: true)
		} else {
			let anim = CABasicAnimation(keyPath: "transform.rotation.z")
			anim.duration = 0.2
			anim.cumulative = true
			anim.removedOnCompletion = false
			anim.fillMode = kCAFillModeForwards
			anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
			if isMenuShow {
				anim.fromValue = CGFloat(-M_PI / 4)
				anim.toValue = CGFloat(0)	//回到0°
				self.slipMenu?.dismiss(nil)
			} else {
				anim.toValue = CGFloat(-M_PI / 4)	//旋转-45°
				slipMenu = SlipMenuAddDeviceView(frame: self.view.bounds)
				slipMenu!.delegate = self
				self.view.addSubview(slipMenu!)
				slipMenu!.show()
			}
			isMenuShow = !isMenuShow
			button.layer.addAnimation(anim, forKey: "rotate")
		}
	}
	
	func slipMenu(didSelectIndex index: Int) {
		if index == 0 {
			self.performSegueWithIdentifier("showRegisterDeviceViewController", sender: nil)
		} else {
			let sheet = UIActionSheet(title: "添加应用设备", delegate: self, cancelButtonTitle: nil, destructiveButtonTitle: nil, otherButtonTitles: "添加电视机", "添加空调")
			sheet.tag == 54321
			sheet.addButtonWithTitle("取消")
			sheet.cancelButtonIndex = sheet.numberOfButtons - 1
			if UIDevice.currentDevice().model == "iPad" {
				sheet.showInView(self.view)
			} else if let tabbar = self.tabBarController?.tabBar {
				sheet.showFromTabBar(tabbar)
			} else {
				sheet.showInView(self.view)
			}
		}
		
		runOnMainQueueDelay(500, block: {
			self.slipMenu(slipMenuWillDismiss:true)
			self.slipMenu?.dismiss(nil)
			self.isMenuShow = false
		})
	}
	
	func slipMenu(slipMenuWillDismiss Dismiss: Bool) {
		let anim = CABasicAnimation(keyPath: "transform.rotation.z")
		anim.duration = 0.2
		anim.cumulative = true
		anim.removedOnCompletion = false
		anim.fillMode = kCAFillModeForwards
		anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
		anim.fromValue = CGFloat(-M_PI / 4)
		anim.toValue = CGFloat(0)	//回到0°
		isMenuShow = false
		self.parentViewController?.navigationItem.rightBarButtonItem?.customView?.layer.addAnimation(anim, forKey: "rotate")
	}
	
	func actionSheet(actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) {
		guard let title = actionSheet.buttonTitleAtIndex(buttonIndex) else {
			return
		}
		switch title {
		case "添加空调":
			let vc = CreateEditAppDeviceViewController()
			vc.title = "添加空调"
			vc.isCreate = true
			let appDev = HRApplianceApplyDev()
			appDev.hostAddr = HRDatabase.shareInstance().server.hostAddr
			appDev.appDevType = HRAppDeviceType.AirCtrl.rawValue
			vc.appDevice = appDev
			navigationController?.pushViewController(vc, animated: true)
		case "添加电视机":
			let vc = CreateEditAppDeviceViewController()
			vc.title = "添加电视机"
			vc.isCreate = true
			let appDev = HRApplianceApplyDev()
			appDev.hostAddr = HRDatabase.shareInstance().server.hostAddr
			appDev.appDevType = HRAppDeviceType.TV.rawValue
			vc.appDevice = appDev
			navigationController?.pushViewController(vc, animated: true)
			
		default: break
		}
	}
}
