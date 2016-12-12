//
//  ADView.swift
//  ADScrollView
//
//  Created by sswukang on 15/3/20.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import UIKit

/// 主页的滚动广告
class ADScrollView: UIScrollView, UIScrollViewDelegate {
    
    var images: [String]?
    var changeImageTime = 4.0
    
    private var _currentPos = 0
    private var _timer      : NSTimer!
    private var _pageCtrl   : UIPageControl!
    private var _isTimeUP   : Bool = false
    
    private var _leftImage  : UIImageView!
    private var _centerImage: UIImageView!
    private var _rightImage : UIImageView!
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.opaque = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.opaque = false
    }
    
    override func drawRect(rect: CGRect) {
        if images == nil || images!.count == 0{
            Log.warn("ADView.drawRect没有图片可以显示，请设置images")
            return
        }
        
        //添加图片
        _leftImage   = UIImageView(frame: CGRectMake(0, 0, self.frame.width, self.frame.height))
        _centerImage = UIImageView(frame: CGRectMake(self.frame.width, 0, self.frame.width, self.frame.height))
        _rightImage  = UIImageView(frame: CGRectMake(self.frame.width*2, 0, self.frame.width, self.frame.height))
        
        _leftImage.image   = UIImage(named: images![images!.count-1])
        _centerImage.image = UIImage(named: images![0])
        _rightImage.image  = UIImage(named: images![1])
        
        addSubview(_leftImage)
        addSubview(_centerImage)
        addSubview(_rightImage)
        
        //添加PageControl
        _pageCtrl    = UIPageControl()
        let pageCenter  = CGPointMake(frame.minX + (frame.width / 2), frame.maxY - 10)
        _pageCtrl.center = pageCenter
        _pageCtrl.numberOfPages      = images!.count
        _pageCtrl.hidesForSinglePage = true
        self.superview!.addSubview(_pageCtrl)
        
        //设置ScrollView的属性
        self.bounces       = false
        self.pagingEnabled = true
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator   = false
        self.contentOffset  = CGPointMake(self.frame.width, 0)
        self.delegate       = self
        self.contentSize    = CGSizeMake(self.frame.width * 3, self.frame.height)
        
//        DLog("定时器启动。。。。")
        _timer = NSTimer.scheduledTimerWithTimeInterval(changeImageTime, target: self, selector: #selector(timerTimeUp(_:)), userInfo: nil, repeats: true)
        _timer.fire()
    }
    
    func timerTimeUp(timer: NSTimer){
//        DLog("定时时间到")
        UIView.transitionWithView(self, duration: 0.5, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            self.contentOffset = CGPointMake(self.frame.width*2, 0)
            }) { (completed) -> Void in
                self._isTimeUP = true
                self.scrollViewDidEndDecelerating(self)
        }
    }


    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        _timer.fireDate = NSDate(timeIntervalSinceNow: changeImageTime)
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
//        DLog("scrollViewDidEndDecelerating, currentPos=\(_currentPos), will +1.")
        var leftPos   = 0
        var rightPos  = 0
        if self.contentOffset.x == self.frame.width{
            return
        }
        if self.contentOffset == CGPoint.zero{
//            DLog("向→→→→→→滑, currentPos=\(_currentPos), will -1.")
			_currentPos -= 1
            if _currentPos == -1{
                _currentPos = images!.count - 1
                leftPos  = _currentPos - 1
                rightPos = 0
            } else {
                leftPos  = _currentPos - 1
                rightPos = _currentPos + 1
                if leftPos == -1 {
                    leftPos = images!.count - 1
                }
            }
        } else {
//            DLog("向←←←←←←滑, currentPos=\(_currentPos), will +1.")
			_currentPos += 1
            if _currentPos == images!.count {
                _currentPos = 0
                leftPos  = images!.count - 1
                rightPos = _currentPos + 1
            } else {
                leftPos  = _currentPos - 1
                rightPos = _currentPos + 1
                if _currentPos == images!.count - 1{
                    rightPos = 0
                }
            }
        }
        _leftImage.image = UIImage(named: images![leftPos])
        _centerImage.image = UIImage(named: images![_currentPos])
        _rightImage.image = UIImage(named: images![rightPos])
        self._pageCtrl.currentPage = _currentPos
        self.contentOffset = CGPointMake(self.frame.width, 0)
        if !_isTimeUP {
            _timer.fireDate = NSDate(timeIntervalSinceNow: changeImageTime)
        }
        _isTimeUP = false
    }
    
}
