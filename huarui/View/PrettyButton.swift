//
//  PrettyButton.swift
//  huarui
//
//  Created by sswukang on 15/3/30.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import UIKit

///继承UIButton实现的更好看的button
@IBDesignable class PrettyButton: UIButton {
    private var _saveBackgroundColor: UIColor?
    var hightLightColor    : UIColor  = UIColor.orangeColor()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.opaque = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.opaque = false
    }
    
    @IBInspectable var cornerRadius: CGFloat = 0.0 {
        didSet{
            self.layer.cornerRadius = cornerRadius
        }
	}
	@IBInspectable var borderWidth: CGFloat = 0.0 {
		didSet{
			self.layer.borderWidth = borderWidth
		}
	}
	@IBInspectable var borderColor: UIColor? {
		didSet{
			self.layer.borderColor = borderColor?.CGColor
		}
	}
	@IBInspectable lazy var shouldHighlight: Bool = true
	
    override var backgroundColor: UIColor? {
        didSet{
            self._saveBackgroundColor = backgroundColor
        }
    }
    
    private var __hightlighted: Bool = false
    
    override var highlighted: Bool{
        didSet{
			if !shouldHighlight { return }
            if highlighted && !__hightlighted {
                self.__hightlighted = true
                let anim = CABasicAnimation(keyPath: "backgroundColor")
                anim.toValue  = hightLightColor.CGColor
                anim.duration = 0.1
                anim.fillMode = kCAFillModeForwards
                anim.removedOnCompletion = false
                anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
                self.layer.addAnimation(anim, forKey: "hightlight")
            }
            if !highlighted && __hightlighted {
                self.__hightlighted = false
                let anim = CABasicAnimation(keyPath: "backgroundColor")
                anim.toValue  = _saveBackgroundColor?.CGColor
                anim.duration = 0.3
                anim.fillMode = kCAFillModeForwards
                anim.removedOnCompletion = false
                self.layer.addAnimation(anim, forKey: "unhightlight")
            }
        }
    }
    
}

