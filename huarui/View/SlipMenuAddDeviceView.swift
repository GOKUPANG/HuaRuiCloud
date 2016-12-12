//
//  SlipMenuView.swift
//  huarui
//
//  Created by sswukang on 15/9/11.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import UIKit

/// 下拉菜单添加设备
class SlipMenuAddDeviceView: UIView {
	
	weak var delegate: SlipMenuAddDeviceViewDelegate?
	
	private var _menuView: UIView!
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		opaque = false
		_menuView = UIView(frame: CGRect(x: 0, y: -105, width: frame.width, height: 100))
//		_menuView.backgroundColor = UIColor(R: 240, G: 240, B: 240, alpha: 1)
		_menuView.backgroundColor = UIColor.whiteColor()
		_menuView.layer.cornerRadius = 2
		
		let leftImageView = UIImageView(frame: CGRect(
								x:0,
								y: _menuView.frame.height*0.1 + 5,
								width: _menuView.frame.width/2,
								height: _menuView.frame.height*0.55
							))
		leftImageView.image = UIImage(named: "ico_brightness")
		leftImageView.contentMode = UIViewContentMode.ScaleAspectFit
		
		let leftLabel = UILabel(frame:CGRectMake(0, leftImageView.frame.maxY, leftImageView.frame.width, _menuView.frame.height*0.3))
		leftLabel.text = "注册设备"
		leftLabel.textColor = UIColor.lightGrayColor()
		leftLabel.textAlignment = .Center
		
		let rightImageView = UIImageView(frame: CGRect(
								x:_menuView.frame.width/2,
								y: _menuView.frame.height*0.1 + 5,
								width: _menuView.frame.width/2,
								height: _menuView.frame.height*0.55
							))
		rightImageView.image = UIImage(named: "ico_plugin")
		rightImageView.contentMode = UIViewContentMode.ScaleAspectFit
		
		let rightLabel = UILabel(frame:CGRectMake(_menuView.frame.width/2, rightImageView.frame.maxY, rightImageView.frame.width, _menuView.frame.height*0.3))
		rightLabel.text = "添加应用设备"
		rightLabel.textColor = UIColor.lightGrayColor()
		rightLabel.textAlignment = .Center
		
		let line = UIView(frame: CGRectMake(_menuView.frame.width/2, 0, 0.5, _menuView.frame.height))
		line.backgroundColor = UIColor.lightGrayColor()
		
		_menuView.addSubview(leftImageView)
		_menuView.addSubview(leftLabel)
		_menuView.addSubview(rightImageView)
		_menuView.addSubview(rightLabel)
		_menuView.addSubview(line)
		
		addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SlipMenuAddDeviceView.onTap(_:))))
	}
	
	override func drawRect(rect: CGRect) {
		
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	//MARK: - Method
	
	func show() {
		self.addSubview(_menuView)
//		UIView.transitionWithView(_menuView, duration: 0.2, options: UIViewAnimationOptions.CurveEaseOut, animations: {
//			self._menuView.center = CGPointMake(self._menuView.center.x, self._menuView.frame.height/2 - 5)
//			}, completion: nil)
		let anim = POPBasicAnimation(propertyNamed: kPOPViewBackgroundColor)
		anim.toValue = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.3).CGColor
		anim.duration = 0.4
		self.pop_addAnimation(anim, forKey: "backgroundColor")
		UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0, options: .CurveLinear, animations: {
			self._menuView.center = CGPointMake(self._menuView.center.x, self._menuView.frame.height/2 - 5)
			}, completion: nil)
		
	}
	
	func dismiss(completion: (()->Void)?) {
		UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .CurveLinear, animations: {
			self._menuView.center = CGPointMake(self._menuView.center.x, -105)
			}, completion: { (completed) in
				self.removeFromSuperview()
		})
		let anim = POPBasicAnimation(propertyNamed: kPOPViewBackgroundColor)
		anim.toValue = UIColor.clearColor().CGColor
		anim.duration = 0.4
		self.pop_addAnimation(anim, forKey: "backgroundColor")
	}
	
	func onTap(gesture: UITapGestureRecognizer) {
		switch gesture.state {
		case .Ended:
			let point = gesture.locationInView(self)
			if point.y > _menuView.frame.height {
				self.delegate?.slipMenu(slipMenuWillDismiss: true)
				self.dismiss(nil)
			} else if point.y > _menuView.frame.minY && point.x < _menuView.frame.width/2 {
				self.delegate?.slipMenu(didSelectIndex: 0)
			} else if point.y > _menuView.frame.minY && point.x >= _menuView.frame.width/2 {
				self.delegate?.slipMenu(didSelectIndex: 1)
			}
		default: break
		}
	}

	
}

protocol SlipMenuAddDeviceViewDelegate: class {
	func slipMenu(didSelectIndex index: Int);
	func slipMenu(slipMenuWillDismiss Dismiss: Bool);
}
