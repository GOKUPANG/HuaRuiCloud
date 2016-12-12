//
//  ManipulatorViewController.swift
//  huarui
//
//  Created by sswukang on 15/5/18.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import UIKit

class ManipulatorViewController: UIViewController {
	var manipulatorView: ManipulatorView!
	var manipDev: HRManipulator!
	private var stopButton: UIButton!
	private var openButton: UIButton!
	private var closeButton: UIButton!
	private var tipsView: TipsView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.view.layer.contents = UIImage(named:APP.param.backgroundImgName)?.CGImage
		if manipDev != nil {
			self.navigationItem.title = manipDev!.name
		}
		initComponent()
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		
	}
	
	
	func initComponent(){
		let topH = self.navigationController!.navigationBar.bounds.height + UIApplication.sharedApplication().statusBarFrame.height
		self.tipsView = TipsView(frame: CGRectMake(0, topH, self.view.bounds.width, 30))
		self.view.addSubview(tipsView)
		
		//中间转盘
		manipulatorView = ManipulatorView(frame: CGRectMake(0, 0, self.view.frame.width, self.view.frame.height))
		manipulatorView.radius = self.view.frame.width/3
		manipulatorView.ringRadius = manipulatorView.radius / 3
		self.view.addSubview(manipulatorView)
		var x: CGFloat = view.center.x - manipulatorView.ringRadius/2 - manipulatorView.ringRadius/2
		var y: CGFloat = view.center.y - manipulatorView.ringRadius/2 - manipulatorView.radius - manipulatorView.ringRadius / 2
		//停止
		stopButton = UIButton(frame: CGRectMake(x, y, manipulatorView.ringRadius*2, manipulatorView.ringRadius*2))
		stopButton.setTitle("停", forState: UIControlState.Normal)
		stopButton.titleLabel?.font = UIFont.systemFontOfSize(manipulatorView.ringRadius)
		stopButton.titleLabel?.textAlignment = NSTextAlignment.Center
		stopButton.addTarget(self, action: #selector(ManipulatorViewController.onStopTap(_:)), forControlEvents: .TouchDown)
		self.view.addSubview(stopButton)
		
		
		//关
		x = view.center.x + manipulatorView.radius * sin(CGFloat(M_PI)/3) - manipulatorView.ringRadius/2 - manipulatorView.ringRadius/2
		y = view.center.y + manipulatorView.radius * cos(CGFloat(M_PI)/3) - manipulatorView.ringRadius/2 - manipulatorView.ringRadius/2
		openButton = UIButton(frame: CGRectMake(x, y, manipulatorView.ringRadius*2, manipulatorView.ringRadius*2))
		openButton.setTitle("关", forState: UIControlState.Normal)
		openButton.titleLabel?.font = UIFont.systemFontOfSize(manipulatorView.ringRadius)
		openButton.titleLabel?.textAlignment = NSTextAlignment.Center
		openButton.addTarget(self, action: #selector(ManipulatorViewController.onCloseTap(_:)), forControlEvents: .TouchDown)
		self.view.addSubview(openButton)
		
		//开
		x = view.center.x - manipulatorView.radius * sin(CGFloat(M_PI)/3) - manipulatorView.ringRadius/2 - manipulatorView.ringRadius/2
		openButton = UIButton(frame: CGRectMake(x, y, manipulatorView.ringRadius*2, manipulatorView.ringRadius*2))
		openButton.setTitle("开", forState: UIControlState.Normal)
		openButton.titleLabel?.font = UIFont.systemFontOfSize(manipulatorView.ringRadius)
		openButton.titleLabel?.textAlignment = NSTextAlignment.Center
		openButton.addTarget(self, action: #selector(ManipulatorViewController.onOpenTap(_:)), forControlEvents: .TouchDown)
		
		self.view.addSubview(openButton)
		
	}
	
	override func viewDidAppear(animated: Bool) {
		if manipDev == nil {
			self.navigationController?.popViewControllerAnimated(true)
			return
		}
		switchToState(manipDev!.status, shouldSendData:  false)
	}
	
	private func degreesToAngle(degress: CGFloat) -> CGFloat {
		return CGFloat(M_PI) * degress / 180.0
	}
	
	func onStopTap(button: UIButton){
		if !_animating {
			switchToState(.Stop, shouldSendData: true)
		}
	}
	
	func onCloseTap(button: UIButton){
		if !_animating {
			switchToState(.Close, shouldSendData: true)
		}
	}
	
	func onOpenTap(button: UIButton){
		if !_animating {
			switchToState(.Open, shouldSendData: true)
		}
	}
	
	private var _animating = false
	private var _rotating = false
	private var _curDegree: CGFloat = 0
	private var _distance: CGFloat = 0
	
	func rotateView(toDegree: CGFloat){
		
		//旋转
		if _rotating {
			return
		}
		_animating = true
		_rotating = true
		var option = UIViewAnimationOptions.CurveLinear
		if toDegree - _curDegree < 0{
			_distance = toDegree + CGFloat(360.0) - _curDegree
		} else {
			_distance = toDegree - _curDegree
		}
		if _distance > 60{
			_curDegree += 60
		} else {
			_curDegree += _distance
			option = UIViewAnimationOptions.CurveEaseOut
		}
		UIView.transitionWithView(manipulatorView, duration: 0.1, options: option, animations: {
			self.manipulatorView.transform = CGAffineTransformMakeRotation(self.degreesToAngle(self._curDegree))
			} , completion: {
				(comp) in
				self._rotating = false
				if self._distance <= 0 {
					self._curDegree = self._curDegree % 360
					self._animating = false
					return
				}
				else {
					self.rotateView(toDegree)
				}
		})
	}
	
	private func doRotate(degree: CGFloat, linearRatate: Bool, completion: ((Bool)->Void)?){
		var option = UIViewAnimationOptions.CurveLinear
		if !linearRatate {
			option = .CurveEaseOut
		}
		UIView.transitionWithView(manipulatorView, duration: 0.5, options: option, animations: {
			self.manipulatorView.transform = CGAffineTransformMakeRotation(self.degreesToAngle(degree))
			} , completion: completion)
	}
	
//	func switchToState(state: HRMotorCtrlStatus, sendData: Bool) {
//		switch state{
//		case .Stop: //顺时针旋转90度
//			rotateView(360 + 90)
//		case .Close:   //210度
//			rotateView(360 + 210)
//		case .Open:     //330度
//			rotateView(360 + 330)
//		}
//		if let ctrlType = HRMotorOperateType(rawValue: state.rawValue)
//			where sendData {
//				HR8000Service.shareInstance().operateManipulator(manipDev, action: ctrlType, delayS: 0, tag: 56, callback: {
//					(error) in
//					return
//				})
//		}
//	}
	
	private func switchToState(state: HRMotorCtrlStatus, shouldSendData: Bool) {
		switch state{
		case .Stop: //顺时针旋转90度
			rotateStateView(360 + 90)
		case .Close:   //210度
			rotateStateView(360 + 210)
		case .Open:     //330度
			rotateStateView(360 + 330)
		}
		
		if let ctrlType = HRMotorOperateType(rawValue: state.rawValue)
			where shouldSendData {
				
				HR8000Service.shareInstance().operateManipulator(manipDev, action: ctrlType, delaySec: 0, callback: { error in
					if error != nil {
						return
					}
				})
		}
	}
	
	private func rotateStateView(angle: Float) {
		let arcAngle = CGFloat((angle * Float(M_PI)) / 180.0 )
		let rotateAnim = POPBasicAnimation(propertyNamed: kPOPLayerRotation)
		rotateAnim.duration = 1
		rotateAnim.toValue	= arcAngle
		rotateAnim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
		
		self.manipulatorView.layer.pop_addAnimation(rotateAnim, forKey: "rotateAnim")
		
	}
	
	//MARK: - delegate
	
	func manipulatorResut(newManip: HRManipulator, tag: Byte) {
		self.manipDev = newManip
		switchToState(newManip.status, shouldSendData: false)
	}
}
