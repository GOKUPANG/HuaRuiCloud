//
//  RepeationPickView.swift
//  viewTest
//
//  Created by sswukang on 15/10/13.
//  Copyright © 2015年 huarui. All rights reserved.
//

import UIKit

///周期选择，比如每周的周期
class RepeationPickView: UIControl {
	
	var textColor: UIColor = UIColor.whiteColor()
	var selectedColor: UIColor = UIColor.orangeColor()
	var deselectedColor: UIColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
	var textSize: CGFloat?
	var repTexts = [String]()
	
	var repSelected: [Bool] = Array() {
		didSet {
			for i in 0..<repSelected.count {
				if let button = self.viewWithTag(100 + i) as? UIButton {
					button.backgroundColor =
						self.repSelected[i] ? selectedColor : deselectedColor
				}
			}
		}
	}
	
	var repeateToByte: Byte {
		var value: Byte = 0
		for i in 0..<repSelected.count where i <= 7 {
			value |= Byte((repSelected[i] ? 0x01 : 0x00) << i)
		}
		return value
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		self.opaque = false
		
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func drawRect(rect: CGRect) {
		let itemWidth = frame.width / CGFloat(repTexts.count + 1)
		let gapWidth  = itemWidth / CGFloat(repTexts.count - 1)
		for i in 0..<repTexts.count {
			let button = UIButton(frame: CGRectMake(itemWidth*CGFloat(i) + gapWidth*CGFloat(i), 0, itemWidth, frame.height))
			button.layer.cornerRadius = 3
			button.tag = 100 + i
			button.setTitle(repTexts[i], forState: .Normal)
			button.setTitleColor(textColor, forState: .Normal)
			button.setTitleColor(textColor, forState: .Selected)
			if let _size = textSize {
				button.titleLabel?.font = UIFont.systemFontOfSize(_size)
			} else {
				button.titleLabel?.font = UIFont.systemFontOfSize(button.frame.height*0.4)
			}
			if i >= repSelected.count {
				button.backgroundColor = deselectedColor
			} else {
				button.backgroundColor =
					self.repSelected[i] ? selectedColor : deselectedColor
				button.selected = self.repSelected[i]
			}
			if enabled {
				button.addTarget(self, action: #selector(RepeationPickView.onButtonClicked(_:)), forControlEvents: UIControlEvents.TouchDown)
			}
			self.addSubview(button)
		}
	}
	
	@objc private func onButtonClicked(button: UIButton) {
		button.selected = !button.selected
		if repSelected.count != repTexts.count {
			repSelected = [Bool](count: repTexts.count, repeatedValue: false)
		}
		if button.tag - 100 >= 0 || button.tag - 100 < repSelected.count {
			repSelected[button.tag - 100] = button.selected
		}
	}
	
	
}
