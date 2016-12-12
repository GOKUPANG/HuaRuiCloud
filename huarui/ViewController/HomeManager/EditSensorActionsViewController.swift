//
//  EditSensorActionsViewController.swift
//  huarui
//
//  Created by sswukang on 15/12/7.
//  Copyright © 2015年 huarui. All rights reserved.
//

import UIKit

///编辑传感器的动作值界面
class EditSensorActionsViewController: UITableViewController, UIAlertViewDelegate {
	
	var sensor: HRSensor!
	
	private var solarSensor: HRSolarSensor?
	private var gasSensor: HRGasSensor?
	private var humiditySensor: HRHumiditySensor?
	private var airQualitySensor: HRAirQualitySensor?
	
	private var editable = false
	private var switch0View: UISwitch!
	private var switch1View: UISwitch!
	
	init() {
		super.init(style: .Grouped)
	}
	
	//请勿删除此init方法，否则在iOS8中会报“use of unimplemented initializer 'init(nibName:bundle:)'”异常.
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.backgroundColor = .tableBackgroundColor()
		tableView.separatorColor = .tableSeparatorColor()
		if sensor == nil { return }
		editable = HRDatabase.isEditPermission
		switch sensor.devType {
		case HRDeviceType.SolarSensor.rawValue:
            self.solarSensor      = sensor.copy() as? HRSolarSensor
		case HRDeviceType.GasSensor.rawValue:
            self.gasSensor        = sensor.copy() as? HRGasSensor
		case HRDeviceType.HumiditySensor.rawValue:
            self.humiditySensor   = sensor.copy() as? HRHumiditySensor
		case HRDeviceType.AirQualitySensor.rawValue:
            self.airQualitySensor = sensor.copy() as? HRAirQualitySensor
		default: break
		}
		
		self.title = (editable ? "编辑": "查看") + "传感器动作值"
		
		addViews()
	}
	
	override func viewDidAppear(animated: Bool) {
		if sensor == nil {
			self.navigationController?.popViewControllerAnimated(true)
		}
	}
	
	private func addViews() {
		if editable {
			navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Save, target: self, action: #selector(EditSensorActionsViewController.tapSaveBarButton))
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
		if sensor.devType == HRDeviceType.AirQualitySensor.rawValue { return 3 }
		return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
		case 0: return 1
		case 1 where sensor.devType == HRDeviceType.HumiditySensor.rawValue: return 1
		case 1 where sensor.devType == HRDeviceType.GasSensor.rawValue: return 2
		case 1 where sensor.devType == HRDeviceType.SolarSensor.rawValue: return 3
		case 1 where sensor.devType == HRDeviceType.AirQualitySensor.rawValue: return 3
		case 2 where sensor.devType == HRDeviceType.AirQualitySensor.rawValue: return 3
		default: return 0
		}
    }

	override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		switch section {
		case 1 where sensor.devType == HRDeviceType.GasSensor.rawValue: return "单位：%LEL"
		case 1 where sensor.devType == HRDeviceType.SolarSensor.rawValue: return "光照上限值必须大于下限值，单位：lux"
		case 1 where sensor.devType == HRDeviceType.AirQualitySensor.rawValue: return "温度上限值必须大于下限值，单位：℃"
		case 2 where sensor.devType == HRDeviceType.AirQualitySensor.rawValue: return "湿度上限值必须大于下限值，单位：%"
		default: return nil
		}
	}
	
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		var cell: UITableViewCell! = tableView.dequeueReusableCellWithIdentifier("section_\(indexPath.section)")
		
		if cell == nil {
			cell = UITableViewCell(style: .Value1, reuseIdentifier: "section_\(indexPath.section)")
			if indexPath.section == 0 {
				let label = UILabel(frame: CGRectMake(0, 0, self.tableView.bounds.width, cell.bounds.height))
				label.text = sensor.name
				label.textAlignment = .Center
				cell.addSubview(label)
				cell.selectionStyle = .None
			}
		}
		switch indexPath.section {
			/*#################### 光照 ##################*/
			/** section 1 **/
		case 1 where indexPath.row == 0 && sensor.devType == HRDeviceType.SolarSensor.rawValue:
			cell.textLabel?.text = "启用联动"
			if switch0View == nil {
				switch0View = UISwitch()
			}
			cell.accessoryView = switch0View
			switch0View.on = solarSensor!.linkEnable
		case 1 where indexPath.row == 1 && sensor.devType == HRDeviceType.SolarSensor.rawValue:
			cell.textLabel?.text = "光照下限值"
			cell.accessoryType = .DisclosureIndicator
			cell.detailTextLabel?.text = "\(solarSensor!.linkLowerValue)"
		case 1 where indexPath.row == 2 && sensor.devType == HRDeviceType.SolarSensor.rawValue:
			cell.textLabel?.text = "光照上限值"
			cell.accessoryType = .DisclosureIndicator
			cell.detailTextLabel?.text = "\(solarSensor!.linkUpperValue)"
			
			/*#################### 可燃气 ##################*/
			/** section 1 **/
		case 1 where indexPath.row == 0 && sensor.devType == HRDeviceType.GasSensor.rawValue:
			cell.textLabel?.text = "启用联动"
			if switch0View == nil {
				switch0View = UISwitch()
			}
			cell.accessoryView = switch0View
			switch0View.on = gasSensor!.linkEnable
		case 1 where indexPath.row == 1 && sensor.devType == HRDeviceType.GasSensor.rawValue:
			cell.textLabel?.text = "报警值"
			cell.accessoryType = .DisclosureIndicator
			cell.detailTextLabel?.text = "\(gasSensor!.linkUpperValue)"
			
			/*#################### 湿敏 ##################*/
			/** section 1 **/
		case 1 where indexPath.row == 0 && sensor.devType == HRDeviceType.HumiditySensor.rawValue:
			cell.textLabel?.text = "启用联动"
			if switch0View == nil {
				switch0View = UISwitch()
			}
			cell.accessoryView = switch0View
			switch0View.on = humiditySensor!.linkEnable
			
			/*#################### 空气质量传感器 ##################*/
			/** section 1 **/
		case 1 where indexPath.row == 0 && sensor.devType == HRDeviceType.AirQualitySensor.rawValue:
			cell.textLabel?.text = "启用温度联动"
			if switch0View == nil {
				switch0View = UISwitch()
			}
			cell.accessoryView = switch0View
			switch0View.on = airQualitySensor!.linkTempEnable
		case 1 where indexPath.row == 1 && sensor.devType == HRDeviceType.AirQualitySensor.rawValue:
            cell.textLabel?.text = "温度下限值"
			cell.accessoryType   = .DisclosureIndicator
			cell.detailTextLabel?.text = "\(airQualitySensor!.linkLowerValueTemp)"
		case 1 where indexPath.row == 2 && sensor.devType == HRDeviceType.AirQualitySensor.rawValue:
            cell.textLabel?.text = "温度上限值"
			cell.accessoryType   = .DisclosureIndicator
			cell.detailTextLabel?.text = "\(airQualitySensor!.linkUpperValueTemp)"
			/** section 2 **/
		case 2 where indexPath.row == 0 && sensor.devType == HRDeviceType.AirQualitySensor.rawValue:
			cell.textLabel?.text = "启用湿度联动"
			if switch1View == nil {
				switch1View = UISwitch()
			}
			cell.accessoryView = switch1View
			switch1View.on = airQualitySensor!.linkHumidEnable
		case 2 where indexPath.row == 1 && sensor.devType == HRDeviceType.AirQualitySensor.rawValue:
            cell.textLabel?.text = "湿度下限值"
			cell.accessoryType   = .DisclosureIndicator
			cell.detailTextLabel?.text = "\(airQualitySensor!.linkLowerValueHumid)"
		case 2 where indexPath.row == 2 && sensor.devType == HRDeviceType.AirQualitySensor.rawValue:
            cell.textLabel?.text = "湿度上限值"
			cell.accessoryType   = .DisclosureIndicator
			cell.detailTextLabel?.text = "\(airQualitySensor!.linkUpperValueHumid)"
		default: break
		}
		switch0View?.enabled = editable
		switch1View?.enabled = editable
        return cell
    }
	
	private let tag_inputSolarLower = 100
	private let tag_inputSolarUpper = 101
	private let tag_inputGasAlarmValue = 102
	private let tag_inputAirQualityTempLower = 103
	private let tag_inputAirQualityTempUpper = 104
	private let tag_inputAirQualityHumiLower = 105
	private let tag_inputAirQualityHumiUpper = 106
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
		if indexPath.row == 0 || !editable { return }
		
		var alertTitle = ""
		var alertMessage = ""
		var alertTag = 0
		var defaultText = ""
		var keyboardType: UIKeyboardType = .NumberPad
		switch indexPath.section {
		case 1 where indexPath.row == 1 && sensor.devType == HRDeviceType.SolarSensor.rawValue:
            alertTitle   = "光照下限值"
            alertMessage = "数值必须为整数，范围：\(SOLAR_MIN)~\(SOLAR_MAX)"
			defaultText  = "\(solarSensor!.linkLowerValue)"
            alertTag     = tag_inputSolarLower
			keyboardType = .NumberPad
		case 1 where indexPath.row == 2 && sensor.devType == HRDeviceType.SolarSensor.rawValue:
			alertTitle   = "光照上限值"
			alertMessage = "数值必须为整数，范围：\(SOLAR_MIN)~\(SOLAR_MAX)"
			defaultText  = "\(solarSensor!.linkUpperValue)"
			alertTag     = tag_inputSolarUpper
			keyboardType = .NumberPad
		case 1 where indexPath.row == 1 && sensor.devType == HRDeviceType.GasSensor.rawValue:
			alertTitle   = "报警值"
			alertMessage = "数值保留两位小数，范围：\(GAS_MIN)~\(GAS_MAX)"
			defaultText  = "\(gasSensor!.linkUpperValue)"
			alertTag     = tag_inputGasAlarmValue
			keyboardType = .NumbersAndPunctuation
		case 1 where indexPath.row == 1 && sensor.devType == HRDeviceType.AirQualitySensor.rawValue:
			alertTitle   = "温度下限值"
			alertMessage = "数值保留一位小数，范围：\(AQS_TEMP_MIN)~\(AQS_TEMP_MAX)"
			defaultText  = "\(airQualitySensor!.linkLowerValueTemp)"
			alertTag     = tag_inputAirQualityTempLower
			keyboardType = .NumbersAndPunctuation
		case 1 where indexPath.row == 2 && sensor.devType == HRDeviceType.AirQualitySensor.rawValue:
			alertTitle   = "温度上限值"
			alertMessage = "数值保留一位小数，范围：\(AQS_TEMP_MIN)~\(AQS_TEMP_MAX)"
			defaultText  = "\(airQualitySensor!.linkUpperValueTemp)"
			alertTag     = tag_inputAirQualityTempUpper
			keyboardType = .NumbersAndPunctuation
		case 2 where indexPath.row == 1 && sensor.devType == HRDeviceType.AirQualitySensor.rawValue:
			alertTitle   = "湿度下限值"
			alertMessage = "数值保留一位小数，范围：\(AQS_HUMI_MIN)~\(AQS_HUMI_MAX)"
			defaultText  = "\(airQualitySensor!.linkLowerValueHumid)"
			alertTag     = tag_inputAirQualityHumiLower
			keyboardType = .NumbersAndPunctuation
		case 2 where indexPath.row == 2 && sensor.devType == HRDeviceType.AirQualitySensor.rawValue:
			alertTitle   = "湿度上限值"
			alertMessage = "数值保留一位小数，范围：\(AQS_HUMI_MIN)~\(AQS_HUMI_MAX)"
			defaultText  = "\(airQualitySensor!.linkUpperValueHumid)"
			alertTag     = tag_inputAirQualityHumiUpper
			keyboardType = .NumbersAndPunctuation
		default: return
		}
		let alert = UIAlertView(title: alertTitle, message: alertMessage, delegate: self, cancelButtonTitle: "取消", otherButtonTitles: "完成")
        alert.tag            = alertTag
        alert.alertViewStyle = .PlainTextInput
		alert.textFieldAtIndex(0)?.text = defaultText
		alert.textFieldAtIndex(0)?.keyboardType = keyboardType
		alert.show()
	}
	
	func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
		if buttonIndex == alertView.cancelButtonIndex { return }
		switch alertView.tag {
		case tag_inputSolarLower:
			let num = NSString(string: alertView.textFieldAtIndex(0)!.text!).integerValue
			solarSensor?.linkLowerValue = num > SOLAR_MAX  ? UInt16(SOLAR_MAX) : (num < SOLAR_MIN ? UInt16(SOLAR_MIN) : UInt16(num))
		case tag_inputSolarUpper:
			let num = NSString(string: alertView.textFieldAtIndex(0)!.text!).integerValue
			solarSensor?.linkUpperValue = num > SOLAR_MAX  ? UInt16(SOLAR_MAX) : (num < SOLAR_MIN ? UInt16(SOLAR_MIN) : UInt16(num))
		case tag_inputGasAlarmValue:
			let num = NSString(string: alertView.textFieldAtIndex(0)!.text!).floatValue
			gasSensor?.linkUpperValue = num > GAS_MAX ? GAS_MAX : (num < GAS_MIN ? GAS_MIN : num)
		case tag_inputAirQualityTempLower:
			let num = NSString(string: alertView.textFieldAtIndex(0)!.text!).floatValue
			airQualitySensor?.linkLowerValueTemp = num > AQS_TEMP_MAX ? AQS_TEMP_MAX : (num < AQS_TEMP_MIN ? AQS_TEMP_MIN : num)
		case tag_inputAirQualityTempUpper:
			let num = NSString(string: alertView.textFieldAtIndex(0)!.text!).floatValue
			airQualitySensor?.linkUpperValueTemp = num > AQS_TEMP_MAX ? AQS_TEMP_MAX : (num < AQS_TEMP_MIN ? AQS_TEMP_MIN : num)
		case tag_inputAirQualityHumiLower:
			let num = NSString(string: alertView.textFieldAtIndex(0)!.text!).floatValue
			airQualitySensor?.linkLowerValueHumid = num > AQS_HUMI_MAX ? AQS_HUMI_MAX : (num < AQS_HUMI_MIN ? AQS_HUMI_MIN : num)
		case tag_inputAirQualityHumiUpper:
			let num = NSString(string: alertView.textFieldAtIndex(0)!.text!).floatValue
			airQualitySensor?.linkUpperValueHumid = num > AQS_HUMI_MAX ? AQS_HUMI_MAX : (num < AQS_HUMI_MIN ? AQS_HUMI_MIN : num)
		default: break
		}
		self.tableView.reloadData()
	}
	@objc private func tapSaveBarButton() {
		let _sensor: HRSensor
		switch sensor.devType {
		case HRDeviceType.SolarSensor.rawValue:
			solarSensor?.linkEnable = switch0View.on
            _sensor = solarSensor!
			if solarSensor?.linkUpperValue < solarSensor?.linkLowerValue {
				UIAlertView(title: "光照上限值必须大于下限值！", message: nil, delegate: nil, cancelButtonTitle: "确定").show()
				return
			}
		case HRDeviceType.GasSensor.rawValue:
			gasSensor?.linkEnable = switch0View.on
            _sensor = gasSensor!
		case HRDeviceType.HumiditySensor.rawValue:
			humiditySensor?.linkEnable = switch0View.on
            _sensor = humiditySensor!
		case HRDeviceType.AirQualitySensor.rawValue:
            airQualitySensor?.linkTempEnable  = switch0View.on
			airQualitySensor?.linkHumidEnable = switch1View.on
			if airQualitySensor?.linkUpperValueTemp < airQualitySensor?.linkLowerValueTemp {
				UIAlertView(title: "温度上限值必须大于下限值！", message: nil, delegate: nil, cancelButtonTitle: "确定").show()
				return
			}
			
			if airQualitySensor?.linkUpperValueHumid < airQualitySensor?.linkLowerValueHumid {
				UIAlertView(title: "湿度上限值必须大于下限值！", message: nil, delegate: nil, cancelButtonTitle: "确定").show()
				return
			}
            _sensor = airQualitySensor!
		default: return
		}
		KVNProgress.showWithStatus("正在保存...")
		HR8000Service.shareInstance().setSensorActionValue(_sensor, result: {
			error in
			if let err = error {
				KVNProgress.showErrorWithStatus(err.domain)
			} else {
				KVNProgress.showSuccessWithStatus("保存成功")
				runOnMainQueueDelay(500, block: {
					self.navigationController?.popViewControllerAnimated(true)
				})
			}
		})
	}
}
