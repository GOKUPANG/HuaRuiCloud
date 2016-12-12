//
//  SmartBedViewController.swift
//  huarui
//
//  Created by sswukang on 15/6/4.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import UIKit

class SmartBedViewController: UIViewController {
    var bedDev: HRSmartBed!
    var tipsView: TipsView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = bedDev.name
        self.view.layer.contents = UIImage(named: APP.param.backgroundImgName)?.CGImage
        let locY = navigationController!.navigationBar.frame.maxY
        tipsView = TipsView(frame: CGRectMake(0, locY, view.frame.width, 30))
        self.view.addSubview(tipsView)
        
        initComponent()
    }
    
    private var tabBar: UIView?
    
    override func viewWillAppear(animated: Bool) {
        if let tabBar = tabBarController?.tabBar{
            self.tabBar = tabBar
            UIView.transitionWithView(tabBar, duration: 0.8, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                tabBar.frame = CGRectMake(0, tabBar.frame.maxY + 200, tabBar.frame.width, tabBar.frame.height)
                }, completion: nil)
            
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        if let tabBar = self.tabBar{
            UIView.transitionWithView(tabBar, duration: 0.3, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                tabBar.frame = CGRectMake(0, tabBar.frame.minY - 200 - tabBar.frame.height, tabBar.frame.width, tabBar.frame.height)
                }, completion: nil)
            
        }
    }
    
    private func initComponent(){
        
        let btnSize = CGSizeMake(view.frame.width/4, view.frame.width/4)
        let gapHorz = btnSize.width/4
        let color = APP.param.themeColor
        let corner = btnSize.width/4
        var x = gapHorz
        var y = gapHorz*2 + navigationController!.navigationBar.frame.maxY
        
        var headUpBtn = UIButton(frame: CGRectMake(x, y, btnSize.width, btnSize.height))
        headUpBtn.backgroundColor = color
        headUpBtn.layer.cornerRadius = corner
        headUpBtn.setTitle("UP", forState: UIControlState.Normal)
        headUpBtn.tag = 1
        headUpBtn.addTarget(self, action: "onButtonClicked:", forControlEvents: UIControlEvents.TouchDown)
        var gesture = UITapGestureRecognizer(target: self, action: "onTap:")
        headUpBtn.addGestureRecognizer(gesture)
        
        var flatBtn = UIButton(frame: CGRectMake(headUpBtn.frame.maxX + gapHorz, y, btnSize.width, btnSize.height))
        flatBtn.backgroundColor = color
        flatBtn.layer.cornerRadius = corner
        flatBtn.setTitle("FLAT", forState: UIControlState.Normal)
        flatBtn.tag = 2
        flatBtn.addTarget(self, action: "onButtonClicked:", forControlEvents: UIControlEvents.TouchDown)
        
        var footUpBtn = UIButton(frame: CGRectMake(flatBtn.frame.maxX + gapHorz, y, btnSize.width, btnSize.height))
        footUpBtn.backgroundColor = color
        footUpBtn.layer.cornerRadius = corner
        footUpBtn.setTitle("UP", forState: UIControlState.Normal)
        footUpBtn.tag = 3
        footUpBtn.addTarget(self, action: "onButtonClicked:", forControlEvents: UIControlEvents.TouchDown)
        gesture = UITapGestureRecognizer(target: self, action: "onTap:")
        footUpBtn.addGestureRecognizer(gesture)
        
        y = headUpBtn.frame.maxY + gapHorz
        var headLabel = UILabel(frame: CGRectMake(headUpBtn.frame.minX, y, btnSize.width, gapHorz))
        headLabel.text = "HEAD"
        headLabel.textColor = UIColor.whiteColor()
        headLabel.textAlignment = NSTextAlignment.Center
        
        var footLabel = UILabel(frame: CGRectMake(footUpBtn.frame.minX, y, btnSize.width, gapHorz))
        footLabel.text = "FOOT"
        footLabel.textColor = UIColor.whiteColor()
        footLabel.textAlignment = NSTextAlignment.Center
        
        y = headLabel.frame.maxY + gapHorz
        var headDownBtn = UIButton(frame: CGRectMake(headUpBtn.frame.minX, y, btnSize.width, btnSize.height))
        headDownBtn.backgroundColor = color
        headDownBtn.layer.cornerRadius = corner
        headDownBtn.setTitle("DOWN", forState: UIControlState.Normal)
        headDownBtn.tag = 4
        headDownBtn.addTarget(self, action: "onButtonClicked:", forControlEvents: UIControlEvents.TouchDown)
        gesture = UITapGestureRecognizer(target: self, action: "onTap:")
        headDownBtn.addGestureRecognizer(gesture)
        
        var readBtn = UIButton(frame: CGRectMake(flatBtn.frame.minX, y, btnSize.width, btnSize.height))
        readBtn.backgroundColor = color
        readBtn.layer.cornerRadius = corner
        readBtn.setTitle("READING", forState: UIControlState.Normal)
        readBtn.tag = 5
        readBtn.addTarget(self, action: "onButtonClicked:", forControlEvents: UIControlEvents.TouchDown)
        
        var footDownBtn = UIButton(frame: CGRectMake(footUpBtn.frame.minX, y, btnSize.width, btnSize.height))
        footDownBtn.backgroundColor = color
        footDownBtn.layer.cornerRadius = corner
        footDownBtn.setTitle("DOWN", forState: UIControlState.Normal)
        footDownBtn.tag = 6
        footDownBtn.addTarget(self, action: "onButtonClicked:", forControlEvents: UIControlEvents.TouchDown)
        gesture = UITapGestureRecognizer(target: self, action: "onTap:")
        footDownBtn.addGestureRecognizer(gesture)
        
        var massageLabel = UILabel(frame: CGRectMake(0, 0, btnSize.width * 2, btnSize.height))
        massageLabel.center = CGPointMake(view.center.x, footDownBtn.frame.maxY + btnSize.height/2)
        massageLabel.text = "MASSAGE"
        massageLabel.textColor = UIColor.whiteColor()
        massageLabel.textAlignment = NSTextAlignment.Center
        
        y = headDownBtn.frame.maxY + btnSize.height
        var msgHeadBtn = UIButton(frame: CGRectMake(headUpBtn.frame.minX, y, btnSize.width, btnSize.height))
        msgHeadBtn.backgroundColor = color
        msgHeadBtn.layer.cornerRadius = corner
        msgHeadBtn.titleLabel?.adjustsFontSizeToFitWidth = true
        msgHeadBtn.setTitle("HEAD", forState: UIControlState.Normal)
        msgHeadBtn.tag = 7
        msgHeadBtn.addTarget(self, action: "onButtonClicked:", forControlEvents: UIControlEvents.TouchDown)
        
        var msgOnOffBtn = UIButton(frame: CGRectMake(readBtn.frame.minX, y, btnSize.width, btnSize.height))
        msgOnOffBtn.backgroundColor = color
        msgOnOffBtn.layer.cornerRadius = corner
        msgOnOffBtn.titleLabel?.adjustsFontSizeToFitWidth = true
        msgOnOffBtn.setTitle("ON/OFF", forState: UIControlState.Normal)
        msgOnOffBtn.tag = 8
        msgOnOffBtn.addTarget(self, action: "onButtonClicked:", forControlEvents: UIControlEvents.TouchDown)
        
        var msgFootBtn = UIButton(frame: CGRectMake(footDownBtn.frame.minX, y, btnSize.width, btnSize.height))
        msgFootBtn.backgroundColor = color
        msgFootBtn.layer.cornerRadius = corner
        msgFootBtn.titleLabel?.adjustsFontSizeToFitWidth = true
        msgFootBtn.setTitle("FOOT", forState: UIControlState.Normal)
        msgFootBtn.tag = 9
        msgFootBtn.addTarget(self, action: "onButtonClicked:", forControlEvents: UIControlEvents.TouchDown)
        
        
        view.addSubview(headUpBtn)
        view.addSubview(flatBtn)
        view.addSubview(footUpBtn)
        view.addSubview(headLabel)
        view.addSubview(footLabel)
        view.addSubview(headDownBtn)
        view.addSubview(readBtn)
        view.addSubview(footDownBtn)
        view.addSubview(massageLabel)
        view.addSubview(msgHeadBtn)
        view.addSubview(msgOnOffBtn)
        view.addSubview(msgFootBtn)
        
        var barbtn = UIBarButtonItem(title: "绑定", style: UIBarButtonItemStyle.Plain, target: self, action: "onBindButtonClicked:")
        self.navigationItem.rightBarButtonItem = barbtn
        
    }
    
    func onBindButtonClicked(barButton: UIBarButtonItem){
        performSegueWithIdentifier("showBindTableViewController", sender: bedDev)
    }
    
    func onButtonClicked(button: UIButton){
        var devAddr: UInt32? = nil
        var action: HRMotorOperateType? = nil
        switch button.tag{
        case 1:
            devAddr = bedDev.poleHeadAddr
            action  = .Open
        case 2:
            if let headAddr = bedDev.poleHeadAddr {
                operateDev(bedDev.poleHeadAddr!, action: .Close)
            }
            if let footAddr = bedDev.poleFootAddr {
                operateDev(bedDev.poleFootAddr!, action: .Close)
            }
            return
        case 3:
            devAddr = bedDev.poleFootAddr
            action  = .Open
        case 4:
            devAddr = bedDev.poleHeadAddr
            action  = .Close
        case 5:
            tipsView.show("暂时不支持Reading位", duration: 2.0)
            return
        case 6:
            devAddr = bedDev.poleFootAddr
            action  = .Close
        case 7:
            devAddr = bedDev.vibratoeAddr
            action  = .Open
        case 8:
            devAddr = bedDev.vibratoeAddr
            action  = .Stop
        case 9:
            devAddr = bedDev.vibratoeAddr
            action  = .Close
        default:
            break
        }
        if devAddr != nil && action != nil {
            operateDev(devAddr!, action: action!)
        } else {
            tipsView.show("该动作没有绑定设备", duration: 2.0)
        }
        
    }
    
    func onTap(gesture: UITapGestureRecognizer) {
        switch gesture.state {
        case .Ended:
            var devAddr: UInt32? = nil
            switch gesture.view!.tag {
            case 1,4:
                devAddr = bedDev.poleHeadAddr
            case 3,6:
                devAddr = bedDev.poleFootAddr
            default:
                break
            }
            if let addr = devAddr {
                operateDev(addr, action: .Stop, showTip: false)
            }
        default:
            break
        }
    }
    
    
    private func operateDev(devAddr: UInt32, action: HRMotorOperateType, showTip: Bool = true, text: String = "通信中...", duration: Double = 1){
        for motor in HR8000Helper.shareInstance()!.getMotors(){
            if motor.devAddr == devAddr {
                self.tipsView.show(text, duration: duration)
                HR8000Helper.shareInstance()!.operateCurtain(actionType: action, motor: motor, tag: 34, callback: {
                    (success, msg) in
                    if !success {
                        self.tipsView.show("失败：\(msg)", duration: 2.5)
                    }
                })
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showBindTableViewController" {
            let controller = segue.destinationViewController as! SmartBedBindViewController
            controller.bedDev = sender as! HRSmartBed
        }
    }
    

}
