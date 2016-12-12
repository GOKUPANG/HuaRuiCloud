//
//  TempView.swift
//
//  Created by sswukang on 15/6/17.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import Foundation
import UIKit


/// 温度
class ThermometerView: UIView {
    var color: UIColor = UIColor.whiteColor()
    var lineWidth: CGFloat = 1
    
    private var _radius: CGFloat = 0
    private var _cylinderLayer: CAShapeLayer!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.opaque = false
        
        _radius = (frame.height - 6) / 6
        
        _cylinderLayer = CAShapeLayer()
        let originPoint = CGPointMake(frame.width/2, frame.height - _radius - 6)
        let path = UIBezierPath()
        path.moveToPoint(CGPointMake(originPoint.x, originPoint.y))
        path.addLineToPoint(CGPointMake(originPoint.x, originPoint.y - _radius*4))
        _cylinderLayer.frame = frame
        _cylinderLayer.position = CGPointMake(frame.width/2, frame.height/2)
        _cylinderLayer.lineWidth = _radius*0.2
        _cylinderLayer.lineCap = kCALineCapRound
        _cylinderLayer.path = path.CGPath
        _cylinderLayer.strokeColor = color.CGColor
        _cylinderLayer.strokeStart = 0
        _cylinderLayer.strokeEnd = 1
        self.layer.addSublayer(_cylinderLayer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        let originPoint = CGPointMake(rect.width/2, rect.height - _radius - lineWidth - 2)
        CGContextSetStrokeColorWithColor(context!, color.CGColor)
        CGContextSetFillColorWithColor(context!, color.CGColor)
        CGContextSetLineWidth(context!, lineWidth)
		
		//底部的大圆
        CGContextAddArc(context!, originPoint.x, originPoint.y, _radius, degreesToAngle(30-90), degreesToAngle(330-90), 0)
		//顶部的小圆
        CGContextAddArc(context!, originPoint.x, originPoint.y-_radius*4, _radius/2, degreesToAngle(180), degreesToAngle(0), 0)
        let point2 = CGContextGetPathCurrentPoint(context!)
        CGContextClosePath(context!)
        CGContextStrokePath(context!)
        
        //中间
        CGContextAddArc(context!, originPoint.x, originPoint.y, _radius*0.4, 0, degreesToAngle(360), 0)
        CGContextFillPath(context!)
        
        //刻度
        CGContextSetLineWidth(context!, lineWidth)
		var y:CGFloat = 5
		while(y <= _radius*3-5) {
            CGContextMoveToPoint(context!, point2.x-_radius*0.2, point2.y+y)
            CGContextAddLineToPoint(context!, point2.x, point2.y+y)
            CGContextStrokePath(context!)
			y += (_radius*3-10)/8 
        }
        
    }
    
    func startAnimation(duration: CFTimeInterval){
        let anim = CAKeyframeAnimation(keyPath: "strokeEnd")
        anim.values = [1.0, 0.6, 1.0, 0.8, 1.0, 0.9, 1.0, 0.95, 1.0]
        anim.duration = duration
        anim.calculationMode = kCAAnimationCubic
        _cylinderLayer.addAnimation(anim, forKey: "bounceAnimation")
    }
    
    private func degreesToAngle(degress: CGFloat) -> CGFloat{
        return CGFloat(M_PI) * degress / 180.0
    }
    
    
    
}

class TempView: UIView {
    var color = UIColor.whiteColor()
    var lineWidth: CGFloat = 1{
        didSet{
            _thermometer.lineWidth = lineWidth
        }
    }
    var radius: CGFloat = 90
	//显示圆形边框
	var showArc: Bool = false
	var value: Float = 0 {
        didSet {
            _textLabel.text = NSString(format: "%.1f", value) as String
        }
    }
    
    private var _thermometer: ThermometerView!
    private var _textLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.opaque = false
        
        radius = frame.width/2 - 4
        let width = radius*1.3
		
		
        _textLabel = UILabel(frame: CGRectMake(0, frame.height - width/2, width, width/2))
		_textLabel.center.x = self.bounds.midX
        _textLabel.textAlignment = NSTextAlignment.Center
        _textLabel.adjustsFontSizeToFitWidth = true
        _textLabel.textColor = color
        _textLabel.font = UIFont(name: ".HelveticaNeueInterface-Thin", size: _textLabel.bounds.height*0.8)
		addSubview(_textLabel)
		
		let unitLabel = UILabel(frame: CGRectMake(0, _textLabel.frame.minY - 20, width, 20))
		unitLabel.center.x = self.bounds.midX
		unitLabel.textAlignment = .Center
		unitLabel.text = "℃"
		unitLabel.textColor = self.color
		unitLabel.font = UIFont(name: ".HelveticaNeueInterface-Thin", size: 15)
		self.addSubview(unitLabel)
		
		let tmpHeight = unitLabel.frame.minY
        _thermometer = ThermometerView(frame: CGRectMake(bounds.midX-tmpHeight/2, 0, tmpHeight, tmpHeight))
        _thermometer.lineWidth = lineWidth
        addSubview(_thermometer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    override func drawRect(rect: CGRect) {
		if showArc {
			let context = UIGraphicsGetCurrentContext()
			CGContextSetStrokeColorWithColor(context!, color.CGColor)
			CGContextSetLineWidth(context!, lineWidth)
			CGContextAddArc(context!, rect.width/2, rect.height/2, radius, 0, degreesToAngle(360), 0)
			
			CGContextStrokePath(context!)
		}
    }
	
    func startAnimation(duration: CFTimeInterval = 1.5) {
        _thermometer.startAnimation(duration)
    }
    
    
    private func degreesToAngle(degress: CGFloat) -> CGFloat{
        return CGFloat(M_PI) * degress / 180.0
    }
    
}
