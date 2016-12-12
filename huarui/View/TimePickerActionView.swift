//
//  TimePickerActionView.swift
//  huarui
//
//  Created by sswukang on 15/10/25.
//  Copyright © 2015年 huarui. All rights reserved.
//

import UIKit

/// 弹出的时间选择器
class TimePickerActionView: UIView, UIPickerViewDelegate, UIPickerViewDataSource {

	var title: String
	weak var delegate : TimePickerActionViewDelegate?
	//当前时间，单位秒
	var currentTimeInSecond: Float = 0
	
	private var backgroundView: UIView!
	private var pickBlankView: UIView!
	private var titleLabel: UILabel!
	private var pickerView: UIPickerView!
	private var closeButton: UIButton!
	private var okButton: PrettyButton!
	private var secondLabel: UILabel!
	
	//MARK: - function 
	
	///初始化
	///
	/// - parameter title: TimePickerActionView的标题
	/// - parameter initSecond: 初始时间
	init(title: String, initSecond: Float?, delegate: TimePickerActionViewDelegate?) {
		self.title = title
		self.delegate = delegate
		self.currentTimeInSecond = initSecond == nil ? 0 : initSecond!
		super.init(frame: CGRectMake(0, 0, 0, 100))
		self.opaque = false
		let size = UIScreen.mainScreen().bounds
		self.frame = CGRectMake(0, 0, size.width, size.height)
		
		//背景遮罩
		backgroundView = UIView(frame: self.bounds)
		backgroundView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.3)
		backgroundView.alpha = 0
		backgroundView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(TimePickerActionView.onTapBackgroundView(_:))))
		//添加pickBlank, 即白色背景
		pickBlankView = UIView(frame: CGRectMake(0, bounds.height, bounds.width, 240))
		pickBlankView.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.98)
		
		titleLabel = UILabel(frame: CGRectMake(0, 10, pickBlankView.frame.width, 25))
		titleLabel.text = title
		titleLabel.textAlignment = .Center
		titleLabel.textColor = UIColor.lightGrayColor()
		
		pickerView = UIPickerView(frame: CGRectMake(pickBlankView.frame.width/2-100, 30, 200, pickBlankView.frame.height - 60))
		pickerView.dataSource = self
		pickerView.delegate = self
		
		//添加x
		closeButton = UIButton(frame: CGRectMake(pickBlankView.frame.width-55, 5, 50, 50))
		closeButton.setImage(UIImage(named: "close_light_gray"), forState: .Normal)
		closeButton.addTarget(self, action: #selector(TimePickerActionView.onTimePickerCloseClicked(_:)), forControlEvents: UIControlEvents.TouchUpInside)
		
		//添加确定按钮
		okButton = PrettyButton(frame: CGRectMake(pickerView.frame.minX, pickBlankView.frame.height - 45, pickerView.frame.width, 40))
		okButton.setTitle("确定", forState: .Normal)
		okButton.backgroundColor = tintColor
		okButton.hightLightColor = tintColor.colorWithAdjustBrightness(-0.3)
		okButton.layer.cornerRadius = 5
		okButton.addTarget(self, action: #selector(TimePickerActionView.onTimePickerOkClicked(_:)), forControlEvents: UIControlEvents.TouchUpInside)
		
		secondLabel = UILabel(frame: CGRectMake(0, 0, 25, 25))
		secondLabel.center = pickerView.center
		secondLabel.text = "秒"
		secondLabel.textAlignment = .Center
		
		self.addSubview(backgroundView)
		self.addSubview(pickBlankView)
		pickBlankView.addSubview(pickerView)
		pickBlankView.addSubview(titleLabel)
		pickBlankView.addSubview(secondLabel)
		pickBlankView.addSubview(closeButton)
		pickBlankView.addSubview(okButton)
	}

	required init?(coder aDecoder: NSCoder) {
		self.title = " "
		super.init(coder: aDecoder)
	}
	
	override func drawRect(rect: CGRect) {
		titleLabel?.text = title
		self.setTime(minuteAndSecond: currentTimeInSecond, animated: false)
    }

	
	func show(){
		guard let wnd: UIWindow! = UIApplication.sharedApplication().delegate?.window where wnd != nil else{
			Log.error("TimePickerActionView.show找不到window，无法显示")
			return
		}
		wnd.addSubview(self)
		
		
		//出现pickerView
		UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveLinear, animations: {
			self.backgroundView.alpha = 1
			self.pickBlankView.center.y = self.bounds.height - self.pickBlankView.bounds.height/2
			}, completion: nil)
	}
	
	func dismiss() {
		
		UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveLinear, animations: {
			self.backgroundView.alpha = 0
			self.pickBlankView.center.y = self.bounds.height + self.pickBlankView.bounds.height/2
			}, completion: { _ in
				self.removeFromSuperview()
		})
		
	}
	
	func setTime(minuteAndSecond sec: Float, animated: Bool) {
		
		//秒
		let _rsec = Int(sec)
		//0.1秒
		let _rpsec = Int(sec * 10 % 10)
		
		if _rsec >= pickerView.numberOfRowsInComponent(0) ||
			_rpsec >= pickerView.numberOfRowsInComponent(1) {
			return
		}
		
		pickerView.selectRow(_rsec, inComponent: 0, animated: animated)
		pickerView.selectRow(_rpsec, inComponent: 1, animated: animated)
	}
	
	//MARK: - UI事件
	
	@objc private func onTapBackgroundView(gesture: UITapGestureRecognizer ) {
		self.dismiss()
		delegate?.timePickerActionView?(dismissWithoutTime: self)
	}
	
	@objc private func onTimePickerCloseClicked(button: UIButton) {
		self.dismiss()
		delegate?.timePickerActionView?(dismissWithoutTime: self)
	}
	
	@objc private func onTimePickerOkClicked(button: UIButton) {
		self.dismiss()
		delegate?.timePickerActionView?(self, dismissWithTimeInSecond: currentTimeInSecond)
	}
	
	
	//MARK: - delegate
	
	func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
		return 2
	}
	
	func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		switch component {
		case 0:
			return 26
		case 1:
			return 10
		default:
			return 0
		}
	}
	
	func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		return "\(row)"
	}
	
	func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		if component == 0 && row == 25 {
			pickerView.selectRow(0, inComponent: 1, animated: true)
		} else if component == 1 && row != 0 && pickerView.selectedRowInComponent(0) == 25 {
			pickerView.selectRow(24, inComponent: 0, animated: true)
		}
		let sec = pickerView.selectedRowInComponent(0)
		let psec = pickerView.selectedRowInComponent(1)
		currentTimeInSecond = Float(sec) + Float(psec) * 0.1
	}
}

@objc protocol TimePickerActionViewDelegate {
	optional func timePickerActionView(picker: TimePickerActionView, dismissWithTimeInSecond second: Float)
	optional func timePickerActionView(dismissWithoutTime picker: TimePickerActionView)
}
