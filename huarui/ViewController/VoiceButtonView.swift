//
//  VoiceButtonView.swift
//  viewTest
//
//  Created by sswukang on 15/11/6.
//  Copyright © 2015年 huarui. All rights reserved.
//

import UIKit

class VoiceButtonView: UIView,CAAnimationDelegate {
 
	var voiceButton: UIButton!
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		opaque = false
		voiceButton = UIButton()
		voiceButton.setImage(UIImage(named: "ico_main_voice"), forState: .Normal)
		self.addSubview(voiceButton)
	}
	

	required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
    override func drawRect(rect: CGRect) {
		voiceButton.frame = CGRectMake(0, 0, rect.height*0.75, rect.height*0.75)
		voiceButton.center = CGPointMake(rect.midX, rect.height*0.65)
		
		//画个点
		let context = UIGraphicsGetCurrentContext()
		CGContextMoveToPoint(context!, rect.midX, rect.height*0.1)
		CGContextAddArc(context!, rect.midX, rect.height*0.15, rect.height*0.05, 0, 2*CGFloat(M_PI), 0)
		CGContextSetFillColorWithColor(context!, tintColor.CGColor)
		CGContextFillPath(context!)
		
		
    }
	
	private func getCircleLayer() -> CAShapeLayer {
		let layer = CAShapeLayer()
		layer.position = voiceButton.center
		layer.path = UIBezierPath(arcCenter: CGPointZero, radius: voiceButton.imageView!.bounds.midX-3, startAngle: 0, endAngle: CGFloat(2*M_PI), clockwise: true).CGPath
		layer.strokeColor = tintColor.colorWithAlphaComponent(1).CGColor
		layer.lineWidth = 1
		layer.fillColor = nil
		return layer
	}
	
	var isAnimationStated = false
	
	func startAnimation() {
		if isAnimationStated { return }
		let circleLayer = getCircleLayer()
		self.layer.insertSublayer(circleLayer, atIndex: 0)
		
		let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
		scaleAnimation.fromValue = 0.9
		scaleAnimation.toValue = 1.2
		scaleAnimation.duration = 1.5
		scaleAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
		
		let opacityAnim = CABasicAnimation(keyPath: "opacity")
		opacityAnim.timeOffset = 0.5
		opacityAnim.toValue = 0
		opacityAnim.duration = 2
		opacityAnim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
		
		let animGroup = CAAnimationGroup()
		animGroup.duration = 2
		animGroup.repeatCount = HUGE
		animGroup.delegate = self
		animGroup.animations = [scaleAnimation, opacityAnim]
		circleLayer.addAnimation(animGroup, forKey: "animGroup")
		
		runOnMainQueueDelay(400, block: {
			self.startAnimation()
			self.isAnimationStated = true
		})
		
	}
	
	 func animationDidStop(anim: CAAnimation, finished flag: Bool) {
		self.isAnimationStated = false
	}
}
