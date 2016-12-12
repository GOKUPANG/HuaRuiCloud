//
//  RegisterButton.swift
//  viewTest
//
//  Created by sswukang on 15/7/7.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import Foundation
import UIKit

///注册设备时的注册button
class RegisterButton: UIButton,CAAnimationDelegate {
    private var _ringLayer: CAShapeLayer
    var lineWidth: CGFloat = 6
    weak var delegate: RegisterButtonDelegate?
    var duration: CFTimeInterval = 15
    var circleColor: UIColor = UIColor.orangeColor()
    var ringColor:   UIColor = UIColor.greenColor()
    
    override init(frame: CGRect) {
        _ringLayer = CAShapeLayer()
        super.init(frame: frame)
        self.opaque = false
        _ringLayer.path = UIBezierPath(arcCenter: CGPointMake(frame.width/2, frame.height/2), radius: frame.width/2 + lineWidth/2, startAngle: 0, endAngle: 3.1415926*2, clockwise: true).CGPath
        _ringLayer.strokeColor = UIColor.clearColor().CGColor
        _ringLayer.fillColor = UIColor.clearColor().CGColor
        _ringLayer.lineWidth = lineWidth
        _ringLayer.strokeStart = 0
        _ringLayer.strokeEnd = 1
        _ringLayer.position = CGPointMake(0, frame.height)
        //        _ringLayer.anchorPoint = CGPointMake(frame.width/2, frame.height/2)
        _ringLayer.transform = CATransform3DMakeRotation(-3.1415926/2, 0, 0, 1)
        self.layer.addSublayer(_ringLayer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        _ringLayer = CAShapeLayer()
        super.init(coder: aDecoder)
    }
    
    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        CGContextAddArc(context!, rect.width/2, rect.width/2, rect.width/2, 0, 3.1415926*2, 0)
        CGContextSetFillColorWithColor(context!, circleColor.CGColor)
        CGContextFillPath(context!)
    }
    
    private var animated: Bool = false {
        didSet {
            if animated {
                startChangeTitle()
            } else {
                self.setTitle(titleBackup, forState: UIControlState.Normal)
                //回到原始大小
                let animScale = CABasicAnimation(keyPath: "transform.scale")
                animScale.duration = 0.5
                animScale.toValue = 1.0
                animScale.fillMode = kCAFillModeForwards
                animScale.removedOnCompletion = false
                animScale.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
                animScale.delegate = self
                layer.addAnimation(animScale, forKey: "animScaleZoomIn")
            }
        }
    }
    
    private var titleBackup: String?
    private var registeringTitle: String?
    private var dotString = "   "
    
    private func startChangeTitle(){
        if self.animated {
            if dotString == "   " {
                dotString = ".  "
            }
            else if dotString == ".  "{
                dotString = ".. "
            }
            else if dotString == ".. "{
                dotString = "..."
            }
            else if dotString == "..." {
                dotString = "   "
            }
            if let title = registeringTitle {
                self.setTitle("\(title)\(dotString)", forState: .Normal)
            }
            runOnMainQueueDelay(800, block: {
                self.startChangeTitle()
            })
        }
    }
    
    func startRegistering(registeringTitle: String?) {
        if animated {
            return
        }
        titleBackup = self.titleLabel?.text
        self.registeringTitle = registeringTitle
        animated = true
//        var animScale = CAKeyframeAnimation(keyPath: "transform.scale")
//        animScale.duration = 0.8
//        animScale.values = [1.0, 1.02, 1.05, 0.9, 0.8, 0.70, 0.75, 0.8]
//        animScale.calculationMode = kCAAnimationCubic
//        animScale.fillMode = kCAFillModeForwards
//        animScale.removedOnCompletion = false
//        animScale.delegate = self
        let animScale = CABasicAnimation(keyPath: "transform.scale")
        animScale.duration = 0.5
        animScale.toValue  = 0.8
//        animScale.calculationMode = kCAAnimationCubic
        animScale.fillMode = kCAFillModeForwards
        animScale.removedOnCompletion = false
        animScale.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        animScale.delegate = self
        self.layer.addAnimation(animScale, forKey: "animScale")
    }
    
    func pauseRegistering(title: String) {
        registeringTitle = title
        //隐藏
        let animDismiss = CABasicAnimation(keyPath: "strokeColor")
        animDismiss.duration = 1
        animDismiss.toValue  = UIColor.clearColor().CGColor
        animDismiss.fillMode = kCAFillModeForwards
        animDismiss.removedOnCompletion = false
        animDismiss.delegate = self
        _ringLayer.addAnimation(animDismiss, forKey: "animDismiss")
        
    }
    
    func stopRegistering(){
        animated = false
        //隐藏
        let animHide = CABasicAnimation(keyPath: "strokeColor")
        animHide.duration = 1
        animHide.toValue  = UIColor.clearColor().CGColor
        animHide.fillMode = kCAFillModeForwards
        animHide.removedOnCompletion = false
        animHide.delegate = self
        _ringLayer.addAnimation(animHide, forKey: "animHide")
    }
    
     func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        
        if anim === layer.animationForKey("animScale") {
            //            println("animScale did Stop")
            let animShow = CABasicAnimation(keyPath: "strokeColor")
            animShow.duration = 1
            animShow.toValue = ringColor.CGColor
            animShow.fillMode = kCAFillModeForwards
            animShow.removedOnCompletion = false
            animShow.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
            
            let animStroke = CABasicAnimation(keyPath: "strokeEnd")
            animStroke.duration = 15
            animStroke.toValue = 0
            animStroke.fillMode = kCAFillModeForwards
            animStroke.removedOnCompletion = false
            animStroke.delegate = self
            
            _ringLayer.addAnimation(animShow, forKey: "animShow")
            _ringLayer.addAnimation(animStroke, forKey: "animStroke")
        }
        else if anim === _ringLayer.animationForKey("animStroke") {
            //            println("animStroke did Stop")
            self.animated = false
            delegate?.registerButton(self, end: true)
            return
        }
        else if anim === _ringLayer.animationForKey("animHide") {
//            println("animHide did Stop")
            _ringLayer.removeAllAnimations()
        }
        else if anim === _ringLayer.animationForKey("animDismiss") {
//            println("animDismiss did Stop")
            _ringLayer.removeAllAnimations()
            _ringLayer.strokeEnd = 1
            if !animated {
                return
            }
            let animShow = CABasicAnimation(keyPath: "strokeColor")
            animShow.duration = 1
            animShow.toValue = ringColor.CGColor
            animShow.fillMode = kCAFillModeForwards
            animShow.removedOnCompletion = false
            animShow.delegate = self
            animShow.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            _ringLayer.addAnimation(animShow, forKey: "animShow")
        }
        else if anim === _ringLayer.animationForKey("animShow") {
            if !animated {
                return
            }
            //隐藏
            let animDismiss = CABasicAnimation(keyPath: "strokeColor")
            animDismiss.duration = 1
            animDismiss.toValue  = UIColor.clearColor().CGColor
            animDismiss.fillMode = kCAFillModeForwards
            animDismiss.removedOnCompletion = false
            animDismiss.delegate = self
            animDismiss.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            _ringLayer.addAnimation(animDismiss, forKey: "animDismiss")
        }
        else if anim === layer.animationForKey("animScaleZoomIn") {
            //            println("animScaleZoomIn did Stop")
            layer.removeAllAnimations()
        }
    }
}

protocol RegisterButtonDelegate: class {
    func registerButton(button: RegisterButton, end: Bool);
}
