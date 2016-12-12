//
//  DoorLockViewController.swift
//  huarui
//
//  Created by sswukang on 15/5/15.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import UIKit

class DoorLockViewController: UIViewController,UITextFieldDelegate {

    var device: HRDevice!
    var textFrame: UITextField!
    var tabBar: UITabBar?
    var tipsView: TipsView!
    
    //文字大小
    var textSize: CGFloat!
    //码文大小
    var textSizePswd: CGFloat!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer.contents = UIImage(named: APP.param.backgroundImgName)?.CGImage
        
        if device != nil {
            self.navigationItem.title = device!.name
        }
        initComponent()
        //添加tipsView 斌注释
        tipsView = TipsView(frame: CGRectMake(0, 0, view.frame.width, 30))
        self.view.addSubview(tipsView)
        
    }
    
	override func viewDidAppear(animated: Bool) {
        
        //如果设备为空的话就返回上一个界面 斌注释
		if device == nil {
			self.navigationController?.popViewControllerAnimated(true)
			return
		}
	}
    
    private func initComponent(){
        var height = UIScreen.mainScreen().bounds.height
        let width  = UIScreen.mainScreen().bounds.width
        var minY:CGFloat = 0.0
        height -= self.navigationController!.navigationBar.frame.height + UIApplication.sharedApplication().statusBarFrame.height
        //边框颜色
        let borderColor = UIColor.blackColor()
        //边框大小
        let borderWidth:CGFloat = 1.0
        
        ///与屏幕边界的距离
        var boundary = width / 16.0
        //圆形按键的半径
        var btnRadius = width / 8.0
        //控件之间垂直间距
        //        var gapVertical: CGFloat = (height - boundary * 4 - btnRadius*2*5) / 4
        //控件之间的间隙 斌注释
        var gapVertical: CGFloat = boundary
        if gapVertical < 0 {
            gapVertical = -gapVertical
        }
        
        textSize = btnRadius * 0.4
        textSizePswd = btnRadius * 0.7
        
        //密码显示框
        textFrame = UITextField(frame: CGRectMake(boundary, boundary, width - boundary * 2, btnRadius))
        
        textFrame.layer.borderWidth = borderWidth
        textFrame.layer.borderColor = borderColor.CGColor
        textFrame.layer.cornerRadius = 3
        textFrame.secureTextEntry = true
        textFrame.textAlignment = NSTextAlignment.Center
        textFrame.placeholder = "请输入门锁密码"
        textFrame.enabled = false
        textFrame.font = UIFont.systemFontOfSize(textSize)
        
        
        
        func getButton(minX: CGFloat, minY: CGFloat, title: String, tag: Int, image:String? = nil) -> UIButton{
            let btn = PrettyButton(frame: CGRectMake(minX, minY, btnRadius*2, btnRadius*2))
            btn.setTitle(title, forState: UIControlState.Normal)
            btn.titleLabel?.font = UIFont(name: ".HelveticaNeueInterface-Thin", size: btnRadius)
            btn.setTitleColor(borderColor, forState: .Normal)
            btn.hightLightColor = UIColor(red: 48/255.0, green: 189/255.0, blue: 238/255.0, alpha: 1)
            btn.layer.cornerRadius = btnRadius
            btn.layer.borderWidth = borderWidth
            btn.layer.borderColor = borderColor.CGColor
            btn.tag = tag
            btn.addTarget(self, action: #selector(DoorLockViewController.onButtonClicked(_:)), forControlEvents: .TouchUpInside)
            return btn
        }
        
        //按照以上的变量布局绝对不会让控件超出横向屏幕，但是垂直屏幕超不超就不知道了
        //假如超了，就要改变以上某些变量的值
        if boundary*3 + gapVertical*4 + btnRadius*9 > height {
            minY = textFrame.frame.maxY + gapVertical
            btnRadius = (height - minY) / 10
            gapVertical = btnRadius / 2 - gapVertical * 0.4
            btnRadius += btnRadius * 0.1
            boundary = (width - btnRadius*6) / 4
            textFrame.frame = CGRectMake(boundary, textFrame.frame.minY, btnRadius*6 + boundary*2, textFrame.frame.height)
        } else {
            minY = textFrame.frame.maxY + boundary*2
        }
        
        var x = boundary
        let btn1 = getButton(x, minY: minY, title: "1", tag: 1)
        x += btnRadius * 2 + boundary
        let btn2 = getButton(x, minY: minY, title: "2", tag: 2)
        x += btnRadius * 2 + boundary
        let btn3 = getButton(x, minY: minY, title: "3", tag: 3)
        
        x = boundary
        minY = minY + btnRadius*2 + gapVertical
        let btn4 = getButton(x, minY: minY, title: "4", tag: 4)
        x += btnRadius * 2 + boundary
        let btn5 = getButton(x, minY: minY, title: "5", tag: 5)
        x += btnRadius * 2 + boundary
        let btn6 = getButton(x, minY: minY, title: "6", tag: 6)
        
        x = boundary
        minY = minY + btnRadius*2 + gapVertical
        let btn7 = getButton(x, minY: minY, title: "7", tag: 7)
        x += btnRadius * 2 + boundary
        let btn8 = getButton(x, minY: minY, title: "8", tag: 8)
        x += btnRadius * 2 + boundary
        let btn9 = getButton(x, minY: minY, title: "9", tag: 9)
        
        x = boundary
        minY = minY + btnRadius*2 + gapVertical
        let btnStart = getButton(x, minY: minY, title: "OK", tag: 11)
        x += btnRadius * 2 + boundary
        let btn0 = getButton(x, minY: minY, title: "0", tag: 0)
        x += btnRadius * 2 + boundary
        let btnSharp = getButton(x, minY: minY, title: "←", tag: 12)
        
        let getsture = UILongPressGestureRecognizer(target: self, action: #selector(onButtonLongClicked(_:)))
        getsture.minimumPressDuration = 1
        btnSharp.addGestureRecognizer(getsture)
        
        self.view.addSubview(btn1)
        self.view.addSubview(btn2)
        self.view.addSubview(btn3)
        self.view.addSubview(btn4)
        self.view.addSubview(btn5)
        self.view.addSubview(btn6)
        self.view.addSubview(btn7)
        self.view.addSubview(btn8)
        self.view.addSubview(btn9)
        self.view.addSubview(btn0)
        self.view.addSubview(btnStart)
        self.view.addSubview(btnSharp)
        
        
        self.view.addSubview(textFrame)
    }
    
    
    func onButtonClicked(button: UIButton){
		
		guard let passwd = textFrame.text else {
			tipsView.show("密码不能为空！", duration: 1.5)
			return
		}
		
        switch(button.tag){
        case 11:    //OK键开锁
            if passwd.characters.count == 0 {
                
               // print(passwd)
                tipsView.show("密码不能为空！", duration: 1.5)
                break
            }
            
            
            // 门锁相关 判断不同的锁使用不同的开锁方法
            switch device.devType{
            case HRDeviceType.DoorLock.rawValue:
                
                
                //斌修改的代码 增加判断是否输入特定字符串"39026922"，输入这个字符串直接提示输入密码错误
                
                if passwd == "39026922" {
                    KVNProgress.showWithStatus("开锁")
                    KVNProgress.showErrorWithStatus("密码错误")
                    // tipsView.show("密码错误", duration: 1.5)
                    break
                }
                
                
                
                unlockDoor(passwd)
                
                if passwd == "1234567890" {
                    KVNProgress.showWithStatus("这个是初始密码，建议修改为6位数的密码")
                    
                    
                    //tipsView.show("这个是初始密码，建议修改为6位数的密码", duration: 3.5)
                    // break
                }

                
                
                break
                
                
            case HRDeviceType.GaoDunDoor.rawValue :
                
                
                if passwd.characters.count<6||passwd.characters.count>12
                {
                    
                    KVNProgress.showErrorWithStatus("请输入6到12位的密码")
                    break
                }
                
                
                
                unlockGaoDunLock(passwd)
                
                print("点击了高盾🔐开锁的OK按钮")
                
                
                
                break
                
            default:
                
                break
                
            }
            
            
           
        case 12:	//删除键
            if passwd.characters.count == 0{
                break
            }
            textFrame.text = (passwd as NSString).substringToIndex(passwd.characters.count-1)
            if textFrame.text?.characters.count == 0{
                textFrame.font = UIFont.systemFontOfSize(textSize)
            }
        default:
            textFrame.font = UIFont.systemFontOfSize(textSizePswd)
            if passwd.characters.count == 16{
                break
            }
            var text:String = passwd
            text += "\(button.tag)"
            textFrame.text = text
            
        }
        
        
    }

    //长按把文字全部删除
    func onButtonLongClicked(gesture: UILongPressGestureRecognizer){
        switch(gesture.state){
        case .Began:
            textFrame.text = ""
            textFrame.font = UIFont.systemFontOfSize(textSize)
        default:
            break
        }
    }
    
    
    
    
    //新增高盾锁的开锁方法 门锁相关 斌
    
    
    private func unlockGaoDunLock(passwd: String)
    
    {
        KVNProgress.showWithStatus("开锁")
        (device as! HRSmartDoor).unlockSmartDoor(passwd, result: {
            (error) in
            
            
            
            if let err = error{
                
                
                
                print("错误码\(err.code)")
                
                           
                if err.code == HRErrorCode.Timeout.rawValue{
                    //                    self.tipsView.show("\(err.domain)", duration: 5.0)
                    KVNProgress.showErrorWithStatus("\(err.domain)")

                    
                } else {
                    KVNProgress.showErrorWithStatus("\(err.domain)")
                }
            }
                
                
            else {
                KVNProgress.showSuccessWithStatus("智能门锁已打开")
            }
            
        })

    }
    
    

	private func unlockDoor(passwd: String){
        
    //开锁帧在这里 斌注释关于门锁
        KVNProgress.showWithStatus("开锁")
        (device as! HRDoorLock).unlock(passwd, result: {
            (error) in
            
//            if passwd == "39026922"
//            {
//                KVNProgress.showErrorWithStatus("密码错误")
//                
//            }

            

            if let err = error{
                
                print("错误码\(err.code)")

                if err.code == HRErrorCode.BatteryLowPower.rawValue{
//                    self.tipsView.show("\(err.domain)", duration: 5.0)
				} else {
					KVNProgress.showErrorWithStatus("\(err.domain)")
				}
            }
            
                
            else {
                KVNProgress.showSuccessWithStatus("智能门锁已打开")
            }
            
        })
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
