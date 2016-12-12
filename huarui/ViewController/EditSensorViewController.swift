//
//  EditSensorViewController.swift
//  huarui
//
//  Created by sswukang on 15/12/7.
//  Copyright © 2015年 huarui. All rights reserved.
//

import UIKit

/// 编辑传感器信息
class EditSensorViewController: UITableViewController {

	var sensor: HRSensor!
	
	private var editable = false
	private var nameTextField: UITextField!
	private var switch0View: UISwitch!
	private var switch1View: UISwitch!
	
	init() {
		super.init(style: .Grouped)
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
		if sensor == nil { return }
		editable = HRDatabase.isEditPermission
		self.title = "编辑\(sensor.name)"
		tableView.backgroundColor = UIColor.tableBackgroundColor()
		tableView.separatorColor = UIColor.tableSeparatorColor()
		addViews()
    }
	
	override func viewDidAppear(animated: Bool) {
		if sensor == nil {
			self.navigationController?.popViewControllerAnimated(true)
		}
	} 
	
	private func addViews() {
		if editable {
			navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Save, target: self, action: #selector(EditSensorViewController.onSaveBarButtonClicked))
		}
		let header = UIView(frame: CGRectMake(0, 0, self.tableView.frame.width, 120))
		let imgView = UIImageView(frame: CGRectMake(0, 0, header.frame.width, 80))
		imgView.center.y = header.frame.height/2
		imgView.image = UIImage(named: sensor.iconName)
		imgView.contentMode = UIViewContentMode.ScaleAspectFit
		header.addSubview(imgView)
		
		tableView.tableHeaderView = header
	}
	
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		if sensor == nil { return 0 }
		if sensor.devType == HRDeviceType.AirQualitySensor.rawValue { return 5 }
		return 4
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
		case 0: return 1
		case 1: return 2
		case 2 where sensor.devType == HRDeviceType.HumiditySensor.rawValue: return 1
		case 2 where sensor.devType == HRDeviceType.GasSensor.rawValue: return 2
		case 2 where sensor.devType == HRDeviceType.SolarSensor.rawValue: return 3
		case 2 where sensor.devType == HRDeviceType.AirQualitySensor.rawValue: return 3
		case 3 where sensor.devType == HRDeviceType.HumiditySensor.rawValue: return 1
		case 3 where sensor.devType == HRDeviceType.GasSensor.rawValue: return 1
		case 3 where sensor.devType == HRDeviceType.SolarSensor.rawValue: return 4
		case 3 where sensor.devType == HRDeviceType.AirQualitySensor.rawValue: return 3
		case 4 where sensor.devType == HRDeviceType.AirQualitySensor.rawValue: return 4
		default: return 0
		}
    }

	
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		var cell: UITableViewCell! = tableView.dequeueReusableCellWithIdentifier("section_\(indexPath.section)")

		if cell == nil {
			cell = UITableViewCell(style: .Value1, reuseIdentifier: "section_\(indexPath.section)")
		}
//		cell.textLabel?.text = "\(indexPath.section)-\(indexPath.row)"
		switch indexPath.section {
		case 0:
			if nameTextField == nil {
				nameTextField = UITextField(frame: CGRectMake(0, 0, tableView.bounds.width, cell.bounds.height))
				nameTextField.placeholder = "请输入设备名称"
				nameTextField.clearButtonMode = .WhileEditing
				nameTextField.enabled = editable
				nameTextField.textAlignment = .Center
				nameTextField.text = sensor.name
				nameTextField.returnKeyType = .Done
				nameTextField.addTarget(self, action: #selector(EditSensorViewController.nameTextFieldEditingDidEnd(_:)), forControlEvents: UIControlEvents.EditingDidEndOnExit)
			}
			cell.addSubview(nameTextField)
			
			////////////////////////// section 1 ////////////////////////////
			
		case 1 where indexPath.row == 0:
			cell.textLabel?.text = "楼层名"
			cell.accessoryType = .DisclosureIndicator
			if let name = sensor.floorName {
				cell.detailTextLabel?.text = name
			}
		case 1 where indexPath.row == 1:
			cell.textLabel?.text = "房间名"
			cell.accessoryType = .DisclosureIndicator
			if let name = sensor.roomName {
				cell.detailTextLabel?.text = name
			}
			
			////////////////////////// section 2、3、4 ////////////////////////////
			
			/*#################### 光照 ##################*/
			/** section 2 **/
		case 2 where indexPath.row == 0 && sensor.devType == HRDeviceType.SolarSensor.rawValue:
			cell.textLabel?.text = "光照动作值"
			if switch0View == nil {
				switch0View = UISwitch()
			}
			cell.accessoryView = switch0View
		case 2 where indexPath.row == 1 && sensor.devType == HRDeviceType.SolarSensor.rawValue:
			cell.textLabel?.text = "光照下限值"
			cell.accessoryType = .DisclosureIndicator
		case 2 where indexPath.row == 2 && sensor.devType == HRDeviceType.SolarSensor.rawValue:
			cell.textLabel?.text = "光照上限值"
			cell.accessoryType = .DisclosureIndicator
			/** section 3 **/
		case 3 where indexPath.row == 0 && sensor.devType == HRDeviceType.SolarSensor.rawValue:
			cell.textLabel?.text = "一级光照度增加联动"
			cell.accessoryType = .DisclosureIndicator
		case 3 where indexPath.row == 1 && sensor.devType == HRDeviceType.SolarSensor.rawValue:
			cell.textLabel?.text = "一级光照度衰减联动"
			cell.accessoryType = .DisclosureIndicator
		case 3 where indexPath.row == 2 && sensor.devType == HRDeviceType.SolarSensor.rawValue:
			cell.textLabel?.text = "二级光照度增加联动"
			cell.accessoryType = .DisclosureIndicator
		case 3 where indexPath.row == 3 && sensor.devType == HRDeviceType.SolarSensor.rawValue:
			cell.textLabel?.text = "二级光照度衰减联动"
			cell.accessoryType = .DisclosureIndicator
			
			/*#################### 可燃气 ##################*/
			/** section 2 **/
		case 2 where indexPath.row == 0 && sensor.devType == HRDeviceType.GasSensor.rawValue:
			cell.textLabel?.text = "可燃气动作值"
			if switch0View == nil {
				switch0View = UISwitch()
			}
			cell.accessoryView = switch0View
		case 2 where indexPath.row == 1 && sensor.devType == HRDeviceType.GasSensor.rawValue:
			cell.textLabel?.text = "报警值"
			cell.accessoryType = .DisclosureIndicator
			/** section 3 **/
		case 3 where indexPath.row == 0 && sensor.devType == HRDeviceType.GasSensor.rawValue:
			cell.textLabel?.text = "联动绑定"
			cell.accessoryType = .DisclosureIndicator
			
			
			/*#################### 湿敏 ##################*/
			/** section 2 **/
		case 2 where indexPath.row == 0 && sensor.devType == HRDeviceType.HumiditySensor.rawValue:
			cell.textLabel?.text = "湿敏动作值"
			if switch0View == nil {
				switch0View = UISwitch()
			}
			cell.accessoryView = switch0View
			/** section 3 **/
		case 3 where indexPath.row == 0 && sensor.devType == HRDeviceType.HumiditySensor.rawValue:
			cell.textLabel?.text = "联动绑定"
			cell.accessoryType = .DisclosureIndicator
			
			/*#################### 空气质量传感器 ##################*/
			/** section 2 **/
		case 2 where indexPath.row == 0 && sensor.devType == HRDeviceType.AirQualitySensor.rawValue:
			cell.textLabel?.text = "温度动作值"
			if switch0View == nil {
				switch0View = UISwitch()
			}
			cell.accessoryView = switch0View
		case 2 where indexPath.row == 1 && sensor.devType == HRDeviceType.AirQualitySensor.rawValue:
			cell.textLabel?.text = "温度下限值"
			cell.accessoryType = .DisclosureIndicator
		case 2 where indexPath.row == 2 && sensor.devType == HRDeviceType.AirQualitySensor.rawValue:
			cell.textLabel?.text = "温度上限值"
			cell.accessoryType = .DisclosureIndicator
			/** section 3 **/
		case 3 where indexPath.row == 0 && sensor.devType == HRDeviceType.AirQualitySensor.rawValue:
			cell.textLabel?.text = "湿度动作值"
			if switch1View == nil {
				switch1View = UISwitch()
			}
			cell.accessoryView = switch1View
		case 3 where indexPath.row == 1 && sensor.devType == HRDeviceType.AirQualitySensor.rawValue:
			cell.textLabel?.text = "湿度下限值"
			cell.accessoryType = .DisclosureIndicator
		case 3 where indexPath.row == 2 && sensor.devType == HRDeviceType.AirQualitySensor.rawValue:
			cell.textLabel?.text = "湿度上限值"
			cell.accessoryType = .DisclosureIndicator
			/** section 4 **/
		case 4 where indexPath.row == 0 && sensor.devType == HRDeviceType.AirQualitySensor.rawValue:
			cell.textLabel?.text = "温度增加联动"
			cell.accessoryType = .DisclosureIndicator
		case 4 where indexPath.row == 1 && sensor.devType == HRDeviceType.AirQualitySensor.rawValue:
			cell.textLabel?.text = "温度衰减联动"
			cell.accessoryType = .DisclosureIndicator
		case 4 where indexPath.row == 2 && sensor.devType == HRDeviceType.AirQualitySensor.rawValue:
			cell.textLabel?.text = "湿度增加联动"
			cell.accessoryType = .DisclosureIndicator
		case 4 where indexPath.row == 3 && sensor.devType == HRDeviceType.AirQualitySensor.rawValue:
			cell.textLabel?.text = "湿度衰减联动"
			cell.accessoryType = .DisclosureIndicator
			
		default: break
		}
		
        return cell
    }


	//MARK: - UI事件
	
	@objc private func onSaveBarButtonClicked() {
		
	}

	@objc private func nameTextFieldEditingDidEnd(textField: UITextField) {
		textField.resignFirstResponder()
	}
	
}
