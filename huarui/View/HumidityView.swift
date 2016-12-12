//
//  HumidityView.swift
//  湿度管理器
//
//  Created by sswukang on 15/6/16.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import UIKit


/// 使用CG画的一个水滴
class WaterDopView: UIView {
    var color: UIColor
    var dropSize: CGFloat = 20{
        didSet{
            setNeedsDisplay()
        }
    }
    var lineWidth: CGFloat = 1
    
    override init(frame: CGRect) {
        self.color = UIColor.whiteColor()
        super.init(frame: frame)
        self.opaque = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.color = UIColor.whiteColor()
        super.init(coder: aDecoder)
	}
	
	override func drawRect(rect: CGRect) {
		self.layer.anchorPoint = CGPointZero
		let context = UIGraphicsGetCurrentContext()
		let topPoint = CGPointMake(rect.width/2, dropSize + lineWidth - 2)
		//圆心
		let arcPoint = CGPointMake(topPoint.x, rect.height - dropSize - lineWidth - 2)
		CGContextSetStrokeColorWithColor(context!, color.CGColor)
		CGContextSetFillColorWithColor(context!, color.CGColor)
		CGContextSetLineWidth(context!, lineWidth)
		
		CGContextAddArc(context!, arcPoint.x, arcPoint.y, dropSize, degreesToAngle(-20), degreesToAngle(200), 0)
		let point = CGContextGetPathCurrentPoint(context!)
		//顶点
		CGContextAddLineToPoint(context!, topPoint.x, topPoint.y)
		CGContextAddLineToPoint(context!, topPoint.x + topPoint.x - point.x, point.y)
		CGContextStrokePath(context!)
		
		CGContextAddArc(context!, arcPoint.x, arcPoint.y, dropSize * 0.7, degreesToAngle(25), degreesToAngle(65), 0)
		CGContextStrokePath(context!)
		
		self.layer.anchorPoint = CGPointMake(0.5, topPoint.y / rect.height)
		self.layer.position = CGPointMake(frame.midX, topPoint.y)
	}
	
	
	func drawRect0(rect: CGRect) {
		let context = UIGraphicsGetCurrentContext()
		let origin = CGPointMake(rect.width/2, 0)
		//圆心
		let arcPoint = CGPointMake(origin.x, origin.y + dropSize*2.5)
		CGContextSetStrokeColorWithColor(context!, color.CGColor)
		CGContextSetFillColorWithColor(context!, color.CGColor)
		CGContextSetLineWidth(context!, lineWidth)
		
		CGContextAddArc(context!, arcPoint.x, arcPoint.y, dropSize, degreesToAngle(-20), degreesToAngle(200), 0)
		let point = CGContextGetPathCurrentPoint(context!)
		//顶点
		let topPoint = CGPointMake(origin.x, origin.y)
		CGContextAddLineToPoint(context!, topPoint.x, topPoint.y)
		CGContextAddLineToPoint(context!, origin.x + origin.x - point.x, point.y)
		CGContextStrokePath(context!)
		
		CGContextAddArc(context!, arcPoint.x, arcPoint.y, dropSize * 0.7, degreesToAngle(25), degreesToAngle(65), 0)
		CGContextStrokePath(context!)
	}
	
	
    private func degreesToAngle(degress: CGFloat) -> CGFloat{
        return CGFloat(M_PI) * degress / 180.0
    }
}

/// 湿度view
class HumidityView: UIView {
	///显示圆形边框
	var showArc: Bool = false
    var radius: CGFloat = 90
    var color = UIColor.whiteColor()
    var value: Float = 33.3 {
        didSet{
            _textLabel.text = NSString(format: "%.1f", value) as String
        }
    }
    
    
    private var _textLabel: UILabel!
    private var _dropView: WaterDopView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        radius = frame.width/2-4
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
		unitLabel.text = "%"
		unitLabel.textColor = self.color
		unitLabel.font = UIFont(name: ".HelveticaNeueInterface-Thin", size: 15)
		addSubview(unitLabel)
		
		
		let dropHeight = unitLabel.frame.minY
        _dropView = WaterDopView(frame: CGRectMake(bounds.midX - dropHeight/2, 0, dropHeight, dropHeight))
        _dropView.dropSize = _dropView.bounds.height * (1-0.618) / 2
//        _dropView.layer.anchorPoint = CGPointMake(0.5, 0)
        addSubview(_dropView)
        
        self.opaque = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func drawRect(rect: CGRect) {
		if showArc {
			let context = UIGraphicsGetCurrentContext()
			CGContextSetStrokeColorWithColor(context!, color.CGColor)
			CGContextSetLineWidth(context!, 1)
			CGContextAddArc(context!, rect.width/2, rect.height/2, radius, 0, degreesToAngle(360), 0)
			
			CGContextStrokePath(context!)
		}
    }
		
    func startAnimation(duration: CFTimeInterval){
        let bounceAnim = CAKeyframeAnimation(keyPath: "transform.scale")
//        bounceAnim.values = [1.0 ,1.4, 0.9, 1.15, 0.95, 1.02, 1.0]
        bounceAnim.values   = [1.0, 0.5, 1.1, 0.95, 1.05, 1.0]
        bounceAnim.duration = duration
        bounceAnim.calculationMode = kCAAnimationCubic
        _dropView.layer.addAnimation(bounceAnim, forKey: "bounceAnimation")
    }
    
    private func degreesToAngle(degress: CGFloat) -> CGFloat{
        return CGFloat(M_PI) * degress / 180.0
    }
}
