//
//  NewAirCtrlViewController.swift
//
//  Created by sswukang on 15/8/21.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import UIKit

class AirCtrlViewController: UIViewController, HRInfraredDelegate,CAAnimationDelegate {
	var todo: Int = SHARETODO_NOTHING
	var appDevice: HRApplianceApplyDev?
	///红外按键编码
	var currentKeyCode: Byte? {
		didSet {
			if todo != SHARETODO_RECORD_AIR_CTRL && currentKeyCode != nil {
				operateAirCtrl(currentKeyCode!)
			}
		}
	}
	weak var delegate: AirCtrlViewControllerDelegate?
	var actionHandler: ((Byte, HRDevice) -> Void)?
	
	//状态
	var stateMode: AirCtrlMode? { didSet { setMode() } }
	var stateSwing: AirCtrlSwing? { didSet{ setSwing() } }
	var statePower: Bool?  { didSet{ setPower() } }
	var stateSpeed: Int? { didSet{ setSpeed() } }
	var stateTemp: Int? {
		didSet {
			if stateTemp != oldValue {
				selectOneItem(arcMaskView)
				setTemp()
			}
		}
	}
	private var frameTag: Byte = 0
	
	private var tipsView: TipsView!
	private var modeAuto: PrettyButton!
	private var modeCool: PrettyButton!
	private var modeWarm: PrettyButton!
	private var modeDry : PrettyButton!
	private var modeWind: PrettyButton!
	private var speedCtrl: PrettyButton!
	private var swingAuto: PrettyButton!
	private var swingHand: PrettyButton!
	private var speedAuto: PrettyButton!
	private var powerCtrl: PrettyButton!
	private var tempAdd: UIButton!
	private var tempSub: UIButton!
	
	private var tempLabel: UILabel!
	private var speedLabel: UILabel!
	private var powerCtrlLabel: UILabel!
	
	private var arcLayer: CAShapeLayer!
	private var thumbView: UIView!
	private var arcMaskView: UIView!
	
	private let arcAngle: CGFloat = CGFloat(M_PI)/2.5
	private var arcRadius: CGFloat!
	private var arcCenter: CGPoint!
	private var themeColor = APP.param.themeColor
	
//MARK: - UIViewController
	
	override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
		return UIInterfaceOrientationMask.Portrait
	}
	
	override func shouldAutorotate() -> Bool {
		return false
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.view.backgroundColor = UIColor.whiteColor()
		if self.title == nil && appDevice != nil{
			self.title = appDevice!.name
		}
		
		initComponent()
		//tipsview
		tipsView = TipsView(frame: CGRectMake(0, 0, view.frame.width, 30))
		self.view.addSubview(tipsView)
		
		if todo == SHARETODO_RECORD_AIR_CTRL {
			let cancelButton = UIBarButtonItem(
				title: "取消",
				style: UIBarButtonItemStyle.Plain,
				target: self,
				action: #selector(AirCtrlViewController.onCancelButtonClicked(_:))
			)
			let doneButton = UIBarButtonItem(
				title: "完成",
				style: UIBarButtonItemStyle.Plain,
				target: self,
				action: #selector(AirCtrlViewController.onDoneButtonClicked(_:))
			)
			navigationItem.leftBarButtonItem = cancelButton
			navigationItem.rightBarButtonItem = doneButton
		} else {
			frameTag = Byte(arc4random() % 128)
			HRProcessCenter.shareInstance().delegates.infraredDelegate = self
			initAirCtrl()
			statePower = false
		}
		
	}
	
	override func viewDidAppear(animated: Bool) {
		if appDevice == nil {
			Log.error("AirCtrlViewController: appDevice值为nil，无法控制设备。")
			self.navigationController?.popViewControllerAnimated(true)
			return
		}
	}
	
	func initComponent() {
		var btnWidth: CGFloat
		var gapHorz: CGFloat
		var gapVert: CGFloat
		var x: CGFloat = 0
		var y: CGFloat = 0
		if self.view.frame.width / self.view.frame.height > 0.6 {
			btnWidth = self.view.frame.width/5
			gapHorz  = (view.frame.width - btnWidth*3) / 4
			gapVert  = (view.frame.height - btnWidth*5) / 5
		} else {
			btnWidth = self.view.frame.width/4.5
			gapHorz  = (view.frame.width - btnWidth*3) / 4
			gapVert  = (view.frame.height - btnWidth*5) / 5
		}
		
		
		//温度显示
		tempLabel = UILabel(frame: CGRectMake(x, y, gapHorz*2.5+btnWidth*2, btnWidth*1.6))
		tempLabel.textAlignment = .Right
		tempLabel.font = UIFont(name: ".HelveticaNeueInterface-Thin", size: btnWidth*1.5)
		tempLabel.text = "--"
		//		tempLabel.backgroundColor = UIColor(red: 0, green: 1, blue: 0, alpha: 0.5)
		
		let unitLabel = UILabel(frame: CGRectMake(tempLabel.frame.maxX+5, tempLabel.frame.maxY - btnWidth/1.5, btnWidth/2, btnWidth/2))
		unitLabel.textAlignment = .Center
		unitLabel.textColor = UIColor.blackColor()
		unitLabel.text = "℃"
		unitLabel.font = UIFont(name: ".HelveticaNeueInterface-Thin", size: btnWidth/3)
		
		self.view.addSubview(tempLabel)
		self.view.addSubview(unitLabel)
		
		arcLayer = CAShapeLayer()
		arcLayer.bounds = self.view.bounds
		arcLayer.position = self.view.center
		
		y = tempLabel.frame.maxY - tempLabel.frame.height*0.1
		
		let point1 = CGPointMake(gapHorz, y)
		let point2 = CGPointMake(self.view.frame.width-gapHorz, y)
		
		arcRadius = (point2.x-point1.x)/2 / sin(arcAngle/2)
		arcCenter = CGPointMake(point1.x + (point2.x-point1.x)/2, point1.y - arcRadius*cos(arcAngle/2))
		
		arcLayer.fillColor = UIColor.clearColor().CGColor
		arcLayer.path = UIBezierPath(arcCenter: arcCenter, radius: arcRadius, startAngle: (CGFloat(M_PI)-arcAngle)/2, endAngle: (CGFloat(M_PI)+arcAngle)/2, clockwise: true).CGPath
		arcLayer.lineWidth = 3
		arcLayer.strokeColor = themeColor.CGColor
		arcLayer.strokeStart = 1
		arcLayer.strokeEnd = 1
		//关闭strokeStart、strokeEnd的隐式动画
		arcLayer.actions = ["strokeStart": NSNull(), "strokeEnd": NSNull()]
		
		let arcBackLayer = CAShapeLayer()
		arcBackLayer.bounds = arcLayer.bounds
		arcBackLayer.position = arcLayer.position
		arcBackLayer.fillColor = UIColor.clearColor().CGColor
		arcBackLayer.path = UIBezierPath(arcCenter: arcCenter, radius: arcRadius, startAngle: (CGFloat(M_PI)-arcAngle)/2, endAngle: (CGFloat(M_PI)+arcAngle)/2, clockwise: true).CGPath
		arcBackLayer.lineWidth = arcLayer.lineWidth
		arcBackLayer.strokeColor = UIColor.lightGrayColor().CGColor
		arcBackLayer.strokeStart = 0
		arcBackLayer.strokeEnd = 1
		
		self.view.layer.addSublayer(arcBackLayer)
		self.view.layer.addSublayer(arcLayer)
		
		
		tempSub = UIButton(frame: CGRectMake(0, 0, btnWidth/2.5, btnWidth/2.5))
		tempSub.setTitle("16", forState: .Normal)
		tempSub.titleLabel?.font = UIFont(name: ".HelveticaNeueInterface-Thin", size: tempSub.frame.width*0.4)
		tempSub.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
		tempSub.backgroundColor = UIColor.whiteColor()
		tempSub.layer.cornerRadius = btnWidth/5
		tempSub.layer.borderWidth = 1
		tempSub.layer.borderColor = UIColor.lightGrayColor().CGColor
		tempSub.center = point1
		tempSub.enabled = false
		
		tempAdd = PrettyButton(frame: CGRectMake(0, 0, btnWidth/2.5, btnWidth/2.5))
		tempAdd.setTitle("30", forState: .Normal)
		tempAdd.titleLabel?.font = UIFont(name: ".HelveticaNeueInterface-Thin", size: tempAdd.frame.width*0.4)
		tempAdd.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
		tempAdd.backgroundColor = UIColor.whiteColor()
		tempAdd.layer.cornerRadius = btnWidth/5
		tempAdd.layer.borderWidth = 1
		tempAdd.layer.borderColor = UIColor.lightGrayColor().CGColor
		tempAdd.center = point2
		tempAdd.enabled = false
		
		thumbView = UIView(frame: CGRectMake(0, 0, btnWidth/2.5, btnWidth/2.5))
		thumbView.backgroundColor = UIColor.orangeColor()
		thumbView.center = tempSub.center
		thumbView.layer.cornerRadius = btnWidth/5
		thumbView.backgroundColor = UIColor.whiteColor()
		thumbView.layer.shadowOffset = CGSizeMake(0, 0)
		thumbView.layer.shadowOpacity = 0.8
		
		arcMaskView = UIView(frame: CGRectMake(tempSub.frame.minX, tempSub.frame.minY, tempAdd.frame.maxX - tempSub.frame.minX, (arcRadius - (point1.y - arcCenter.y))*1.8))
		
		
		self.view.addSubview(arcMaskView)
		self.view.addSubview(tempSub)
		self.view.addSubview(tempAdd)
		self.view.addSubview(thumbView)
		
		let maskGesture = UIPanGestureRecognizer(target: self, action: #selector(AirCtrlViewController.onThumbViewMove(_:)))
		arcMaskView.addGestureRecognizer(maskGesture)
		let thumbGesture = UIPanGestureRecognizer(target: self, action: #selector(AirCtrlViewController.onThumbViewMove(_:)))
		thumbView.addGestureRecognizer(thumbGesture)
		
		///屏幕底部距离arcMaskView底部的距离
		let tmpDis = self.view.frame.height - navigationController!.navigationBar.frame.height - UIApplication.sharedApplication().statusBarFrame.height - arcMaskView.frame.maxY
		if tmpDis < btnWidth * 4.5 {
			btnWidth = tmpDis / 4.5
			gapVert = btnWidth / 2
			gapHorz = (self.view.frame.width - btnWidth*3) / 4
		}
		
		x = gapHorz
		y = arcMaskView.frame.maxY
		modeAuto = PrettyButton(frame: CGRectMake(x, y, btnWidth, btnWidth))
		modeAuto.cornerRadius = btnWidth/2
		modeAuto.borderColor = UIColor.lightGrayColor()
		modeAuto.borderWidth = 1
//		modeAuto.setTitle("自动", forState: .Normal)
//		modeAuto.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
		modeAuto.setBackgroundImage(UIImage(named: "ico_air_mode_auto_gray"), forState: UIControlState.Normal)
		modeAuto.setBackgroundImage(UIImage(named: "ico_air_mode_auto"), forState: UIControlState.Selected)
		modeAuto.hightLightColor = themeColor
		
		x += gapHorz + btnWidth
		modeCool = PrettyButton(frame: CGRectMake(x, y, btnWidth, btnWidth))
		modeCool.cornerRadius = btnWidth/2
		modeCool.borderColor = UIColor.lightGrayColor()
		modeCool.borderWidth = 1
//		modeCool.setTitle("制冷", forState: .Normal)
//		modeCool.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
		modeCool.setBackgroundImage(UIImage(named: "ico_air_mode_cool_gray"), forState: UIControlState.Normal)
		modeCool.setBackgroundImage(UIImage(named: "ico_air_mode_cool"), forState: UIControlState.Selected)
		modeCool.hightLightColor = themeColor
		
		x += gapHorz + btnWidth
		modeDry = PrettyButton(frame: CGRectMake(x, y, btnWidth, btnWidth))
		modeDry.cornerRadius = btnWidth/2
		modeDry.borderColor = UIColor.lightGrayColor()
		modeDry.borderWidth = 1
//		modeDry.setTitle("除湿", forState: .Normal)
//		modeDry.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
		modeDry.setBackgroundImage(UIImage(named: "ico_air_mode_dry_gray"), forState: UIControlState.Normal)
		modeDry.setBackgroundImage(UIImage(named: "ico_air_mode_dry"), forState: UIControlState.Selected)
		modeDry.hightLightColor = themeColor
		
		x = gapHorz
		y += gapVert + btnWidth
		modeWind = PrettyButton(frame: CGRectMake(x, y, btnWidth, btnWidth))
		modeWind.cornerRadius = btnWidth/2
		modeWind.borderColor = UIColor.lightGrayColor()
		modeWind.borderWidth = 1
//		modeWind.setTitle("送风", forState: .Normal)
//		modeWind.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
		modeWind.setBackgroundImage(UIImage(named: "ico_air_mode_wind_gray"), forState: UIControlState.Normal)
		modeWind.setBackgroundImage(UIImage(named: "ico_air_mode_wind"), forState: UIControlState.Selected)
		modeWind.hightLightColor = themeColor
		
		x += gapHorz + btnWidth
		modeWarm = PrettyButton(frame: CGRectMake(x, y, btnWidth, btnWidth))
		modeWarm.cornerRadius = btnWidth/2
		modeWarm.borderColor = UIColor.lightGrayColor()
		modeWarm.borderWidth = 1
//		modeWarm.setTitle("制热", forState: .Normal)
//		modeWarm.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
		modeWarm.setBackgroundImage(UIImage(named: "ico_air_mode_warm_gray"), forState: UIControlState.Normal)
		modeWarm.setBackgroundImage(UIImage(named: "ico_air_mode_warm"), forState: UIControlState.Selected)
		modeWarm.hightLightColor = themeColor
		
		x += gapHorz + btnWidth
		speedCtrl = PrettyButton(frame: CGRectMake(x, y, btnWidth, btnWidth))
		speedCtrl.cornerRadius = btnWidth/2
		speedCtrl.borderColor = UIColor.lightGrayColor()
		speedCtrl.borderWidth = 1
		speedCtrl.setBackgroundImage(UIImage(named: "ico_air_fan_gray"), forState: .Normal)
		speedCtrl.setBackgroundImage(UIImage(named: "ico_air_fan"), forState: .Selected)
//		speedCtrl.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
		speedCtrl.hightLightColor = themeColor
		
		speedLabel = UILabel(frame: CGRectMake(speedCtrl.frame.maxX - btnWidth*0.3, speedCtrl.frame.minY, btnWidth*0.4, btnWidth*0.3))
		speedLabel.hidden = true
		speedLabel.text = "自动"
		speedLabel.textAlignment = .Center
		speedLabel.font = UIFont.systemFontOfSize(speedLabel.frame.height*0.5)
		speedLabel.textColor = UIColor.whiteColor()
		speedLabel.adjustsFontSizeToFitWidth = true
		speedLabel.layer.borderWidth = 1
		speedLabel.layer.borderColor = UIColor.whiteColor().CGColor
		speedLabel.layer.cornerRadius = speedLabel.frame.height/2
		speedLabel.layer.backgroundColor = themeColor.CGColor
		
		x = gapHorz
		y += gapVert + btnWidth
		swingAuto = PrettyButton(frame: CGRectMake(x, y, btnWidth, btnWidth))
		swingAuto.cornerRadius = btnWidth/2
		swingAuto.borderColor = UIColor.lightGrayColor()
		swingAuto.borderWidth = 1
//		swingAuto.setTitle("Auto", forState: .Normal)
//		swingAuto.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
		swingAuto.setBackgroundImage(UIImage(named: "ico_air_swing_auto_gray"), forState: .Normal)
		swingAuto.setBackgroundImage(UIImage(named: "ico_air_swing_auto"), forState: .Selected)
		swingAuto.hightLightColor = themeColor
		
		x += gapHorz + btnWidth
		swingHand = PrettyButton(frame: CGRectMake(x, y, btnWidth, btnWidth))
		swingHand.cornerRadius = btnWidth/2
		swingHand.borderColor = UIColor.lightGrayColor()
		swingHand.borderWidth = 1
//		swingHand.setTitle("Hand", forState: .Normal)
//		swingHand.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
		swingHand.setBackgroundImage(UIImage(named: "ico_air_swing_hand_gray"), forState: .Normal)
		swingHand.setBackgroundImage(UIImage(named: "ico_air_swing_hand"), forState: .Selected)
		swingHand.hightLightColor = themeColor
		
		x += gapHorz + btnWidth
		powerCtrl = PrettyButton(frame: CGRectMake(x, y, btnWidth, btnWidth))
		powerCtrl.cornerRadius = btnWidth/2
		powerCtrl.borderColor = UIColor.lightGrayColor()
		powerCtrl.borderWidth = 1
		powerCtrl.setImage(UIImage(named: "ico_power_light_gray"), forState: .Normal)
		powerCtrl.hightLightColor = UIColor.redColor()
		
		modeAuto.tag = 100
		modeCool.tag = 101
		modeDry.tag  = 102
		modeWind.tag = 103
		modeWarm.tag = 104
		speedCtrl.tag = 105
		swingAuto.tag = 106
		swingHand.tag = 107
		powerCtrl.tag = 108
		
		modeAuto.addTarget(self, action: #selector(AirCtrlViewController.onButtonClicked(_:)), forControlEvents: .TouchUpInside)
		modeCool.addTarget(self, action: #selector(AirCtrlViewController.onButtonClicked(_:)), forControlEvents: .TouchUpInside)
		modeWarm.addTarget(self, action: #selector(AirCtrlViewController.onButtonClicked(_:)), forControlEvents: .TouchUpInside)
		modeDry.addTarget(self, action: #selector(AirCtrlViewController.onButtonClicked(_:)), forControlEvents: .TouchUpInside)
		modeWind.addTarget(self, action: #selector(AirCtrlViewController.onButtonClicked(_:)), forControlEvents: .TouchUpInside)
		speedCtrl.addTarget(self, action: #selector(AirCtrlViewController.onButtonClicked(_:)), forControlEvents: .TouchUpInside)
		swingAuto.addTarget(self, action: #selector(AirCtrlViewController.onButtonClicked(_:)), forControlEvents: .TouchUpInside)
		swingHand.addTarget(self, action: #selector(AirCtrlViewController.onButtonClicked(_:)), forControlEvents: .TouchUpInside)
		powerCtrl.addTarget(self, action: #selector(AirCtrlViewController.onButtonClicked(_:)), forControlEvents: .TouchUpInside)
		
		self.view.addSubview(modeAuto)
		self.view.addSubview(modeCool)
		self.view.addSubview(modeWarm)
		self.view.addSubview(modeDry)
		self.view.addSubview(modeWind)
		self.view.addSubview(speedCtrl)
		self.view.addSubview(speedLabel)
		self.view.addSubview(swingAuto)
		self.view.addSubview(swingHand)
		self.view.addSubview(powerCtrl)
		
		let modeAutoLabel = UILabel(frame: CGRectMake(modeAuto.frame.minX, modeAuto.frame.maxY+4, btnWidth, btnWidth/4))
		modeAutoLabel.text = "自动"
		modeAutoLabel.font = UIFont.systemFontOfSize(UIFont.systemFontSize())
		modeAutoLabel.textAlignment = .Center
		modeAutoLabel.textColor = UIColor.lightGrayColor()
		
		let modeCoolLabel = UILabel(frame: CGRectMake(modeCool.frame.minX, modeCool.frame.maxY+4, btnWidth, btnWidth/4))
		modeCoolLabel.text = "制冷"
		modeCoolLabel.font = UIFont.systemFontOfSize(UIFont.systemFontSize())
		modeCoolLabel.textAlignment = .Center
		modeCoolLabel.textColor = UIColor.lightGrayColor()
		
		let modeWarmLabel = UILabel(frame: CGRectMake(modeWarm.frame.minX, modeWarm.frame.maxY+4, btnWidth, btnWidth/4))
		modeWarmLabel.text = "制热"
		modeWarmLabel.font = UIFont.systemFontOfSize(UIFont.systemFontSize())
		modeWarmLabel.textAlignment = .Center
		modeWarmLabel.textColor = UIColor.lightGrayColor()
		
		let modeDryLabel = UILabel(frame: CGRectMake(modeDry.frame.minX, modeDry.frame.maxY+4, btnWidth, btnWidth/4))
		modeDryLabel.text = "除湿"
		modeDryLabel.font = UIFont.systemFontOfSize(UIFont.systemFontSize())
		modeDryLabel.textAlignment = .Center
		modeDryLabel.textColor = UIColor.lightGrayColor()
		
		let modeWindLabel = UILabel(frame: CGRectMake(modeWind.frame.minX, modeWind.frame.maxY+4, btnWidth, btnWidth/4))
		modeWindLabel.text = "送风"
		modeWindLabel.font = UIFont.systemFontOfSize(UIFont.systemFontSize())
		modeWindLabel.textAlignment = .Center
		modeWindLabel.textColor = UIColor.lightGrayColor()
		
		let speedCtrlLabel = UILabel(frame: CGRectMake(speedCtrl.frame.minX, speedCtrl.frame.maxY+4, btnWidth, btnWidth/4))
		speedCtrlLabel.text = "风速"
		speedCtrlLabel.font = UIFont.systemFontOfSize(UIFont.systemFontSize())
		speedCtrlLabel.textAlignment = .Center
		speedCtrlLabel.textColor = UIColor.lightGrayColor()
		
		let swingAutoLabel = UILabel(frame: CGRectMake(swingAuto.frame.minX, swingAuto.frame.maxY+4, btnWidth, btnWidth/4))
		swingAutoLabel.text = "自动摆风"
		swingAutoLabel.font = UIFont.systemFontOfSize(UIFont.systemFontSize())
		swingAutoLabel.textAlignment = .Center
		swingAutoLabel.textColor = UIColor.lightGrayColor()
		
		let swingHandLabel = UILabel(frame: CGRectMake(swingHand.frame.minX, swingHand.frame.maxY+4, btnWidth, btnWidth/4))
		swingHandLabel.text = "手动摆风"
		swingHandLabel.font = UIFont.systemFontOfSize(UIFont.systemFontSize())
		swingHandLabel.textAlignment = .Center
		swingHandLabel.textColor = UIColor.lightGrayColor()
		
		powerCtrlLabel = UILabel(frame: CGRectMake(powerCtrl.frame.minX, powerCtrl.frame.maxY+4, btnWidth, btnWidth/4))
		powerCtrlLabel.text = "电源"
		powerCtrlLabel.font = UIFont.systemFontOfSize(UIFont.systemFontSize())
		powerCtrlLabel.textAlignment = .Center
		powerCtrlLabel.textColor = UIColor.lightGrayColor()
		
		self.view.addSubview(modeAutoLabel)
		self.view.addSubview(modeCoolLabel)
		self.view.addSubview(modeWarmLabel)
		self.view.addSubview(modeDryLabel)
		self.view.addSubview(modeWindLabel)
		self.view.addSubview(speedCtrlLabel)
		self.view.addSubview(swingAutoLabel)
		self.view.addSubview(swingHandLabel)
		self.view.addSubview(powerCtrlLabel)
		
		
	}
	
//MARK: - 控制方法
	
	func initAirCtrl(){
		if appDevice == nil { return }
		KVNProgress.showWithStatus("正在初始化...")
		HR8000Service.shareInstance().initAirCtrl(appDevice!, completion:{(error) in
			if let err = error {
				KVNProgress.showErrorWithStatus(err.domain)
			} else {
				KVNProgress.dismiss()
			}
		})
	}
	
	func operateAirCtrl(code: Byte){
		guard let key = getIRStudyState(code) else {
			tipsView.show("该按键还没有学习红外码！", duration: 2.0)
			return
		}
		HR8000Service.shareInstance().operateInfrared(appDevice!, infraredKey: key, tag: frameTag, callback: { (error) in
			if let err = error {
				self.tipsView.show(err.domain, duration: 2.0)
			} else{
				self.tipsView.show("操作成功", duration: 1.0)
			}
		})
	}
	
	func getIRStudyState(code: Byte) -> HRInfraredKey? {
		for key in appDevice!.learnKeys {
			if key.keyCode == code {
				return key
			}
		}
		return nil
	}
	
//MARK: - UI事件
	
	func onCancelButtonClicked(button: UIBarButtonItem) {
		currentKeyCode = nil
		if self.navigationController?.popViewControllerAnimated(true) == nil {
			self.dismissViewControllerAnimated(true, completion: nil)
		}
	}
	
	func onDoneButtonClicked(button: UIBarButtonItem) {
		if currentKeyCode != nil && appDevice != nil {
			self.delegate?.airCtrlResult(recordKeyCode: currentKeyCode!, device: appDevice!)
			self.actionHandler?(currentKeyCode!, appDevice!)
		}
		if self.navigationController?.popViewControllerAnimated(true) == nil {
			self.dismissViewControllerAnimated(true, completion: nil)
		}
	}
	
	/// 调温度滑块在线上的位置比率，范围0~1
	private var tempLineRate: CGFloat = 0
	
	func onThumbViewMove(gesture: UIPanGestureRecognizer) {
		switch gesture.state {
		case .Changed:
			let point = gesture.translationInView(self.view)
			var x = thumbView.center.x + point.x
			var y = sqrt(arcRadius*arcRadius - (x-arcCenter.x)*(x-arcCenter.x)) + arcCenter.y
			if x <= tempSub.center.x {
				x = tempSub.center.x
				y = tempSub.center.y
			} else if x >= tempAdd.center.x {
				x = tempAdd.center.x
				y = tempAdd.center.y
			}
			gesture.setTranslation(CGPoint.zero, inView: self.view)
			let rate = (x - tempSub.center.x) / (tempAdd.center.x - tempSub.center.x)
			if rate - tempLineRate > 0.05 || tempLineRate - rate > 0.05 {
				arcLayer.strokeStart = 1 - rate
				tempLineRate = rate
			}
			thumbView.center = CGPointMake(x, y)
			
			stateTemp = Int(16 + (30 - 16)*rate)
		case .Ended:
			if stateTemp != nil {
				currentKeyCode = HRAirKeyCode.Celsius16.rawValue + Byte(stateTemp! - 16)
			}
			break
		default: break
		}
	}
	
	
	func onButtonClicked(button: PrettyButton) {
		selectOneItem(button)
		switch button.tag {
		case 100, 101, 102, 103, 104:
			currentKeyCode = HRAirKeyCode.ModeAuto.rawValue + Byte(button.tag-100)
			self.stateMode = AirCtrlMode(rawValue: button.tag)
		case 105:
			if stateSpeed == nil {
				showSpeedLabel()
				stateSpeed = 0
			} else {
				stateSpeed! += 1
				if stateSpeed! == 4 {
					stateSpeed = 0
				}
			}
			currentKeyCode = HRAirKeyCode.SpeedAuto.rawValue + Byte(stateSpeed!)
		case 106:
			stateSwing = .Auto
			currentKeyCode = HRAirKeyCode.SwingAuto.rawValue
		case 107:
			stateSwing = .Hand
			currentKeyCode = HRAirKeyCode.SwingHand.rawValue
		case 108:
			if statePower == nil {
				statePower = false
			} else {
				statePower = !statePower!
			}
			if statePower! {
				currentKeyCode = HRAirKeyCode.PowerOn.rawValue
			} else {
				currentKeyCode = HRAirKeyCode.PowerOff.rawValue
			}
		default: break
		}
	}
	
	private func selectOneItem(item: UIView) {
		if todo != SHARETODO_RECORD_AIR_CTRL { return }
		if stateMode != nil && item !== modeWind
			&& item !== modeAuto && item !== modeCool
			&& item !== modeWarm && item !== modeDry {
				stateMode = nil
//				setMode()
		}
		if statePower != nil && item !== powerCtrl {
			statePower = nil
//			setPower()
		}
		if stateSwing != nil && item !== swingAuto
			&& item !== swingHand {
				stateSwing = nil
//				setSwing()
		}
		if stateSpeed != nil && item !== speedCtrl {
			stateSpeed = nil
		}
		if stateTemp != nil && item !== arcMaskView {
			stateTemp = nil
//			setTemp()
		}
	}
	
	///
	private func setPower() {
		if statePower == nil {	//为nil，设置为灰色状态
			powerCtrl.setImage(UIImage(named: "ico_power_light_gray"), forState: .Normal)
			powerCtrl.layer.backgroundColor = UIColor.clearColor().CGColor
			powerCtrl.layer.borderColor = UIColor.lightGrayColor().CGColor
			powerCtrlLabel.textColor = UIColor.lightGrayColor()
		} else if statePower! {
			powerCtrl.setImage(UIImage(named: "ico_power_bai"), forState: UIControlState.Normal)
			powerCtrl.layer.backgroundColor = UIColor.redColor().CGColor
			powerCtrl.layer.borderColor = UIColor.clearColor().CGColor
			powerCtrlLabel.textColor = UIColor.redColor()
		} else { //设置为关闭状态
			powerCtrl.setImage(UIImage(named: "ico_power_light_red"), forState: .Normal)
			powerCtrl.layer.backgroundColor = UIColor.clearColor().CGColor
			powerCtrl.layer.borderColor = UIColor.redColor().CGColor
			powerCtrlLabel.textColor = UIColor.redColor()
			//同时风速为nil
			stateSpeed = nil
		}
	}
	
	///设置模式
	private func setMode() {
		if stateMode != .Auto && modeAuto.selected {
			modeAuto.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
			modeAuto.layer.borderColor = UIColor.lightGrayColor().CGColor
			modeAuto.layer.backgroundColor = UIColor.clearColor().CGColor
			modeAuto.selected = false
		} else if stateMode != .Cool && modeCool.selected {
			modeCool.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
			modeCool.layer.borderColor = UIColor.lightGrayColor().CGColor
			modeCool.layer.backgroundColor = UIColor.clearColor().CGColor
			modeCool.selected = false
		} else if stateMode != .Warm && modeWarm.selected {
			modeWarm.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
			modeWarm.layer.borderColor = UIColor.lightGrayColor().CGColor
			modeWarm.layer.backgroundColor = UIColor.clearColor().CGColor
			modeWarm.selected = false
		} else if stateMode != .Dry && modeDry.selected {
			modeDry.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
			modeDry.layer.borderColor = UIColor.lightGrayColor().CGColor
			modeDry.layer.backgroundColor = UIColor.clearColor().CGColor
			modeDry.selected = false
		} else if stateMode != .Wind && modeWind.selected {
			modeWind.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
			modeWind.layer.borderColor = UIColor.lightGrayColor().CGColor
			modeWind.layer.backgroundColor = UIColor.clearColor().CGColor
			modeWind.selected = false
		}
		
		if stateMode != nil {
			var modeView: PrettyButton
			switch stateMode! {
			case .Cool:
				modeView = modeCool
			case .Auto:
				modeView = modeAuto
			case .Warm:
				modeView = modeWarm
			case .Dry:
				modeView = modeDry
			case .Wind:
				modeView = modeWind
			}
			modeView.setTitleColor(UIColor.whiteColor(), forState: .Normal)
			modeView.layer.borderColor = UIColor.clearColor().CGColor
			modeView.layer.backgroundColor = themeColor.CGColor
			modeView.selected = true
		}
	}
	
	
	
	///设置模式
	private func setMode(mode: AirCtrlMode?) {
		modeAuto.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
		modeAuto.layer.borderColor = UIColor.lightGrayColor().CGColor
		modeAuto.layer.backgroundColor = UIColor.clearColor().CGColor
		modeAuto.selected = false
		
		modeCool.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
		modeCool.layer.borderColor = UIColor.lightGrayColor().CGColor
		modeCool.layer.backgroundColor = UIColor.clearColor().CGColor
		modeCool.selected = false
		
		modeWarm.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
		modeWarm.layer.borderColor = UIColor.lightGrayColor().CGColor
		modeWarm.layer.backgroundColor = UIColor.clearColor().CGColor
		modeWarm.selected = false
		
		modeDry.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
		modeDry.layer.borderColor = UIColor.lightGrayColor().CGColor
		modeDry.layer.backgroundColor = UIColor.clearColor().CGColor
		modeDry.selected = false
		
		modeWind.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
		modeWind.layer.borderColor = UIColor.lightGrayColor().CGColor
		modeWind.layer.backgroundColor = UIColor.clearColor().CGColor
		modeWind.selected = false
		
		if mode != nil {
			var modeView: PrettyButton
			switch mode! {
			case .Cool:
				modeView = modeCool
			case .Auto:
				modeView = modeAuto
			case .Warm:
				modeView = modeWarm
			case .Dry:
				modeView = modeDry
			case .Wind:
				modeView = modeWind
			}
			modeView.setTitleColor(UIColor.whiteColor(), forState: .Normal)
			modeView.layer.borderColor = UIColor.clearColor().CGColor
			modeView.layer.backgroundColor = themeColor.CGColor
			modeView.selected = true
		}
		stateMode = mode
	}
	
	private func showSpeedLabel() {
		speedLabel.hidden = false
		let bounceAnim = CAKeyframeAnimation(keyPath: "transform.scale")
		//        bounceAnim.values = [1.0 ,1.4, 0.9, 1.15, 0.95, 1.02, 1.0]
		bounceAnim.values   = [1.0, 0.5, 1.1, 0.95, 1.05, 1.0]
		bounceAnim.duration = 0.8
		bounceAnim.fillMode = kCAFillModeForwards
		bounceAnim.removedOnCompletion = false
		bounceAnim.calculationMode = kCAAnimationCubic
		speedLabel.layer.addAnimation(bounceAnim, forKey: "bounceAnim")
	}
	
	private func setSpeed(){
		if stateSpeed == nil {
			if speedLabel.hidden {
				return
			}
			//隐藏speedLabel
			let anim = CABasicAnimation(keyPath: "transform.scale")
			anim.toValue = 0
			anim.duration = 0.4
			anim.fillMode = kCAFillModeForwards
			anim.removedOnCompletion = false
			anim.delegate = self
			speedLabel.layer.addAnimation(anim, forKey: "speeLabelDismiss")
			speedCtrl.layer.removeAnimationForKey("speeCtrlRatation")
			speedCtrl.layer.backgroundColor = UIColor.clearColor().CGColor
			speedCtrl.layer.borderColor = UIColor.lightGrayColor().CGColor
			speedCtrl.selected = false
			return
		}
		speedCtrl.layer.backgroundColor = themeColor.CGColor
		speedCtrl.layer.borderColor = UIColor.clearColor().CGColor
		speedCtrl.selected = true
		if speedLabel.hidden {
			showSpeedLabel()
		}
		if stateSpeed! == 0 {
			speedLabel.text = "自动"
		} else {
			speedLabel.text = "\(stateSpeed!)X"
		}
		
		let anim = CABasicAnimation(keyPath: "transform.rotation.z")
		anim.toValue = CGFloat(M_PI * 2) * CGFloat(stateSpeed!+1)
		anim.duration = 5
		anim.repeatCount = 10000
		anim.delegate = self
		anim.cumulative = true
		speedCtrl.layer.addAnimation(anim, forKey: "speeCtrlRatation")
		
	}
	
	 func animationDidStop(anim: CAAnimation, finished flag: Bool) {
		if anim === speedLabel.layer.animationForKey("speeLabelDismiss") {
			
			speedLabel.hidden = true
		}
		else if anim === speedCtrl.layer.animationForKey("speeCtrlRatation") {
			
		}
	}
	
	
	///设置温度
	private func setTemp() {
		if stateTemp == nil {
			tempLabel.text = "--"
		} else {
			tempLabel.text = "\(stateTemp!)"
		}
	}
	
	/// 被动设置温度控制条
	private func setTempViewPassive() {
		
		let originX = thumbView.center.x
		let targetX = tempSub.center.x + (tempAdd.center.x - tempSub.center.x) * (CGFloat(stateTemp! - 16) / 14)
		if originX == targetX { return }
		
		let anim = POPCustomAnimation { (obj, customAnim) -> Bool in
			let x: CGFloat
			if originX < targetX {
				x = self.thumbView.center.x + CGFloat(customAnim.elapsedTime*200)
			} else {
				x = self.thumbView.center.x - CGFloat(customAnim.elapsedTime*200)
			}
			let y = sqrt(self.arcRadius*self.arcRadius - (x-self.arcCenter.x)*(x-self.arcCenter.x)) + self.arcCenter.y
			self.thumbView.center = CGPointMake(x, y)
			let rate = (x - self.tempSub.center.x) / (self.tempAdd.center.x - self.tempSub.center.x)
			if rate - self.tempLineRate > 0.05 || self.tempLineRate - rate > 0.05 {
				self.arcLayer.strokeStart = 1 - rate
				self.tempLineRate = rate
			}
			
			if originX < targetX && self.thumbView.center.x >= targetX {
				return false
			}
			if originX > targetX && self.thumbView.center.x <= targetX {
				return false
			}
			return true
		}
		
		thumbView.pop_addAnimation(anim, forKey: "moveThumb")
	}
	
	///设置风向
	private func setSwing() {
		if stateSwing == nil {
			swingHand.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
			swingHand.layer.borderColor = UIColor.lightGrayColor().CGColor
			swingHand.layer.backgroundColor = UIColor.clearColor().CGColor
			swingHand.selected = false
			
			swingAuto.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
			swingAuto.layer.borderColor = UIColor.lightGrayColor().CGColor
			swingAuto.layer.backgroundColor = UIColor.clearColor().CGColor
			swingAuto.selected = false
		} else if stateSwing! == .Auto {
			swingHand.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
			swingHand.layer.borderColor = UIColor.lightGrayColor().CGColor
			swingHand.layer.backgroundColor = UIColor.clearColor().CGColor
			swingHand.selected = false
			
			swingAuto.setTitleColor(UIColor.whiteColor(), forState: .Normal)
			swingAuto.layer.borderColor = UIColor.clearColor().CGColor
			swingAuto.layer.backgroundColor = themeColor.CGColor
			swingAuto.selected = true
		} else {
			swingAuto.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
			swingAuto.layer.borderColor = UIColor.lightGrayColor().CGColor
			swingAuto.layer.backgroundColor = UIColor.clearColor().CGColor
			swingAuto.selected = false
			
			swingHand.setTitleColor(UIColor.whiteColor(), forState: .Normal)
			swingHand.layer.borderColor = UIColor.clearColor().CGColor
			swingHand.layer.backgroundColor = themeColor.CGColor
			swingHand.selected = true
		}
	}
	
//MARK: - HRInfraredDelegate 
	
	func infraredTransmit(initInfrared appDevID: UInt16, devType: Byte, tag: Byte, result: Bool) {
		//如果反馈的不是当前设备
		if UInt32(appDevID) != appDevice?.appDevID && tag != frameTag {
			return
		}
		if !result {
			tipsView.show("初始化失败！", duration: 3.0)
		}
	}
	
	func infraredTransmit(normalOperated appDevID: UInt16, devType: Byte, tag: Byte, keyCode: Byte, codeIndex: UInt32, result: Bool) {
		//如果反馈的不是当前设备
		if UInt32(appDevID) != appDevice?.appDevID || tag == frameTag {
			return
		}
		
		switch keyCode {
		case HRAirKeyCode.Celsius16.rawValue...HRAirKeyCode.Celsius30.rawValue:
			stateTemp = 16 + Int(keyCode - HRAirKeyCode.Celsius16.rawValue)
			Log.info("AirCtrlViewContrller.onNormalOperated: 温度更改为\(stateTemp)度.")
			setTempViewPassive()
		case HRAirKeyCode.ModeAuto.rawValue...HRAirKeyCode.ModeHeating.rawValue:
			Log.info("AirCtrlViewContrller.onNormalOperated: 模式更改了.")
			stateMode = AirCtrlMode(rawValue: AirCtrlMode.Auto.rawValue + Int(keyCode - HRAirKeyCode.ModeAuto.rawValue))
			
		case HRAirKeyCode.SpeedAuto.rawValue...HRAirKeyCode.SpeedHigh.rawValue:
			Log.info("AirCtrlViewContrller.onNormalOperated: 风速更改了.")
			stateSpeed = Int(keyCode - HRAirKeyCode.SpeedAuto.rawValue)

		case HRAirKeyCode.SwingAuto.rawValue...HRAirKeyCode.SwingHand.rawValue:
			stateSwing =
				keyCode == HRAirKeyCode.SwingAuto.rawValue ? .Auto : .Hand
		case HRAirKeyCode.PowerOn.rawValue, HRAirKeyCode.PowerOff.rawValue:
			statePower = keyCode == HRAirKeyCode.PowerOn.rawValue
		default: break
		}

	}
	
	enum AirCtrlMode: Int{
		case Auto	= 100
		case Cool	= 101
		case Dry	= 102
		case Wind	= 103
		case Warm	= 104
	}
	
	enum AirCtrlSwing {
		case Auto
		case Hand
	}
}

//MARK: - AirCtrlViewControllerDelegate

protocol AirCtrlViewControllerDelegate: class {

	/**
	当前选择的KeyCode
	
	- parameter code: keyCode
	*/
	func airCtrlResult(recordKeyCode code: Byte, device: HRDevice!)
}
