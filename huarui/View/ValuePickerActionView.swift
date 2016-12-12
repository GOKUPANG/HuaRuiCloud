//
//  ValuePickerActionView.swift
//  huarui
//
//  Created by sswukang on 15/10/29.
//  Copyright © 2015年 huarui. All rights reserved.
//

import UIKit

/// 弹出的值选择器
class ValuePickerActionView: UIView, UIPickerViewDataSource, UIPickerViewDelegate {

	var title: String
	weak var delegate : ValuePickerActionViewDelegate?
	var currentRow: Int = 0
	var values: [String]!
	
	private var backgroundView: UIView!
	private var pickBlankView: UIView!
	private var titleLabel: UILabel!
	private var pickerView: UIPickerView!
	private var closeButton: UIButton!
	private var okButton: PrettyButton!
	
	//MARK: - function
	
	///初始化
	///
	/// - parameter title: ValuePickerActionView的标题
	/// - parameter currentRow: 初始选择位置
	init(title: String, values: [String], currentRow: Int?, delegate: ValuePickerActionViewDelegate?) {
		self.title = title
		self.values = values
		self.delegate = delegate
		self.currentRow = currentRow == nil ? 0 : currentRow!
		super.init(frame: CGRectMake(0, 0, 0, 100))
		self.opaque = false
		let size = UIScreen.mainScreen().bounds
		self.frame = CGRectMake(0, 0, size.width, size.height)
		
		//背景遮罩
		backgroundView = UIView(frame: self.bounds)
		backgroundView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.3)
		backgroundView.alpha = 0
		backgroundView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ValuePickerActionView.onTapBackgroundView(_:))))
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
		closeButton.addTarget(self, action: #selector(ValuePickerActionView.onPickerCloseClicked(_:)), forControlEvents: UIControlEvents.TouchUpInside)
		
		//添加确定按钮
		okButton = PrettyButton(frame: CGRectMake(pickerView.frame.minX, pickBlankView.frame.height - 45, pickerView.frame.width, 40))
		okButton.setTitle("确定", forState: .Normal)
		okButton.backgroundColor = tintColor
		okButton.hightLightColor = tintColor.colorWithAdjustBrightness(-0.3)
		okButton.layer.cornerRadius = 5
		okButton.addTarget(self, action: #selector(ValuePickerActionView.onPickerOkClicked(_:)), forControlEvents: UIControlEvents.TouchUpInside)
		
		self.addSubview(backgroundView)
		self.addSubview(pickBlankView)
		pickBlankView.addSubview(pickerView)
		pickBlankView.addSubview(titleLabel)
		pickBlankView.addSubview(closeButton)
		pickBlankView.addSubview(okButton)
	}
	
	required init?(coder aDecoder: NSCoder) {
		self.title = " "
		super.init(coder: aDecoder)
	}
	
	override func drawRect(rect: CGRect) {
		titleLabel?.text = title
		pickerView.selectRow(currentRow, inComponent: 0, animated: false)
	}
	
	private var handlerBlock: ((String, Int)->Void)?
	
	///显示，并绑定事件处理block，当点击picker的确定按键使picker消失后，该block被调用
	func showWithHandler(block: (String, Int)->Void) {
		self.handlerBlock = block
		self.show()
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
	
	//MARK: - UI事件
	
	@objc private func onTapBackgroundView(gesture: UITapGestureRecognizer ) {
		self.dismiss()
		self.delegate?.valuePickerActionView?(dismissWithoutSelection: self)
	}
	
	@objc private func onPickerCloseClicked(button: UIButton) {
		self.dismiss()
		self.delegate?.valuePickerActionView?(dismissWithoutSelection: self)
	}
	
	@objc private func onPickerOkClicked(button: UIButton) {
		self.dismiss()
		let row = pickerView.selectedRowInComponent(0)
		delegate?.valuePickerActionView?(self, dismissWithSelectedRow: row, values: self.values)
		handlerBlock?(values[row], row)
	}
	
	
	//MARK: - delegate
	
	func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
		return 1
	}
	
	func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		return values.count
	}
	
	func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		return values[row]
	}
	
	func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		
	}
}

@objc protocol ValuePickerActionViewDelegate {
	optional func valuePickerActionView(picker: ValuePickerActionView, dismissWithSelectedRow row: Int, values: [String])
	/// 点击取消或者背景，即没有选择
	optional func valuePickerActionView(dismissWithoutSelection picker: ValuePickerActionView)
}
