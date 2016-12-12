//
//  RootNavigationViewController.swift
//  huarui
//
//  Created by sswukang on 15/12/17.
//  Copyright © 2015年 huarui. All rights reserved.
//

import UIKit

/// 一般的navigationVC
class RootNavgationViewController: UINavigationController {
	
	override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
		return UIInterfaceOrientationMask.Portrait
	}
	
	override func shouldAutorotate() -> Bool {
		return false
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()

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
