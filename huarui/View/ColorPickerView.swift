//
//  ColorPickerView.swift
//  huarui
//
//  Created by sswukang on 16/1/7.
//  Copyright © 2016年 huarui. All rights reserved.
//

import UIKit

/// 颜色选择器
class ColorPickerView: UIView {
	
	private var wheelImageView: UIImageView!
	/// 左边的旧颜色
	private var oldColorField: UIView!
	/// 右边的新颜色
	private var newColorField: UIView!
	private var pickerKnobView: UIImageView!
	weak var delegate: ColorPickerViewDelegate?
	dynamic var currentColor: UIColor = .whiteColor()
	/// 右边新颜色
	var newColor: UIColor? {
		didSet {
			setBackgroundColor(newColorField, color: newColor)
		}
	}
	/// 左边旧颜色
	var oldColor: UIColor? {
		didSet {
			setBackgroundColor(oldColorField, color: oldColor)
		}
	}
	
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		self.opaque = false
		initSubviews()
	}
	
	override func awakeFromNib() {
		initSubviews()
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		self.opaque = false
	}
	
	private func initSubviews() {
		wheelImageView = UIImageView(image: UIImage(named: "pickerColorWheel"))
		wheelImageView.contentMode = .ScaleAspectFit
		oldColorField = UIView()
		newColorField = UIView()
		pickerKnobView = UIImageView(image: UIImage(named: "colorPickerKnob"))
		
		self.addSubview(wheelImageView)
		self.addSubview(pickerKnobView)
		self.insertSubview(oldColorField, belowSubview: wheelImageView)
		self.insertSubview(newColorField, belowSubview: wheelImageView)
		oldColorField.layer.borderColor = UIColor(htmlColor: 0xFFCCCCCC).CGColor
		newColorField.layer.borderColor = UIColor(htmlColor: 0xFFCCCCCC).CGColor
		setBackgroundColor(oldColorField, color: UIColor.whiteColor())
		setBackgroundColor(newColorField, color: UIColor.whiteColor())
		
		wheelImageView.userInteractionEnabled = true
		wheelImageView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(ColorPickerView.panView(_:))))
		wheelImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ColorPickerView.panView(_:))))
		oldColorField.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ColorPickerView.tapColorField(_:))))
		newColorField.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ColorPickerView.tapColorField(_:))))
	}
	
    override func drawRect(rect: CGRect) {
		var wheelFrame = CGRectMake(0, 0, rect.width * 3 / 4, rect.width * 3 / 4)
		if wheelFrame.width > rect.height*0.8 {
			wheelFrame = CGRectMake(0, 0, rect.height * 0.8, rect.height * 0.8)
		}
		wheelImageView.frame = wheelFrame
		wheelImageView.center = CGPointMake(bounds.midX, bounds.midY)
		pickerKnobView.frame = CGRectMake(0, 0, wheelImageView.bounds.width*0.1, wheelImageView.bounds.width*0.1)
		pickerKnobView.center = wheelImageView.center
		
		oldColorField.frame = CGRectMake(0, 0, wheelImageView.bounds.width * 0.2, wheelImageView.bounds.width * 0.2)
		oldColorField.center = CGPointMake(bounds.midX * 0.25, bounds.midY * 0.3)
		newColorField.frame = oldColorField.bounds
		newColorField.center = CGPointMake(bounds.midX * 1.75, oldColorField.center.y)
		
		oldColorField.layer.cornerRadius = oldColorField.bounds.width/2
		newColorField.layer.cornerRadius = newColorField.bounds.width/2
    }
	
	@objc private func panView(gesture: UIGestureRecognizer) {
		let point = gesture.locationInView(self)
		let _center = wheelImageView.center
		var targetPoint = point
		let deltaX = point.x - _center.x
		let deltaY = point.y - _center.y
		let distance = sqrt(deltaX * deltaX + deltaY * deltaY)
		let radius = wheelImageView.bounds.width/2 - 2
		if distance > radius {
			targetPoint.x = _center.x + (deltaX * radius) / distance
			targetPoint.y = _center.y + (deltaY * radius) / distance
		}
		pickerKnobView.center = targetPoint
	
		var angle = atan(abs(deltaY) / abs(deltaX))
		var saturation = min(distance/radius, 1.0);
		
		if isnan(angle) {
			angle = 0
		}
		if distance < 10 {
			saturation = 0
		}
		if point.x < _center.x {
			angle = CGFloat(M_PI) - angle
		}
		if point.y > _center.y {
			angle = 2.0 * CGFloat(M_PI) - angle;
		} 
		currentColor = UIColor(hue: angle / (2.0 * CGFloat(M_PI)), saturation: saturation, brightness: 1.0, alpha: 1)
		
		setBackgroundColor(newColorField, color: currentColor)
		delegate?.colorPickerView?(self, colorChanged: currentColor)
		if gesture.state == .Ended {
			delegate?.colorPickerView?(self, didPickedColor: currentColor)
		}
//		print("point=\(point), \tdistance=\(distance),\ttargetPoint=\(targetPoint)")
	}

	@objc private func tapColorField(gesture: UITapGestureRecognizer) {
		if gesture.view === oldColorField {
			delegate?.colorPickerView?(self, didSelectedOldColor: oldColorField.backgroundColor!)
		} else {
			delegate?.colorPickerView?(self, didSelectedNewColor: newColorField.backgroundColor!)
		}
	}
	
	private func setBackgroundColor(fieldView: UIView, color: UIColor? ) {
		if let color = color {
			var R:CGFloat = 0
			var G:CGFloat = 0
			var B:CGFloat = 0
			color.getRed(&R, green: &G, blue: &B, alpha: nil)
			if R + G + B > 3-0.2 {
				fieldView.layer.borderWidth = 0.5
			} else {
				fieldView.layer.borderWidth = 0
			}
			fieldView.backgroundColor = color
		}
	}
}

@objc protocol ColorPickerViewDelegate {
	/// 颜色改变
	optional func colorPickerView(pickerView: ColorPickerView, colorChanged color: UIColor)
	/// 颜色选择完毕
	optional func colorPickerView(pickerView: ColorPickerView, didPickedColor color: UIColor)
	/// 点击上一次选择的颜色
	optional func colorPickerView(pickerView: ColorPickerView, didSelectedOldColor color: UIColor)
	/// 点击了已经选择的颜色
	optional func colorPickerView(pickerView: ColorPickerView, didSelectedNewColor color: UIColor)
}

