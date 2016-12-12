//
//  SceneTabBarBaseViewController.swift
//  huarui
//
//  Created by sswukang on 15/11/9.
//  Copyright © 2015年 huarui. All rights reserved.
//

import UIKit

class SceneTabBarBaseViewController: UITabBarController {

	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		if let items = self.tabBar.items {
			for i in 0..<items.count {
				let item = items[i]
				switch i {
				case 0:
					item.image = UIImage(named: "底栏-情景模式")?.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
				case 1:
					item.image = UIImage(named: "底栏-定时任务")?.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
				case 2:
					item.image = UIImage(named: "底栏-情景面板")?.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
				default: break
				}
			}
		}
    }

}
