//
//  SensorManagerViewController.swift
//  huarui
//
//  Created by sswukang on 15/5/18.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import UIKit

/// 传感器界面
class SensorManagerViewController: BaseManagerViewController, UICollectionViewDataSource, UICollectionViewDelegate, HR8000HelperDelegate, UIAlertViewDelegate {

    private var collection: UICollectionView!
    //没有情景的时候提示“无设备”的view
    private var noDevicesTipsView: UIView?
	private var _currentSlectedDevice: HRDevice?
    var sensors: [HRSensor]!
	
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
		
		let header = MJRefreshNormalHeader(refreshingTarget: self, refreshingAction: #selector(SensorManagerViewController.collectionViewWillRefresh))
		header.tintColor = UIColor.whiteColor()
		header.setTitle("下拉刷新", forState: MJRefreshStateIdle)
		header.setTitle("松开刷新数据", forState: MJRefreshStatePulling)
		header.setTitle("WillRefresh", forState: MJRefreshStateWillRefresh)
		header.setTitle("正在刷新数据...", forState: MJRefreshStateRefreshing)
		header.lastUpdatedTimeLabel?.hidden = true
		
		collection.header = header
    
    }
    
	override func viewWillAppear(animated: Bool) {
		self.title = "探测器"
		super.viewWillAppear(animated) 
    }
    
    override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		
        HRProcessCenter.shareInstance().delegates.hr8000HelperDelegate = self
        collection.reloadData()
	}
	
//MARK: - CollectionView
	
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
        let cellNib = UINib(nibName: "DeviceCollectionViewCell", bundle: nil)
        collectionView.registerNib(cellNib, forCellWithReuseIdentifier: "deviceCell")
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        sensors = HRDatabase.shareInstance().getAllSensors()
        if sensors.count == 0 {
            if self.noDevicesTipsView == nil {
				self.noDevicesTipsView = getTipView("无设备")
				self.noDevicesTipsView?.center = self.view.center
                self.view.addSubview(noDevicesTipsView!)
            }
        } else {
            self.noDevicesTipsView?.removeFromSuperview()
            self.noDevicesTipsView = nil
        }
        return sensors.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("deviceCell", forIndexPath: indexPath) as! DeviceCollectionViewCell
		
        let sensor = sensors[indexPath.row]
		cell.device = sensor
		
		if let gestures = cell.gestureRecognizers {
			for gesture in gestures {
				cell.removeGestureRecognizer(gesture)
			}
		}
        cell.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(SensorManagerViewController.onCellLongClicked(_:))))
        
        return cell
    }
	
//MARK: - UI事件
	
	///下拉刷新
	func collectionViewWillRefresh() {
		HR8000Service.shareInstance().queryDevice(HRDeviceType.GasSensor)
		HR8000Service.shareInstance().queryDevice(HRDeviceType.SolarSensor)
		HR8000Service.shareInstance().queryDevice(HRDeviceType.HumiditySensor)
		HR8000Service.shareInstance().queryDevice(HRDeviceType.AirQualitySensor)
		///3秒之后停止refreshing
		runOnMainQueueDelay(3000, block: {
			self.collection.header.endRefreshing()
		})
	}
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! DeviceCollectionViewCell
        if let device = cell.device {
			runOnGlobalQueue({
				DeviceUseFrequency.addDevice(HRDatabase.shareInstance().acount.userName, device: device)
			})
            switch device.devType {
            case HRDeviceType.Manipulator.rawValue:
                performSegueWithIdentifier("showManipulatorViewController", sender: device)
            case HRDeviceType.SolarSensor.rawValue:
                performSegueWithIdentifier("showSolarSensorViewController", sender: device)
            case HRDeviceType.GasSensor.rawValue:
                performSegueWithIdentifier("showGasSensorViewController", sender: device)
            case HRDeviceType.AirQualitySensor.rawValue:
                performSegueWithIdentifier("showAirQualitySensorViewController", sender: device)
            default:
				KVNProgress.showErrorWithStatus("暂时不支持该设备(\(device.devType))")
                break
            }
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
	
	//请求删除的AlertView的tag
	private let tagAlertViewDelete = 100
	
	override func actionSheet(actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) {
		super.actionSheet(actionSheet, didDismissWithButtonIndex: buttonIndex)
		if self._currentSlectedDevice == nil { return }
		if actionSheet.buttonTitleAtIndex(buttonIndex) == "删除" {
			let delAlert = UIAlertView(title: "提示", message: "您确定要删除“\(self._currentSlectedDevice!.name)”吗？", delegate: self, cancelButtonTitle: "取消", otherButtonTitles: "确定")
			delAlert.tag = tagAlertViewDelete
			delAlert.show()
		}
	}
	
	func alertView(alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
		if self._currentSlectedDevice == nil || buttonIndex == alertView.cancelButtonIndex {
			return
		}
		switch alertView.tag {
		case tagAlertViewDelete:
			KVNProgress.showWithStatus("正在删除...")
			self._currentSlectedDevice?.deleteFromRemote({ (error) in
				if let err = error {
					KVNProgress.showErrorWithStatus(err.domain)
				} else {
					KVNProgress.showSuccessWithStatus("删除成功!")
				}
			})
			break
		default: break
		}
	}
// MARK: - HR8000HelperDelegate
	
    ///查询设备
    func hr8000Helper(queryDeviceInfo device: HRDevice, indexOfDatabase index: Int, devices: [HRDevice]) {
        switch device.devType {
        case HRDeviceType.sensorTypes():
            if !HRDatabase.shareInstance().getAllSensors().elementsEqual(self.sensors) {
                collection.reloadData()
            }
            
        default: break
        }
    }
	
	func hr8000Helper(finishedQueryDeviceInfo finish: Bool) {
		self.collection.header.endRefreshing()
		collection.reloadData()
	}
	
	func hr8000Helper(didDeleteDevice device: HRDevice) {
		switch device.devType {
		case HRDeviceType.sensorTypes():

			for i in 0..<self.sensors.count {
				if device.devAddr == self.sensors[i].devAddr {
					self.collection.deleteItemsAtIndexPaths([NSIndexPath(forRow: i, inSection: 0)])
					break
				}
			}
		default: break
		}
	}
	
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showManipulatorViewController"{
            let controller = segue.destinationViewController as! ManipulatorViewController
            controller.manipDev = sender as! HRManipulator
        }
        else if segue.identifier == "showSolarSensorViewController"{
            let controller = segue.destinationViewController as! SolarSensorViewController
            controller.solarDev = sender as! HRSolarSensor
        }
        else if segue.identifier == "showGasSensorViewController" {
            let controller = segue.destinationViewController as! GasSensorViewController
            controller.gasDev = sender as! HRGasSensor
        }
        else if segue.identifier == "showAirQualitySensorViewController" {
            let controller = segue.destinationViewController as! AirQualitySensorViewController
            controller.aqsDev = sender as! HRAirQualitySensor
        }
    }

}
