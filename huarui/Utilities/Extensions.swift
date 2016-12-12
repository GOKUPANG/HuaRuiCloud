//
//  Extension.swift
//  huarui
//
//  Created by sswukang on 16/3/7.
//  Copyright © 2016年 huarui. All rights reserved.
//

import Foundation



//MARK: - extensions

extension UIImage {
	class func initWithColor(color: UIColor, size: CGSize) -> UIImage {
		UIGraphicsBeginImageContext(size)
		let context = UIGraphicsGetCurrentContext()
		
		CGContextSetFillColorWithColor(context!, APP.param.themeColor.CGColor)
		CGContextFillRect(context!, CGRectMake(0, 0, size.width, size.height))
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return image!
	}
}



extension UIColor{
	convenience init(htmlColor: UInt32){
		let alphaPiece = CGFloat((htmlColor & 0xFF00_0000) >> 24)
		let redPiece   = CGFloat((htmlColor & 0x00FF_0000) >> 16)
		let greenPiece = CGFloat((htmlColor & 0x0000_FF00) >> 8)
		let bluePiece  = CGFloat(htmlColor & 0x0000_00FF)
		self.init(red: redPiece/255, green: greenPiece/255, blue: bluePiece/255, alpha: alphaPiece/255)
	}
	
	convenience init(R: Int, G: Int, B: Int, alpha: CGFloat){
		self.init(red: CGFloat(R) / 255.0, green: CGFloat(G) / 255.0, blue: CGFloat(B) / 255.0, alpha: alpha)
	}
	
	///调节亮度值
	///
	///- parameter adjust: 正数为调亮，负数为调暗，范围0~1
	func colorWithAdjustBrightness(adjust: CGFloat) -> UIColor {
		var hue: CGFloat        = 0
		var saturation: CGFloat = 0
		var brightness: CGFloat = 0
		var alpha: CGFloat      = 0
		
		self.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
		brightness += adjust
		if brightness > 1 { brightness = 1 }
		if brightness < 0 { brightness = 0 }
		
		return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
	}
	
	//MARK: --colors for app
	/// tableView的背景
	class func tableBackgroundColor() -> UIColor {
		return UIColor(red:0.93, green:0.93, blue:0.93, alpha:1)
	}
	/// tableView的分割线
	class func tableSeparatorColor() -> UIColor {
		return UIColor(red:0.87, green:0.87, blue:0.87, alpha:1)
	}
	//// tableView标题的颜色
	class func tableTextColor() -> UIColor {
		return UIColor(red:0.13, green:0.13, blue:0.13, alpha:1)
	}
}

extension Array {
	
	///判断某个元素是否存在数组中。参考：http://stackoverflow.com/questions/30319700/array-extension-generic-equatable-cannot-invoke-with/30320159
	func itemExists<T: Equatable>(item: T) -> Bool
	{
		return self.filter({$0 as? T == item}).count > 0
	}
}

extension UIView {
	
	func startRotate(repeatCount: Float = 1000, duration: CFTimeInterval = 2) {
		let anim = CABasicAnimation(keyPath: "transform.rotation.z")
		anim.toValue = M_PI * 2
		anim.duration = duration
		anim.repeatCount = repeatCount
		self.layer.addAnimation(anim, forKey: "rotationAnimation")
	}
	
	///动画是否已经启动
	func rotationStarted() -> Bool {
		return self.layer.animationForKey("rotationAnimation") != nil
	}
	
	func endRotate() {
		self.layer.removeAnimationForKey("rotationAnimation")
	}
	
	func startBackgroundTransition(startColor: UIColor, toColor: UIColor) {
		let anim = CAKeyframeAnimation(keyPath: "backgroundColor")
		anim.values = [startColor.CGColor, toColor.CGColor, startColor.CGColor]
		anim.duration = 3
		anim.repeatCount = 10000
		anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
		self.layer.addAnimation(anim, forKey: "backgroundTransition")
	}
	
	func isBackgroundTransitionStarted() -> Bool {
		return self.layer.animationForKey("backgroundTransition") != nil
	}
	
	func stopBackgroundTransition() {
		self.layer.removeAnimationForKey("backgroundTransition")
		
	}
}

extension NSError {
	convenience init(code: Int, description: String) {
		var userInfo = [NSObject:AnyObject]()
		userInfo[NSLocalizedDescriptionKey] = description
		self.init(domain: kDomain, code: code, userInfo: userInfo)
	}
}


//MARK: - 重载运算符

///增加switch-case结构的case条件判断方法
func ~=<T: Equatable>(lhs: [T], rhs: T) -> Bool {
	for ltmp in lhs where rhs == ltmp {
		return true
	}
	return false
}

