//
//  DevicesAndScenesTableViewController.swift
//  huarui
//
//  Created by sswukang on 15/12/3.
//  Copyright © 2015年 huarui. All rights reserved.
//

import UIKit

/****************  devicesModel结构  ***************
[
	{
		"group": "Title",
		"count": 100,
		"devices":
		[
			{
				"type": "Curtain",
				"count": 100
			},

			{
				"type": "RelayBox",
				"count": 100
			}
		]
	}
]
*****************************************************/

/// 设置 - 主机信息 - 设备数量
class DevicesAndScenesTableViewController: UITableViewController {

	private var devicesModel: [[String: AnyObject]]!
	
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
		self.title = "设备/情景数量"
		tableView.backgroundColor = UIColor.tableBackgroundColor()
		tableView.separatorColor = UIColor.tableSeparatorColor()
		
		initData()
    }
	
	private func initData() {
		devicesModel = [[String: AnyObject]]()
		let descipAndTypes: [String: [HRDeviceType]] = [
			"继电器类设备"		: [.RelayControlBox, .SwitchPanel, .SocketPanel],
			"电机控制类设备"	: [.CurtainControlUnit, .Manipulator, .SmartBed],
			"家电应用类设备"	: [.ApplyDevice],
			"安防类设备"		: [.DoorLock, .DoorMagCard, .InfraredDetectorUnit, .DoorBell],
			"探测器类设备"		: [.GasSensor, .SolarSensor, .HumiditySensor, .AirQualitySensor],
			"情景面板类设备"	: [.ScenePanel],
			"情景/定时"		: [.Scene, .Task],
			"其他设备"		: [.RGBLamp, .BluetoothControlUnit, .InfraredTransmitUnit]
			
		]
		
		for (descrip, types) in descipAndTypes {
			if let group = self.deviceModelFactory(descipAndTypes: descrip, types: types) {
				devicesModel.append(group)
			}
		}
		//排序
		devicesModel = devicesModel.sort {
			if $0["group"] as! String == "其他设备" { return false }
			if $1["group"] as! String == "其他设备" { return true }
			return $0["group"] as! String > $1["group"] as! String
		}
	}
	
	private func deviceModelFactory(descipAndTypes description: String, types: [HRDeviceType]) -> [String: AnyObject]? {
		var count = 0
		var group = [String: AnyObject]()
		var devices0 =  [[String: AnyObject]]()
		for type in types {
			let devCount = HRDatabase.shareInstance().getDevicesOfTypes([type]).count
			if devCount > 0 {
				var devDict = [String: AnyObject]()
				devDict["type"] = type.description
				devDict["count"] = devCount
				devices0.append(devDict)
				count += devCount
			}
		}
		if count > 0 {
			group["group"]   = description
			group["count"]   = count
			group["devices"] = devices0
		
			return group
		}
		return nil
	}

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return devicesModel.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let arr = devicesModel[section]["devices"] as! [AnyObject]
		return arr.count
    }

	
	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return "\(devicesModel[section]["group"]!): \(devicesModel[section]["count"]!)"
	}
	
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("cell")

		if cell == nil {
			cell = UITableViewCell(style: .Value1, reuseIdentifier: "cell")
		}
		
		let devices = devicesModel[indexPath.section]["devices"] as! [[String: AnyObject]]

		cell?.textLabel?.text = devices[indexPath.row]["type"] as? String
		cell?.detailTextLabel?.text = "\(devices[indexPath.row]["count"]!)"
		
        return cell!
    }

}
