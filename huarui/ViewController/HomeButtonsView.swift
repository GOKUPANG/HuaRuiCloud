//
//  HomeButtonsView.swift
//  viewTest
//
//  Created by sswukang on 15/11/6.
//  Copyright © 2015年 huarui. All rights reserved.
//

import UIKit

class HomeButtonsView: UIView {

	private let sqrt2: CGFloat = 1.414106
	private var btnWidth: CGFloat!
	
	var btnWidthRate: CGFloat = 0.57 {
		didSet{
			self.setNeedsDisplay()
		}
	}
	var homeManagerButton: UIButton!
	var viewCtrlButton: UIButton!
	var sceneManagerButton: UIButton!
	var settingsButton: UIButton!
	
	var homeManagerText = "家居管理"
	var viewCtrlText = "可见可控"
	var sceneManagerText = "情景管理"
	var settingsText = "系统设置"
	
	private var homeManagerLabel: UILabel!
	private var viewCtrlLabel: UILabel!
	private var sceneManagerLabel: UILabel!
	private var settingsLabel: UILabel!
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		opaque = false
		let radius = frame.height < frame.width ? frame.height/2:frame.width/2
		btnWidth = radius - radius * (1-btnWidthRate) * sqrt2
		
		homeManagerButton = UIButton(frame: CGRectMake(0, 0, btnWidth, btnWidth))
		viewCtrlButton = UIButton(frame: CGRectMake(0, 0, btnWidth, btnWidth))
		sceneManagerButton = UIButton(frame: CGRectMake(0, 0, btnWidth, btnWidth))
		settingsButton = UIButton(frame: CGRectMake(0, 0, btnWidth, btnWidth))
		
		homeManagerLabel = UILabel(frame: CGRectMake(0, 0, btnWidth*2, 30))
		viewCtrlLabel = UILabel(frame: CGRectMake(0, 0, btnWidth*2, 30))
		sceneManagerLabel = UILabel(frame: CGRectMake(0, 0, btnWidth*2, 30))
		settingsLabel = UILabel(frame: CGRectMake(0, 0, btnWidth*2, 30))
		
		homeManagerLabel.textAlignment = .Center
		viewCtrlLabel.textAlignment = .Center
		sceneManagerLabel.textAlignment = .Center
		settingsLabel.textAlignment = .Center
		
		self.addSubview(homeManagerButton)
		self.addSubview(viewCtrlButton)
		self.addSubview(sceneManagerButton)
		self.addSubview(settingsButton)
		self.addSubview(homeManagerLabel)
		self.addSubview(viewCtrlLabel)
		self.addSubview(sceneManagerLabel)
		self.addSubview(settingsLabel)
	}

	required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
	override func drawRect(rect: CGRect) {
		let radius = rect.height < rect.width ? rect.height/2:rect.width/2
		//按键到Y轴的水平距离
		let btnHorzDistanceToCenter = radius * (1-btnWidthRate)
		//按键到X轴的垂直距离
		let btnVerzDistanceToCenter = radius * (1-btnWidthRate) * 1.1
		btnWidth = radius - radius * (1-btnWidthRate) * sqrt2
		btnWidth = btnWidth * sqrt2
		layer.cornerRadius = radius
		layer.backgroundColor = tintColor.CGColor
		
		//画“+”线条
		let context = UIGraphicsGetCurrentContext()
		CGContextMoveToPoint(context!, 0, rect.height/2)
		CGContextAddLineToPoint(context!, rect.width, rect.height/2)
		CGContextMoveToPoint(context!, rect.width/2, 0)
		CGContextAddLineToPoint(context!, rect.width/2, rect.height)
		CGContextSetLineWidth(context!, 0.5)
		CGContextSetStrokeColorWithColor(context!, UIColor.lightGrayColor().CGColor)
		CGContextStrokePath(context!)
		
		homeManagerButton.frame = CGRectMake(0, 0, btnWidth, btnWidth)
		viewCtrlButton.frame = CGRectMake(0, 0, btnWidth, btnWidth)
		sceneManagerButton.frame = CGRectMake(0, 0, btnWidth, btnWidth)
		settingsButton.frame = CGRectMake(0, 0, btnWidth, btnWidth)
		
		homeManagerButton.center = CGPointMake(bounds.midX - btnHorzDistanceToCenter, bounds.midY - btnVerzDistanceToCenter)
		viewCtrlButton.center = CGPointMake(bounds.midX + btnHorzDistanceToCenter, bounds.midY - btnVerzDistanceToCenter)
		sceneManagerButton.center = CGPointMake(bounds.midX - btnHorzDistanceToCenter, bounds.midY + btnVerzDistanceToCenter)
		settingsButton.center = CGPointMake(bounds.midX + btnHorzDistanceToCenter, bounds.midY + btnVerzDistanceToCenter)
		
		homeManagerButton.setImage(UIImage(named: "ico_main_homemanage"), forState: .Normal)
		viewCtrlButton.setImage(UIImage(named: "ico_main_ctrlwithvisible"), forState: .Normal)
		sceneManagerButton.setImage(UIImage(named: "ico_main_scene"), forState: .Normal)
		settingsButton.setImage(UIImage(named: "ico_main_settings"), forState: .Normal)
		
		homeManagerLabel.text = homeManagerText
		viewCtrlLabel.text = viewCtrlText
		sceneManagerLabel.text = sceneManagerText
		settingsLabel.text = settingsText
		
		let size = UIScreen.mainScreen().bounds.size
		if size.width == 320 && size.height == 480 { //如果是3.5寸屏
			homeManagerLabel.font = UIFont.systemFontOfSize(15)
			viewCtrlLabel.font = UIFont.systemFontOfSize(15)
			sceneManagerLabel.font = UIFont.systemFontOfSize(15)
			settingsLabel.font = UIFont.systemFontOfSize(15)
			
			homeManagerLabel.frame = CGRectMake(0, 0, homeManagerLabel.bounds.width, bounds.midY - homeManagerButton.frame.maxY)
			viewCtrlLabel.frame = CGRectMake(0, 0, viewCtrlLabel.bounds.width, bounds.midY - viewCtrlButton.frame.maxY)
			sceneManagerLabel.frame = CGRectMake(0, 0, sceneManagerLabel.bounds.width, sceneManagerButton.frame.minY - bounds.midY)
			settingsLabel.frame = CGRectMake(0, 0, settingsLabel.bounds.width, settingsButton.frame.minY - bounds.midY)
		}
		
		homeManagerLabel.center = CGPointMake(homeManagerButton.center.x, bounds.midY - homeManagerLabel.bounds.midY)
		viewCtrlLabel.center = CGPointMake(viewCtrlButton.center.x, bounds.midY - viewCtrlLabel.bounds.midY)
		sceneManagerLabel.center = CGPointMake(sceneManagerButton.center.x, bounds.midY + sceneManagerLabel.bounds.midY)
		settingsLabel.center = CGPointMake(settingsButton.center.x, bounds.midY + settingsLabel.bounds.midY)
		
	}
}
