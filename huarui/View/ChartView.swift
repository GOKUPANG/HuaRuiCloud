//
//  ChartView.swift
//  LuxView
//
//  Created by sswukang on 15/5/29.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import Foundation
import UIKit

/// 传感器页面使用的表格
class ChartView: UIView{
    var values = [Float]()
    var maxX = 15
    var maxY = 4000
    var strokColor = UIColor.orangeColor()
    var fillColor  = UIColor(red: 1, green: 128/255.0, blue: 0, alpha: 0.3)
    
    private var currentMaxY = 4000
    
    var isCurve = false{
        didSet{
            setNeedsDisplay()
        }
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.opaque = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func drawRect(rect: CGRect) {
        let originPoint = CGPointMake(0, rect.height)
        let context = UIGraphicsGetCurrentContext()
        CGContextSaveGState(context!)
        CGContextTranslateCTM(context!, originPoint.x, originPoint.y-1)
        CGContextScaleCTM(context!, 1, -1)
        ////////////////////////////////////////////////////////////////////////////
        
        let chartWidth  = rect.width - originPoint.x * 2
        let chartHeight = frame.height - 10
        
        let (_, max) = getMinMax(values)
        if max >= 0 && max < 10 {
            currentMaxY = 10
        }
        else if max >= 10 && max < 50 {
            currentMaxY = 50
        }
        else if max >= 50 && max < 100 {
            currentMaxY = 100
        }
        else if max >= 100 && max < 200 {
            currentMaxY = 200
        }
        else if max >= 200 && max < 500 {
            currentMaxY = 500
        }
        else if max >= 500 && max < 1000 {
            currentMaxY = 1000
        }
        else if max >= 1000 && max < 2000 {
            currentMaxY = 2000
        }
        else if max >= 2000 && max < 4000 {
            currentMaxY = 4000
        } else {
            currentMaxY = Int(max)
        }
        
        for v in self.subviews {
            v.removeFromSuperview()
        }
        //画等高线
        for i in 0...10{
            var mark = 0
            CGContextMoveToPoint(context!, 0, chartHeight * CGFloat(i)/10)
            CGContextAddLineToPoint(context!, chartWidth, chartHeight * CGFloat(i)/10)
            CGContextSetRGBStrokeColor(context!, 1, 1, 1, 0.2-CGFloat(i)/10*0.15)
            CGContextStrokePath(context!)
            if i % 2 == 0{
                mark = currentMaxY - Int(CGFloat(currentMaxY) * CGFloat(i) / 10.0)
                
                let labelHeight = ((1/10.0) * chartHeight) * 0.4
                let markLabel = UILabel(frame: CGRectMake(2, chartHeight * CGFloat(i)/10 - labelHeight + 7, labelHeight * 5, labelHeight))
                markLabel.text = "\(mark)"
                markLabel.textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.2+CGFloat(i)/10*0.15)
                markLabel.font = UIFont.systemFontOfSize(labelHeight*1.2)
                addSubview(markLabel)
            }
        }
        
        if values.count == 0{
            CGContextRestoreGState(context!)
            return
        }
        
        //X轴的段宽
        let xStep = chartWidth/CGFloat(maxX-1)
        //Y轴的段高
        let yStep = chartHeight/CGFloat(currentMaxY)
        let path = UIBezierPath()
        path.moveToPoint(CGPointMake(0, yStep * CGFloat(values[0])))
		for (i, value) in values.enumerate() {
            let point = CGPointMake(xStep * CGFloat(i+1), yStep * CGFloat(value))
            
            if !isCurve {
                path.addLineToPoint(point)
                if i == values.count {
                    strokColor.setStroke()
                    fillColor.setFill()
                    path.stroke()
                    UIColor.clearColor().setStroke()
                    path.addLineToPoint(CGPointMake(point.x, 0))
                    path.addLineToPoint(CGPoint.zero)
                    path.closePath()
                    path.fill()
                }
                continue
            }
            
            let prevPoint = CGPointMake(xStep * CGFloat(i-1), yStep * CGFloat(values[i-1]))
            var nextPoint:CGPoint
            
            if i != values.count-1 {
                nextPoint = CGPointMake(xStep * CGFloat(i+1), yStep * CGFloat(values[i+1]))
            } else {
                nextPoint = CGPointMake(0, 0)
            }
            let cx1 = (prevPoint.x - nextPoint.x)/6 + point.x
            let cy1 = (prevPoint.y - nextPoint.y)/6 + point.y
            
            if i == 1 {
                path.addQuadCurveToPoint(point, controlPoint: CGPointMake(cx1, cy1))
                
            }
            else {
                let pprevPoint = CGPointMake(xStep * CGFloat(i-2), yStep * CGFloat(values[i-2]))
                let cxf = (point.x - pprevPoint.x)/6 + prevPoint.x
                let cyf = (point.y - pprevPoint.y)/6 + prevPoint.y
                if i == values.count-1{
                    path.addQuadCurveToPoint(point, controlPoint: CGPointMake(cxf, cyf))
                    
                    strokColor.setStroke()
                    fillColor.setFill()
                    path.stroke()
                    UIColor.clearColor().setStroke()
                    path.addLineToPoint(CGPointMake(point.x, 0))
                    path.addLineToPoint(CGPoint.zero)
                    path.closePath()
                    path.fill()
                    
                } else {
                    path.addCurveToPoint(point, controlPoint1: CGPointMake(cxf, cyf), controlPoint2: CGPointMake(cx1, cy1))
                }
            }
        }        
        
        ////////////////////////////////////////////////////////////////////////////
        CGContextRestoreGState(context!)
        
    }
    
    func addValue(value: Float, animation: Bool){
        if values.count == maxX{
            values.removeAtIndex(0)
        }
        values.append(value)
        setNeedsDisplay()
    }
    
    
    func getMinMax(values: [Float]) -> (Float, Float){
        var min:Float = 0
        var max:Float = 0
        for i in values {
            min = i < min ? i : min
            max = i > max ? i : max
        }
        return (min, max)
    }
}
