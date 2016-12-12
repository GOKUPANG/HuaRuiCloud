//
//  CreateEditTaskViewController.swift
//  huarui
//
//  Created by sswukang on 15/10/10.
//  Copyright © 2015年 huarui. All rights reserved.
//

import UIKit


///创建或编辑定时任务
class CreateEditTaskViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, TimePickerActionViewDelegate, PickDeviceViewControllerDelegate {
	
	private enum TaskTodo {
		case View
		case Edit
		case Create
	}
	
	
	
	var taskDevice: HRTask?
	var deviceTypes: [PickDeviceType] = [.Relay, .Motor, .Scene, .RGB]
	private var deviceDatas: [PickDeviceType: [HRDevsInTask]]!
	private var todo = TaskTodo.View
	private var newTask: HRTask!
	
	private var taskImage: UIButton!
	private var nameTextField: UITextField!
	private var topFrontView: UIView!
	private var tableView: UITableView!
	private var timePicker: UIDatePicker!
	private var repeatPickView: RepeationPickView!
	private var scrollTitles: ScrollTitleView!
	private var actionBarView: BottomActionBar?
	private var bottomContainerToolbar: UIToolbar?
	private let scrollTitleHeight: CGFloat = 46
	private let bottomActionBarHeight: CGFloat = 50
	private let tableViewRowHeight: CGFloat = 50
	private let tableViewSectionHeaderHeight: CGFloat = 50
	
	//MARK: - UIViewController 
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		initData()
		addViews()
		initViews()
	}
	
	override func viewDidDisappear(animated: Bool) {
		
		//释放cell
		for section in 0..<tableView.numberOfSections {
			for row in 0..<tableView.numberOfRowsInSection(section) {
				let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: row, inSection: section)) as? SceneBindCell
				cell?.free()
			}
		}
	}
	
	private func initData() {
		if taskDevice == nil && HRDatabase.isEditPermission {
			todo = .Create
			newTask = HRTask()
			newTask.hostAddr = HRDatabase.shareInstance().server.hostAddr
			newTask.enable = true
		} else if taskDevice != nil && HRDatabase.isEditPermission {
			todo = .Edit
			newTask = taskDevice!.copy() as! HRTask
		} else {
			todo = .View
			newTask = taskDevice!.copy() as! HRTask
		}
		deviceDatas = [PickDeviceType:[HRDevsInTask]]()
		for type in deviceTypes {
			deviceDatas[type] = [HRDevsInTask]()
		}
		for devsInTask in newTask.devsInTask {
			//数据库中查找设备
			guard let devInDatabase = HRDatabase.shareInstance().getDevice(devsInTask.devType, devAddr: devsInTask.devAddr) else {
				continue
			}
			switch devsInTask.devType {
			case HRDeviceType.relayTypes():
				if let relayComplexes = devInDatabase as? HRRelayComplexes{
					for relay in relayComplexes.relays {
						if Int(relay.relaySeq) < devsInTask.actBinds.count && devsInTask.actBinds[Int(relay.relaySeq)] < 0x03 {
							devsInTask.device = relay
							deviceDatas[.Relay]?.append(devsInTask)
						}
					}
				}
			default:
				devsInTask.device = devInDatabase
				for ptype in PickDeviceType.allTypes {
					if let hrtype = HRDeviceType(rawValue: devsInTask.devType) where ptype.hrDeviceTypes.contains(hrtype) {
						deviceDatas[ptype]?.append(devsInTask)
					}
				}
			}
		}
	}
	
	private func addViews() {
		self.edgesForExtendedLayout = UIRectEdge.None
		let navBarHeight = self.navigationController!.navigationBar.frame.height + UIApplication.sharedApplication().statusBarFrame.height
		self.view.frame = CGRectMake(0, 0, self.view.frame.width, self.view.frame.height - navBarHeight)
		tableView = UITableView(frame: self.view.bounds, style: UITableViewStyle.Grouped)
        tableView.sectionFooterHeight = 0
        tableView.backgroundColor     = UIColor.tableBackgroundColor()
        tableView.separatorColor      = UIColor.tableSeparatorColor()
        tableView.scrollsToTop        = true
		self.view.addSubview(tableView)
		
		topFrontView = UIView(frame: CGRectMake(0, 0, self.view.frame.width, 200))
		self.view.addSubview(topFrontView)
		self.view.bringSubviewToFront(topFrontView)
		
		topFrontView.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.98)
		tableView.delegate = self
		tableView.dataSource = self
		
		//image
		taskImage = UIButton(frame: CGRectMake(0, 0, view.bounds.width * 0.25, view.bounds.width * 0.25))
		taskImage.center = CGPointMake(view.bounds.width/2, taskImage.bounds.height*0.55)
		taskImage.imageView?.contentMode = .ScaleAspectFit
		topFrontView.addSubview(taskImage)
		
		//line1
		let line1 = UIView(frame: CGRectMake(self.view.frame.width*0.05, taskImage.frame.maxY + 5, self.view.frame.width*0.9, 0.5))
		line1.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
		topFrontView.addSubview(line1)
		
		//name textField
		nameTextField = UITextField(frame: CGRectMake(line1.frame.minX, line1.frame.maxY+2, line1.bounds.width, 45))
		nameTextField.textAlignment = .Center
		nameTextField.clearButtonMode = .WhileEditing
		nameTextField.placeholder = "请输入定时任务名称"
		nameTextField.returnKeyType = .Done
		nameTextField.addTarget(self, action: #selector(CreateEditTaskViewController.nameTextFieldEditEnd(_:)), forControlEvents: .EditingDidEndOnExit)
		topFrontView.addSubview(nameTextField)
		
		//line2
		let line2 = UIView(frame: CGRectMake(self.view.frame.width*0.05, nameTextField.frame.maxY + 2, self.view.frame.width*0.9, 0.5))
		line2.backgroundColor = line1.backgroundColor
		topFrontView.addSubview(line2)
		
		//time picker
		timePicker = UIDatePicker(frame: CGRectMake(line2.frame.minX+10, line2.frame.maxY+2, line2.bounds.width-20, 140))
		timePicker.datePickerMode = .Time
		timePicker.date = NSDate()
		topFrontView.addSubview(timePicker)
		
		//line3
		let line3 = UIView(frame: CGRectMake(self.view.frame.width*0.05, timePicker.frame.maxY + 2, self.view.frame.width*0.9, 0.5))
		line3.backgroundColor = line1.backgroundColor
		topFrontView.addSubview(line3)
		
		//repeation
		let size = NSString(string:"重复").sizeWithAttributes([NSFontAttributeName: nameTextField.font!])
		let repeatLabel = UILabel(frame: CGRectMake(line3.frame.minX + 5, line3.frame.maxY, size.width, 45))
		repeatLabel.text = "重复"
		topFrontView.addSubview(repeatLabel)
		
		//repeatPickView
		repeatPickView = RepeationPickView(frame: CGRectMake(topFrontView.bounds.width*0.3, 0, topFrontView.bounds.width*0.7-10, 30))
		repeatPickView.center.y = repeatLabel.center.y
		repeatPickView.repTexts = ["日","一","二","三","四","五","六"]
		//		repeatPickView.repTexts = ["Sun","Mon","Thu","Wen","Thr","Fri","Sat"]
		repeatPickView.selectedColor = APP.param.themeColor
		topFrontView.addSubview(repeatPickView)
		
		//line4
		let line4 = UIView(frame: CGRectMake(self.view.frame.width*0.05, repeatLabel.frame.maxY + 2, self.view.frame.width*0.9, 0.5))
		line4.backgroundColor = line1.backgroundColor
		topFrontView.addSubview(line4)
		
		//titles
		scrollTitles = ScrollTitleView(frame: CGRectMake(0, line4.frame.maxY, topFrontView.frame.width, scrollTitleHeight))
		scrollTitles.titles = deviceTypes.map{$0.description}
		scrollTitles.tintColor = APP.param.themeColor
		scrollTitles.setHandler(scrollTitleDidSelectedItem)
		topFrontView.addSubview(scrollTitles)
		
		topFrontView.frame = CGRectMake(topFrontView.frame.minX, topFrontView.frame.minY, topFrontView.bounds.width, scrollTitles.frame.maxY)
		tableView.contentInset = UIEdgeInsetsMake(topFrontView.bounds.height, 0, 60, 0)
		tableView.scrollsToTop = true
		tableView.scrollIndicatorInsets = tableView.contentInset
		
		//Add Device Buton
		if todo != .View {
			bottomContainerToolbar = UIToolbar(frame: CGRectMake(0, view.bounds.height - bottomActionBarHeight, view.bounds.width, bottomActionBarHeight))
			actionBarView = BottomActionBar(frame: bottomContainerToolbar!.bounds)
			actionBarView?.tintColor = APP.param.themeColor
			actionBarView?.addButton.addTarget(self, action: #selector(CreateEditTaskViewController.tapBottomAddButton), forControlEvents: .TouchUpInside)
			actionBarView?.editButton.addTarget(self, action: #selector(CreateEditTaskViewController.tapBottomEditButton), forControlEvents: .TouchUpInside)
			actionBarView?.doneButton.addTarget(self, action: #selector(CreateEditTaskViewController.tapBottomDoneButton), forControlEvents: .TouchUpInside)
			bottomContainerToolbar!.addSubview(actionBarView!)
			self.view.addSubview(bottomContainerToolbar!)
			self.tableView.contentInset.bottom   = bottomActionBarHeight
			self.tableView.scrollIndicatorInsets.bottom = bottomActionBarHeight
			
			if topFrontView.frame.maxY > view.frame.height * 0.7 {
				//topFrontView超过屏幕的70%，隐藏bottomContainerToolbar
				bottomContainerToolbar!.center.y = self.view.bounds.height + bottomContainerToolbar!.frame.height*0.6
			} else {
				tableView.scrollIndicatorInsets.bottom = actionBarView!.bounds.height
			}
		}
	}
	
	private func initViews() {
		
		if todo != .View {
			let barSaveButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Save, target: self, action: #selector(CreateEditTaskViewController.onBarSaveButtonClicked(_:)))
			barSaveButton.tintColor = UIColor.whiteColor()
			self.navigationItem.rightBarButtonItem = barSaveButton
			
			let barCancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: #selector(CreateEditTaskViewController.onBarCancelButtonClicked(_:)))
			barCancelButton.tintColor = UIColor.whiteColor()
			self.navigationItem.leftBarButtonItem = barCancelButton
		}
		
		switch todo {
		case .Create:
			self.title = "创建定时任务"
		case .Edit:
			self.title = "编辑" + taskDevice!.name
		case .View:
			self.title = taskDevice!.name
			actionBarView?.hidden = true
			nameTextField.enabled = false
			timePicker.enabled = false
			timePicker.userInteractionEnabled = false
			repeatPickView.enabled = false
		}
		guard let task = taskDevice else {
			taskImage.setImage(UIImage(named: HRTask().iconName), forState: .Normal)
			return
		}
		taskImage.setImage(UIImage(named: task.iconName), forState: .Normal)
		
		//名称
		self.nameTextField.text = task.name


		if let date = task.time.date() {
			self.timePicker.setDate(date, animated: false)
		}
		
		repeatPickView.repSelected = [
			task.repeation & (0x01 << 0) != 0x00,
			task.repeation & (0x01 << 1) != 0x00,
			task.repeation & (0x01 << 2) != 0x00,
			task.repeation & (0x01 << 3) != 0x00,
			task.repeation & (0x01 << 4) != 0x00,
			task.repeation & (0x01 << 5) != 0x00,
			task.repeation & (0x01 << 6) != 0x00,
		]
		
	}
	
	//MARK: - UITableViewDataSource
	
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return deviceTypes.count
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let type = deviceTypes[section]
		return deviceDatas[type]?.count ?? 0
	}
	
	func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return tableViewRowHeight
	}
	
	func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return tableViewSectionHeaderHeight
	}
	
	func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		let type = deviceTypes[section]
		let count = deviceDatas[type]?.count ?? 0
		return count == 0 ? "":"\(type.description): \(count)"
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		var cell:SceneBindCell!  = tableView.dequeueReusableCellWithIdentifier("section\(indexPath.section)_cell") as? SceneBindCell
		let devInScene = getDevsInTask(indexPath)!
		
		if cell == nil {
			cell = SceneBindCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "section\(indexPath.section)_cell", devInTask: devInScene)
		} else {
			cell.sceneBind = devInScene
		}
		cell.enabled = todo != .View
		return cell
	}
	
	func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
		return todo != .View ? .Delete:.None
	}
	
	func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
		let type = deviceTypes[indexPath.section]
		deviceDatas[type]?.removeAtIndex(indexPath.row)
		let cell = tableView.cellForRowAtIndexPath(indexPath) as? SceneBindCell
		cell?.free()
		tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Top)
		runOnMainQueueDelay(500, block: {
			self.tableView.reloadData()
		})
	}
	
	private func getDevsInTask(indexPath: NSIndexPath) -> HRDevsInTask? {
		let type = deviceTypes[indexPath.section]
		return deviceDatas[type]?[indexPath.row]
	}
	
	//MARK: - 保存与关闭
	
	@objc private func onBarCancelButtonClicked(sender: AnyObject) {
		self.navigationController?.popViewControllerAnimated(true)
	}
	
	//保存
	@objc private func onBarSaveButtonClicked(button: UIBarButtonItem) {
		guard let name = nameTextField.text
			where !name.isEmpty && name.isDeviceName else {
			UIAlertView(title: "提示", message: "定时任务名称为空或命名中含有非法字符。", delegate: nil, cancelButtonTitle: "确定").show()
			return
		}
		newTask.devsInTask = [HRDevsInTask]()
		for (_, devs) in self.deviceDatas {
			newTask.devsInTask += devs
		}
		if newTask.devsInTask.count == 0 {
			UIAlertView(title: "提示", message: "定时任务中至少绑定一个设备！", delegate: nil, cancelButtonTitle: "确定").show()
			return
		}
		
		newTask.name = name
		let formatter = NSDateFormatter()
		//转换成0时区，因为主机的时区为0时区
		formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
		formatter.dateFormat = "HH"
		newTask.time.hour = Byte(formatter.stringFromDate(timePicker.date))!
		formatter.dateFormat = "mm"
		newTask.time.min = Byte(formatter.stringFromDate(timePicker.date))!
//		formatter.dateFormat = "ss"
//		newTask.time.sec = Byte(formatter.stringFromDate(timePicker.date))!
//		Log.info("时间：\(newTask.time.hour):\(newTask.time.min):00")
		
		
		newTask.repeation = repeatPickView.repeateToByte
		
		KVNProgress.showWithStatus("正在保存...")
		HR8000Service.shareInstance().createOrModifyTask(newTask, isCreate: todo == .Create, result: { error in
			if let err = error {
				KVNProgress.showErrorWithStatus("\(err.domain)(\(err.code))")
			} else {
				KVNProgress.showSuccessWithStatus("保存成功！")
				runOnMainQueueDelay(1000, block: {
					self.navigationController?.popViewControllerAnimated(true)
				})
			}
		})
	}
	
	//MARK: - UI事件
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		if todo == .View {
			tableView.deselectRowAtIndexPath(indexPath, animated: true)
			return
		}
		let dev   = getDevsInTask(indexPath)!
		let title = dev.device!.name
		let delay = Float(dev.delayCode[0])/10
		TimePickerActionView(title: title, initSecond: delay, delegate: self).show()
	}
	
	func timePickerActionView(dismissWithoutTime picker: TimePickerActionView) {
		guard let indexPath = tableView.indexPathForSelectedRow else { return }
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
	}
	
	func timePickerActionView(picker: TimePickerActionView, dismissWithTimeInSecond second: Float) {
		guard let indexPath = tableView.indexPathForSelectedRow else { return }
		let devsInTask = getDevsInTask(indexPath)!
		if let relay = devsInTask.device as? HRRelayInBox
			where Int(relay.relaySeq) < devsInTask.delayCode.count {
				devsInTask.delayCode = [
					relay.relaySeq == 0 ? Byte(second * 10) : 0,
					relay.relaySeq == 1 ? Byte(second * 10) : 0,
					relay.relaySeq == 2 ? Byte(second * 10) : 0,
					relay.relaySeq == 3 ? Byte(second * 10) : 0,
				]
		} else {
			devsInTask.delayCode[0] = second <= 25.5 ? Byte(second * 10):0
		}
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
		tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
	}
	
	//MARK: --点击bottom action toolbar
	@objc private func tapBottomAddButton() {
		PickDeviceViewController.show(self, delegate: self)
	}
	
	@objc private func tapBottomEditButton() {
		self.tableView.setEditing(true, animated: true)
	}
	
	@objc private func tapBottomDoneButton() {
		self.tableView.setEditing(false, animated: true)
		//延迟500ms刷新tableView
		runOnMainQueueDelay(500, block: {
			self.tableView.reloadData()
		})
	}
	
	///每一个Section的frame的最大Y值
	private var sectionFrameMaxYs = [CGFloat]()
	
	func scrollViewWillBeginDragging(scrollView: UIScrollView) {
		sectionFrameMaxYs = [CGFloat]()
		sectionFrameMaxYs.append(0)
		for section in 0..<tableView.numberOfSections {
			let rows = tableView.numberOfRowsInSection(section)
			sectionFrameMaxYs.append(sectionFrameMaxYs[section] + tableViewRowHeight * CGFloat(rows) + tableViewSectionHeaderHeight)
		}
	}
	
	func scrollViewDidScroll(scrollView: UIScrollView) {
		let topFHeight = topFrontView.frame.height
		
		//移动topFrontView
		if (topFrontView.frame.maxY > scrollTitleHeight || scrollView.contentOffset.y < -scrollTitleHeight)
			&&
			(-scrollView.contentOffset.y - topFHeight > scrollTitleHeight - topFrontView.frame.height) {
				//移动topFrontView
				topFrontView.frame = CGRectMake(
					0,
					-scrollView.contentOffset.y - topFHeight,
					topFrontView.frame.width,
					topFrontView.frame.height
				)
				//改变滚动条
				tableView.scrollIndicatorInsets.top = topFrontView.frame.maxY
		} else if topFrontView.frame.maxY != scrollTitleHeight {
			topFrontView.frame = CGRectMake(
				0,
				scrollTitleHeight - topFrontView.frame.height,
				topFrontView.frame.width,
				topFrontView.frame.height
			)
		}
		
		//根据tableView的移动设置scrollTitles中游标的位置
		if sectionFrameMaxYs.count > 0 {
			for i in 1..<sectionFrameMaxYs.count {
				if tableView.contentOffset.y + scrollTitleHeight
					> sectionFrameMaxYs[i] {
						continue
				} else {
					if scrollTitles.currentPos != i-1 {
						scrollTitles.setSelectedItem(i-1, animated: true)
					}
					break
				}
			}
		}
		
		//显示Add Device Button
		if let bottomContainerToolbar = self.bottomContainerToolbar {
			let delta = view.bounds.height * 0.7 - topFrontView.frame.maxY
			if delta > 0 && bottomContainerToolbar.frame.minY >= view.bounds.height {
				//topFrontView位置往上低于70%, 且toobar已经隐藏, 则显示toolbar
				UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.95, initialSpringVelocity: 0, options: .CurveLinear, animations: {
						bottomContainerToolbar.center.y = self.view.bounds.height - bottomContainerToolbar.frame.height/2
					}, completion: nil)
			} else if  delta <= 0 && bottomContainerToolbar.frame.minY < view.bounds.height {
				//topFrontView位置往下超过70%, 且toobar已经显示, 则隐藏toolbar
				UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.95, initialSpringVelocity: 0, options: .CurveLinear, animations: {
					bottomContainerToolbar.center.y = self.view.bounds.height + bottomContainerToolbar.frame.height * 0.55
					}, completion: nil)
			}
		}
		
		
	}
	
	@objc private func nameTextFieldEditEnd(textField: UITextField ) {
		textField.resignFirstResponder()
	}
	
	//MARK: - 一些delegate
	
	lazy var scrollTitleDidSelectedItem: (Int, String)->Void = {
		[unowned self] (index, title) in
		var height: CGFloat = 0
		for section in 0..<index {
			let rows = self.tableView.numberOfRowsInSection(section)
			height += self.tableViewRowHeight * CGFloat(rows)
			height += self.tableViewSectionHeaderHeight
		}
		self.sectionFrameMaxYs.removeAll()
		self.tableView.setContentOffset(CGPointMake(0, -self.scrollTitleHeight + height), animated: true)
	}
	
	func pickDeviceVC(shouldShowDeviceTypes vc: PickDeviceViewController) -> [PickDeviceType] {
		return self.deviceTypes
	}
	
	func pickDeviceVC(vc: PickDeviceViewController, type: PickDeviceType, devices: [HRDevInScene]) {
		self.deviceDatas[type]? += devices
		self.tableView.reloadData()
	}
}

