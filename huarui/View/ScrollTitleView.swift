//
//  ScrollTitleView.swift
//  viewTest
//
//  Created by sswukang on 15/10/12.
//  Copyright © 2015年 huarui. All rights reserved.
//

import UIKit

/// 可滑动标题
class ScrollTitleView: UIView, UIScrollViewDelegate {
	
	var titleColor: UIColor = UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1)
	var titles = [String]()
	var currentPos = 0
	var cursorHeight: CGFloat = 5
	var containerScrollView: UIScrollView
	
	private var cursorView: UIView
	private var lineView: UIView
	private var actionBlock: ((Int, String)->Void)?
	
	override init(frame: CGRect) {
        cursorView          = UIView()
        lineView            = UIView()
        containerScrollView = UIScrollView()
		super.init(frame: frame)
		
		initSubviews()
	}
	
	required init?(coder aDecoder: NSCoder) {
		cursorView          = UIView()
		lineView            = UIView()
		containerScrollView = UIScrollView()
		super.init(coder: aDecoder)
		
		initSubviews()
	}
	
	private func initSubviews() {
        containerScrollView.bounces      = false
        containerScrollView.delegate     = self
        containerScrollView.scrollsToTop = false
		self.backgroundColor = UIColor.whiteColor()
		
		self.addSubview(lineView)
		self.addSubview(containerScrollView)
	}
	
	override func drawRect(rect: CGRect) {
		for v in containerScrollView.subviews {
			v.removeFromSuperview()
		}
		lineView.frame = CGRectMake(0, bounds.height - 1, bounds.width, 1)
		lineView.backgroundColor = tintColor
		containerScrollView.frame = CGRectMake(0, 0, bounds.width, bounds.height-1)
		
		if titles.count == 0 { return }
		
		var offset:CGFloat = 0
		var buttons = [UIButton]()
		for (i, title) in titles.enumerate() {
			let size = NSString(string: title).sizeWithAttributes([NSFontAttributeName: UIFont.systemFontOfSize(UIFont.systemFontSize() + 3)])
			let itemWidth = size.width + 30
			
			let button = UIButton(frame: CGRectMake(offset, 0, itemWidth, bounds.height-cursorHeight))
			button.setTitle(title, forState: .Normal)
			button.setTitleColor(titleColor, forState: .Normal)
			button.setTitleColor(tintColor, forState: .Selected)
			button.selected = currentPos == i
			button.tag = 100 + i
			button.addTarget(self, action: #selector(ScrollTitleView.onButtonClicked(_:)), forControlEvents: .TouchUpInside)
			containerScrollView.addSubview(button)
			buttons.append(button)
			offset += itemWidth
		}
		
		if offset < self.bounds.width {	//如果buttons的长度小于屏幕宽度，则重新布局button的位置
			let inc = (self.bounds.width - offset) / CGFloat(buttons.count)
			offset = 0
			for button in buttons {
				button.frame = CGRectMake(offset, 0, button.bounds.width + inc, button.bounds.height)
				offset += button.bounds.width
			}
		}
		containerScrollView.contentSize = CGSizeMake(offset, containerScrollView.bounds.height)
		let button: UIButton
		if currentPos < 0 || currentPos >= buttons.count {
			currentPos = 0
		}
		button = buttons[currentPos]
		cursorView.frame = CGRectMake(button.frame.minX, bounds.height - cursorHeight, button.bounds.width, cursorHeight)
		cursorView.backgroundColor = tintColor
		self.addSubview(cursorView)
	}
	
	func setHandler(handler: (Int, String)->Void) {
		self.actionBlock = handler
	}
	
	@objc private func onButtonClicked(button: UIButton) {
		setSelectedItem(button.tag - 100, animated: true)
		if let handler = self.actionBlock {
			handler(currentPos, titles[currentPos])
		}
	}
	
	///
	func setSelectedItem(index: Int, animated: Bool) {
		if index >= titles.count || currentPos == index { return }
		if let currentButton = self.viewWithTag(100 + index) as? UIButton {
			(self.viewWithTag(100 + currentPos) as? UIButton)?.selected = false
			currentButton.selected = true
			currentPos = index
			 
			let cursorX = currentButton.frame.minX - containerScrollView.contentOffset.x
			if animated {
				UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.98, initialSpringVelocity: 0, options: .CurveLinear, animations: {
						self.cursorView.frame = CGRectMake(cursorX, self.cursorView.frame.minY, currentButton.bounds.width, self.cursorView.frame.height)
					}, completion: nil)
			} else {
				self.cursorView.frame = CGRectMake(cursorX, self.cursorView.frame.minY, currentButton.bounds.width, self.cursorView.frame.height)
			}
			scrollPointToNearCenter(currentButton.center, animated: animated)
		}
		
	}
	
	
	///居中显示
	func scrollPointToNearCenter(point: CGPoint, animated: Bool) {
		
		let distance = containerScrollView.bounds.midX - point.x
		
		var targetPoint:CGPoint
		targetPoint = CGPointMake(containerScrollView.contentOffset.x - distance, 0)
		
		if targetPoint.x < 0 {
			targetPoint = CGPoint.zero
		} else if targetPoint.x > containerScrollView.contentSize.width - containerScrollView.bounds.width {
			targetPoint = CGPointMake(containerScrollView.contentSize.width - containerScrollView.bounds.width, 0)
		}
		containerScrollView.setContentOffset(targetPoint, animated: animated)
	}
	
	//MARK: - ScrollView delegate
	
	func scrollViewDidScroll(scrollView: UIScrollView) {
		if let currentButton = self.viewWithTag(100 + currentPos) as? UIButton {
			
			let cursorX = currentButton.frame.minX - scrollView.contentOffset.x
			
			self.cursorView.frame = CGRectMake(cursorX, self.cursorView.frame.minY, self.cursorView.frame.width, self.cursorView.frame.height)
		}
	}
}