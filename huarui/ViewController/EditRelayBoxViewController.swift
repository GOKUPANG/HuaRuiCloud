//
//  RegisterRelayBoxViewController.swift
//  huarui
//
//  Created by sswukang on 15/8/28.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import UIKit

/// 编辑继电器控制盒、开关面板、智能插座、单火开关等HRRelayComplexes
class EditRelayBoxViewController: UITableViewController,SelectListTableViewControllerDelegate, UIAlertViewDelegate {
	/// 要编辑的继电器设备
	var relayBox: HRRelayComplexes!
	
	/// 要编辑的继电器路数，总共4路。赋值为true代表要编辑，否则为不可编辑，界面上不显示
	var routerEnable = [false, false, false, false]
	
	private var relaysData: [[String: String]]!
	/// 数据是否更改，用于判断用户点击退出界面时是否提示未保存退出
	private var isDataChanged = false
	private var editEnable = true

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
	
//MARK: - ViewController
    override func viewDidLoad() {
        super.viewDidLoad()
		if relayBox == nil { return }
		tableView.backgroundColor = UIColor.tableBackgroundColor()
		tableView.separatorColor = UIColor.tableSeparatorColor()
		
		let permission = HRDatabase.shareInstance().acount.permission
		editEnable = permission == 2 || permission == 3
		
		if editEnable {
			let saveButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Save, target: self, action: #selector(EditRelayBoxViewController.saveAndDismiss(_:)))
			self.navigationItem.rightBarButtonItem = saveButton
			if self.title == nil {
				self.title = "编辑\(relayBox.name)"
			}
		} else {
			if self.title == nil {
				self.title = "查看\(relayBox.name)"
			}
		}
		
		tableView.registerClass(UITableViewCell.classForCoder(), forCellReuseIdentifier: "cell")
		
		relaysData = [[String: String]]()
		for i in 0...3 {
			if !routerEnable[i] {
				continue
			}
			var relayData = ["router": "\(i)"]
			for relay in relayBox.relays {
				if Int(relay.relaySeq) == i {
                    relayData["name"]  = relay.name
                    relayData["floor"] = relay.insFloorName
                    relayData["room"]  = relay.insRoomName
				}
			}
			if relayData["floor"] == nil {	//如果楼层名没有，则使用默认的
				relayData["floor"] = relayBox.insFloorName
			}
			if relayData["room"]  == nil {
				relayData["room"]  = relayBox.insRoomName
			}
			relaysData.append(relayData)
		}
		
		
    }
	
	override func viewDidAppear(animated: Bool) {
		if relayBox == nil {
			self.dismissViewControllerAnimated(true, completion: nil)
		}
	}
	
//MARK: - UI事件
	
	///点击左上角取消按钮
	func cancelAndDismiss(button: UIBarButtonItem) {
		if isDataChanged {
			UIAlertView(title: "提示", message:  "编辑未完成，您确定要退出吗？", delegate: self, cancelButtonTitle: "取消", otherButtonTitles: "确定").show()
			return
		}
		self.navigationController?.popViewControllerAnimated(true)
	}
	
	///点击右上角保存按钮
	func saveAndDismiss(button: UIBarButtonItem) {
		let box = HRRelayCtrlBox()
        box.devType  = self.relayBox.devType
        box.hostAddr = self.relayBox.hostAddr
        box.devAddr  = self.relayBox.devAddr
        box.name     = self.relayBox.name
		
		var error : String?
		for i in 0..<relaysData.count {
			let relay = HRRelayInBox()
			relay.relaySeq = Byte((relaysData[i]["router"]! as NSString).integerValue)
			if relaysData[i]["name"] != nil && !relaysData[i]["name"]!.isEmpty {
				relay.name = relaysData[i]["name"]!
			} else {
				error = "有一路或多路负载未命名！"
				break
			}
			
			if let floor = relaysData[i]["floor"] {
				if let floorId = HRDatabase.shareInstance().getFloorID(floor){
					relay.insFloorID = UInt16(floorId)
				} else {
					error = "有一路或多路负载未设置楼层或楼层无效！"
					break
				}
				if let room = relaysData[i]["room"] {
					if let roomId = HRDatabase.shareInstance().getRoomID(floor, roomName: room){
						relay.insRoomID = roomId
					} else {
						error = "有一路或多路负载未设置房间或房间无效！"
						break
					}
				} else {
					error = "有一路或多路负载未设置房间或房间无效！"
					break
				}
			} else {
				error = "有一路或多路负载未设置楼层或楼层无效！"
				break
			}
			box.relays.append(relay)
		}
		if let err = error {
			UIAlertView(title: "提示", message: err, delegate: nil, cancelButtonTitle: "确定").show()
			return
		}
		
		KVNProgress.showWithStatus("正在保存...")
		HR8000Service.shareInstance().bindRelayLoads(box,
			result: { (error) in
				if let err = error {
					KVNProgress.showErrorWithStatus("失败：\(err.domain)(\(err.code))")
					return
				}
				KVNProgress.showSuccessWithStatus("保存成功！")
				runOnMainQueueDelay(900, block: {
					self.navigationController?.popViewControllerAnimated(true)
				})
		})
	}
	
	func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
		if buttonIndex != alertView.cancelButtonIndex {
			self.navigationController?.popViewControllerAnimated(true)
		}
	}
	
//MARK: - Tableview delegate & dataSource
	private var currentIndexPath: NSIndexPath?
	private var textFields: [Int: UITextField]!
	
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		if relaysData == nil {
			return 0
		}
		textFields = [Int: UITextField]()
		return relaysData.count
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 3
	}
	
	override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let label = UILabel(frame: CGRectMake(0, 15, tableView.frame.width, 35))
		label.textAlignment = .Center
		label.font = UIFont.systemFontOfSize(label.font.pointSize-3)
		label.textColor = UIColor.lightGrayColor()
		switch relaysData[section]["router"]! {
		case "0":
			label.text = "第一路(A)绑定负载："
		case "1":
			label.text = "第二路(B)绑定负载："
		case "2":
			label.text = "第三路(C)绑定负载："
		case "3":
			label.text = "第四路(D)绑定负载："
		default :
			label.text = "绑定负载："
		}
		return label
	}
	
	override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 50
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "cell")
		
		switch indexPath.row {
		case 0:
			if cell.viewWithTag(indexPath.section+100) == nil {
				let textField = UITextField(frame: CGRectMake(15, 0, tableView.bounds.width-10, cell.frame.height))
				textField.tag = indexPath.section+100
				textField.placeholder = "负载名称"
				textField.clearButtonMode = .WhileEditing
				textField.text = relaysData[indexPath.section]["name"]
				if indexPath.section == relaysData.count-1 {
					textField.returnKeyType = UIReturnKeyType.Done
				} else {
					textField.returnKeyType = UIReturnKeyType.Next
				}
				textField.addTarget(self, action: #selector(EditRelayBoxViewController.textFieldEdting(_:)), forControlEvents: .EditingChanged)
				textField.addTarget(self, action: #selector(EditRelayBoxViewController.textFieldEditDone(_:)), forControlEvents: [.EditingDidEndOnExit, .EditingDidEnd])
				cell.addSubview(textField)
				textFields[indexPath.section] = textField
				textField.enabled = editEnable
			}
		case 1:
			cell.textLabel?.text = "楼层名"
			cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
			if let floorName = relaysData[indexPath.section]["floor"] {
				cell.detailTextLabel?.text = floorName
			}
		case 2:
			cell.textLabel?.text = "房间名"
			cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
			if let roomName = relaysData[indexPath.section]["room"] {
				cell.detailTextLabel?.text = roomName
			}
		default: break
		}
		
		return cell
	}
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let cell = tableView.cellForRowAtIndexPath(indexPath)
		cell?.setSelected(false, animated: true)
		if !editEnable { return }
		
		if indexPath.row == 1  {	//选择楼层
			currentIndexPath = indexPath
			var list = [String]()
			for floor in HRDatabase.shareInstance().floors {
				list.append(floor.name)
			}
			if list.count == 0 {
				UIAlertView(title: "提示", message: "没有楼层！", delegate: self, cancelButtonTitle: "确定").show()
				return
			}
			let selectVC = SelectListTableViewController(style: UITableViewStyle.Grouped)
			selectVC.title = "选择楼层"
			selectVC.delegate = self
			selectVC.textList = list
			if let floor = relaysData[indexPath.section]["floor"] {
				for i in 0..<list.count {
					if floor == list[i] {
						selectVC.selectedIndex = i
					}
				}
			}
			self.navigationController?.pushViewController(selectVC, animated: true)
		} else if indexPath.row == 2 { //选择房间
			currentIndexPath = indexPath
			var list = [String]()
			if let floorName = relaysData[indexPath.section]["floor"] {
				if let rooms = HRDatabase.shareInstance().getRooms(floorName) {
					for room in rooms {
						list.append(room.name)
					}
				}
			}
			if list.count == 0 {
				UIAlertView(title: "提示", message: "该楼层无房间或楼层名无效！", delegate: self, cancelButtonTitle: "确定").show()
				return
			}
			let selectVC = SelectListTableViewController(style: UITableViewStyle.Grouped)
			selectVC.title = "选择房间"
			selectVC.delegate = self
			selectVC.textList = list
			if let room = relaysData[indexPath.section]["room"] {
				for i in 0..<list.count {
					if room == list[i] {
						selectVC.selectedIndex = i
					}
				}
			}
			self.navigationController?.pushViewController(selectVC, animated: true)
		}
		
	}
	
	@objc private func textFieldEdting(textField: UITextField) {
		if textField.text == nil { return }
		if relaysData[textField.tag-100]["name"] != textField.text &&
			!(relaysData[textField.tag-100]["name"] == nil && textField.text!.isEmpty) {
				isDataChanged = true
		}
		relaysData[textField.tag-100]["name"] = textField.text
	}
	
	@objc private func textFieldEditDone(textField: UITextField) {
		if textField.text == nil { return }
		
		if textField.tag-100 == relaysData.count-1 {
			textField.resignFirstResponder()
		} else {
			textFields[textField.tag-100 + 1]?.becomeFirstResponder()
		}
	}
	
	func selectList(didSelectRow: Int, textList: [String]!) {
		if let indexPath = currentIndexPath {
			let cell = tableView.cellForRowAtIndexPath(indexPath)
			cell?.detailTextLabel?.text = textList[didSelectRow]
			if indexPath.row == 1 {
				if relaysData[indexPath.section]["floor"] != textList[didSelectRow] {
					isDataChanged = true
				}
				relaysData[indexPath.section]["floor"] = textList[didSelectRow]
			} else if indexPath.row == 2 {
				if relaysData[indexPath.section]["room"] != textList[didSelectRow] {
					isDataChanged = true
				}
				relaysData[indexPath.section]["room"] = textList[didSelectRow]
			}
		}
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
