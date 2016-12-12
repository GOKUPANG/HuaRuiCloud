//
//  CommonViewController.swift
//  huarui
//
//  Created by sswukang on 15/1/19.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import UIKit

/**
* 常用设备
*/
class CommonViewController: UITabBarController {
    
    @IBOutlet weak var devTabBar: UITabBar!
    var navbarTitle: String = "" {
        didSet {
            self.title = navbarTitle
        }
    }
	
    //点击返回按钮，返回到上一层
    @IBAction func onBackBtnClicked(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    func addCenterButton() {
        let centerButton = UIButton()
        
        let centerBtnImg  = UIImage(named: "底栏-语音控制")
        let hightlightImg = UIImage(named: "底栏-语音控制")
        
        if let _ = centerBtnImg {
            centerButton.frame = CGRectMake(0, 0, centerBtnImg!.size.width, centerBtnImg!.size.height)
            centerButton.autoresizingMask = [UIViewAutoresizing.FlexibleRightMargin, .FlexibleLeftMargin, .FlexibleBottomMargin, .FlexibleTopMargin]
            centerButton.setBackgroundImage(centerBtnImg, forState: UIControlState.Normal)
            centerButton.setBackgroundImage(hightlightImg, forState: UIControlState.Highlighted)
            centerButton.addTarget(self, action: nil, forControlEvents: UIControlEvents.TouchUpInside)
            
            let imgHeight = centerBtnImg!.size.height
            let barHeight = devTabBar.frame.height
            let delta     = imgHeight - barHeight
            
            let centerX = devTabBar.frame.width / 2
            var centerY: CGFloat
            if delta <= 0 { //图片比bar低
                centerY = devTabBar.frame.height / 2
            } else {
                centerY = devTabBar.frame.height / 2 - delta / 2
            }
            centerButton.center = CGPointMake(centerX, centerY)
            tabBar.backgroundImage = UIImage.initWithColor(UIColor.redColor(), size: tabBar.frame.size)
            tabBar.shadowImage = UIImage(named: "shadowImage")
            devTabBar.addSubview(centerButton)
        }
        
        centerButton.addTarget(self, action: #selector(CommonViewController.onCenterButtonClicked(_:)), forControlEvents: UIControlEvents.TouchUpInside)
    }
	
	override func viewDidLoad() {
		super.viewDidLoad()
		addCenterButton()
		//tabbar items 的未选图片
		if let items = self.tabBar.items {
			for i in 0..<items.count {
				let item = items[i]
				switch i {
				case 0:
					item.image = UIImage(named: "底栏-常用设备")?.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
				case 1:
					item.image = UIImage(named: "底栏-房间管理")?.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
				case 3:
					item.image = UIImage(named: "底栏-安防")?.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
				case 4:
					item.image = UIImage(named: "底栏-探测器")?.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
				default: break
				}
			}
		}
	}
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        
    }
    
    func onCenterButtonClicked(sender: UIButton){
        let voiceUtls = VoiceUtils.shareInstance()
        voiceUtls.startGramListening()
        
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
