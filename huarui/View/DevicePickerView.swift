//
//  DevicePickerView.swift
//  huarui
//
//  Created by sswukang on 16/2/18.
//  Copyright © 2016年 huarui. All rights reserved.
//

import UIKit

/// 设备选择器
class DevicePickerView: UIView, UIScrollViewDelegate {
	weak var delegate: DevicePickerViewDelegate?
	var currentIndex: Int {
		return scrollTitleView.currentPos
	}
	
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var scrollTitleView: ScrollTitleView!
	@IBOutlet weak var scrollContainerView: UIScrollView!
	@IBOutlet weak var selectAllButton: UIButton!
	@IBOutlet weak var cancelButton: UIButton!
	@IBOutlet weak var doneButton: UIButton!
	@IBOutlet weak var horizontalLine: UIView!
	@IBOutlet weak var verticalLine: UIView!
	
	override init(frame: CGRect) {
		super.init(frame: frame)
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	override func awakeFromNib() {
		selectAllButton.addTarget(self, action: #selector(DevicePickerView.tapSelectAll(_:)), forControlEvents: .TouchUpInside)
		cancelButton.addTarget(self, action: #selector(DevicePickerView.tapCancelButton), forControlEvents: .TouchUpInside)
		doneButton.addTarget(self, action: #selector(DevicePickerView.tapDoneButton), forControlEvents: .TouchUpInside)
        scrollContainerView.pagingEnabled = true
        scrollContainerView.bounces       = false
        scrollContainerView.delegate      = self
        scrollContainerView.showsVerticalScrollIndicator   = false
		scrollContainerView.showsHorizontalScrollIndicator = false
		
		scrollTitleView.setHandler { [unowned self](index, title) in
			self.scrollContainerView.setContentOffset(CGPointMake(self.scrollContainerView.bounds.width * CGFloat(index), 0), animated: true)
		}
	}
	
	override func drawRect(rect: CGRect) {
		super.drawRect(rect)
		scrollTitleView.tintColor = APP.param.themeColor
		horizontalLine.frame = CGRectMake(0, horizontalLine.frame.minY+singleLineAdjustOffset, horizontalLine.bounds.width, singleLineWidth)
		verticalLine.frame = CGRectMake(verticalLine.frame.minX+singleLineAdjustOffset, verticalLine.frame.minY+2, singleLineWidth, verticalLine.bounds.height-4)
		if delegate == nil { return }
		
		scrollTitleView.titles = self.delegate!.deviceTitles(self)
		for (index, title) in scrollTitleView.titles.enumerate() {
			let size = CGSizeMake(scrollContainerView.bounds.width, scrollContainerView.bounds.height)
			let view = self.delegate!.devicePickerView(self, viewForTitle: title, index: index, size: size)
			view.frame = CGRectMake(CGFloat(index) * size.width, 0, size.width, size.height)
			view.tintColor = self.tintColor
			scrollContainerView.addSubview(view)
		}
		selectAllButton.hidden = self.delegate?.devicePickerView?(shouldShowSelectAllButton: self) ?? false
		scrollContainerView.contentSize = CGSizeMake(scrollContainerView.bounds.width * CGFloat(scrollTitleView.titles.count), scrollContainerView.bounds.height)
	}
	
	@objc private func tapCancelButton() {
		delegate?.devicePickerView?(tapCancelButton: self)
	}
	
	@objc private func tapDoneButton() {
		delegate?.devicePickerView?(tapDoneButton: self) 
	}
	
	@objc private func tapSelectAll(button: UIButton) {
		delegate?.devicePickerView?(self, tapSelectAllButton: button)
	}
	
	func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
		let pos = Int(scrollView.contentOffset.x / scrollView.bounds.width)
		scrollTitleView.setSelectedItem(pos, animated: true)
	}
}

//MARK: - DevicePickerViewDelegate

@objc protocol DevicePickerViewDelegate {
	
	func deviceTitles(pickerView: DevicePickerView) -> [String]
	
	func devicePickerView(pickerView: DevicePickerView, viewForTitle title: String, index: Int, size: CGSize) -> UIView
	
	optional func devicePickerView(shouldShowSelectAllButton pickerView: DevicePickerView) -> Bool
	
	optional func devicePickerView(pickerView: DevicePickerView, didFocusDevices title: String)
	
	optional func devicePickerView(pickerView: DevicePickerView, tapSelectAllButton button: UIButton)
	
	optional func devicePickerView(tapCancelButton pickerView: DevicePickerView)
	
	optional func devicePickerView(tapDoneButton pickerView: DevicePickerView)
}
