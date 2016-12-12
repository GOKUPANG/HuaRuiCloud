//
//  ManipulatorView.swift
//  huarui
//
//  Created by sswukang on 15/5/18.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import UIKit


/// 机械手
class ManipulatorView: UIView {
    var radius:CGFloat = 80
    var ringRadius:CGFloat = 30
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.opaque = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func drawRect(rect: CGRect) {
        
        let context = UIGraphicsGetCurrentContext()
        
        let startColor = UIColor(red: 157/255.0, green: 229/255.0, blue: 254/255.0, alpha: 1)
        let endColor   = UIColor(red: 50/255.0, green: 190/255.0, blue: 238/255.0, alpha: 1)
        
        CGContextSaveGState(context!)
        CGContextTranslateCTM(context!, frame.minX, frame.maxY)
        CGContextScaleCTM(context!, 1, -1)
        
        
        //移动原点到圆形中间
        CGContextSaveGState(context!)
        CGContextTranslateCTM(context!, center.x, center.y)
        CGContextMoveToPoint(context!, 0, 0)
        
        let times = 4*radius / 1
        var red = CGColorGetComponents(startColor.CGColor)[0]
        var green = CGColorGetComponents(startColor.CGColor)[1]
        var blue = CGColorGetComponents(startColor.CGColor)[2]
        var alpha = CGColorGetComponents(startColor.CGColor)[3]
        
        let redInc = (CGColorGetComponents(endColor.CGColor)[0] - red) / times
        let greenInc = (CGColorGetComponents(endColor.CGColor)[1] - green) / times
        let blueInc = (CGColorGetComponents(endColor.CGColor)[2] - blue) / times
        
        
        CGContextSetRGBFillColor(context!, red, green, blue, alpha)
        CGContextAddArc(context!, -radius, -0.01, ringRadius, 0, degreesToAngle(360), 1)
        CGContextFillPath(context!)
		
		var x = -radius
		while(x < radius) {
            let y = sqrt(radius * radius - x * x)
            
            CGContextSetRGBFillColor(context!, red, green, blue, alpha)
            CGContextAddArc(context!, x, y, ringRadius, 0, degreesToAngle(360), 1)
            CGContextFillPath(context!)
            
            red += redInc
            green += greenInc
            blue += blueInc
			alpha += alpha
			x += 1
        }
        
        x = radius
		while(x > -radius) {
            let y = -sqrt(radius * radius - x * x)
            
            CGContextSetRGBFillColor(context!, red, green, blue, alpha)
            CGContextAddArc(context!, x, y, ringRadius, 0, degreesToAngle(360), 1)
            CGContextFillPath(context!)
            
            red += redInc
            green += greenInc
            blue += blueInc
            alpha += alpha
			x -= 1
        }
        
        //中间圆形填充
        CGContextAddArc(context!, 0, 0, radius - ringRadius + 1, 0, degreesToAngle(360), 1)
        CGContextSetRGBFillColor(context!, 226/255.0, 226/255.0, 226/255.0, 1)
        CGContextFillPath(context!)
        
        //外圆轮廓
        CGContextSetLineWidth(context!, 4)
        CGContextSetRGBStrokeColor(context!, 226/255.0, 226/255.0, 226/255.0, 1)
        CGContextAddArc(context!, 0, 0, radius + ringRadius + 1 , 0, degreesToAngle(360), 1)
        CGContextStrokePath(context!)
        
        //内线圈
        CGContextSetStrokeColorWithColor(context!, endColor.CGColor)
        CGContextSetLineWidth(context!, 1)
        CGContextAddArc(context!, 0, 0, radius - ringRadius - 8, 0, degreesToAngle(360), 1)
        CGContextStrokePath(context!)
        
        //红点
        CGContextSetRGBFillColor(context!, 180/255.0, 53/255.0, 40/255.0, 1)
        CGContextAddArc(context!,  -radius + ringRadius + 8, 0, 3, 0, degreesToAngle(360), 1)
        CGContextFillPath(context!)
        
        CGContextRestoreGState(context!)
        CGContextRestoreGState(context!)
        
        
    }
    
    private func degreesToAngle(degress: CGFloat) -> CGFloat{
        return CGFloat(M_PI) * degress / 180.0
    }
    
}
