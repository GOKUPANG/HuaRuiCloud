//
//  Login2CUSwift.swift
//  huarui
//
//  Created by sswukang on 15/5/13.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import Foundation


class Connect2CUHelper: NSObject{
    
    /**检查是否已经注册了账号*/
    class func checkRegistration() -> (Bool, String, String){
        let user = NSUserDefaults.standardUserDefaults().stringForKey("2cuUserName")
        let pswd = NSUserDefaults.standardUserDefaults().stringForKey("2cuPassword")
        if user == nil || pswd == nil{
                return (false, "", "")
        }
        return (true, user!, pswd!)
    }
    
    /**注册一个2cu的账号*/
    class func register2cuAcount(callback: (NSError?)->Void){
        //生成账号：4个随机字母+时间@gzhuarui.cn
        let rand = arc4random()
        let a1 = rand % 26 + 65
        let a2 = (rand / 7) % 26 + 65
        let a3 = (rand / 13) % 26 + 65
        let a4 = (rand / 9) % 26 + 65
        let time = NSDate().timeIntervalSince1970 % 100_000_000
        let passwd = NSString(format: "%.0f", time) as String
        let email  = NSString(format: "%c%c%c%c\(passwd)@gzhuarui.cn", a1,a2,a3,a4) as String
        Login2CU.registerAcount(email, passwd: passwd, callback: {
            (error) in
            if error == nil { //注册成功
                Log.info("注册2cu账号成功：\(email)")
                //保存账号信息
                NSUserDefaults.standardUserDefaults().setValue(email, forKey: "2cuUserName")
                NSUserDefaults.standardUserDefaults().setValue(passwd, forKey: "2cuPassword")
                callback(nil)
                return
            }
            callback(error)
        })
    }
	
	///打开门锁
	///
	/// - parameter inView: 门锁选择界面显示的父view
	class func unlockDoor(inView: UIView) {
		let lockView = NSBundle.mainBundle().loadNibNamed("UnlockDoorLocksView", owner: self, options: nil)![0] as! UnlockDoorLocksView
		lockView.frame = CGRectMake(0, 0, 300, inView.bounds.height*0.7)
		lockView.center.x = inView.bounds.midX
		lockView.center.y = inView.bounds.midY - 20
		lockView.cancelButton.layer.borderColor = UIColor.whiteColor().CGColor
		lockView.backgroundView = UIView(frame: inView.bounds)
		lockView.showInView(inView)
	}
}


