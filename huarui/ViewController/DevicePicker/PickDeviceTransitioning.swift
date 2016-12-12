//
//  ShowDevicePickerTransitioning.swift
//  huarui
//
//  Created by sswukang on 16/2/24.
//  Copyright © 2016年 huarui. All rights reserved.
//

import UIKit

class ShowDevicePickerTransitioning: NSObject, UIViewControllerAnimatedTransitioning {
	
	func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
		return 0.1
	}
	
	func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
		let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)
		transitionContext.containerView().addSubview(toVC!.view)
		transitionContext.completeTransition(true)
	}
}

class DismissDevicePickerTransitioning: NSObject, UIViewControllerAnimatedTransitioning {
	
	func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
		return 0.1
	}
	
	func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
		transitionContext.completeTransition(true)
	}
}
