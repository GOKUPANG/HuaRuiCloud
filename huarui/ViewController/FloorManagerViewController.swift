//
//  FloorManagerViewController.swift
//  huarui
//
//  Created by sswukang on 15/11/30.
//  Copyright © 2015年 huarui. All rights reserved.
//

import UIKit

/// 设置 - 楼层管理
class FloorManagerViewController: UITableViewController, UIAlertViewDelegate, UIActionSheetDelegate, HR8000HelperDelegate {
    /// 添加
    private let TAG_ADD		= 100
    /// 删除
    private let TAG_DELETE	= 101
    /// 编辑
	private let TAG_EDIT		= 102
	/// 添加弹出的警告
	private let TAG_ADD_WARN = 103
	///编辑弹出的警告
	private let TAG_EDIT_WARN = 104
	
	private var floors: [HRFloorInfo?]!
	private var editable = false
	private var floorImage: UIImage!
	private var currentPos: Int?
	private var editButtonInCell: UIView?
	private var deleteButtonInCell: UIView?
	
	
	init() {
		super.init(style: UITableViewStyle.Grouped)
	}

	required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
	//请勿删除此init方法，否则在iOS8中会报“use of unimplemented initializer 'init(nibName:bundle:)'”异常.
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		self.title = "楼层管理"
		tableView.backgroundColor = UIColor.tableBackgroundColor()
		tableView.separatorColor = UIColor.tableSeparatorColor()
		editable = HRDatabase.isEditPermission
		
		if editable {
			navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(FloorManagerViewController.tapAddBarButton))
		}
		floorImage = UIImage(named: "ico_floor")?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
		floors = getFloorsFromDatabase()
//		floors = HRDeviceDatabase.shareInstance().floors	//如果用这句代码，会发生错误：array cannot be bridged from Objective-C
		
    }
	
	override func viewDidAppear(animated: Bool) {
		HRProcessCenter.shareInstance().delegates.hr8000HelperDelegate = self
		floors = getFloorsFromDatabase()
		self.tableView.reloadData()
	}
	
	private func getFloorsFromDatabase() -> [HRFloorInfo?] {
		var floors = [HRFloorInfo?]()
		if let fs = HRDatabase.shareInstance().getDevicesOfType(.FloorInfo) as? [HRFloorInfo] {
			for floor in fs {
				floors.append(floor)
			}
		}
		return floors
	}
	
	//MARK: - tableView
	
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		
		return 1
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return floors.count
	}
	
	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return 50
	}
	
	override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
		cell.separatorInset = UIEdgeInsetsZero
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		if let floor = floors[indexPath.row] {
			var cell: UITableViewCell! = tableView.dequeueReusableCellWithIdentifier("cell")
			if cell == nil {
				cell = UITableViewCell(style: .Value1, reuseIdentifier: "cell")
			}
			cell.textLabel?.text = floor.name
			cell.imageView?.image = floorImage
			cell.imageView?.tintColor = APP.param.themeColor
			cell.accessoryType = HRDatabase.isEditPermission ? .None:.DisclosureIndicator
			if cell.tag != 777 && HRDatabase.isEditPermission {
				let dropButton = UIButton(frame: CGRectMake(tableView.bounds.width - 80, 0, 80, 50))
				dropButton.imageView?.contentMode = .ScaleAspectFit
				dropButton.setImage(UIImage(named: "ico_user_pick"), forState: .Normal)
				dropButton.tag = indexPath.row
				dropButton.addTarget(self, action: #selector(FloorManagerViewController.tapDropButton(_:)), forControlEvents: .TouchUpInside)
				cell.addSubview(dropButton)
				cell.tag = 777
			}
			for v in cell.subviews where v is UIButton {
				v.tag = indexPath.row
			}
			return cell
		} else {	//扩展的cell
			var cell: UITableViewCell! = tableView.dequeueReusableCellWithIdentifier("expand")
			if cell == nil {
				cell = UITableViewCell(style: .Value1, reuseIdentifier: "expand")
			}
			if editButtonInCell == nil {
				editButtonInCell = getCellButtonView(
					CGRectMake(0, 0, tableView.bounds.width / 3, 50),
					imageName: "ico_edit",
					title: "重命名",
					color: .lightGrayColor()
				)
				editButtonInCell?.center.x = tableView.bounds.width * 0.3
				editButtonInCell?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(FloorManagerViewController.tapEditButton(_:))))
			}
			if deleteButtonInCell == nil {
				deleteButtonInCell = getCellButtonView(
					CGRectMake(0, 0, tableView.bounds.width / 3, 50),
					imageName: "ico_trash",
					title: "删除",
					color: UIColor(R: 217, G: 82, B: 87, alpha: 1)
				)
				deleteButtonInCell?.center.x = tableView.bounds.width * 0.7
				deleteButtonInCell!.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(FloorManagerViewController.tapDeleteButton(_:))))
			}
            editButtonInCell!.tag   = indexPath.row - 1
            deleteButtonInCell!.tag = indexPath.row - 1
			cell.contentView.addSubview(editButtonInCell!)
			cell.contentView.addSubview(deleteButtonInCell!)
			cell.contentView.backgroundColor = tableView.backgroundColor
			cell.selectionStyle = .None
			return cell
		}
	}
	
	///或去展开cell内部的按键view
	private func getCellButtonView(frame: CGRect, imageName: String, title: String, color: UIColor) -> UIView {
		let cellButton = UIView(frame: frame)
		
        let imageView      = UIImageView(frame: CGRectMake(0, 0, frame.height*2/3, frame.height*2/3))
        imageView.center.x = frame.midX
        imageView.image    = UIImage(named: imageName)?.imageWithRenderingMode(.AlwaysTemplate)
		cellButton.addSubview(imageView)
		
		let label = UILabel(frame: CGRectMake(0, imageView.frame.maxY, frame.width, frame.height / 3))
        label.textAlignment = .Center
        label.textColor     = color
        label.text          = title
        label.font          = UIFont.systemFontOfSize(UIFont.systemFontSize())
		cellButton.addSubview(label)
		
		cellButton.tintColor = color
		
		return cellButton
	}
	
	//MARK: - UI事件
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
		currentPos = indexPath.row
		//要进入下一页之前，因先关闭已展开的cell，否则会出现一些异常
		closeCellOfExpanded()
		if let floor = floors[indexPath.row] {
			let vc = RoomManagerViewController()
			vc.floor = floor
			navigationController?.pushViewController(vc, animated: true)
		}
	}
	
	///点击有上角“+”按钮
	@objc private func tapAddBarButton() {
		let alert = UIAlertView(title: "新楼层名称", message: "名称只能是中文、字母或数字，不能含有标点符号", delegate: self, cancelButtonTitle: "取消", otherButtonTitles: "添加")
		alert.tag = TAG_ADD
		alert.alertViewStyle = .PlainTextInput
		alert.show()
	}
	
	///点击下拉箭头的button
	@objc private func tapDropButton(button: UIButton) {
		if !button.selected {
			for i in 0..<floors.count where floors[i] == nil {
				closeCellOfExpanded(i-1)
				break  //这个break一定要加上，因为删除cell会改变floors数组，for循环不能继续
			}
			let expandRow = button.tag + 1
			floors.insert(nil, atIndex: expandRow)
			tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: expandRow, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Top)
		} else {
			let expandRow = button.tag + 1
			floors.removeAtIndex(expandRow)
			tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: expandRow, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Top)
		}
		//旋转button
		let anim = CABasicAnimation(keyPath: "transform.rotation.z")
		anim.fromValue = button.selected ? CGFloat(M_PI) : CGFloat(0)
		anim.toValue = button.selected ? CGFloat(0) : CGFloat(M_PI)
		anim.duration = 0.35
		anim.removedOnCompletion = false
		anim.fillMode = kCAFillModeForwards
		button.layer.addAnimation(anim, forKey: "rotaion_anim")
		
		button.selected = !button.selected
	}
	
	///关闭已经打开的cell
	///
	/// - parameter row: 点击了dropButton的行，并不是展开的行！
	private func closeCellOfExpanded(row: Int) {
		//删除
		if let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: row, inSection: 0)) {
			for v in cell.subviews where v is UIButton {
				tapDropButton(v as! UIButton)
			}
		}
	}
	
	///关闭已经展开的cell
	private func closeCellOfExpanded() {
		//如果有cell已经展开，则应该关闭再刷新
		for i in 0..<self.floors.count where self.floors[i] == nil {
			self.closeCellOfExpanded(i-1)
			break  //这个break一定要加上，因为删除cell会改变floors数组，for循环不能继续
		}
	}
	
	///点击展开的cell的编辑按钮
	@objc private func tapEditButton(gesture: UITapGestureRecognizer) {
		currentPos = gesture.view!.tag
		closeCellOfExpanded(currentPos!)
		let floor = floors[currentPos!]!
		let alert = UIAlertView(title: "修改楼层名称", message: "名称只能是中文、字母、数字、下划线或空格，不能含有其他标点符号", delegate: self, cancelButtonTitle: "取消", otherButtonTitles: "修改")
		alert.tag = TAG_EDIT
		alert.alertViewStyle = .PlainTextInput
		alert.textFieldAtIndex(0)?.text = floor.name
		alert.show()
	}
	
	///点击展开的cell的删除按钮
	@objc private func tapDeleteButton(gesture: UITapGestureRecognizer) {
		currentPos = gesture.view!.tag
		closeCellOfExpanded(currentPos!)
		let floor = floors[currentPos!]!
		let  alert = UIAlertView(title: "删除“\(floor.name)”?", message: "该楼层的所有房间也将删除，但这些房间里的设备不受影响，仍会保留。", delegate: self, cancelButtonTitle: "取消", otherButtonTitles: "删除")
		alert.tag = TAG_DELETE
		alert.show()
	}
	
	func alertView(alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
		let isTapCancel = buttonIndex == alertView.cancelButtonIndex
		switch alertView.tag {
		case TAG_ADD where !isTapCancel:
			let name = alertView.textFieldAtIndex(0)?.text ?? ""
			if let error = HRDatabase.shareInstance().checkName(HRDeviceType.FloorInfo.rawValue, name: name) {
				let alert = UIAlertView(title: error.localizedDescription , message: nil, delegate: self, cancelButtonTitle: "明白")
				alert.tag = TAG_ADD_WARN
				alert.show()
				break
			}
			let floor = HRFloorInfo()
			floor.name = name
			floor.hostAddr = HRDatabase.shareInstance().server.hostAddr
			KVNProgress.showWithStatus("正在加载...")
			HR8000Service.shareInstance().createFloor(floor, result: {
				error in
				if let err = error {
					KVNProgress.showErrorWithStatus(err.domain)
				} else {
					KVNProgress.showSuccessWithStatus("添加成功！")
				}
			})
		case TAG_DELETE where !isTapCancel:
			KVNProgress.showWithStatus("正在删除...")
			HR8000Service.shareInstance().deleteFloor(floors[currentPos!]!, result: {
				error in
				if let err = error {
					KVNProgress.showErrorWithStatus(err.domain)
				} else {
					KVNProgress.showSuccessWithStatus("删除成功！")
				}
			})
		case TAG_ADD_WARN:
			tapAddBarButton()
		case TAG_EDIT_WARN:
			let alert = UIAlertView(title: "修改楼层名称", message: "名称只能是中文、字母、数字、下划线或空格，不能含有其他标点符号", delegate: self, cancelButtonTitle: "取消", otherButtonTitles: "修改")
			alert.tag = TAG_EDIT
			alert.alertViewStyle = .PlainTextInput
			if let pos = currentPos {
				alert.textFieldAtIndex(0)?.text = floors[pos]?.name
			}
			alert.show()
		case TAG_EDIT where !isTapCancel: //重命名
			let name = alertView.textFieldAtIndex(0)?.text ?? ""
			if let error = HRDatabase.shareInstance().checkName(HRDeviceType.FloorInfo.rawValue, name: name) {
				let alert = UIAlertView(title: error.localizedDescription , message: nil, delegate: self, cancelButtonTitle: "明白")
				alert.tag = TAG_EDIT_WARN
				alert.show()
				break
			}
			let floor = HRFloorInfo()
			floor.name = name
			floor.id = floors[currentPos!]!.id
			floor.hostAddr = floors[currentPos!]!.hostAddr
			KVNProgress.showWithStatus("正在保存...")
			HR8000Service.shareInstance().editFloorInfo(floor, result: {
				error in
				if let err = error {
					KVNProgress.showErrorWithStatus(err.domain)
				} else {
					KVNProgress.showSuccessWithStatus("修改成功！")
				}
			})
		default: break
		}
	}
	
	//MARK: - delegate
	
	func hr8000Helper(didDeleteDevice device: HRDevice) {
		if let floorByDel = device as? HRFloorInfo {
			for i in 0..<floors.count  where floors[i] != nil && floors[i]!.id == floorByDel.id {
				runOnMainQueue({
					self.floors.removeAtIndex(i)
					self.tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: i, inSection: 0)], withRowAnimation: .Fade)
					
					//reload被删除的cell后面的cell，因为后面cell的tag已经不是指向自己了。注意，这个操作最好延时一下，不然界面看上去乱，延时300毫秒足矣
					runOnMainQueueDelay(300, block: {
						var indexs = [NSIndexPath]()
						for index in i..<self.floors.count {
							indexs.append(NSIndexPath(forRow: index, inSection: 0))
						}
						self.tableView.reloadRowsAtIndexPaths(indexs, withRowAnimation: .None)
					})
				})
				break
			}
		}
	}
	
	func hr8000Helper(finishedQueryDeviceInfo finish: Bool) {
		runOnMainQueue({
			//如果有cell已经展开，则应该关闭再刷新
			for i in 0..<self.floors.count where self.floors[i] == nil {
				self.closeCellOfExpanded(i-1)
				break  //这个break一定要加上，因为删除cell会改变floors数组，for循环不能继续
			}
			self.floors = self.getFloorsFromDatabase()
			self.tableView.reloadData()
		})
	}
}
