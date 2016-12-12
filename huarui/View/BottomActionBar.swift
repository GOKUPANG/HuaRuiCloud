//
//  BottomAddDeviceView.swift
//  viewTest
//
//  Created by sswukang on 15/10/13.
//  Copyright © 2015年 huarui. All rights reserved.
//

import UIKit

/// 底部的Actionbar
class BottomActionBar: UIView {
	var addButton: UIButton!
	var doneButton: UIButton!
	var editButton: UIButton!
	
	//MARK: - function
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		self.opaque = false
//		self.backgroundColor = UIColor(R: 242, G: 242, B: 242, alpha: 0.98)
		doneButton = UIButton(frame: CGRectMake(0, 0, 40, 40))
		doneButton.center = CGPointMake(frame.width/2, frame.height/2)
		doneButton.layer.cornerRadius = doneButton.bounds.height/2
		doneButton.setTitle("完 成", forState: .Normal)
		
		editButton = UIButton(frame: CGRectMake(0, 0, 40, 40))
		editButton.setImage(UIImage(named: "ico_edit")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
		
		addButton  = UIButton(frame: CGRectMake(0, 0, 40, 40))
		addButton.setImage(UIImage(named: "ico_add_blue")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
		
		editButton.addTarget(self, action: #selector(BottomActionBar.onEditButtonClicked(_:)), forControlEvents: .TouchUpInside)
		doneButton.addTarget(self, action: #selector(BottomActionBar.onDoneButtonClicked(_:)), forControlEvents: .TouchUpInside)
		self.addSubview(addButton)
		self.addSubview(editButton)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func drawRect(rect: CGRect) {
		editButton.center = CGPointMake(rect.width*0.25, rect.height/2)
		addButton.center = CGPointMake(rect.width*0.75, rect.height/2)
		
        doneButton.backgroundColor = tintColor
        editButton.tintColor       = tintColor
        addButton.tintColor        = tintColor
	}
	
	
	//MARK: - 点击事件
	
	@objc private func onEditButtonClicked(button: UIButton) {
		//show main button
		self.addSubview(doneButton)
		UIView.animateWithDuration(0.6, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveLinear, animations: {
			self.doneButton.frame = CGRectMake(self.bounds.width*0.1, self.doneButton.center.y - self.doneButton.bounds.height/2, self.bounds.width*0.8, self.doneButton.bounds.height)
			}, completion: nil)
	}
	
	@objc private func onDoneButtonClicked(button: UIButton) {
		
		UIView.animateWithDuration(1, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 1, options: UIViewAnimationOptions.CurveLinear, animations: {
			self.doneButton.frame = CGRectMake(self.doneButton.center.x - self.doneButton.bounds.height/2, self.doneButton.center.y - self.doneButton.bounds.height/2, self.doneButton.bounds.height, self.doneButton.bounds.height)
			
			self.doneButton.center = self.doneButton.center
			}, completion: nil)
		UIView.animateWithDuration(0.2, delay: 0.3, options: UIViewAnimationOptions.CurveEaseIn, animations: {
			button.layer.opacity = 0
			}, completion: { _ in
				button.removeFromSuperview()
				button.layer.opacity = 1
		})
	}
}