//
//  DevicePickerViewController.swift
//  huarui
//
//  Created by sswukang on 16/2/24.
//  Copyright © 2016年 huarui. All rights reserved.
//

import UIKit

/// 弹出选择设备界面
class PickDeviceViewController: UIViewController, DevicePickerViewDelegate, UIViewControllerTransitioningDelegate, UITableViewDataSource, UITableViewDelegate {

	var pickTypes: [PickDeviceType] = [.Relay, .Motor, .Scene, .Apply, .RGB]
	weak var delegate: PickDeviceViewControllerDelegate?
	
	private var pickerView: DevicePickerView!
	private var tableViews: [UITableView]!
	private var deviceData = [PickDeviceType: [PickDeviceModel]]()
	private var pickerViewDidShowed = false
	
	override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
		return UIInterfaceOrientationMask.Portrait
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		tableViews = [UITableView]()
		initData()
		pickerView = NSBundle.mainBundle().loadNibNamed("DevicePickerView", owner: nil, options: nil)![0] as! DevicePickerView
		pickerView.frame = CGRectMake(0, self.view.bounds.height, self.view.bounds.width, self.view.bounds.height*0.7)
		pickerView.delegate = self
		self.view.addSubview(pickerView) 
    }
	
	override func viewDidAppear(animated: Bool) {
		if !pickerViewDidShowed {
			UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.95, initialSpringVelocity: 0, options: .CurveLinear, animations: {
				self.pickerView.frame = CGRectOffset(self.pickerView.frame, 0, -self.pickerView.bounds.height)
				self.view.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.3)
				}, completion: { (completed) in
					self.pickerViewDidShowed = true
				})
		}
	}
	
	private func initData() {
		pickTypes = delegate?.pickDeviceVC(shouldShowDeviceTypes: self) ?? pickTypes
		for type in pickTypes {
			switch type {
			case .Relay:
				var models = [PickDeviceModel]()
				for relay in HRDatabase.shareInstance().getAllRelays() {
					models.append(PickDeviceModel(type: type, device: relay))
				}
				deviceData[type] = models
			case .Motor:
				var models = [PickDeviceModel]()
				for motor in HRDatabase.shareInstance().getAllMotorDev() {
					models.append(PickDeviceModel(type: type, device: motor))
				}
				deviceData[type] = models
			case .Apply:
				var models = [PickDeviceModel]()
				for appDevice in HRDatabase.shareInstance().getDevicesOfTypes([.ApplyDevice]) {
					models.append(PickDeviceModel(type: type, device: appDevice))
				}
				deviceData[type] = models
			case .Scene:
				var models = [PickDeviceModel]()
				for scene in HRDatabase.shareInstance().getDevicesOfTypes([.Scene]) {
					models.append(PickDeviceModel(type: type, device: scene))
				}
				deviceData[type] = models
			case .RGB:
				var models = [PickDeviceModel]()
				for rgb in HRDatabase.shareInstance().getDevicesOfTypes([.RGBLamp]) {
					models.append(PickDeviceModel(type: type, device: rgb))
				}
				deviceData[type] = models
			}
		}
	}
	
	func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return ShowDevicePickerTransitioning()
	}
	
	func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return DismissDevicePickerTransitioning()
	}
	
	private func dismissPickerView() {
		UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.95, initialSpringVelocity: 0, options: .CurveLinear, animations: {
			self.pickerView.frame = CGRectOffset(self.pickerView.frame, 0, self.pickerView.frame.height)
			self.view.backgroundColor = UIColor.clearColor()
			}) { (finished) -> Void in
				self.pickerViewDidShowed = false
				self.dismissViewControllerAnimated(true, completion: nil)
		}
	}
	
	func deviceTitles(pickerView: DevicePickerView) -> [String] {
		return pickTypes.map { (type) -> String in
			type.description
		}
	}
	
	func devicePickerView(pickerView: DevicePickerView, viewForTitle title: String, index: Int, size: CGSize) -> UIView {
		let tableView = UITableView(frame: CGRectMake(0, 0, size.width, size.height))
		tableView.delegate   = self
		tableView.dataSource = self
		tableView.tag        = index + 100
		self.tableViews.append(tableView)
		tableView.tableFooterView = UIView()
		return tableView
	}
	
	//MARK: - tableView delegate
	
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let type = pickTypes[tableView.tag - 100]
		if let devs = deviceData[type] {
			return devs.count
		}
		return 0
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		var cell: PickDeviceViewCell! = tableView.dequeueReusableCellWithIdentifier("cell") as? PickDeviceViewCell
		
		if cell == nil {
			cell = PickDeviceViewCell(style: .Subtitle, reuseIdentifier: "cell")
		}
		let type = pickTypes[tableView.tag - 100]
		//设置cell
		cell.setModel(deviceData[type]![indexPath.row])
		return cell
	}
	
	//MARK: - 点击事件
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
		
		let type = pickTypes[tableView.tag - 100]
		let model = deviceData[type]![indexPath.row]
		switch type {
		case .Relay, .Motor, .Scene:
			model.selected = !model.selected
			tableView.reloadData()
		case .Apply:
			if model.selected {
				model.actBinds = [0xFF, 0xFF, 0xFF, 0xFF]
				model.selected = false
				tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
				break
			}
			if let appDevice = model.device as? HRApplianceApplyDev {
				switch appDevice.appDevType {
				case HRAppDeviceType.AirCtrl.rawValue:
					let airCtrlVC = AirCtrlViewController()
                    airCtrlVC.appDevice = appDevice
                    airCtrlVC.todo      = SHARETODO_RECORD_AIR_CTRL
					airCtrlVC.actionHandler = { (code, appDevice) in
						model.actBinds[0] = code
						model.selected = true
						tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
					}
					presentToViewController(airCtrlVC)
				case HRAppDeviceType.TV.rawValue:
					let tvCtrlVC = TVCtrlViewController()
                    tvCtrlVC.appDevice = appDevice
                    tvCtrlVC.todo      = SHARETODO_RECORD_TV_CTRL
					tvCtrlVC.actionHandler = { (code, appDevice) in
						model.actBinds[0] = code
						model.selected = true
						tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
					}
					presentToViewController(tvCtrlVC)
				default:
					break
				}
			}
		case .RGB:
			if model.selected {
				model.actBinds = [0xFF, 0xFF, 0xFF, 0xFF]
				model.selected = false
				tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
				break
			}
			if let rgbDevice = model.device as? HRRGBLamp {
				let rgbCtrlVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("RGBCtrlViewController") as! RGBCtrlViewController
				rgbCtrlVC.rgbDevice = rgbDevice
				rgbCtrlVC.todo = SHARETODO_RECORD_RGB_COLOR
				rgbCtrlVC.actionHandler = { (mode, r, g, b) in
					model.actBinds[0] = mode
					model.actBinds[1] = r
					model.actBinds[2] = g
					model.actBinds[3] = b
					model.selected = true
					tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
				}
				presentToViewController(rgbCtrlVC)
			}
			break
		}
		
	}
	
	func devicePickerView(pickerView: DevicePickerView, tapSelectAllButton button: UIButton) {
		let type = pickTypes[pickerView.currentIndex]
		deviceData[type] = deviceData[type]?.map({ (model) -> PickDeviceModel in
			model.selected = true
			return model
		})
		tableViews[pickerView.currentIndex].reloadData()
	}
	
	func devicePickerView(tapDoneButton pickerView: DevicePickerView) {
		if let delegate = self.delegate {
			for (type, models) in deviceData {
				let result = models.reduce([HRDevInScene](), combine: { (devInScenes, model) -> [HRDevInScene] in
					var _devInScenes = devInScenes
					if model.selected {
						_devInScenes.append(model.devInScene)
					}
					return _devInScenes
				})
				if result.count > 0 {
					delegate.pickDeviceVC(self, type: type, devices: result)
				}
			}
		}
		delegate = nil
		dismissPickerView()
	}
	
	func devicePickerView(tapCancelButton pickerView: DevicePickerView) {
		delegate = nil
		dismissPickerView()
	}
	
	private func presentToViewController(vc: UIViewController) {
		let navVC = RootNavgationViewController(rootViewController: vc)
		navVC.navigationBar.translucent = false
		navVC.navigationBar.barTintColor = APP.param.themeColor
		presentViewController(navVC, animated: true, completion: nil)
	}
	
	class func show(fromVC: UIViewController, delegate: PickDeviceViewControllerDelegate?) {
		let toVC = PickDeviceViewController()
        toVC.delegate                     = delegate
        toVC.view.backgroundColor         = UIColor.clearColor()
        fromVC.definesPresentationContext = true
		if #available(iOS 8.0, *) {
			toVC.modalPresentationStyle = .OverFullScreen
		} else {
			toVC.modalPresentationStyle = .FullScreen
		}
		toVC.transitioningDelegate = toVC
		fromVC.presentViewController(toVC, animated: true, completion: nil)
		return
	}

}

protocol PickDeviceViewControllerDelegate: class {
	func pickDeviceVC(shouldShowDeviceTypes vc: PickDeviceViewController) -> [PickDeviceType]
	func pickDeviceVC(vc: PickDeviceViewController, type: PickDeviceType, devices: [HRDevInScene])
}
