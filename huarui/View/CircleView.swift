//
//  CircleView.swift
//  LuxView
//
//  Created by sswukang on 15/5/26.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import Foundation
import UIKit

/// 传感器页面使用的圆圈显示值
class CircleView: UIView{
    
    private var _trackStart: CGFloat = 0
    private var _trackEnd  : CGFloat = 0
    private var _radius    : CGFloat = 0
    private var _numlabel  : UILabel!
    private var _unitLabel : UILabel!
    private var _pointLayer: PointLayer!
    private var _trackLayer: CAShapeLayer!
    private var _currentValue:Float = 0
    
    var currentValue: Float {
        get{
            return _currentValue
        }
    }
    
    /**最大值*/
    var maxValue:CGFloat = 4000
    /**主颜色*/
    var mainColor = UIColor(hue: 55/360.0, saturation: 1.0, brightness: 1.0, alpha: 1)
    /**显示数字的颜色渐变*/
    var isNumLabelColorGradient = true
    /**在圆环上显示当前位置*/
    var showPoint = false {
        didSet{
            if showPoint && _pointLayer == nil {
                _pointLayer = PointLayer()
                _pointLayer.bounds = bounds
                _pointLayer.position = CGPointMake(frame.width/2, frame.height/2)
                _pointLayer.radius = _radius
                self.layer.addSublayer(_pointLayer)
                _pointLayer.setNeedsDisplay()
            }
            else if !showPoint && _pointLayer != nil {
                _pointLayer.removeFromSuperlayer()
            }
        }
    }
    /**单位*/
    var unitText: String = "Lux"{
        didSet{
            if let label = _unitLabel {
                label.text = unitText
            }
        }
    }
    
    var startValue: Int = 0{
        didSet{
            if startValue == endValue{
                _trackStart = _trackEnd
                if startValue == 0 {
                    _trackStart = -CGFloat(M_PI)/2
                }
                setNeedsDisplay()
                return
            }
            _trackStart = CGFloat(startValue) / maxValue * 2 * CGFloat(M_PI) - CGFloat(M_PI)/2
            _trackLayer.strokeStart = CGFloat(startValue) / maxValue
            //            _trackLayer.strokeStart = 0
        }
    }
    
    var endValue: Int = 0{
        didSet{
            if startValue == endValue{
                _trackEnd = _trackStart
                if endValue == 0 {
                    _trackEnd = -CGFloat(M_PI)/2
                }
                setNeedsDisplay()
                return
            }
            _trackEnd = CGFloat(endValue) / maxValue * 2 * CGFloat(M_PI) - CGFloat(M_PI)/2
            
            setNeedsDisplay()
            let anim = CABasicAnimation(keyPath: "strokeEnd")
            anim.fromValue = _trackLayer.strokeEnd
            anim.toValue = CGFloat(endValue) / maxValue
            anim.fillMode = kCAFillModeForwards
            anim.removedOnCompletion = false
            anim.duration = 0.5
            anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
            
            _trackLayer.addAnimation(anim, forKey: "strokeEnd")
        }
    }
    
    /**显示的值是否是整数*/
    var valueUseInt = true
    
    var value: Float = 0{
        didSet{
            if _numlabel != nil {
                if value == _currentValue {
                    return
                }
                let diff = value - _currentValue > 0 ? value - _currentValue : _currentValue - value
                let step = diff / 50
                let delayUS:Int64 = 1000_000_000 / 50
//                if step < 1{
//                    step = 1
//                    delayUS = Int64(1000_000_000 / diff)
//                }
                value - _currentValue > 0 ? addValueAnimation(step, delayUS: delayUS) : subValueAnimation(step, delayUS: delayUS)
            }
        }
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        let centerPoint = CGPointMake(frame.width/2, frame.height/2)
        _radius = frame.width/3
        if _radius*2+20 > frame.height{
            _radius = frame.height * 0.4
        }
        self.opaque = false
        _trackLayer = CAShapeLayer()
        _trackLayer.frame = self.frame
        _trackLayer.position = CGPointMake(frame.width/2, frame.height/2)
        _trackLayer.path = UIBezierPath(arcCenter: centerPoint, radius: _radius-3, startAngle: -CGFloat(M_PI)/2, endAngle: CGFloat(M_PI)*2-CGFloat(M_PI)/2, clockwise: true).CGPath
        _trackLayer.strokeColor = mainColor.CGColor
        _trackLayer.fillColor = nil
        _trackLayer.lineWidth = 6
        _trackLayer.strokeStart = 0
        _trackLayer.strokeEnd = 0
        self.layer.addSublayer(_trackLayer)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    private func addValueAnimation(add: Float, delayUS: Int64){
        if _currentValue + add < value {
            setNumLabelText(_currentValue)
            _currentValue += add
            let time = dispatch_time(DISPATCH_TIME_NOW, delayUS)
            dispatch_after(time, dispatch_get_main_queue(), {
                self.addValueAnimation(add, delayUS: delayUS)
            })
        }
        else if _currentValue < value{
            _currentValue = value
            setNumLabelText(_currentValue)
        }
    }
    
    private func subValueAnimation(sub: Float, delayUS: Int64){
        if _currentValue - sub > value{
            setNumLabelText(_currentValue)
            _currentValue -= sub
            let time = dispatch_time(DISPATCH_TIME_NOW, delayUS)
            dispatch_after(time, dispatch_get_main_queue(), {
                self.subValueAnimation(sub, delayUS: delayUS)
            })
        }
        else if _currentValue > value{
            _currentValue = value
            setNumLabelText(_currentValue)
        }
    }
    
    private func setNumLabelText(num: Float){
        if valueUseInt {
            _numlabel.text = "\(Int(num))"
        } else {
            _numlabel.text = (NSString(format: "%.2f", num) as String)
        }
        var v = CGFloat(num)/maxValue * 0.9
        v = v > 0.9 ? 0.9: v
        var h: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        if isNumLabelColorGradient {
            mainColor.getHue(&h, saturation: nil, brightness: &b, alpha: &a)
            _numlabel.textColor = UIColor(hue: h, saturation: 1-v, brightness: b, alpha: a)
        } else {
            _numlabel.textColor = mainColor
        }
        
        if showPoint {
            if CGFloat(num) > maxValue {
                _pointLayer.angle = 2 * CGFloat(M_PI) - CGFloat(M_PI)/2
            } else {
                _pointLayer.angle = CGFloat(num)/maxValue * 2 * CGFloat(M_PI) - CGFloat(M_PI)/2
            }
            _pointLayer.setNeedsDisplay()
        }
    }
    
    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        for v in subviews{
            v.removeFromSuperview()
        }
        
        CGContextSaveGState(context!)
        CGContextTranslateCTM(context!, rect.width/2, rect.height/2)
        
        CGContextSetStrokeColorWithColor(context!, mainColor.CGColor)
        CGContextSetLineWidth(context!, 2)
        CGContextAddArc(context!, 0, 0, _radius, 0, 2 * CGFloat(M_PI), 1)
        CGContextStrokePath(context!)
        
        
        _unitLabel = UILabel(frame: CGRectMake(0, 0, _radius, _radius*0.4))
        _unitLabel.center = CGPointMake(rect.width/2, rect.height/2 + _radius*0.3 + _unitLabel.frame.height)
        _unitLabel.text = self.unitText
        _unitLabel.textColor = self.mainColor
        _unitLabel.textAlignment = NSTextAlignment.Center
        _unitLabel.font = UIFont.systemFontOfSize(_radius*0.2)
        addSubview(_unitLabel)
        
        _numlabel = UILabel(frame: CGRectMake(rect.width/2-_radius*0.9, rect.height/2-_radius/2, _radius*1.8, _radius))
        
        _numlabel.textAlignment = NSTextAlignment.Center
        setNumLabelText(value)
        _numlabel.textColor = mainColor
        _numlabel.adjustsFontSizeToFitWidth = true
        _numlabel.font = UIFont.systemFontOfSize(_radius*2/3)
        addSubview(_numlabel)
        
        if startValue != endValue && endValue != 0{
            addLabel("\(startValue)", angle: _trackStart, radius: _radius-5)
            
            addLabel("\(endValue)", angle: _trackEnd, radius: _radius-5)
        }
        
        
        CGContextRestoreGState(context!)
    }
    
    
    private func addLabel(text: String, angle: CGFloat, radius:CGFloat){
        let label = UILabel()
        label.text = text
        label.textColor = UIColor.whiteColor()
        label.font = UIFont(name: ".HelveticaNeueInterface-Thin", size: 12)
        let attr = [NSFontAttributeName: UIFont.systemFontOfSize(12)]
        let textSize = NSString(string:text).sizeWithAttributes(attr)
        label.frame = CGRectMake(0, 0, textSize.width, textSize.height)
		
//		var x = frame.width/2 + radius * cos(angle) - (cos(angle) * sqrt(textSize.width*textSize.width + textSize.height*textSize.height)) / 2
		var x = cos(angle) * sqrt(textSize.width*textSize.width + textSize.height*textSize.height) / 2
		x = frame.width/2 + radius * cos(angle) - x
		
//        let y = frame.height/2 + radius * sin(angle) - (sin(angle) * sqrt(textSize.width*textSize.width + textSize.height*textSize.height)) / 2
		var y = (sin(angle) * sqrt(textSize.width*textSize.width + textSize.height*textSize.height)) / 2
		y = frame.height/2 + radius * sin(angle) - y
        label.center = CGPointMake(x, y)
        addSubview(label)
    }
    
    private func degreesToAngle(degress: CGFloat) -> CGFloat{
        return CGFloat(M_PI) * degress / 180.0
    }
    
    //MARK: - PointLayer
    
    internal class PointLayer: CAShapeLayer {
        var angle : CGFloat = 0
        var radius: CGFloat = 0
        
        override init(){
            super.init()
        }
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        }
        
        override init(layer: AnyObject) {
            super.init(layer: layer)
            self.angle = (layer as! PointLayer).angle
        }
        
        override class func needsDisplayForKey(key: String) -> Bool {
            if key == "angle" || key == "radius"{
                return true
            }
            else {
                return super.needsDisplayForKey(key)
            }
        }
        
        override func drawInContext(context: CGContext) {
            shouldRasterize = true
            rasterizationScale = 0.9
            CGContextSetInterpolationQuality(context, CGInterpolationQuality.High)
            let x = position.x + radius * cos(angle)
            let y = position.y + radius * sin(angle)
            CGContextAddArc(context, x, y, 4, 0, CGFloat(2*M_PI), 1)
            CGContextSetFillColorWithColor(context, UIColor(red: 171/255.0, green: 66/255.0, blue: 51/255.0, alpha: 1).CGColor)
            CGContextFillPath(context)
        }
        
    }
}
