//
//  RegisterDeviceViewController.swift
//  SmartBed
//
//  Created by sswukang on 15/7/7.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import UIKit

/// 注册设备
class RegisterDeviceViewController: UIViewController, RegisterButtonDelegate, HRRegisterDevicesDelegate, UIAlertViewDelegate {
	private enum RegisterStatus {
		///准备
		case Ready
		///正在搜索。搜索可注册的设备
		case Searching
		///正在编辑。接收到了设备确认，需要编辑属性才能完成
		case Editing
		///提交了设备。编辑完成后用户点击保存，App会发送允许注册的帧给主机，但还没收到主机的回复，所以处于Commited提交状态。
		case Commited
	}
	
	var floorName: String?
	var roomName:  String?
	
	///当前注册处于的状态
	private var registerStatus: RegisterStatus = .Ready
	
	private var regButton: RegisterButton!
	private var maskBackView: UIScrollView!
	private var container: RegisterDeviceInfoView!
	private var saveButton: PrettyButton!
	private var cancelButton: PrettyButton!
	private var containerOriginCenterY: CGFloat!
	private var saveButtonOriginCenterY: CGFloat!
	private var cancelButtonOriginCenterY: CGFloat!
//	private var _edgesForExtendedLayout: UIRectEdge!
	
//MARK: - ViewController
	
    override func viewDidLoad() {
        super.viewDidLoad()
		self.navigationController?.interactivePopGestureRecognizer?.enabled = false
		self.title = NSLocalizedString("hr_register_devices")
		self.title = NSLocalizedString("hr_register_devices", comment: "register_devices_comment")
        view.layer.contents = UIImage(named: APP.param.backgroundImgName)?.CGImage
		
		let backButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: #selector(RegisterDeviceViewController.onBackButtonClicked(_:)))
		self.navigationItem.leftBarButtonItem = backButton
        
        initComponent()
        
    }
	
    override func viewWillAppear(animated: Bool) {
//		_edgesForExtendedLayout = self.edgesForExtendedLayout
		self.edgesForExtendedLayout = UIRectEdge.All
		
        //注册键盘弹出的广播
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(RegisterDeviceViewController.onKeyBoardShown(_:)), name: UIKeyboardDidShowNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
//		self.edgesForExtendedLayout = _edgesForExtendedLayout
//		HRProcessCenter.shareInstance().delegates.registerDevicesDelegate = nil
        regButton.delegate = nil
		regButton.stopRegistering()
        //注销键盘弹出的广播
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardDidShowNotification, object: nil)
    }
	
	
//MARK: - 布局
	
	func initComponent(){
		let viewTopY = self.navigationController!.navigationBar.frame.height + UIApplication.sharedApplication().statusBarFrame.height
		/// view的可见高度
		let visableViewHeight = self.view.frame.height - viewTopY
//		let visableViewHeight = view.frame.height - view.
		let isShortScreen: Bool
		if UIScreen.mainScreen().bounds.height <= 480 {
			isShortScreen = true
		} else {
			isShortScreen = false
		}
		
		//开始布局
		regButton = RegisterButton(frame: CGRectMake(0, 0, self.view.frame.width/2, self.view.frame.width/2))
		regButton.center = CGPointMake(view.frame.width/2, view.frame.height/2)
		regButton.titleLabel?.font = UIFont.systemFontOfSize(30)
		regButton.setTitle("注册", forState: UIControlState.Normal)
		regButton.addTarget(self, action: #selector(RegisterDeviceViewController.registerButtonClicked(_:)), forControlEvents: UIControlEvents.TouchUpInside)
		regButton.delegate = self
		view.addSubview(regButton)
		
		maskBackView = UIScrollView(frame: CGRectMake(0, 0, view.frame.width, visableViewHeight))
		maskBackView.scrollEnabled = false
		maskBackView.showsVerticalScrollIndicator = false
		maskBackView.showsHorizontalScrollIndicator = false
		maskBackView.contentSize = CGSizeMake(maskBackView.frame.width, maskBackView.frame.height+200)
		
		if isShortScreen {
			container = RegisterDeviceInfoView(frame: CGRectMake(0, 15, 270, 280))
		} else if maskBackView.frame.width * 0.85 > 360 {
			container = RegisterDeviceInfoView(frame: CGRectMake(0, 40, 360, 405))
		} else {
			container = RegisterDeviceInfoView(frame: CGRectMake(0, 40, 270, 300))
		}
		
		container.center.x = view.frame.width/2
		container.backgroundColor = UIColor.whiteColor()
		container.layer.cornerRadius = 15
		container.image = UIImage(named: "设备图标-未知设备")
		container.currentFloorName = floorName
		container.currentRoomName  = roomName
		container.nameTextField.addTarget(self, action: #selector(RegisterDeviceViewController.onNameTextFieldEditEnd(_:)), forControlEvents: [.EditingDidEnd, .EditingDidEndOnExit])
		//		container.nameTextField.delegate = self
		maskBackView.addSubview(container)
		
		
		saveButton = PrettyButton(frame: CGRectMake(view.frame.width*0.1, container.frame.maxY + 15, container.frame.width*0.95, 45))
		saveButton.center.x = maskBackView.frame.width/2
		saveButton.cornerRadius    = saveButton.frame.height/2
		saveButton.backgroundColor = UIColor(red: 10/255.0, green: 200/255.0, blue: 10/255.0, alpha: 1)
		saveButton.hightLightColor = saveButton.backgroundColor!.colorWithAdjustBrightness(-0.3)
		saveButton.setTitle("保存", forState: UIControlState.Normal)
		saveButton.addTarget(self, action: #selector(RegisterDeviceViewController.onSaveButtonClicked(_:)), forControlEvents: UIControlEvents.TouchUpInside)
		
		cancelButton = PrettyButton(frame: CGRectMake(saveButton.frame.minX, saveButton.frame.maxY + 15, saveButton.frame.width, saveButton.frame.height))
		cancelButton.center.x = maskBackView.frame.width/2
		cancelButton.cornerRadius    = cancelButton.frame.height/2
		cancelButton.backgroundColor = UIColor(red: 200/255.0, green: 10/255.0, blue: 10/255.0, alpha: 1)
		cancelButton.hightLightColor = cancelButton.backgroundColor!.colorWithAdjustBrightness(-0.3)
		cancelButton.setTitle("取消", forState: UIControlState.Normal)
		cancelButton.addTarget(self, action: #selector(RegisterDeviceViewController.onCancelButtonClicked(_:)), forControlEvents: UIControlEvents.TouchUpInside)
		
		maskBackView.addSubview(saveButton)
		maskBackView.addSubview(cancelButton)
		
		if isShortScreen {
			let savaButtonCenterY   = container.frame.maxY + (visableViewHeight - container.frame.maxY) * 0.3
			let cancelButtonCenterY = container.frame.maxY + (visableViewHeight - container.frame.maxY) * 0.75
			
			saveButton.center = CGPointMake(self.view.frame.width/2, savaButtonCenterY)
			cancelButton.center = CGPointMake(self.view.frame.width/2, cancelButtonCenterY)
		}
		
		container.layer.opacity = 0
		saveButton.layer.opacity = 0
		cancelButton.layer.opacity = 0
		
		
        containerOriginCenterY    = container.center.y
        saveButtonOriginCenterY   = saveButton.center.y
        cancelButtonOriginCenterY = cancelButton.center.y
		
        container.center.y    += 50
        saveButton.center.y   += 50
        cancelButton.center.y += 50
		
	}
	
	func showContainerWithAnimation(){
		self.view.addSubview(maskBackView)
		
		UIView.animateWithDuration(0.4, delay: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
			self.container.center.y = self.containerOriginCenterY
			self.container.layer.opacity = 1
			}, completion: nil)
		
		UIView.animateWithDuration(0.4, delay: 0.05, options: UIViewAnimationOptions.CurveEaseOut, animations: {
			
			self.saveButton.center.y = self.saveButtonOriginCenterY
			self.saveButton.layer.opacity = 1
			}, completion: nil)
		
		UIView.animateWithDuration(0.4, delay: 0.1, options: UIViewAnimationOptions.CurveEaseOut, animations: {
			self.cancelButton.center.y = self.cancelButtonOriginCenterY
			self.cancelButton.layer.opacity = 1
			}, completion: nil)
	}
	
	func dismissContainerWithAnimation(){
		UIView.animateWithDuration(0.5, delay: 0.1, options: UIViewAnimationOptions.CurveEaseOut, animations: {
			self.container.center.y = self.containerOriginCenterY + 50
			self.container.layer.opacity = 0
			}, completion: { (complete) in
				self.maskBackView.removeFromSuperview()
		})
		
		UIView.animateWithDuration(0.5, delay: 0.05, options: UIViewAnimationOptions.CurveEaseOut, animations: {
			self.saveButton.center.y = self.saveButtonOriginCenterY + 50
			self.saveButton.layer.opacity = 0
			}, completion: nil)
		
		UIView.animateWithDuration(0.5, delay: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
			self.cancelButton.center.y = self.cancelButtonOriginCenterY + 50
			self.cancelButton.layer.opacity = 0
			}, completion: nil)
	}
	
//MARK: - UI事件
	///键盘弹出
	func onKeyBoardShown(notification: NSNotification) {
		let keyboardHeight = (notification.userInfo![UIKeyboardFrameBeginUserInfoKey] as! NSValue).CGRectValue().height
		
		if container.frame.maxY > maskBackView.frame.height - keyboardHeight {
			let diff = self.saveButton.frame.maxY - self.view.frame.height + keyboardHeight + 10
			maskBackView.setContentOffset(CGPointMake(0, diff), animated: true)
			
		}
	}
	
    ///开始编辑
    func onNameTextFieldEditBegin(textField: UITextField) {
        
    }
	
	///完成编辑
	func onNameTextFieldEditEnd(textField: UITextField) {
		maskBackView.setContentOffset(CGPointZero, animated: true)
	}

	
	
///MARK: - 点击按键
	
	///点击注册按键
	func registerButtonClicked(button: RegisterButton) {
		if registerStatus == .Ready {
			regButtonTransitTo(true)
		} else if registerStatus == .Searching {
			regButtonTransitTo(false)
		}
	}
	
	/**
	regbutton状态切换，动画方式改变regbutton
	
	- parameter startOrStop: 开始注册或停止注册
	*/
	private func regButtonTransitTo(startOrStop: Bool) {
		if startOrStop {
			registerStatus = .Searching
			HR8000Service.shareInstance().registerDeviceStart()
			HRProcessCenter.shareInstance().delegates.registerDevicesDelegate = self
			self.regButton.startRegistering("搜索中")
			UIView.transitionWithView(self.regButton, duration: 0.5, options: UIViewAnimationOptions.CurveEaseOut, animations: {
				self.regButton.center.y = self.view.frame.height/3
				}, completion: nil)
		} else {
			registerStatus = .Ready
			HRProcessCenter.shareInstance().delegates.registerDevicesDelegate = nil
			HR8000Service.shareInstance().registerDeviceEnd()
			self.regButton.stopRegistering()
			UIView.transitionWithView(self.regButton, duration: 0.5, options: UIViewAnimationOptions.CurveEaseOut, animations: {
				self.regButton.center.y = self.view.frame.height/2
				}, completion: nil)
			dismissContainerWithAnimation()
		}
	}
	
	///搜索设备超时
	func registerButton(button: RegisterButton, end: Bool) {
		regButtonTransitTo(false)
      // 斌  门锁相关
        print("搜索设备超时")
        
	}
	
	//点击导航栏上的取消按钮（后退）
	func onBackButtonClicked(button: UIBarButtonItem) {
		switch registerStatus {
		case .Searching:
			HR8000Service.shareInstance().registerDeviceEnd()
		case .Editing:
			let alert = UIAlertView(title: "提示", message: "是否要放弃注册？", delegate: self, cancelButtonTitle: "否", otherButtonTitles: "是")
			alert.tag = 77
			alert.show()
			return
		default: break
		}
		self.navigationController?.popViewControllerAnimated(true)
	}
	
	
	///点击保存按键
	func onSaveButtonClicked(button: PrettyButton) {
		if let newDev = tempDevice {
			var name = container.nameTextField.text ?? ""
			name = name.isEmpty ? (container.nameTextField.placeholder ?? ""): name
            
            //检查命名是否错误 斌 门锁相关
			if let error = HRDatabase.shareInstance().checkName(newDev.devType, name: name, allowDuplication: true) {
				UIAlertView(title: error.localizedDescription, message: nil, delegate: nil, cancelButtonTitle: "明白").show()
				return
			}
			let roomName = container.currentRoomName != nil ?
				container.currentRoomName! : ""
			let floorName = container.currentFloorName != nil ?
				container.currentFloorName! : ""
			self.registerStatus = .Commited
            //把注册的新设备的名字 所在楼层和房间传入进去注册 斌 门锁相关
			HR8000Service.shareInstance().registerDeviceAllow(newDev.devType, devAddr: newDev.devAddr, name: name, room: roomName, floor: floorName)
		}
		self.dismissContainerWithAnimation()
		self.regButton.enabled = false
		runOnMainQueueDelay(500, block: {
			self.container.nameTextField.text = ""
		})
	}

	///点击取消按键, 放弃本次注册
	func onCancelButtonClicked(button: PrettyButton) {
		self.dismissContainerWithAnimation()
		runOnMainQueueDelay(500, block: {
			self.container.nameTextField.text = ""
			self.regButtonTransitTo(false)
		})
	}
	
	func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
		if (alertView.tag == 77 && buttonIndex != alertView.cancelButtonIndex )
			||
			(alertView.tag == 88){
			//退出注册
			HRProcessCenter.shareInstance().delegates.registerDevicesDelegate = nil
			HR8000Service.shareInstance().registerDeviceEnd()
			self.navigationController?.popViewControllerAnimated(true)
		}
		
	}
	
	private func getNewDeviceDefaultName(devType: Byte) -> String {
		var name = ContentHelper.deviceNameString(devType)
		let formatter = NSDateFormatter()
		formatter.dateFormat = "MMDDHHmm"
		name += "_" + formatter.stringFromDate(NSDate())
		return name
	}
	
//MARK: - HRRegisterDeviceDelegate
	
    /// 临时设备对象，注册进行时用到
    private var tempDevice: HRDevice?
    
    ///接收到注册的设备信息
	
	
	//流程2，接收到待注册的设备信息
	func registerDevices(devType: Byte, hostAddr: UInt32, deviceInfo devAddr: UInt32) {
		if registerStatus != .Searching { return }
		registerStatus = .Editing
		Log.verbose("############################")
		Log.verbose("搜索到新设备：\n设备类型:\(devType)\n设备地址：\(devAddr)")
		Log.verbose("############################")
        
        //获取到新设备的图标 门锁相关 斌
		container.image = UIImage(named: ContentHelper.getIconName(devType))
        //获取到新设备的名字  门锁相关 斌
		container.title = "新的\(ContentHelper.deviceNameString(devType))"
		container.nameTextField.hidden = false
        
        
        
        //MARK 获取设备名字
		container.nameTextField.placeholder = getNewDeviceDefaultName(devType)
		saveButton.hidden = false
			
		tempDevice = HRDevice()
		tempDevice?.devType = devType
		tempDevice?.devAddr = devAddr
		tempDevice?.hostAddr = hostAddr
		self.regButton.pauseRegistering("注册中")
		runOnMainQueueDelay(500, block: {
			self.showContainerWithAnimation()
		})
	}
	
	//流程3，设备已经注册到主机，主机上送设备状态
	func registerDevices(devType: Byte, newDevice device: HRDevice, data: [Byte]) {
        
        
        print("流程三，设备已经注册到主机")
        
        
		if registerStatus == .Editing {
			//如果返回了0x03, 但App还处于编辑状态，这种情况就是其他手机完成了注册。
			let alert = UIAlertView(title: "提示", message: "其它手机已经完成了注册，所以无法继续编辑。", delegate: self, cancelButtonTitle: "退出注册")
			alert.tag = 88
			alert.show()
			return
		}
		if registerStatus != .Commited { return }
		guard let relayboxName = container.nameTextField.text else {
			Log.error("RegisterDevices：保存时名字为nil")
			return
		}
		self.regButton.enabled = true
		self.regButtonTransitTo(false)
		
		switch device.devType {
		case HRDeviceType.relayTypes():	//如果是继电器设备，则要绑定继电器负载
			let relayBox = HRRelayCtrlBox()
            relayBox.devType  = device.devType
            relayBox.devAddr  = device.devAddr
            relayBox.hostAddr = device.hostAddr
            relayBox.name     = relayboxName
            relayBox.states   = data[6]
			if let floorName = container.currentFloorName {
				if let floorId = HRDatabase.shareInstance().getFloorID(floorName) {
					relayBox.insFloorID = UInt16(floorId)
				}
				if let roomName = container.currentRoomName {
					if let roomId = HRDatabase.shareInstance().getRoomID(floorName, roomName: roomName) {
						relayBox.insRoomID = roomId
					}
				}
			}
			let controller = EditRelayBoxViewController()
			controller.relayBox = relayBox
			let states = controller.relayBox.states
			controller.routerEnable = [
				states & 0b0000_0011 != 0b0000_0011,
				states & 0b0000_1100 != 0b0000_1100,
				states & 0b0011_0000 != 0b0011_0000,
				states & 0b1100_0000 != 0b1100_0000,
			]
			self.navigationController?.pushViewController(controller, animated: true)
		default: break
		}
		
		
	}
	
	//流程4，主机确认退出注册状态
	func registerDevices(didEndRegister: Bool) {
		print("didEndRegister")
	}
	
    
	
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "showEditRelayBoxViewController" {
			let controller = segue.destinationViewController as! EditRelayBoxViewController
			controller.relayBox = sender as! HRRelayComplexes
			let states = controller.relayBox.states
			controller.routerEnable = [
				states & 0b0000_0011 != 0b0000_0011,
				states & 0b0000_1100 != 0b0000_1100,
				states & 0b0011_0000 != 0b0011_0000,
				states & 0b1100_0000 != 0b1100_0000,
			]
		}
		
    }

}


// MARK: - RegisterDeviceInfoView类

class RegisterDeviceInfoView: UIView, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
	var image: UIImage? {
		didSet {
			_imageView.image = image
		}
	}
	var title: String = "新的设备" {
		didSet {
			_titleLabel.text = title
		}
	}
	/// 当前选择的房间
	var currentFloorName: String? {
		didSet{
			_menuList.reloadData()
		}
	}
	var currentRoomName: String? {
		didSet{
			_menuList.reloadData()
		}
	}
	var nameTextField: UITextField!
	
	private var _scrollView: UIScrollView!
	private var _imageView: UIImageView!
	private var _titleLabel: UILabel!
	private var _menuList: UITableView!
	private var _secondList: UITableView!
	private var _secondListTitle: UILabel!
	
	/// 当前选择的菜单索引
	private var _currentMenuSelected: Int = 0
	private var _secondListNames = [String]()
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		self.opaque = false
		self.backgroundColor = UIColor.whiteColor()
		self.layer.shadowOffset = CGSizeMake(0, 0)
		self.layer.shadowOpacity = 0.8
		self.layer.cornerRadius = 15
		
		_scrollView = UIScrollView(frame: CGRectMake(0, 0, frame.width, frame.height))
		_scrollView.contentSize = CGSizeMake(frame.width*2, frame.height)
		_scrollView.showsVerticalScrollIndicator = false
		_scrollView.showsHorizontalScrollIndicator = false
		_scrollView.bounces = false
		_scrollView.pagingEnabled = true
		addSubview(_scrollView)
		
		_imageView = UIImageView(frame: CGRectMake(0, 10, frame.width, frame.height*0.3))
		//		_imageView.backgroundColor = UIColor.orangeColor()
		_imageView.contentMode = UIViewContentMode.ScaleAspectFit
		_scrollView.addSubview(_imageView)
		
		_titleLabel = UILabel(frame: CGRectMake(0, _imageView.frame.maxY + 10, frame.width, frame.height/7))
//		_titleLabel.backgroundColor = UIColor.purpleColor()
		_titleLabel.textAlignment = NSTextAlignment.Center
		_titleLabel.textColor = UIColor.lightGrayColor()
		_titleLabel.font = UIFont.systemFontOfSize(_titleLabel.frame.height*0.5)
		_scrollView.addSubview(_titleLabel)
		
		nameTextField = UITextField(frame: CGRectMake(15, 0, frame.width-15, 60))
		nameTextField.font = UIFont.systemFontOfSize(nameTextField.font!.pointSize + 3)
		nameTextField.borderStyle = UITextBorderStyle.None
		nameTextField.returnKeyType = UIReturnKeyType.Done
		nameTextField.placeholder = "输入设备名称"
		
		
		_menuList = UITableView(frame: CGRectMake(0, _titleLabel.frame.maxY, frame.width, frame.height - _titleLabel.frame.maxY))
		_menuList.delegate = self
		_menuList.dataSource = self
		_menuList.separatorStyle = UITableViewCellSeparatorStyle.None
		_menuList.scrollEnabled = false
		
		_scrollView.addSubview(_menuList)
		
		let headView = UIView(frame: CGRectMake(frame.width, 0, frame.width, 50))
		_secondListTitle = UILabel(frame: CGRectMake(0, 0, headView.frame.width, 49))
		_secondListTitle.textAlignment = .Center
		if _currentMenuSelected == 1 {
			_secondListTitle.text = "楼层"
		} else if _currentMenuSelected == 2 {
			_secondListTitle.text = "房间"
		}
		_secondListTitle.textColor = UIColor.lightGrayColor()
		let line = UIView(frame: CGRectMake(0, headView.frame.height-1, headView.frame.width, 0.5))
		line.backgroundColor = UIColor.lightGrayColor()
		headView.backgroundColor = UIColor.whiteColor()
		
		headView.addSubview(_secondListTitle)
		headView.addSubview(line)
		_scrollView.addSubview(headView)
		
		_secondList = UITableView(frame: CGRectMake(frame.width, headView.frame.height, frame.width, frame.height-50))
		_secondList.delegate = self
		_secondList.dataSource = self
		_secondList.registerClass(UITableViewCell.classForCoder(), forCellReuseIdentifier: "tableViewCell")
//		_secondList.separatorStyle = UITableViewCellSeparatorStyle.None
		_secondList.tableFooterView = UIView()
		_scrollView.addSubview(_secondList)
		_scrollView.scrollEnabled = false
		
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func drawRect(rect: CGRect) {
		_imageView.image = image
		_titleLabel.text = title
	}
	
	private func getTipsView(text: String) -> UIView {
		let tipsView = UIView(frame: CGRectMake(self.frame.width, 0, self.frame.width, self.frame.height))
		let tipsImage = UIImageView(frame: CGRectMake(0, 0, self.frame.width/3, self.frame.width/3))
		tipsImage.center = CGPointMake(tipsView.frame.width/2, tipsView.frame.height/2)
		tipsImage.image = UIImage(named: "ico_warn_light_gray")
		let textLabel = UILabel(frame: CGRectMake(0, tipsImage.frame.maxY, self.frame.width, 45))
		textLabel.textAlignment = .Center
		textLabel.text = text
		textLabel.textColor = UIColor.lightGrayColor()
		
		tipsView.addSubview(tipsImage)
		tipsView.addSubview(textLabel)
		
		return tipsView
	}
	
	func onTipsViewTap(gesture: UITapGestureRecognizer) {
		switch gesture.state {
		case .Ended:
			_scrollView.setContentOffset(CGPointZero, animated: true)
		default: break
		}
	}
	
	
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if tableView === _menuList {
			return 3
		} else  {
			if let tips = _scrollView.viewWithTag(555) {
				tips.removeFromSuperview()
			}
			if _currentMenuSelected == 1 {
				_secondListNames.removeAll(keepCapacity: false)
				let floors = HRDatabase.shareInstance().floors
				for floor in floors {
					_secondListNames.append(floor.name)
				}
				//判断
				if _secondListNames.count == 0 {
					let tipsView = getTipsView("没有楼层")
					tipsView.tag = 555
					tipsView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(RegisterDeviceInfoView.onTipsViewTap(_:))))
					_scrollView.addSubview(tipsView)
				} else {
					return _secondListNames.count
				}
			} else if _currentMenuSelected == 2 && currentFloorName != nil {
				if let rooms = HRDatabase.shareInstance().getRooms(currentFloorName!) {
					_secondListNames.removeAll(keepCapacity: false)
					for room in rooms {
						_secondListNames.append(room.name)
					}
					//判断
					if _secondListNames.count == 0 {
						let tipsView = getTipsView("没有房间")
						tipsView.tag = 555
						tipsView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(RegisterDeviceInfoView.onTipsViewTap(_:))))
						_scrollView.addSubview(tipsView)
					} else {
						return _secondListNames.count
					}
				}
			}
		}
		return 0
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell: UITableViewCell
		if tableView === _menuList {
			cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "cell")
		} else {
			cell = tableView.dequeueReusableCellWithIdentifier("tableViewCell")!
		}
		
		if tableView === _menuList {
			let lineView = UIView(frame: CGRectMake(0, 0, frame.width, 0.5))
			lineView.backgroundColor = UIColor.lightGrayColor()
			lineView.tag = 100
			cell.contentView.addSubview(lineView)
		}
		switch indexPath.row {
		case 0 where tableView === _menuList:
			if cell.viewWithTag(888) == nil {
				nameTextField.tag = 888
				cell.contentView.addSubview(nameTextField)
			}
		case 1 where tableView === _menuList:
			cell.textLabel?.text = "楼层名"
			cell.accessoryType = .DisclosureIndicator
			if let name = currentFloorName {
				cell.detailTextLabel?.text = name
			}
		case 2 where tableView === _menuList:
			cell.textLabel?.text = "房间名"
			cell.accessoryType = .DisclosureIndicator
			if let name = currentRoomName {
				cell.detailTextLabel?.text = name
			}
		case let row where tableView === _secondList:
			cell.textLabel?.text = _secondListNames[row]
			if (_currentMenuSelected == 1
				&& currentFloorName == _secondListNames[row] )
				||
				(_currentMenuSelected == 2
					&& currentRoomName == _secondListNames[row]){
						cell.accessoryType = .Checkmark
			} else {
				cell.accessoryType = .None
			}
		default: break
		}
		return cell
	}
	
	func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		if tableView === _menuList {
			return tableView.frame.height / 3
		} else {
			return 50
		}
	}
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let cell = tableView.cellForRowAtIndexPath(indexPath)
		cell?.setSelected(false, animated: true)
		
		switch indexPath.row {
		case 0 where tableView == _menuList:
			nameTextField.becomeFirstResponder()
		case let row where tableView === _menuList:
			_currentMenuSelected = row
			if row == 1 {
				self._secondListTitle.text = "楼层"
			} else if row == 2 {
				self._secondListTitle.text = "房间"
			}
			_secondList.reloadData()
			_scrollView.setContentOffset(CGPointMake(self.frame.width, 0), animated: true)
		case let row where tableView === _secondList:
			for tmpCell in tableView.visibleCells {
				(tmpCell ).accessoryType = .None
			}
			cell?.accessoryType = .Checkmark
			if _currentMenuSelected == 1 {
				let rooms = HRDatabase.shareInstance().getRooms(_secondListNames[row])
				let rCell = _menuList.cellForRowAtIndexPath(NSIndexPath(forRow: 2, inSection: 0))
				if rooms == nil || rooms!.count == 0 {
//					rCell?.detailTextLabel?.text = ""
					currentRoomName = ""
				} else if currentFloorName != _secondListNames[row] {
					rCell?.detailTextLabel?.text = rooms![0].name
					currentRoomName = rooms![0].name
				}
				_menuList.reloadRowsAtIndexPaths([NSIndexPath(forRow: 2, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
				currentFloorName = _secondListNames[row]
			} else if _currentMenuSelected == 2 {
				currentRoomName = _secondListNames[row]
			}
			runOnMainQueueDelay(200, block: {
				tableView.reloadData()
			})
			_scrollView.setContentOffset(CGPointMake(0, 0), animated: true)
			runOnMainQueueDelay(200, block: {
				tableView.reloadData()
			})
		default: break
		}
	}
}
