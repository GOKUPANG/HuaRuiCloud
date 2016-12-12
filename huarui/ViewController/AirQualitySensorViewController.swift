//
//  AirQualitySensorViewController.swift
//  huarui
//
//  Created by sswukang on 15/6/17.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import UIKit

class AirQualitySensorViewController: UIViewController, HRSensorValuesDelegate {
    var aqsDev: HRAirQualitySensor!
    
    private var tempView: TempView!
    private var humiView: HumidityView!
    private var chartView: ChartView!
	private var tipsView: TipsView!
	
	private var _timer: NSTimer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = aqsDev.name
        self.view.backgroundColor = UIColor(red: 33/255.0, green: 152/255.0, blue: 42/255.0, alpha: 1)
		
        let topH = navigationController!.navigationBar.frame.height + UIApplication.sharedApplication().statusBarFrame.height
		self.view.frame = CGRectMake(view.frame.minX, view.frame.minY, view.frame.width, view.frame.height - topH)
		
		tipsView = TipsView(frame: CGRectMake(0, 0, view.frame.width, 30))
		self.view.addSubview(tipsView)
		
        //温度
        tempView = TempView(frame: CGRectMake(0, 0, view.frame.width/2, view.frame.width/2))
		tempView.center.x = self.view.bounds.width*0.25
		tempView.center.y = self.view.bounds.height*0.2
        tempView.value = 0
        self.view.addSubview(tempView)
		
		let line = UIView(frame: CGRectMake(0, 0, 0.5, tempView.bounds.height*0.8))
		line.center.x = self.view.bounds.midX
		line.center.y = self.tempView.center.y
		line.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.9)
		self.view.addSubview(line)
        
        //湿度
		humiView = HumidityView(frame: CGRectMake(0, 0, tempView.frame.width, tempView.frame.height))
		humiView.center.x = self.view.bounds.width - tempView.center.x
		humiView.center.y = tempView.center.y
        humiView.value = 0
        self.view.addSubview(humiView)
        
        //表格
        chartView = ChartView(frame: CGRectMake(0, view.bounds.midY, view.frame.width, view.frame.height/2 - 3))
        view.addSubview(chartView)
		
		//右上角刷新按钮
		let customView = UIButton(frame: CGRectMake(0, 0, 25, 25))
		customView.setImage(UIImage(named: "ico_refresh"), forState: .Normal)
		customView.tintColor = UIColor.whiteColor()
		customView.addTarget(self, action: #selector(AirQualitySensorViewController.onRefreshButtonClicked(_:)), forControlEvents: .TouchUpInside)
		let refreshBtn = UIBarButtonItem(customView: customView)
		self.navigationItem.rightBarButtonItem = refreshBtn
    }
	
    override func viewDidAppear(animated: Bool) {
		if aqsDev == nil {
			self.navigationController?.popViewControllerAnimated(true)
			HRProcessCenter.shareInstance().delegates.sensorValuesDelegate = nil
			return
		}
        humiView.startAnimation(1.5)
		tempView.startAnimation(1.5)
		HRProcessCenter.shareInstance().delegates.sensorValuesDelegate = self
		//查询值
		self.aqsDev.queryValue()
		_timer = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: #selector(AirQualitySensorViewController.timeUp(_:)), userInfo: nil, repeats: false)
	}
	
	override func viewDidDisappear(animated: Bool) {
		HRProcessCenter.shareInstance().delegates.sensorValuesDelegate = nil
	}
	
	@objc private func onRefreshButtonClicked(button: UIButton) {
		button.startRotate(1)
		self.aqsDev.queryValue()
		_timer.invalidate()
		_timer = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: #selector(AirQualitySensorViewController.timeUp(_:)), userInfo: nil, repeats: false)
	}
	
	@objc private func timeUp(timer: NSTimer) {
		tipsView.show("获取数据超时", duration: 2.5)
	}

	//MARK: - Sensor Values Delegate
	func sensorValues(tempAirValueResult devAddr: UInt32, temperature: Int16, humidity: UInt16, airQuality: UInt16, tag: Byte) {
		if devAddr != self.aqsDev.devAddr { return }
		runOnMainQueue({
			self.humiView.value = Float(humidity)/10
			self.tempView.value = Float(temperature)/10
		})
		self._timer.invalidate()
	}
	
}
