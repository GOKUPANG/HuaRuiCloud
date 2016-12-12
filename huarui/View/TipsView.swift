//
//  TipsView.swift
//  huarui
//
//  Created by sswukang on 15/3/26.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import UIKit

/// 标题栏显示的tips
class TipsView: UILabel {
    private var height: CGFloat!
    
    override init(frame: CGRect){
        super.init(frame: frame)
        self.opaque = false
        self.hidden = true
        self.textColor = UIColor.whiteColor()
        self.font = UIFont.systemFontOfSize(15)
        self.textAlignment = NSTextAlignment.Center
        self.backgroundColor = UIColor(red: 244/255.0, green: 162/255.0, blue: 0/255.0, alpha: 1)
        
        self.height = frame.height

    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    
    private var _timer: NSTimer?
    
    ///显示
    ///
    ///- parameter text: 显示的文字
    ///- parameter duration: 时间，单位为秒
    func show(text: String, duration: Double){
        
        self.backgroundColor = UIColor(red: 244/255.0, green: 162/255.0, blue: 0/255.0, alpha: 1)
        if !hidden {  //如果还显示
            //先隐藏
            UIView.transitionWithView(self, duration: 0.3, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
				self.alpha = 0
                }, completion: { (completed) in
                    self.hidden = true
                    self.show(text, duration: duration)
            })
			
            return
		}
		self.text = text
		self.hidden = false
        UIView.transitionWithView(self, duration: 0.5, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
			self.alpha = 1
        }, completion: nil)
        
        if _timer != nil {
            _timer!.invalidate()
        }
        
        _timer = NSTimer.scheduledTimerWithTimeInterval(duration, target: self, selector: #selector(TipsView.timeup(_:)), userInfo: nil, repeats: false)
    }
    
    //MARK:新增方法
    func show(text: String, duration: Double, tipsViewColor: UIColor){
        
        self.backgroundColor = tipsViewColor
        
        if !hidden {  //如果还显示
            //先隐藏
            UIView.transitionWithView(self, duration: 0.3, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
                self.alpha = 0
                }, completion: { (completed) in
                    self.hidden = true
                    self.show(text, duration: duration)
            })
            
            return
        }
        self.text = text
        self.hidden = false
        UIView.transitionWithView(self, duration: 0.5, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            self.alpha = 1
            }, completion: nil)
        
        if _timer != nil {
            _timer!.invalidate()
        }
        
        _timer = NSTimer.scheduledTimerWithTimeInterval(duration, target: self, selector: #selector(TipsView.timeup(_:)), userInfo: nil, repeats: false)
    }
    
    func timeup(timer: NSTimer){
        if !self.hidden {
            self.dismiss()
        }
    }
    
    func dismiss(){
        UIView.transitionWithView(self, duration: 0.3, options: UIViewAnimationOptions.CurveEaseOut, animations: {
//            self.hidden = true
			self.alpha = 0
        }, completion: { (completed) in
			self.hidden = true
        })
    }
}
