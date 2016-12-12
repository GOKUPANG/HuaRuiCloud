//
//  EditSensorBindsViewController.swift
//  huarui
//
//  Created by sswukang on 15/12/7.
//  Copyright © 2015年 huarui. All rights reserved.
//

import UIKit

/// 编辑传感器绑定界面
class EditSensorBindsViewController: UITableViewController, HR8000HelperDelegate {
	
	var sensor: HRSensor!
	
	private var solarSensor: HRSolarSensor?
	private var gasSensor: HRGasSensor?
	private var humiditySensor: HRHumiditySensor?
	private var airQualitySensor: HRAirQualitySensor?
	
	private var editable = false 
	
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
		self.title = (editable ? "编辑":"查看") + "动作值与设备绑定"
		tableView.backgroundColor = UIColor.tableBackgroundColor()
		tableView.separatorColor = UIColor.tableSeparatorColor()
		self.initDatas()
		addViews()
		HRProcessCenter.shareInstance().delegates.hr8000HelperDelegate = self
	}
	
	override func viewDidAppear(animated: Bool) {
		if sensor == nil {
			self.navigationController?.popViewControllerAnimated(true)
		}
	}
	
	private func initDatas() {
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
	}
	
	private func addViews() {
		
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
		case 1 where sensor.devType == HRDeviceType.SolarSensor.rawValue: return 4
		case 1 where sensor.devType == HRDeviceType.HumiditySensor.rawValue: return 1
		case 1 where sensor.devType == HRDeviceType.GasSensor.rawValue: return 1
		case 1 where sensor.devType == HRDeviceType.AirQualitySensor.rawValue: return 2
		case 2 where sensor.devType == HRDeviceType.AirQualitySensor.rawValue: return 2
		default: return 0
		}
    }

	private var nameLabel: UILabel!
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		var cell: UITableViewCell! = tableView.dequeueReusableCellWithIdentifier("section_\(indexPath.section)")
		
		if cell == nil {
			cell = UITableViewCell(style: .Value1, reuseIdentifier: "section_\(indexPath.section)")
			if indexPath.section == 0 {
				nameLabel = UILabel(frame: CGRectMake(0, 0, self.tableView.bounds.width, cell.bounds.height))
				nameLabel.textAlignment = .Center
				cell.addSubview(nameLabel)
				cell.selectionStyle = .None
			}
		}
		
		if indexPath.section > 0 {
			cell.accessoryType = .DisclosureIndicator
		}
		
		switch indexPath.section {
		case 0:
			nameLabel?.text = sensor.name
		case 1 where indexPath.row == 0 && solarSensor != nil:
			cell.textLabel?.text = "一级光照增加联动"
		case 1 where indexPath.row == 1 && solarSensor != nil:
			cell.textLabel?.text = "一级光照衰减联动"
		case 1 where indexPath.row == 2 && solarSensor != nil:
			cell.textLabel?.text = "二级光照增加联动"
		case 1 where indexPath.row == 3 && solarSensor != nil:
			cell.textLabel?.text = "二级光照衰减联动"
		case 1 where indexPath.row == 0 && gasSensor != nil:
			cell.textLabel?.text = "可燃气报警联动"
		case 1 where indexPath.row == 0 && humiditySensor != nil:
			cell.textLabel?.text = "湿敏联动"
		case 1 where indexPath.row == 0 && airQualitySensor != nil:
			cell.textLabel?.text = "温度增加联动"
		case 1 where indexPath.row == 1 && airQualitySensor != nil:
			cell.textLabel?.text = "温度衰减联动"
		case 2 where indexPath.row == 0 && airQualitySensor != nil:
			cell.textLabel?.text = "湿度增加联动"
		case 2 where indexPath.row == 1 && airQualitySensor != nil:
			cell.textLabel?.text = "湿度衰减联动"
		default: break
		}
		
        return cell
    }
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
		let cell = tableView.cellForRowAtIndexPath(indexPath)!
		
		let sensor: HRSensor
		let sensorBind: HRSensorBind
		let operateType: BindSensorOperateType
		switch indexPath.section {
		case 1 where indexPath.row == 0 && solarSensor != nil:
            sensor      = solarSensor!
            sensorBind  = solarSensor!.sensorBinds[0]
            operateType = .Solar
		case 1 where indexPath.row == 1 && solarSensor != nil:
			sensor      = solarSensor!
			sensorBind  = solarSensor!.sensorBinds[2]
			operateType = .Solar
		case 1 where indexPath.row == 2 && solarSensor != nil:
			sensor      = solarSensor!
			sensorBind  = solarSensor!.sensorBinds[1]
			operateType = .Solar
		case 1 where indexPath.row == 3 && solarSensor != nil:
			sensor      = solarSensor!
			sensorBind  = solarSensor!.sensorBinds[3]
			operateType = .Solar
		case 1 where indexPath.row == 0 && gasSensor != nil:
			sensor      = gasSensor!
			sensorBind  = gasSensor!.sensorBinds[0]
			operateType = .Gas
		case 1 where indexPath.row == 0 && humiditySensor != nil:
			sensor      = humiditySensor!
			sensorBind  = humiditySensor!.sensorBinds[0]
			operateType = .HumiditySensor
		case 1 where indexPath.row == 0 && airQualitySensor != nil:
			sensor      = airQualitySensor!
			sensorBind  = airQualitySensor!.sensorBindsTemp[0]
			operateType = .Temperature
		case 1 where indexPath.row == 1 && airQualitySensor != nil:
			sensor      = airQualitySensor!
			sensorBind  = airQualitySensor!.sensorBindsTemp[1]
			operateType = .Temperature
		case 2 where indexPath.row == 0 && airQualitySensor != nil:
			sensor      = airQualitySensor!
			sensorBind  = airQualitySensor!.sensorBindsHumi[0]
			operateType = .Humidity
		case 2 where indexPath.row == 1 && airQualitySensor != nil:
			sensor      = airQualitySensor!
			sensorBind  = airQualitySensor!.sensorBindsHumi[1]
			operateType = .Humidity
		default: return
		}
		let vc = EditSensorBindDetailsViewController(sensor: sensor, sensorBind: sensorBind, operateType: operateType)
		vc.title = cell.textLabel?.text
		self.navigationController?.pushViewController(vc, animated: true)
	}
 
	func hr8000Helper(queryDeviceInfo device: HRDevice, indexOfDatabase index: Int, devices: [HRDevice]) {
		if device.devType == sensor.devType && device.devAddr == sensor.devAddr {
			self.sensor = device as! HRSensor
			self.initDatas()
			self.tableView.reloadData()
		}
	}
}
