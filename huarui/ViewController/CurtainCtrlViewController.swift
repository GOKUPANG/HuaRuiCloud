//
//  CurtainCtrlViewController.swift
//  huarui
//
//  Created by sswukang on 15/3/23.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import UIKit

class CurtainCtrlViewController: UIViewController {
    var curtainDev: HRCurtainCtrlDev!
    
    @IBOutlet weak var openButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
	@IBOutlet weak var image: UIImageView!
	private var tipsView: TipsView!
	
	
    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer.contents = UIImage(named: APP.param.backgroundImgName)?.CGImage
        
//        let btnWidth = self.view.frame.width / 4
//        let gapWidth = (self.view.frame.width - btnWidth * 3) / 4
//        let y = image.frame.maxY + (self.view.frame.height - image.frame.height) / 2 - btnWidth/2
//        
//        openButton = UIButton(frame: CGRectMake(gapWidth, y, btnWidth, btnWidth))
//        stopButton = UIButton(frame: CGRectMake(gapWidth * 2 + btnWidth, y, btnWidth, btnWidth))
//        closeButton = UIButton(frame: CGRectMake(gapWidth * 3 + btnWidth * 2, y, btnWidth, btnWidth))
//        
//        openButton.setImage(UIImage(named: "ico_control_curtain_open"), forState: UIControlState.Normal)
//        stopButton.setImage(UIImage(named: "ico_control_curtain_stop"), forState: UIControlState.Normal)
//        closeButton.setImage(UIImage(named: "ico_control_curtain_close"), forState: UIControlState.Normal)
		
        openButton.addTarget(self, action: #selector(CurtainCtrlViewController.openButtonClick(_:)), forControlEvents: UIControlEvents.TouchDown)
        stopButton.addTarget(self, action: #selector(CurtainCtrlViewController.stopButtonClick(_:)), forControlEvents: UIControlEvents.TouchDown)
        closeButton.addTarget(self, action: #selector(CurtainCtrlViewController.closeButtonClick(_:)), forControlEvents: UIControlEvents.TouchDown)
        
//        view.addSubview(openButton)
//        view.addSubview(stopButton)
//        view.addSubview(closeButton)
		
		
        tipsView = TipsView(frame: CGRectMake(0, 0, view.frame.width, 30))
        
        view.addSubview(tipsView)
		
		self.title = curtainDev == nil ? "(窗帘控制)" : curtainDev!.name
		
    }
    
    override func viewDidAppear(animated: Bool) {
		//如果设备为空，则推出界面
		if curtainDev == nil {
			self.navigationController?.popViewControllerAnimated(true)
			return 
		}
    }
	
	/**打开窗帘*/
	func openButtonClick(sender: UIButton) {
		tipsView.show("正在打开...", duration: 5.0)
		
		curtainDev.open({
			(error) in
			if let err = error {
				self.tipsView.show("暂时无法操作：\(err.domain)", duration: 3.0)
			}
		})
	}
	
	/**停止窗帘*/
	func stopButtonClick(sender: UIButton) {
		tipsView.show("正在停止...", duration: 5.0)
		curtainDev.stop {
			(error) in
			if let err = error {
				self.tipsView.show("暂时无法操作：\(err.domain)", duration: 3.0)
			}
		}
	}
	
	/**关闭窗帘*/
	func closeButtonClick(sender: UIButton) {
		tipsView.show("正在关闭...", duration: 5.0)
		curtainDev.close({
			(error)  in
			if let err = error {
				self.tipsView.show("暂时无法操作：\(err.domain)", duration: 3.0)
			}
		})
	}
}
