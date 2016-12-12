//
//  AboutUsViewController.swift
//  huarui
//
//  Created by sswukang on 15/7/20.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import UIKit

/// 设置 - 关于我们
class AboutUsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layer.contents = UIImage(named: APP.param.backgroundImgName)?.CGImage
        self.title = "关于"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
