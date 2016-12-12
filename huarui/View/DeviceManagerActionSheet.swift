//
//  DeviceManagerActionSheet.swift
//  huarui
//
//  Created by sswukang on 16/3/3.
//  Copyright © 2016年 huarui. All rights reserved.
//

import UIKit

enum DeviceManagerGroupType: Int, CustomStringConvertible {
	case None = 0
	case ByFloor
	case ByDeviceType
	
	var description: String {
		switch self {
		case .None:			return "不分组"
		case .ByDeviceType: return "按设备类型"
		case .ByFloor:		return "按楼层"
		}
	}
}

/// 设置中的设备管理界面弹出的排序和分组的选中sheet
class DeviceManagerActionSheet: UIView, UITableViewDelegate, UITableViewDataSource {
	
	var title: String
	weak var delegate : DeviceManagerActionSheetDelegate?
	var groupType: DeviceManagerGroupType = .None
	
	private var backgroundView: UIView!
	private var sheetBlankView: UIView!
	private var tableView: UITableView!
	private var titleLabel: UILabel!
	
	//MARK: - function
	
	///初始化
	///
	/// - parameter title: ValuePickerActionView的标题
	/// - parameter currentRow: 初始选择位置
	init(title: String, delegate: DeviceManagerActionSheetDelegate?) {
		self.title = title
		self.delegate = delegate
		super.init(frame: CGRectMake(0, 0, 0, 140))
		self.opaque = false
		let size = UIScreen.mainScreen().bounds
		self.frame = CGRectMake(0, 0, size.width, size.height)
		//背景遮罩
		backgroundView = UIView(frame: self.bounds)
		backgroundView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.3)
		backgroundView.alpha = 0
		backgroundView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(DeviceManagerActionSheet.onTapBackgroundView(_:))))
		//添加pickBlank, 即白色背景
		sheetBlankView = UIView(frame: CGRectMake(0, bounds.height, bounds.width, 200))
		sheetBlankView.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.98)
		
		titleLabel = UILabel(frame: CGRectMake(0, 10, sheetBlankView.frame.width, 25))
		titleLabel.text = title
		titleLabel.textAlignment = .Center
		titleLabel.textColor = UIColor.lightGrayColor()
		
		tableView = UITableView(frame: CGRectMake(20, 40, sheetBlankView.bounds.width - 40, sheetBlankView.frame.height - 40))
        tableView.center.y        = (sheetBlankView.bounds.height - 80) / 2 + 60
        tableView.backgroundColor = .clearColor()
        tableView.dataSource      = self
        tableView.delegate        = self
        tableView.tableFooterView = UIView()
        tableView.scrollEnabled   = false
        tableView.separatorStyle  = .None
        tableView.rowHeight       = tableView.bounds.height / CGFloat(tableView.numberOfRowsInSection(0)) - 8
		
		self.addSubview(backgroundView)
		self.addSubview(sheetBlankView)
		sheetBlankView.addSubview(tableView)
		sheetBlankView.addSubview(titleLabel)
	}
	
	required init?(coder aDecoder: NSCoder) {
		self.title = ""
		super.init(coder: aDecoder)
	}
	
	override func drawRect(rect: CGRect) {
		titleLabel?.text = title
	}
	
	private var handlerBlock: ((String, Int)->Void)?
	
	///显示，并绑定事件处理block，当点击picker的确定按键使picker消失后，该block被调用
	func showWithHandler(block: (String, Int)->Void) {
		self.handlerBlock = block
		self.show()
	}
	
//MARK: - tableView datasource
	
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 3
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		var cell = tableView.dequeueReusableCellWithIdentifier("cell")
		if cell == nil {
			cell = UITableViewCell(style: .Default, reuseIdentifier: "cell")
		}
        cell?.selectionStyle  = .None
        cell?.backgroundColor = .clearColor()
        cell?.tintColor       = self.tintColor
		switch indexPath.row {
		case 0:
			cell?.textLabel?.text = DeviceManagerGroupType.None.description
		case 1:
			cell?.textLabel?.text = DeviceManagerGroupType.ByFloor.description
		case 2:
			cell?.textLabel?.text = DeviceManagerGroupType.ByDeviceType.description
		default: break
		}
//		cell?.textLabel?.font = UIFont.systemFontOfSize(18)
		if groupType.rawValue == indexPath.row {
			cell?.textLabel?.textColor = self.tintColor
			cell?.accessoryType = .Checkmark
		} else {
			cell?.textLabel?.textColor = UIColor(red:0.43, green:0.43, blue:0.45, alpha:1)
			cell?.accessoryType = .None
		}
		
		return cell!
	}
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let type = DeviceManagerGroupType(rawValue: indexPath.row) ?? .None
		dismiss()
		delegate?.deviceManagerActionSheet(self, dismissWithGroupType: type)
	}
	
	func show(){
		guard let wnd: UIWindow! = UIApplication.sharedApplication().delegate?.window where wnd != nil else{
			Log.error("TimePickerActionView.show找不到window，无法显示")
			return
		}
		wnd.addSubview(self)
		
		//出现pickerView
		UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveLinear, animations: {
			self.backgroundView.alpha = 1
			self.sheetBlankView.center.y = self.bounds.height - self.sheetBlankView.bounds.midY
			}, completion: nil)
	}
	
	func dismiss() {
		
		UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveLinear, animations: {
			self.backgroundView.alpha = 0
			self.sheetBlankView.center.y = self.bounds.height + self.sheetBlankView.bounds.midY
			}, completion: { _ in
				self.removeFromSuperview()
		})
		
	}
	
	//MARK: - UI事件
	
	@objc private func onTapBackgroundView(gesture: UITapGestureRecognizer ) {
		self.dismiss()
	}

}

protocol DeviceManagerActionSheetDelegate: class {
	func deviceManagerActionSheet(sheet: DeviceManagerActionSheet, dismissWithGroupType groupType: DeviceManagerGroupType)
}