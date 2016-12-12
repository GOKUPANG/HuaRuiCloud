//
//  EditScenePanelViewController.swift
//  huarui
//
//  Created by sswukang on 15/10/29.
//  Copyright © 2015年 huarui. All rights reserved.
//

import UIKit

class EditScenePanelViewController: UITableViewController {

	var scenePanel: HRScenePanel!
	
	private var editable: Bool = false
	private var viewModel: ScenePanelViewModel!
	
	init() {
		super.init(style: UITableViewStyle.Grouped)
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	//请勿删除此init方法，否则在iOS8中会报“use of unimplemented initializer 'init(nibName:bundle:)'”异常.
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		if scenePanel != nil {
			initData()
			addViews()
			initViews()
		}
    }
	
	override func viewDidAppear(animated: Bool) {
		if scenePanel == nil { //情景面板对象为空则退出
			self.navigationController?.popViewControllerAnimated(true)
		}
	}

	private func initData() {
		editable = HRDatabase.isEditPermission
		viewModel = ScenePanelViewModel(scenePanel: scenePanel)
	}
	
	private func addViews() {
		if editable {	//给导航栏添加按键
//			navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: "onBackBarButtonClicked:")
			navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Save, target: self, action: #selector(onSaveBarButtonClicked(_:)))
		}
		let header = UIView(frame: CGRectMake(0, 0, self.tableView.frame.width, 120))
		let imgView = UIImageView(frame: CGRectMake(0, 0, header.frame.width, 80))
		imgView.center.y = header.frame.height/2
		imgView.image = UIImage(named: scenePanel.iconName)
		imgView.contentMode = UIViewContentMode.ScaleAspectFit
		header.addSubview(imgView)
		
		tableView.tableHeaderView = header
	}
	
	private func initViews() {
		self.title = "编辑情景面板"
		tableView.backgroundColor = UIColor.tableBackgroundColor()
		tableView.separatorColor = UIColor.tableSeparatorColor()
		tableView.sectionFooterHeight = 0
		
	}
	
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		if scenePanel == nil {
			return 0
		}
		return 3
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
		case 0:
			return 1
		case 1:
			return 2
		default:
			return viewModel.numberOfValidKeys
		}
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		var cellIdentifier = "cell"
		if indexPath.section == 0 && indexPath.row == 0 {
			cellIdentifier = "nameCell"
		}
		var cell: UITableViewCell! = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)
		
		if cell == nil {
			
			if indexPath.section == 0 && indexPath.row == 0 {
				cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: cellIdentifier)
				let nameTextField = UITextField(frame: CGRectMake(0, 0, tableView.frame.width, cell.frame.height))
				nameTextField.placeholder = "请输入情景面板名称"
				nameTextField.clearButtonMode = .WhileEditing
				nameTextField.text = viewModel.name
				nameTextField.textAlignment = .Center
				nameTextField.returnKeyType = UIReturnKeyType.Done
				nameTextField.addTarget(self, action: #selector(nameTextFieldOnExit(_:)), forControlEvents: UIControlEvents.EditingDidEndOnExit)
				nameTextField.addTarget(self, action: #selector(nameTextFielOnEditing(_:)), forControlEvents: UIControlEvents.EditingChanged)
				cell.contentView.addSubview(nameTextField)
				nameTextField.enabled = editable

				cell.contentView.addSubview(nameTextField)
			} else {
				cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: cellIdentifier)
				cell.detailTextLabel?.textColor = UIColor.lightGrayColor()
			}
		}
		
		switch indexPath.section {
		case 1 where indexPath.row == 0 :
			cell.textLabel?.text = "楼层"
			cell.detailTextLabel?.text = "\(indexPath.section)"
			cell.detailTextLabel?.text = viewModel.insFloorName
			cell.accessoryType = .DisclosureIndicator
		case 1 where indexPath.row == 1 :
			cell.textLabel?.text = "房间"
			cell.detailTextLabel?.text = "\(indexPath.section)"
			cell.detailTextLabel?.text = viewModel.insRoomName
			cell.accessoryType = .DisclosureIndicator
		case 2 :
			let numTexts = ["一","二","三","四"]
			if indexPath.row <= numTexts.count {
				cell.textLabel?.text = "按键\(numTexts[indexPath.row])"
			} else {
				cell.textLabel?.text = "按键\(indexPath.row)"
			}
			cell.detailTextLabel?.text = viewModel.getKeyDescription(indexPath.row)
			cell.accessoryType = .DisclosureIndicator
		default: break
		}
		
		return cell
	}
	
	override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		if section == 0 { return nil }
		var headerView = tableView.dequeueReusableHeaderFooterViewWithIdentifier("header_\(section)")
		
		if headerView == nil {
			headerView = UITableViewHeaderFooterView(reuseIdentifier: "header_\(section)")
			let label = UILabel(frame: CGRectMake(0, 0, tableView.frame.width, 35))
			label.textAlignment = .Center
			label.font = UIFont.systemFontOfSize(label.font.pointSize-3)
			label.textColor = UIColor.lightGrayColor()
			headerView!.addSubview(label)
			switch section {
			case 0:
				label.text = "名称："
			case 1:
				label.text = "安装位置："
			case 2:
				label.text = "按键绑定的设备/情景："
			default: break
			}
		}
		
		return headerView
	}
	
	override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		if section == 0 { return 0 }
		return 35
	}
	
	//MARK: - 关闭与保存
	@objc private func onBackBarButtonClicked(button: UIBarButtonItem) {
		self.navigationController?.popViewControllerAnimated(true)
	}
	
	@objc private func onSaveBarButtonClicked(button: UIBarButtonItem) {
		if viewModel.name.isEmpty || !viewModel.name.isDeviceName {
			UIAlertView(title: "提示", message: "设备名称为空或使用了非法字符！", delegate: nil, cancelButtonTitle: "确定").show()
			return
		}
		if HRDatabase.shareInstance().getFloorID(viewModel.insFloorName)==nil{
			UIAlertView(title: "提示", message: "未选择楼层或楼层无效！", delegate: nil, cancelButtonTitle: "确定").show()
			return
		}
		if HRDatabase.shareInstance().getRoomID(viewModel.insFloorName, roomName: viewModel.insRoomName) == nil {
			UIAlertView(title: "提示", message: "未选择房间或房间无效！", delegate: nil, cancelButtonTitle: "确定").show()
			return
		}
		
		KVNProgress.showWithStatus("正在保存...")
		HR8000Service.shareInstance().editDeviceInfo(viewModel.scenePanel, result: nil)
		HR8000Service.shareInstance().editScenePanelBindings(viewModel.scenePanel, result: { error in
			if let err = error {
				KVNProgress.showErrorWithStatus("失败：\(err.domain)")
			} else {
				KVNProgress.showSuccessWithStatus("保存成功")
				runOnMainQueueDelay(500, block: {
					self.navigationController?.popViewControllerAnimated(true)
				})
			}
		})
	}
	
	//MARK: - UI事件
	
	@objc private func nameTextFieldOnExit(textField: UITextField) {
		textField.resignFirstResponder()
	}
	
	@objc private func nameTextFielOnEditing(textField: UITextField) {
		guard let text = textField.text else {
			viewModel.name = ""
			return
		}
		viewModel.name = text
	}
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
		switch indexPath.section {
		case 1 where indexPath.row == 0 && editable:	//点击楼层
			let floorNames = viewModel.floorNames
			var currentRow = 0
			for i in 0..<floorNames.count {
				if viewModel.insFloorName == floorNames[i] {
					currentRow = i
					break
				}
			}
			ValuePickerActionView(title: "选择楼层", values: floorNames, currentRow: currentRow, delegate: nil).showWithHandler({ (floorName, _) -> Void in
				//如果新选择的楼层与当前楼层不一致
				if floorName != self.viewModel.insFloorName{
					self.viewModel.insFloorName = floorName
					let roomNames = self.viewModel.roomNames
					if roomNames.count > 0 {
						self.viewModel.insRoomName = roomNames[0]
					}
					tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: UITableViewRowAnimation.None)
				}
			})
		case 1 where indexPath.row == 1 && editable:	//点击房间
			let roomNames = viewModel.roomNames
			var currentRow = 0
			for i in 0..<roomNames.count {
				if viewModel.insRoomName == roomNames[i] {
					currentRow = i
					break
				}
			}
			ValuePickerActionView(title: "选择房间", values: roomNames, currentRow: currentRow, delegate: nil).showWithHandler({ (roomName, _) -> Void in
				self.viewModel.insRoomName = roomName
				tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
			})
		case 2:
			
			
			let vc = ScenePanelBindDetailViewController()
			vc.editable = editable
			vc.bindState = viewModel.scenePanel.keyStatusBind[indexPath.row]
			vc.handlerBlock = { bindState in
				self.viewModel.scenePanel.keyStatusBind[indexPath.row] = bindState
				tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
			}
			self.navigationController?.pushViewController(vc, animated: true)
		default: break
		}
	}
}
