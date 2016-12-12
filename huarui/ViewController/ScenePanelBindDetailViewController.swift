//
//  ScenePanelBindDetailViewController.swift
//  huarui
//
//  Created by sswukang on 15/10/30.
//  Copyright © 2015年 huarui. All rights reserved.
//

import UIKit

class ScenePanelBindDetailViewController: UITableViewController {

	var bindState: HRScenePanelBindStates!
	
	var handlerBlock: ((HRScenePanelBindStates)->Void)?
	var editable = false
	
	//当前选择的设备类型，非HRDeviceType
	private var currentSelectType = -1
	private var currentDevice: HRDevice? {
		didSet {
			if currentDevice == nil {
				tableView.tableFooterView = nil
			} else if currentDevice!.devType != oldValue?.devType || currentDevice!.devAddr != oldValue?.devAddr{
				let footer = UIView()
				var y: CGFloat = 20
				switch currentDevice!.devType {
				case HRDeviceType.relayTypes():
					let relayBox = currentDevice! as! HRRelayComplexes
					for relay in relayBox.relays {
						let label = UILabel(frame: CGRectMake(0, y, tableView.bounds.width, 45))
						label.textAlignment = .Center
						label.text = "\"\(relay.name)\"绑定的动作："
						footer.addSubview(label)
						
						let segment = DVSwitch(stringsArray: ["关", "开", "翻转","无效"])
						segment.tag = 100 + Int(relay.relaySeq)
						footer.addSubview(segment)
						segment.frame = CGRectMake(15, label.frame.maxY + 5, 280, 45)
						segment.center.x = tableView.bounds.width/2
						y = segment.frame.maxY + 20
						segment.cornerRadius = segment.bounds.height/2
						segment.enabled = editable
						if bindState.devType == currentDevice!.devType && bindState.devAddr == currentDevice!.devAddr && relay.relaySeq <= 3{
							segment.selectIndex(Int(bindState.operation.getBytes()[Int(relay.relaySeq)]), animated: false)
						} else {
							segment.selectIndex(3, animated: false)
						}
						segment.setPressedHandler({ index in
							var operations = self.bindState.operation.getBytes()
							operations[Int(relay.relaySeq)] = Byte(index)
							self.bindState.operation = UInt32(fourBytes: operations)
						})
					}
					
				case HRDeviceType.motorTypes():
					let label = UILabel(frame: CGRectMake(0, 20, tableView.bounds.width, 45))
					label.textAlignment = .Center
					label.text = "绑定状态："
					footer.addSubview(label)
					let segment = DVSwitch(stringsArray: ["关", "开", "停"])
					segment.frame = CGRectMake(15, label.frame.maxY + 5, 280, 45)
					segment.center.x = tableView.bounds.width/2
					y = segment.frame.maxY + 20
					segment.cornerRadius = segment.bounds.height/2
					segment.enabled = editable
					if bindState.devType == currentDevice!.devType && bindState.devAddr == currentDevice!.devAddr {
						segment.selectIndex(Int(bindState.operation.getBytes()[0]), animated: false)
					} else {
						segment.selectIndex(2, animated: false)
					}
					footer.addSubview(segment)
					segment.setPressedHandler({ index in
						self.bindState.operation = UInt32(index)
						self.bindState.operation |= 0xFFFF_FF00
					})
				case HRDeviceType.Scene.rawValue:
					self.bindState.operation = 0xFFFF_FFFF
				default: break
				}
				footer.frame = CGRectMake(0, 0, tableView.bounds.width, y)
				tableView.tableFooterView = footer
			}
		}
	}
	
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
		tableView.backgroundColor = UIColor.tableBackgroundColor()
		tableView.separatorColor = UIColor.tableSeparatorColor()
		if editable {
			navigationItem.rightBarButtonItem = UIBarButtonItem(title: "完成", style: UIBarButtonItemStyle.Done, target: self, action: #selector(ScenePanelBindDetailViewController.onDoneBarButtonClicked(_:)))
		}
		initData()
    }
	
	private func initData() {
		if bindState == nil { return }
		//复制一个bindState对象
		let newState = HRScenePanelBindStates()
		newState.devType = bindState.devType
		newState.devAddr = bindState.devAddr
		newState.hostAddr = bindState.hostAddr
		newState.operation = bindState.operation
		newState.description = bindState.description
		bindState = newState
		switch bindState.devType {
		case HRDeviceType.relayTypes():
			self.currentSelectType = 0
			for relayBox in HRDatabase.shareInstance().getAllRelayBoxs()
				where relayBox.devAddr == bindState.devAddr {
				self.currentDevice = relayBox
				break
			}
		case HRDeviceType.motorTypes():
			self.currentSelectType = 1
			for motor in HRDatabase.shareInstance().getAllMotorDev()
				where motor.devAddr == bindState.devAddr {
					self.currentDevice = motor
					break
			}
		case HRDeviceType.Scene.rawValue:
			self.currentSelectType = 2
			self.currentDevice = HRDatabase.shareInstance().getScene(sceneId: Byte(bindState.devAddr))
		default : break
		}
	}
	
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
		case 0: return 1
		case 1: return 2
		case 2 where currentSelectType == 0: return 3
		case 2 where currentSelectType == 1: return 1
		case 2 where currentSelectType == 2: return 1
		default: return 0
		}
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		var cell: UITableViewCell! = tableView.dequeueReusableCellWithIdentifier("section_\(indexPath.section)")
		
		if cell == nil && indexPath.section == 0 {
			cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "section_\(indexPath.section)")
		} else if cell == nil && indexPath.section == 1 {
			cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "section_\(indexPath.section)")
		} else if cell == nil {
			cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "section_\(indexPath.section)")
		}
		
		switch indexPath.section {
		case 0:
			cell.textLabel?.text = "不绑定"
			cell.textLabel?.textAlignment = .Center
			cell.textLabel?.textColor = cell.textLabel?.tintColor
		case 1 where indexPath.row == 0:
			cell.textLabel?.text = "绑定类型"
			cell.accessoryType = .DisclosureIndicator
			switch currentSelectType {
			case 0:
				cell.detailTextLabel?.text = "继电器类"
			case 1:
				cell.detailTextLabel?.text = "电机类"
			case 2:
				cell.detailTextLabel?.text = "情景模式"
			default :
				cell.detailTextLabel?.text = ""
			}
		case 1 where indexPath.row == 1:
			cell.textLabel?.text = "绑定设备"
			cell.accessoryType = .DisclosureIndicator
			if let dev = currentDevice {
				cell.detailTextLabel?.text = dev.name
			} else {
				cell.detailTextLabel?.text = ""
			}
		default: break
		}


        return cell
    }
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
		if !editable { return }
		switch indexPath.section {
		case 0:
			bindState.devType = 0x00
			bindState.devAddr = 0xFFFF_FFFF
			bindState.description = "未绑定"
			handlerBlock?(bindState)
			self.navigationController?.popViewControllerAnimated(true)
		case 1 where indexPath.row == 0:
			ValuePickerActionView(
				title: "选择设备类型",
				values: ["继电器类", "电机类", "情景模式"],
				currentRow: currentSelectType > 0 ? currentSelectType:0,
				delegate: nil)
				.showWithHandler({
				(_, index) in
				if self.currentSelectType != index {
					self.currentSelectType = index
					self.currentDevice = nil
					self.tableView.reloadData()
				}
			})
		case 1 where indexPath.row == 1 && currentSelectType >= 0 && currentSelectType < 3:
			var devices = [HRDevice]()
			var deviceNames = [String]()
			var currentDevIndex = 0
			switch currentSelectType {
			case 0:
				devices = HRDatabase.shareInstance().getAllRelayBoxs()
				for i in 0..<devices.count {
					deviceNames.append(devices[i].name)
					if currentDevice?.devAddr == devices[i].devAddr {
						currentDevIndex = i
					}
				}
			case 1:
				devices = HRDatabase.shareInstance().getAllMotorDev()
				for i in 0..<devices.count {
					deviceNames.append(devices[i].name)
					if currentDevice?.devAddr == devices[i].devAddr {
						currentDevIndex = i
					}
				}
			case 2:
				devices = HRDatabase.shareInstance().getNonilDevicesOfType(.Scene)
				for i in 0..<devices.count {
					deviceNames.append(devices[i].name)
					if currentDevice?.devAddr == devices[i].devAddr {
						currentDevIndex = i
					}
				}
			default: break
			}
			ValuePickerActionView(
				title: "选择设备/情景",
				values: deviceNames,
				currentRow: currentDevIndex,
				delegate: nil)
				.showWithHandler({
					(_, index) in
					self.currentDevice = devices[index]
					self.tableView.reloadData()
				})
		default: break
		}
	}
	
	@objc private func onDoneBarButtonClicked(button: UIBarButtonItem) {
		if let dev = currentDevice {
			bindState.devType = dev.devType
			bindState.devAddr = dev.devAddr
			bindState.hostAddr = dev.hostAddr
			bindState.description = dev.name
			handlerBlock?(bindState)
		}
		self.navigationController?.popViewControllerAnimated(true)
	}

}
