//
//  PM25View.swift
//
//  Created by sswukang on 15/6/17.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import UIKit

/// 显示PM2.5的view
class PM25View: UIView{
    var lineWidth: CGFloat = 2
    var color = UIColor.whiteColor()
    
    var value: Float = 0{
        didSet {
            _numLabel.text = NSString(format: "%.1f", value) as String
        }
    }
	
	
    private var _numLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.opaque = false
        
        let radius = (frame.width-8) / 2
        
        let textLabel = UILabel(frame: CGRectMake(frame.width/2-radius/2, frame.height/2-radius*0.75, radius, radius/2))
        textLabel.text = "PM2.5"
        textLabel.textColor = color
        textLabel.textAlignment = NSTextAlignment.Center
        textLabel.font = UIFont(name: ".HelveticaNeueInterface-Thin", size: textLabel.frame.height*0.4)
        
        //        textLabel.backgroundColor = UIColor.orangeColor()
        addSubview(textLabel)
        
        _numLabel = UILabel(frame: CGRectMake(frame.width/2-radius, frame.height/2-radius/4, radius*2, radius/2))
        _numLabel.text = "234.6"
        _numLabel.textAlignment = .Center
        _numLabel.textColor = color
        _numLabel.adjustsFontSizeToFitWidth = true
        _numLabel.font = UIFont(name: ".HelveticaNeueInterface-Thin", size: _numLabel.frame.height)
        
        //        _numLabel.backgroundColor = UIColor.greenColor()
        addSubview(_numLabel)
        
        let unitLabel = UILabel(frame: CGRectMake(frame.width/2-radius/2, frame.height/2+radius*0.35, radius, radius*0.4))
        unitLabel.text = "μg/m³"
        unitLabel.textColor = color
        unitLabel.textAlignment = NSTextAlignment.Center
        unitLabel.font = UIFont(name: ".HelveticaNeueInterface-Thin", size: textLabel.frame.height*0.4)
        
        addSubview(unitLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        let originPoint = CGPointMake(rect.width/2, rect.height/2)
        let radius = (rect.width-8) / 2
        
        CGContextSetLineWidth(context!, lineWidth)
        CGContextSetStrokeColorWithColor(context!, color.CGColor)
        CGContextAddArc(context!, originPoint.x, originPoint.y, radius, 0, CGFloat(M_PI) * 2, 1)
        CGContextStrokePath(context!)
        
    }
    
}
