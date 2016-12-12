//
//  UsualViewController.swift
//  huarui
//
//  Created by sswukang on 15/1/21.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import UIKit
/**
 *  常用设备
 */
class UsualViewController: BaseManagerViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIGestureRecognizerDelegate, HRRelayBaseDeviceDelegate , HR8000HelperDelegate, UIAlertViewDelegate {

    private var collection: UICollectionView!
    //没有情景的时候提示“无设备”的view
    private var noDevicesTipsView: UIView?
    private var devices: [HRDevice]!
	private var _currentSlectedDevice: HRDevice?
	private var isMenuShow = false
	
//MARK: - ViewController
	
    override func viewDidLoad() {
        super.viewDidLoad()
        let navBarHeight = navigationController!.navigationBar.frame.height + UIApplication.sharedApplication().statusBarFrame.height
        let tabHeight = tabBarController!.tabBar.frame.height + navBarHeight
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsetsMake(5, 10, tabHeight + 10, 10)
        layout.itemSize = CGSizeMake(95, 115)
        layout.minimumLineSpacing = 5
        layout.minimumInteritemSpacing = 5
        
        collection = UICollectionView(frame: view.frame, collectionViewLayout: layout)
        self.view.addSubview(collection)
        let cellNib = UINib(nibName: "DeviceCollectionViewCell", bundle: nil)
        collection.registerNib(cellNib, forCellWithReuseIdentifier: "deviceCell")
        collection.backgroundColor = UIColor.clearColor()
		collection.scrollIndicatorInsets = UIEdgeInsetsMake(2, 0, tabHeight, 1)
		collection.dataSource = self
		collection.delegate   = self
		HRProcessCenter.shareInstance().delegates.relayBaseDeviceDelegate = self
		HRProcessCenter.shareInstance().delegates.hr8000HelperDelegate    = self

		
		let header = MJRefreshNormalHeader(refreshingTarget: self, refreshingAction: #selector(UsualViewController.collectionViewWillRefresh))
		header.tintColor = UIColor.whiteColor()
		header.setTitle("下拉刷新", forState: MJRefreshStateIdle)
		header.setTitle("松开刷新数据", forState: MJRefreshStatePulling)
		header.setTitle("WillRefresh", forState: MJRefreshStateWillRefresh)
		header.setTitle("正在刷新数据...", forState: MJRefreshStateRefreshing)
		header.lastUpdatedTimeLabel?.hidden = true
		collection.header = header
	}
	
	override func viewWillAppear(animated: Bool) {
		self.title = "常用设备"
        super.viewWillAppear(animated) 
    }
	
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
	}
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		
		if (HRProcessCenter.shareInstance().delegates.relayBaseDeviceDelegate
			as? AnyObject ) !== self
			|| (HRProcessCenter.shareInstance().delegates.hr8000HelperDelegate
			as? AnyObject) !== self {
			HRProcessCenter.shareInstance().delegates.relayBaseDeviceDelegate = self
			HRProcessCenter.shareInstance().delegates.hr8000HelperDelegate    = self
			collection.reloadData()
		}
	}
	
//MARK: - UI布局
	
    private func getTipView(text: String) -> UIView{
		let label = UILabel()
		let str = NSString(string: text)
		let attr = [NSFontAttributeName: UIFont.systemFontOfSize(30)]
		let size = str.sizeWithAttributes(attr)
		
		label.frame = CGRectMake(0, 0, size.width, size.height )
		label.text = text
		label.textColor = UIColor.lightGrayColor()
		label.font = UIFont.systemFontOfSize(30)
		label.textAlignment = NSTextAlignment.Center
		
		return label
    }
	
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//		Log.info("numberOfItemsInSection")
		self.devices = HRDatabase.shareInstance().getAllCtrlDevices()
		self.devices = DeviceUseFrequency.getLocalDevicesBySort(
			HRDatabase.shareInstance().acount.userName,
			devices: self.devices
		)
        if devices.count == 0 {
            if self.noDevicesTipsView == nil {
                self.noDevicesTipsView = getTipView("无记录")
				self.noDevicesTipsView?.center = self.view.center
                self.view.addSubview(noDevicesTipsView!)
            }
        } else {
            self.noDevicesTipsView?.removeFromSuperview()
            self.noDevicesTipsView = nil
        }
        return devices.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("deviceCell", forIndexPath: indexPath) as! DeviceCollectionViewCell
        
        let device = devices[indexPath.row]
        cell.device = device 
		
		if let gestures = cell.gestureRecognizers {
			for gesture in gestures {
				cell.removeGestureRecognizer(gesture)
			}
		}
        //增加单击手势
        cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(UsualViewController.onCellTapClicked(_:))))
        //增加长按手势
        cell.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(UsualViewController.onCellLongClicked(_:))))
		
        return cell
    }

//MARK: - UI事件
	
//	func onAddButtonClicked(button: UIButton) {
//		let anim = CABasicAnimation(keyPath: "transform.rotation.z")
//		anim.duration = 0.2
//		anim.cumulative = true
//		anim.removedOnCompletion = false
//		anim.fillMode = kCAFillModeForwards
//		anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
//		if isMenuShow {
//			anim.fromValue = CGFloat(-M_PI / 4)
//			anim.toValue = CGFloat(0)	//回到0°
//			SlipMenuAddDeviceView.dismiss()
//		} else {
//			anim.toValue = CGFloat(-M_PI / 4)	//旋转-45°
//			SlipMenuAddDeviceView.showInView(self.view.bounds, view: self.view)
//			SlipMenuAddDeviceView.delegate = self
//		}
//		isMenuShow = !isMenuShow
//		button.layer.addAnimation(anim, forKey: "rotate")
//	}
//	
//	func slipMenu(didSelectIndex index: Int) {
//		if index == 0 {
//			self.performSegueWithIdentifier("showRegisterDeviceViewController", sender: nil)
//		} else {
//			self.performSegueWithIdentifier("showRegisterDeviceViewController", sender: nil)
//		}
//		
//		runOnMainQueueDelay(500, {
//			SlipMenuAddDeviceView.dismiss()
//			self.slipMenu(slipMenuWillDismiss:true)
//		})
//	}
//	
//	func slipMenu(slipMenuWillDismiss Dismiss: Bool) {
//		let anim = CABasicAnimation(keyPath: "transform.rotation.z")
//		anim.duration = 0.2
//		anim.cumulative = true
//		anim.removedOnCompletion = false
//		anim.fillMode = kCAFillModeForwards
//		anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
//		anim.fromValue = CGFloat(-M_PI / 4)
//		anim.toValue = CGFloat(0)	//回到0°
//		isMenuShow = !isMenuShow
//		self.parentViewController?.navigationItem.rightBarButtonItem?.customView?.layer.addAnimation(anim, forKey: "rotate")
//	}
	
    func onCellTapClicked(gesture: UITapGestureRecognizer){
        if gesture.view == nil || !(gesture.view is DeviceCollectionViewCell){
            return
        }
        let device = (gesture.view as! DeviceCollectionViewCell).device
        if device == nil{
            return
        }
		runOnGlobalQueue({
			DeviceUseFrequency.addDevice(HRDatabase.shareInstance().acount.userName, device: device)
		})
        switch device!.devType {
        case HRDeviceType.RelayControlBox.rawValue,
                HRDeviceType.SwitchPanel.rawValue,
                HRDeviceType.SocketPanel.rawValue,
				HRDeviceType.LiveWireSwitch.rawValue: //点击的是继电器设备
            KVNProgress.showWithStatus("通信中...")
            (device! as! HRRelayInBox).operate(.Reverse,
                result: { (error) in
                    if let err = error {
                        KVNProgress.showErrorWithStatus("失败：\(err.domain)")
                    } else {
                        KVNProgress.dismiss()
                    }
            })
        case HRDeviceType.CurtainControlUnit.rawValue: //点击的是窗帘控制器
            self.performSegueWithIdentifier("showCurtainCtrl", sender: device)
		case HRDeviceType.RGBLamp.rawValue:
			self.performSegueWithIdentifier("showRGBCtrlViewController", sender: device)
        case HRDeviceType.ApplyDevice.rawValue: //应用设备
            let apply = device as! HRApplianceApplyDev
            switch apply.appDevType {
            case HRAppDeviceType.AirCtrl.rawValue: //空调
				let controller = AirCtrlViewController()
				controller.appDevice = apply
				self.navigationController?.pushViewController(controller, animated: true)
            case HRAppDeviceType.TV.rawValue:       //电视机
				let controller = TVCtrlViewController()
				controller.appDevice = apply
				self.navigationController?.pushViewController(controller, animated: true)
            default:
                break
            }
        case HRDeviceType.SmartBed.rawValue: //点击的是床
			self.performSegueWithIdentifier("showSmartBedViewController", sender: device)
		case HRDeviceType.Manipulator.rawValue:	//机械手
			performSegueWithIdentifier("showManipulatorViewController", sender: device)
		case HRDeviceType.SolarSensor.rawValue:	//光照传感器
			performSegueWithIdentifier("showSolarSensorViewController", sender: device)
		case HRDeviceType.GasSensor.rawValue:	//可燃气体传感器
			performSegueWithIdentifier("showGasSensorViewController", sender: device)
		case HRDeviceType.AirQualitySensor.rawValue:	//空气质量传感器
			performSegueWithIdentifier("showAirQualitySensorViewController", sender: device)
		case HRDeviceType.DoorLock.rawValue:
			self.performSegueWithIdentifier("showDoorLockViewController", sender: device!)
        default:
			KVNProgress.showErrorWithStatus("暂时不支持该设备(\(device.devType))")
            break
        }
    }
    
    func onCellLongClicked(gestrue: UILongPressGestureRecognizer){
        if gestrue.view == nil || !(gestrue.view is DeviceCollectionViewCell) {
            return
        }
        let cell = gestrue.view! as! DeviceCollectionViewCell
        switch gestrue.state {
		case .Began:
			cell.selected = true
			if self.tabBarController?.tabBar == nil || currentDeviceModel == .iPad {
				cell.longClickedHandler(showInView: self.view, navigationController: self.navigationController)
			} else {
				cell.longClickedHandler(showInView: self.tabBarController!.tabBar, navigationController: self.navigationController)
			}
		case .Ended:
			cell.selected = false
        default:
            break
        }
    }
	
	///下拉刷新
	func collectionViewWillRefresh() {
		HR8000Service.shareInstance().queryAllDevice()
		///3秒之后停止refreshing
		runOnMainQueueDelay(3000, block: {
			self.collection.header.endRefreshing()
		})
	}
	
// MARK: - HRRelayBaseDeviceDelegate代理
	
	func relayBaseDevice(relayBaseDevice: HRRelayComplexes) {
		let cells = collection.visibleCells() as! [DeviceCollectionViewCell]
		for cell in cells{
			if let relayInCell = cell.device as? HRRelayInBox where relayInCell.devType == relayBaseDevice.devType {
				for relay in relayBaseDevice.relays {
					if relay.devAddr == relayInCell.devAddr
						&& relay.relaySeq == relayInCell.relaySeq {
							cell.updateSatus(true)
					}
				}
				
			}
		}
	}

//MARK: - HR8000HelperDelegate代理

	func hr8000Helper(commitDeviceState device: HRDevice) {
		if let relayComplexes = device as? HRRelayComplexes {
			self.relayBaseDevice(relayComplexes)
		}
	}
	
	//查询设备完成
    func hr8000Helper(finishedQueryDeviceInfo finish: Bool) {
		collection.reloadData()
		self.collection.header.endRefreshing()
    }
	
	//删除设备
	func hr8000Helper(didDeleteDevice device: HRDevice) {
		
		var indexs = [Int]()
		for i in 0..<self.devices.count {
			if device.devType == HRDeviceType.ApplyDevice.rawValue {
				if let curAppDev = self.devices[i] as? HRApplianceApplyDev {
					if curAppDev.appDevType == (device as! HRApplianceApplyDev).appDevType
					&& curAppDev.appDevID == (device as! HRApplianceApplyDev).appDevID {
						indexs.append(i)
						break
					}
				}
			} else if device.devAddr == self.devices[i].devAddr{
				indexs.append(i)
			}
		}
		if indexs.count == 0 { return }
		var indexPaths = [NSIndexPath]()
		for index in indexs {
			indexPaths.append(NSIndexPath(forRow: index, inSection: 0))
		}
		self.collection.deleteItemsAtIndexPaths(indexPaths)
	}
    
    
//MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		switch segue.identifier! {
		case "showCurtainCtrl":
			let curtainCtrller = segue.destinationViewController as! CurtainCtrlViewController
			curtainCtrller.curtainDev = sender as? HRCurtainCtrlDev
		case "showAirCtrl":
			let airCtrller = segue.destinationViewController as! AirCtrlViewController
			airCtrller.appDevice = sender as? HRApplianceApplyDev
		case "showTVCtrl":
			let tvCtrller = segue.destinationViewController as! TVCtrlViewController
			tvCtrller.appDevice = sender as? HRApplianceApplyDev
		case "showManipulatorViewController":
			let controller = segue.destinationViewController as! ManipulatorViewController
			controller.manipDev = sender as! HRManipulator
		case "showSolarSensorViewController":
			let controller = segue.destinationViewController as! SolarSensorViewController
			controller.solarDev = sender as! HRSolarSensor
		case "showGasSensorViewController":
			let controller = segue.destinationViewController as! GasSensorViewController
			controller.gasDev = sender as! HRGasSensor
		case "showAirQualitySensorViewController":
			let controller = segue.destinationViewController as! AirQualitySensorViewController
			controller.aqsDev = sender as! HRAirQualitySensor
		case "showDoorLockViewController":
			let controller = segue.destinationViewController as! DoorLockViewController
			controller.device = sender as! HRDevice
		case "showEditRelayBoxViewController":
			let controller = segue.destinationViewController as!
				EditRelayBoxViewController
			let relay = sender as! HRRelayInBox
			controller.relayBox = relay.relayBox
			controller.routerEnable = [
				relay.relaySeq == 0,
				relay.relaySeq == 1,
				relay.relaySeq == 2,
				relay.relaySeq == 3,
			]
		case "showRGBCtrlViewController":
			let controller = segue.destinationViewController as! RGBCtrlViewController
			controller.rgbDevice = sender as! HRRGBLamp  
//		case "showSmartBedViewController":
//			let controller = segue.destinationViewController as! SmartBedViewController
//            controller.bedDev = sender as! HRSmartBed
		default: break
		}
    }

}
