//
//  TVCtrlViewController.swift
//  huarui
//
//  Created by sswukang on 15/3/28.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import UIKit

class TVCtrlViewController: UIViewController, HRInfraredLearningDelegate, UIAlertViewDelegate {
	
	var todo = SHARETODO_NOTHING
	var currentKeyCode: Byte?
    var appDevice: HRApplianceApplyDev!
	var actionHandler: ((Byte, HRDevice) -> Void)?
	weak var delegate: TVCtrlViewControllerDelegate?
	
	private var tipsView: TipsView!
	private var containerView: UIView!
	private var muteBtn: PrettyButton!
	private var powerBtn: PrettyButton!
	private var menuBtn: PrettyButton!
	private var btn1: PrettyButton!
	private var btn2: PrettyButton!
	private var btn3: PrettyButton!
	private var btn4: PrettyButton!
	private var btn5: PrettyButton!
	private var btn6: PrettyButton!
	private var btn7: PrettyButton!
	private var btn8: PrettyButton!
	private var btn9: PrettyButton!
	private var btnBack: PrettyButton!
	private var btn0: PrettyButton!
	private var btnSelect: PrettyButton!
	private var btnVolAdd: PrettyButton!
	private var btnChAdd: PrettyButton!
	private var btnOK: PrettyButton!
	private var btnVolSub: PrettyButton!
	private var btnChSub: PrettyButton!
	private var btnUp: UIButton!
	private var btnDown: UIButton!
	private var btnLeft: UIButton!
	private var btnRight: UIButton!
	
	private let backColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
	private let textColor = UIColor(red: 105/255.0, green: 181/255.0, blue: 1.0, alpha: 1.0)
	private let selectedColor = APP.param.selectedColor
	
//MARK: - UIViewController 
	
    override func viewDidLoad() {
        super.viewDidLoad()
		view.layer.contents = UIImage(named: APP.param.backgroundImgName)?.CGImage
		if let app = appDevice {
			self.title = app.name
		}
		if todo == SHARETODO_RECORD_TV_CTRL {
			let cancelButton = UIBarButtonItem(title: "取消", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(TVCtrlViewController.onCancelButtonClicked(_:)))
			navigationItem.leftBarButtonItem = cancelButton
			let doneButton = UIBarButtonItem(title: "完成", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(TVCtrlViewController.onDoneButtonClicked(_:)))
			navigationItem.rightBarButtonItem = doneButton
		} else if todo == SHARETODO_LEARNING_TV_CTRL {
			let doneButton = UIBarButtonItem(title: "完成", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(TVCtrlViewController.onLearningDoneButtonClicked(_:)))
			navigationItem.leftBarButtonItem = doneButton
		}
        addViews()
        tipsView = TipsView(frame: CGRectMake(0, 0, view.frame.width, 30))
        self.view.addSubview(tipsView)
		
	}
	
	override func viewDidAppear(animated: Bool) {
		if appDevice == nil {
			self.navigationController?.popViewControllerAnimated(true)
			return 
		}
	}
	
	//8行3列
	func addViews() {
		let containerH = self.view.frame.height - self.navigationController!.navigationBar.frame.height - UIApplication.sharedApplication().statusBarFrame.height - 5
		if self.todo == SHARETODO_LEARNING_TV_CTRL {	//红外学习
			containerView = UIView(frame: CGRectMake(0, 80, self.view.frame.width, containerH-80))
			//红外学习的操作按键
			let maskView = UIView(frame: CGRectMake(0, 0, self.view.frame.width, containerView.frame.minY))
			maskView.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.3)
			let learnBtn = PrettyButton(frame: CGRectMake(0, maskView.frame.maxY - 55, 200, 48))
			learnBtn.center.x = maskView.center.x
			learnBtn.backgroundColor = UIColor.orangeColor()
			learnBtn.hightLightColor = UIColor.orangeColor().colorWithAdjustBrightness(-0.3)
			learnBtn.layer.cornerRadius = 10
			learnBtn.setTitle("开始学习", forState: .Normal)
			learnBtn.setTitle("结束学习", forState: .Selected)
			learnBtn.addTarget(self, action: #selector(TVCtrlViewController.learnButtonClicked(_:)), forControlEvents: .TouchUpInside)
			
			loadingView = UIActivityIndicatorView(frame: CGRectMake(learnBtn.frame.minX - maskView.frame.height, 0, maskView.frame.height, maskView.frame.height))
			loadingView?.activityIndicatorViewStyle = .WhiteLarge
			loadingView?.hidesWhenStopped = true
			
			self.view.addSubview(maskView)
			self.view.addSubview(learnBtn)
			self.view.addSubview(loadingView!)
			HRProcessCenter.shareInstance().delegates.infraredLearningDelegate = self
			
		} else {
			containerView = UIView(frame: CGRectMake(0, 0, self.view.frame.width, containerH))
		}
		self.view.addSubview(containerView)
		//按键的高度
		var btnW = containerView.frame.width / 5
		var btnH = btnW * 2 / 3
		var cornerRadius = btnH / 2
		
		//按键之间的间隙
		var gapW = (containerView.frame.width - (btnW * 3)) / 4
		var gapH = (containerView.frame.height - (btnH * 8)) / 10
		
		if gapH < 10 {
			btnH = (containerView.frame.height - 10 * 10) / 8
			btnW = btnH * 3 / 2
			cornerRadius = btnH / 2
			gapW = (containerView.frame.width - (btnW * 3)) / 4
			gapH = (containerView.frame.height - (btnH * 8)) / 10
		}
		
		var textFont:UIFont!
		//按键的字体大小，最小不能小于18
		textFont = UIFont.systemFontOfSize(btnH * 0.3 < 18 ? 18 : btnH * 0.3)
		//第一个按键的位置
		var frame = CGRectMake(gapW, gapH * 2, btnW, btnH)
		//静音键
		muteBtn = PrettyButton(frame: frame)
		muteBtn.cornerRadius = cornerRadius
		muteBtn.layer.backgroundColor = backColor.CGColor
		muteBtn.setTitle("静音", forState: UIControlState.Normal)
		muteBtn.titleLabel?.font = textFont
		muteBtn.setTitleColor(textColor, forState: .Normal)
		muteBtn.setTitleColor(UIColor.whiteColor(), forState: .Selected)
		muteBtn.addTarget(self, action: #selector(TVCtrlViewController.buttonClicked(_:)), forControlEvents: UIControlEvents.TouchUpInside)
		
		///电源键
		frame = CGRectMake(frame.maxX + gapW, frame.minY, btnW, btnH)
		powerBtn = PrettyButton(frame: frame)
		powerBtn.cornerRadius = cornerRadius
		powerBtn.titleLabel?.font = textFont
		powerBtn.imageView?.contentMode = .ScaleAspectFit
		powerBtn.setImage(UIImage(named: "ico_power_bai"), forState: .Selected)
		if todo == SHARETODO_LEARNING_TV_CTRL {
			powerBtn.layer.backgroundColor = backColor.CGColor
			powerBtn.setImage(UIImage(named: "ico_power_light_red"), forState: .Normal)
		} else {
			powerBtn.layer.backgroundColor = UIColor.redColor().CGColor
			powerBtn.setImage(UIImage(named: "ico_power_bai"), forState: .Normal)
		}
		powerBtn.addTarget(self, action: #selector(TVCtrlViewController.buttonClicked(_:)), forControlEvents: UIControlEvents.TouchUpInside)
		
		///菜单键
		frame = CGRectMake(frame.maxX + gapW, frame.minY, btnW, btnH)
		menuBtn = PrettyButton(frame: frame)
		menuBtn.cornerRadius = cornerRadius
		menuBtn.layer.backgroundColor = backColor.CGColor
		menuBtn.setTitle("菜单", forState: UIControlState.Normal)
		menuBtn.titleLabel?.font = textFont
		menuBtn.setTitleColor(textColor, forState: UIControlState.Normal)
		menuBtn.setTitleColor(UIColor.whiteColor(), forState: .Selected)
		menuBtn.addTarget(self, action: #selector(TVCtrlViewController.buttonClicked(_:)), forControlEvents: UIControlEvents.TouchUpInside)
		
		//1
		frame = CGRectMake(gapW, frame.maxY + gapH, btnW, btnH)
		btn1 = PrettyButton(frame: frame)
		btn1.cornerRadius = cornerRadius
		btn1.layer.backgroundColor = backColor.CGColor
		btn1.setTitle("1", forState: UIControlState.Normal)
		btn1.titleLabel?.font = textFont
		btn1.setTitleColor(textColor, forState: UIControlState.Normal)
		btn1.setTitleColor(UIColor.whiteColor(), forState: .Selected)
		btn1.addTarget(self, action: #selector(TVCtrlViewController.buttonClicked(_:)), forControlEvents: UIControlEvents.TouchUpInside)
		
		//2
		frame = CGRectMake(frame.maxX + gapW, frame.minY, btnW, btnH)
		btn2 = PrettyButton(frame: frame)
		btn2.cornerRadius = cornerRadius
		btn2.layer.backgroundColor = backColor.CGColor
		btn2.setTitle("2", forState: UIControlState.Normal)
		btn2.titleLabel?.font = textFont
		btn2.setTitleColor(textColor, forState: UIControlState.Normal)
		btn2.setTitleColor(UIColor.whiteColor(), forState: .Selected)
		btn2.addTarget(self, action: #selector(TVCtrlViewController.buttonClicked(_:)), forControlEvents: UIControlEvents.TouchUpInside)
		
		//3
		frame = CGRectMake(frame.maxX + gapW, frame.minY, btnW, btnH)
		btn3 = PrettyButton(frame: frame)
		btn3.cornerRadius = cornerRadius
		btn3.layer.backgroundColor = backColor.CGColor
		btn3.setTitle("3", forState: UIControlState.Normal)
		btn3.titleLabel?.font = textFont
		btn3.setTitleColor(textColor, forState: UIControlState.Normal)
		btn3.setTitleColor(UIColor.whiteColor(), forState: .Selected)
		btn3.addTarget(self, action: #selector(TVCtrlViewController.buttonClicked(_:)), forControlEvents: UIControlEvents.TouchUpInside)
		
		//4
		frame = CGRectMake(gapW, frame.maxY + gapH, btnW, btnH)
		btn4 = PrettyButton(frame: frame)
		btn4.cornerRadius = cornerRadius
		btn4.layer.backgroundColor = backColor.CGColor
		btn4.setTitle("4", forState: UIControlState.Normal)
		btn4.titleLabel?.font = textFont
		btn4.setTitleColor(textColor, forState: UIControlState.Normal)
		btn4.setTitleColor(UIColor.whiteColor(), forState: .Selected)
		btn4.addTarget(self, action: #selector(TVCtrlViewController.buttonClicked(_:)), forControlEvents: UIControlEvents.TouchUpInside)
		
		//5
		frame = CGRectMake(frame.maxX + gapW, frame.minY, btnW, btnH)
		btn5 = PrettyButton(frame: frame)
		btn5.cornerRadius = cornerRadius
		btn5.layer.backgroundColor = backColor.CGColor
		btn5.setTitle("5", forState: UIControlState.Normal)
		btn5.titleLabel?.font = textFont
		btn5.setTitleColor(textColor, forState: UIControlState.Normal)
		btn5.setTitleColor(UIColor.whiteColor(), forState: .Selected)
		btn5.addTarget(self, action: #selector(TVCtrlViewController.buttonClicked(_:)), forControlEvents: UIControlEvents.TouchUpInside)
		
		//6
		frame = CGRectMake(frame.maxX + gapW, frame.minY, btnW, btnH)
		btn6 = PrettyButton(frame: frame)
		btn6.cornerRadius = cornerRadius
		btn6.layer.backgroundColor = backColor.CGColor
		btn6.setTitle("6", forState: UIControlState.Normal)
		btn6.titleLabel?.font = textFont
		btn6.setTitleColor(textColor, forState: UIControlState.Normal)
		btn6.setTitleColor(UIColor.whiteColor(), forState: .Selected)
		btn6.addTarget(self, action: #selector(TVCtrlViewController.buttonClicked(_:)), forControlEvents: UIControlEvents.TouchUpInside)
		
		//7
		frame = CGRectMake(gapW, frame.maxY + gapH, btnW, btnH)
		btn7 = PrettyButton(frame: frame)
		btn7.cornerRadius = cornerRadius
		btn7.layer.backgroundColor = backColor.CGColor
		btn7.setTitle("7", forState: UIControlState.Normal)
		btn7.titleLabel?.font = textFont
		btn7.setTitleColor(textColor, forState: UIControlState.Normal)
		btn7.setTitleColor(UIColor.whiteColor(), forState: .Selected)
		btn7.addTarget(self, action: #selector(TVCtrlViewController.buttonClicked(_:)), forControlEvents: UIControlEvents.TouchUpInside)
		
		//8
		frame = CGRectMake(frame.maxX + gapW, frame.minY, btnW, btnH)
		btn8 = PrettyButton(frame: frame)
		btn8.cornerRadius = cornerRadius
		btn8.layer.backgroundColor = backColor.CGColor
		btn8.setTitle("8", forState: UIControlState.Normal)
		btn8.titleLabel?.font = textFont
		btn8.setTitleColor(textColor, forState: UIControlState.Normal)
		btn8.setTitleColor(UIColor.whiteColor(), forState: .Selected)
		btn8.addTarget(self, action: #selector(TVCtrlViewController.buttonClicked(_:)), forControlEvents: UIControlEvents.TouchUpInside)
		
		//9
		frame = CGRectMake(frame.maxX + gapW, frame.minY, btnW, btnH)
		btn9 = PrettyButton(frame: frame)
		btn9.cornerRadius = cornerRadius
		btn9.layer.backgroundColor = backColor.CGColor
		btn9.setTitle("9", forState: UIControlState.Normal)
		btn9.titleLabel?.font = textFont
		btn9.setTitleColor(textColor, forState: UIControlState.Normal)
		btn9.setTitleColor(UIColor.whiteColor(), forState: .Selected)
		btn9.addTarget(self, action: #selector(TVCtrlViewController.buttonClicked(_:)), forControlEvents: UIControlEvents.TouchUpInside)
		
		//返回
		frame = CGRectMake(gapW, frame.maxY + gapH, btnW, btnH)
		btnBack = PrettyButton(frame: frame)
		btnBack.cornerRadius = cornerRadius
		btnBack.layer.backgroundColor = backColor.CGColor
		btnBack.setTitle("返回", forState: UIControlState.Normal)
		btnBack.titleLabel?.font = textFont
		btnBack.setTitleColor(textColor, forState: UIControlState.Normal)
		btnBack.setTitleColor(UIColor.whiteColor(), forState: .Selected)
		btnBack.addTarget(self, action: #selector(TVCtrlViewController.buttonClicked(_:)), forControlEvents: UIControlEvents.TouchUpInside)
		
		//0
		frame = CGRectMake(frame.maxX + gapW, frame.minY, btnW, btnH)
		btn0 = PrettyButton(frame: frame)
		btn0.cornerRadius = cornerRadius
		btn0.layer.backgroundColor = backColor.CGColor
		btn0.setTitle("0", forState: UIControlState.Normal)
		btn0.titleLabel?.font = textFont
		btn0.setTitleColor(textColor, forState: UIControlState.Normal)
		btn0.setTitleColor(UIColor.whiteColor(), forState: .Selected)
		btn0.addTarget(self, action: #selector(TVCtrlViewController.buttonClicked(_:)), forControlEvents: UIControlEvents.TouchUpInside)
		
		//选台 -/--
		frame = CGRectMake(frame.maxX + gapW, frame.minY, btnW, btnH)
		btnSelect = PrettyButton(frame: frame)
		btnSelect.cornerRadius = cornerRadius
		btnSelect.layer.backgroundColor = backColor.CGColor
		btnSelect.setTitle("-/--", forState: UIControlState.Normal)
		btnSelect.titleLabel?.font = textFont
		btnSelect.setTitleColor(textColor, forState: UIControlState.Normal)
		btnSelect.setTitleColor(UIColor.whiteColor(), forState: .Selected)
		btnSelect.addTarget(self, action: #selector(TVCtrlViewController.buttonClicked(_:)), forControlEvents: UIControlEvents.TouchUpInside)
		
		//V+
		frame = CGRectMake(gapW, frame.maxY + gapH, btnW, btnH)
		btnVolAdd = PrettyButton(frame: frame)
		btnVolAdd.cornerRadius = cornerRadius
		btnVolAdd.layer.backgroundColor = backColor.CGColor
		btnVolAdd.setTitle("V+", forState: UIControlState.Normal)
		btnVolAdd.titleLabel?.font = textFont
		btnVolAdd.setTitleColor(textColor, forState: UIControlState.Normal)
		btnVolAdd.setTitleColor(UIColor.whiteColor(), forState: .Selected)
		btnVolAdd.addTarget(self, action: #selector(TVCtrlViewController.buttonClicked(_:)), forControlEvents: UIControlEvents.TouchUpInside)
		
		//CH+
		frame = CGRectMake(frame.maxX + gapW * 2 + btnW, frame.minY, btnW, btnH)
		btnChAdd = PrettyButton(frame: frame)
		btnChAdd.cornerRadius = cornerRadius
		btnChAdd.layer.backgroundColor = backColor.CGColor
		btnChAdd.setTitle("CH+", forState: UIControlState.Normal)
		btnChAdd.titleLabel?.font = textFont
		btnChAdd.setTitleColor(textColor, forState: UIControlState.Normal)
		btnChAdd.setTitleColor(UIColor.whiteColor(), forState: .Selected)
		btnChAdd.addTarget(self, action: #selector(TVCtrlViewController.buttonClicked(_:)), forControlEvents: UIControlEvents.TouchUpInside)
		
		//OK
		let okRd = btnH + 5
		frame = CGRectMake(self.view.frame.width / 2 - okRd / 2, frame.maxY + gapH, okRd, okRd)
		btnOK = PrettyButton(frame: frame)
		btnOK.cornerRadius = okRd / 2
		btnOK.layer.backgroundColor = backColor.CGColor
		btnOK.setTitle("OK", forState: UIControlState.Normal)
		btnOK.titleLabel?.font = textFont
		btnOK.setTitleColor(textColor, forState: UIControlState.Normal)
		btnOK.setTitleColor(UIColor.whiteColor(), forState: .Selected)
		btnOK.addTarget(self, action: #selector(TVCtrlViewController.buttonClicked(_:)), forControlEvents: UIControlEvents.TouchUpInside)
		
		//V-
		frame = CGRectMake(gapW, frame.maxY + gapH, btnW, btnH)
		btnVolSub = PrettyButton(frame: frame)
		btnVolSub.cornerRadius = cornerRadius
		btnVolSub.layer.backgroundColor = backColor.CGColor
		btnVolSub.setTitle("V-", forState: UIControlState.Normal)
		btnVolSub.titleLabel?.font = textFont
		btnVolSub.setTitleColor(textColor, forState: UIControlState.Normal)
		btnVolSub.setTitleColor(UIColor.whiteColor(), forState: .Selected)
		btnVolSub.addTarget(self, action: #selector(TVCtrlViewController.buttonClicked(_:)), forControlEvents: UIControlEvents.TouchUpInside)
		
		//CH-
		frame = CGRectMake(frame.maxX + gapW * 2 + btnW, frame.minY, btnW, btnH)
		btnChSub = PrettyButton(frame: frame)
		btnChSub.cornerRadius = cornerRadius
		btnChSub.layer.backgroundColor = backColor.CGColor
		btnChSub.setTitle("CH-", forState: UIControlState.Normal)
		btnChSub.titleLabel?.font = textFont
		btnChSub.setTitleColor(textColor, forState: UIControlState.Normal)
		btnChSub.setTitleColor(UIColor.whiteColor(), forState: .Selected)
		btnChSub.addTarget(self, action: #selector(TVCtrlViewController.buttonClicked(_:)), forControlEvents: UIControlEvents.TouchUpInside)
		
		
		frame = btnOK.frame
		//导航按键的宽高
		let navBtnW = btnW * 1.6
		let navBtnH = navBtnW * 0.45
		//上
		btnUp   = UIButton()
		btnUp.setBackgroundImage(UIImage(named: "ico_control_up"), forState: UIControlState.Normal)
		btnUp.setBackgroundImage(UIImage(named: "ico_control_up_select"), forState: UIControlState.Selected)
		btnUp.frame = CGRectMake(btnOK.center.x - navBtnW / 2, frame.minY - navBtnH, navBtnW, navBtnH)
		btnUp.addTarget(self, action: #selector(TVCtrlViewController.buttonClicked(_:)), forControlEvents: UIControlEvents.TouchUpInside)
		
		//下
		btnDown = UIButton()
		btnDown.setBackgroundImage(UIImage(named: "ico_control_down"), forState: UIControlState.Normal)
		btnDown.setBackgroundImage(UIImage(named: "ico_control_down_select"), forState: .Selected)
		btnDown.frame = CGRectMake(btnOK.center.x - navBtnW / 2, frame.maxY, navBtnW, navBtnH)
		btnDown.addTarget(self, action: #selector(TVCtrlViewController.buttonClicked(_:)), forControlEvents: UIControlEvents.TouchUpInside)
		
		//左
		btnLeft = UIButton()
		btnLeft.setBackgroundImage(UIImage(named: "ico_control_left"), forState: UIControlState.Normal)
		btnLeft.setBackgroundImage(UIImage(named: "ico_control_left_select"), forState: .Selected)
		btnLeft.frame = CGRectMake(frame.minX - navBtnH, btnOK.center.y - navBtnW / 2, navBtnH, navBtnW)
		btnLeft.addTarget(self, action: #selector(TVCtrlViewController.buttonClicked(_:)), forControlEvents: UIControlEvents.TouchUpInside)
		
		//右
		btnRight = UIButton()
		btnRight.setBackgroundImage(UIImage(named: "ico_control_right"), forState: UIControlState.Normal)
		btnRight.setBackgroundImage(UIImage(named: "ico_control_right_select"), forState: .Selected)
		btnRight.frame = CGRectMake(frame.maxX, btnOK.center.y - navBtnW / 2, navBtnH, navBtnW)
		btnRight.addTarget(self, action: #selector(TVCtrlViewController.buttonClicked(_:)), forControlEvents: UIControlEvents.TouchUpInside)
		
		
		containerView.addSubview(muteBtn)
		containerView.addSubview(powerBtn)
		containerView.addSubview(menuBtn)
		containerView.addSubview(btn1)
		containerView.addSubview(btn2)
		containerView.addSubview(btn3)
		containerView.addSubview(btn4)
		containerView.addSubview(btn5)
		containerView.addSubview(btn6)
		containerView.addSubview(btn7)
		containerView.addSubview(btn8)
		containerView.addSubview(btn9)
		containerView.addSubview(btnBack)
		containerView.addSubview(btn0)
		containerView.addSubview(btnSelect)
		containerView.addSubview(btnVolAdd)
		containerView.addSubview(btnChAdd)
		containerView.addSubview(btnOK)
		containerView.addSubview(btnVolSub)
		containerView.addSubview(btnChSub)
		containerView.addSubview(btnUp)
		containerView.addSubview(btnDown)
		containerView.addSubview(btnLeft)
		containerView.addSubview(btnRight)
		
        muteBtn.tag   = Int(HRTVKeyCode.Mute.rawValue)
        powerBtn.tag  = Int(HRTVKeyCode.StandBy.rawValue)
        menuBtn.tag   = Int(HRTVKeyCode.Menu.rawValue)
        btn1.tag      = Int(HRTVKeyCode.NumOne.rawValue)
        btn2.tag      = Int(HRTVKeyCode.NumTwo.rawValue)
        btn3.tag      = Int(HRTVKeyCode.NumThree.rawValue)
        btn4.tag      = Int(HRTVKeyCode.NumFour.rawValue)
        btn5.tag      = Int(HRTVKeyCode.NumFive.rawValue)
        btn6.tag      = Int(HRTVKeyCode.NumSix.rawValue)
        btn7.tag      = Int(HRTVKeyCode.NumSeven.rawValue)
        btn8.tag      = Int(HRTVKeyCode.NumEight.rawValue)
        btn9.tag      = Int(HRTVKeyCode.NumNine.rawValue)
        btnBack.tag   = Int(HRTVKeyCode.Return.rawValue)
        btn0.tag      = Int(HRTVKeyCode.NumZero.rawValue)
        btnSelect.tag = Int(HRTVKeyCode.SingleAndDouble.rawValue)
        btnVolAdd.tag = Int(HRTVKeyCode.VolumeAdd.rawValue)
        btnChAdd.tag  = Int(HRTVKeyCode.ChannelAdd.rawValue)
        btnOK.tag     = Int(HRTVKeyCode.DpadOk.rawValue)
        btnVolSub.tag = Int(HRTVKeyCode.VolumeSub.rawValue)
        btnChSub.tag  = Int(HRTVKeyCode.ChannelSub.rawValue)
        btnUp.tag     = Int(HRTVKeyCode.DpadUp.rawValue)
        btnDown.tag   = Int(HRTVKeyCode.DpadDown.rawValue)
        btnLeft.tag   = Int(HRTVKeyCode.DpadLeft.rawValue)
        btnRight.tag  = Int(HRTVKeyCode.DpadRight.rawValue)
		
		prepareForInfraredLearning()
	}
	
	///为红外学习准备
	private func prepareForInfraredLearning() {
		if todo != SHARETODO_LEARNING_TV_CTRL { return }
		for key in appDevice.learnKeys {
			self.selectItems(Int(key.keyCode))
		}
        muteBtn.shouldHighlight   = false
        powerBtn.shouldHighlight  = false
        menuBtn.shouldHighlight   = false
        btn1.shouldHighlight      = false
        btn2.shouldHighlight      = false
        btn3.shouldHighlight      = false
        btn4.shouldHighlight      = false
        btn5.shouldHighlight      = false
        btn6.shouldHighlight      = false
        btn7.shouldHighlight      = false
        btn8.shouldHighlight      = false
        btn9.shouldHighlight      = false
        btn0.shouldHighlight      = false
        btnBack.shouldHighlight   = false
        btnSelect.shouldHighlight = false
        btnOK.shouldHighlight     = false
        btnVolAdd.shouldHighlight = false
        btnVolSub.shouldHighlight = false
        btnChAdd.shouldHighlight  = false
        btnChSub.shouldHighlight  = false
	}
	
//MARK: - UI事件
	
	@objc private func onCancelButtonClicked(button: UIBarButtonItem) {
		currentKeyCode = nil
		if self.navigationController?.popViewControllerAnimated(true) == nil {
			self.dismissViewControllerAnimated(true, completion: nil)
		}
	}
	
	@objc private func onDoneButtonClicked(button: UIBarButtonItem) {
//		performSegueWithIdentifier("unwindToCreateSceneViewController", sender: self)
		if currentKeyCode != nil && appDevice != nil {
			delegate?.tvCtrlResult(recordKeyCode: currentKeyCode!, device: appDevice)
			actionHandler?(currentKeyCode!, appDevice)
		}
		if self.navigationController?.popViewControllerAnimated(true) == nil {
			self.dismissViewControllerAnimated(true, completion: nil)
		}
	}


    func buttonClicked(button: UIButton) {
        currentKeyCode = Byte(button.tag)
		
		if todo == SHARETODO_RECORD_TV_CTRL {
			selectedOneItem(button)
			return
		} else if todo == SHARETODO_LEARNING_TV_CTRL { //红外学习
			if isStartLearning {
				HR8000Service.shareInstance().learningInfraredRecordKey(appDevice, keyCode: currentKeyCode!, result: { (error) in
					if let err = error {
						KVNProgress.showErrorWithStatus("学习失败：\(err.domain)")
					} else {
						button.selected = true
						button.startBackgroundTransition(self.backColor, toColor: self.selectedColor)
						self.tipsView.show("请将遥控器对准红外学习器，再按下按键来学习", duration: 120)
						KVNProgress.showWithStatus("等待完成...")
						self.isWaitForLearning = true
						
						self.recordKeyTimer?.invalidate()
						self.recordKeyTimer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: #selector(TVCtrlViewController.recordKeyTimeout(_:)), userInfo: button, repeats: false)
					}
				})
			}
			return
		}
		
        if let key = getIRStudyState(currentKeyCode!) {
			HR8000Service.shareInstance().operateInfrared(self.appDevice, infraredKey: key, tag: 45, callback: {
                (error) in
				if let err = error {
					self.tipsView.show(err.domain, duration: 2.0)
				} else{
					self.tipsView.show("操作成功", duration: 1.0)
				}
            })
        } else {
            tipsView.show("该按键还没有学习红外码！", duration: 1.0)
        }
	}
	
	private func selectedOneItem(button: UIButton)  {
		for v in containerView.subviews {
			if let subBtn = v as? UIButton {
				subBtn.selected = subBtn === button
				switch Byte(subBtn.tag) {
				case HRTVKeyCode.DpadUp.rawValue, HRTVKeyCode.DpadDown.rawValue,HRTVKeyCode.DpadLeft.rawValue, HRTVKeyCode.DpadRight.rawValue:
					break
				case HRTVKeyCode.StandBy.rawValue:
					subBtn.layer.backgroundColor = subBtn.selected ?
						selectedColor.CGColor : UIColor.redColor().CGColor
				default:
					subBtn.layer.backgroundColor
						= subBtn.selected ? selectedColor.CGColor : backColor.CGColor
				}
			}
		}
	}
	
	private func selectItems(tag: Int)  {
		if tag == 0 {
			btn0.selected = true
			btn0.layer.backgroundColor = selectedColor.CGColor
			return
		}
		guard let button = containerView.viewWithTag(tag) as? UIButton else {
			return
		}
		button.selected = true
		switch Byte(tag) {
		case HRTVKeyCode.DpadUp.rawValue, HRTVKeyCode.DpadDown.rawValue,HRTVKeyCode.DpadLeft.rawValue, HRTVKeyCode.DpadRight.rawValue:
			break
		default:
			button.layer.backgroundColor = selectedColor.CGColor
		}
	}
	
	
    private func getIRStudyState(code: Byte) -> HRInfraredKey? {
        for key in appDevice.learnKeys {
            if key.keyCode == code {
                return key
            }
        }
        return nil
	}
	
	//MARK: - 红外学习
	
	private var loadingView : UIActivityIndicatorView?
	private var recordKeyTimer: NSTimer?
	lazy private var isStartLearning = false
	lazy private var isWaitForLearning = false
	
	@objc private func learnButtonClicked(button: UIButton) {
		if !button.selected {
			KVNProgress.showWithStatus("正在请求开始学习...")
			HR8000Service.shareInstance().learningInfraredStart(appDevice, result: { (error) in
				if let err = error {
					KVNProgress.showErrorWithStatus("请求失败：\(err.domain)")
				} else {
					self.loadingView?.startAnimating()
					button.selected = true
					KVNProgress.dismiss()
					self.tipsView.show("学习开始，请点击任意遥控器按键来学习红外码！", duration: 120)
					self.isStartLearning = true
				}
			})
		} else {
			KVNProgress.showWithStatus("正在停止，请稍候...")
			HR8000Service.shareInstance().learningInfraredStop(appDevice, result: { (error) in
				if let err = error {
					KVNProgress.showErrorWithStatus(err.domain)
				} else {
					KVNProgress.dismiss()
					self.loadingView?.stopAnimating()
					button.selected = false
					self.tipsView.show("学习结束！", duration: 1)
					self.isStartLearning = false
				}
			})
		}
	}
	
	@objc private func onLearningDoneButtonClicked(button: UIBarButtonItem) {
		if isStartLearning {
			UIAlertView(title: "警告", message: "学习未结束，您确定结束学习并退出吗？", delegate: self, cancelButtonTitle: "取消", otherButtonTitles: "确定").show()
		} else {
			self.navigationController?.popViewControllerAnimated(true)
		}
	}
	
	@objc private func recordKeyTimeout(timer: NSTimer) {
		if self.isWaitForLearning {	//10秒之后还在等待，说明超时了
			KVNProgress.showErrorWithStatus("超时：未收到红外信号！")
			self.tipsView.show("学习开始，请点击任意遥控器按键来学习红外码！", duration: 120)
			guard let button = timer.userInfo as? UIButton else {
				return
			}
			button.selected = false
			button.stopBackgroundTransition()
		}
	}
	
	
	func alertView(alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
		if buttonIndex != alertView.cancelButtonIndex {
			HR8000Service.shareInstance().learningInfraredStop(appDevice, result: nil)
			self.navigationController?.popViewControllerAnimated(true)
		}
	}
	
	
//MARK: - 红外学习Delegate
	
	func infraredLearning(learningStart start: Bool) {
		
	}
	
	func infraredLearning(recordKey appDevType: Byte, appDevID: UInt16, keyCode: Byte, success: Bool) {
		if UInt32(appDevID) != appDevice.appDevID { return }
		if isWaitForLearning && success {
			KVNProgress.showSuccessWithStatus("学习成功！")
			selectItems(Int(keyCode))
			if let button = containerView.viewWithTag(Int(keyCode)) {
				button.stopBackgroundTransition()
			}
			self.tipsView.show("学习开始，请点击任意遥控器按键来学习红外码！", duration: 120)
			isWaitForLearning = false
		}
		
	}
	
	func infraredLearning(learningStop appDevType: Byte, apDevID: UInt16) {
		
	}
	
}

//MARK: - TVCtrlViewControllerDelegate
protocol TVCtrlViewControllerDelegate: class {

	func tvCtrlResult(recordKeyCode code: Byte, device: HRApplianceApplyDev!)
}
