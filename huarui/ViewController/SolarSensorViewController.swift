//
//  SolarSensorViewController.swift
//  huarui
//
//  Created by sswukang on 15/5/25.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import UIKit

class SolarSensorViewController: UIViewController, HRSensorValuesDelegate {
    private var luxView  : CircleView!
    private var chartView: ChartView!
    private var tipsView : TipsView!
    private var _timer   : NSTimer!
//    private var _isReceive = false
    
    var solarDev : HRSolarSensor!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if solarDev != nil {
            self.navigationItem.title = solarDev!.name
        }
        view.backgroundColor = UIColor(red: 33/255.0, green: 119/255.0, blue: 150/255.0, alpha: 1)
//        let topH = navigationController!.navigationBar.frame.height + UIApplication.sharedApplication().statusBarFrame.height 
		let topH: CGFloat = 0
		let containerH: CGFloat = self.view.frame.height - navigationController!.navigationBar.frame.height - UIApplication.sharedApplication().statusBarFrame.height
        luxView = CircleView(frame: CGRectMake(0, topH, view.frame.width, containerH/2-topH))
        chartView = ChartView(frame: CGRectMake(0, containerH / 2 + topH - 2, view.frame.width, (containerH-topH*2)/2))
        tipsView = TipsView(frame: CGRectMake(0, topH, view.frame.width, 30))
        
        view.addSubview(luxView)
        view.addSubview(chartView)
        view.addSubview(tipsView)
        
        //右上角刷新按钮
        let customView = UIButton(frame: CGRectMake(0, 0, 25, 25))
        customView.setImage(UIImage(named: "ico_refresh"), forState: .Normal)
        customView.tintColor = UIColor.whiteColor()
        customView.addTarget(self, action: #selector(SolarSensorViewController.onRefreshButtonClicked(_:)), forControlEvents: .TouchUpInside)
        let refreshBtn = UIBarButtonItem(customView: customView)
        self.navigationItem.rightBarButtonItem = refreshBtn
        
        luxView.valueUseInt = true
        luxView.unitText = "Lux"
        luxView.maxValue = 4000
        luxView.isNumLabelColorGradient = true
        luxView.showPoint = true
        
        var gesture = UITapGestureRecognizer(target: self, action: #selector(SolarSensorViewController.onChartTap(_:)))
        chartView.addGestureRecognizer(gesture)
        gesture = UITapGestureRecognizer(target: self, action: #selector(SolarSensorViewController.onLuxTap(_:)))
        luxView.addGestureRecognizer(gesture)
		
        HRProcessCenter.shareInstance().delegates.sensorValuesDelegate = self
        
        _timer = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: #selector(SolarSensorViewController.timeUp(_:)), userInfo: nil, repeats: false)
        
    }
    
    func onChartTap(gesture: UITapGestureRecognizer){
        switch gesture.state {
        case .Ended:
            chartView.isCurve = !chartView.isCurve
        default:
            break
        }
    }
    
    func onRefreshButtonClicked(button: UIButton) {
        button.startRotate(1)
        solarDev.queryValue()
        _timer.invalidate()
        _timer = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: #selector(SolarSensorViewController.timeUp(_:)), userInfo: nil, repeats: false)
    }
    
    func onLuxTap(gesture: UITapGestureRecognizer){
        switch gesture.state {
        case .Ended:
            solarDev.queryValue()
            _timer.invalidate()
            _timer = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: #selector(SolarSensorViewController.timeUp(_:)), userInfo: nil, repeats: false)
        default:
            break
        }
    }

    func timeUp(timer: NSTimer){
        tipsView.show("获取数据超时", duration: 2.5)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidAppear(animated: Bool) {
		if solarDev == nil {
			self.navigationController?.popViewControllerAnimated(true)
			HRProcessCenter.shareInstance().delegates.sensorValuesDelegate = nil
			return
		}
		solarDev.queryValue()
        luxView.startValue = Int(solarDev.linkLowerValue)
        luxView.endValue   = Int(solarDev.linkUpperValue)
    }
	
	override func viewDidDisappear(animated: Bool) {
		HRProcessCenter.shareInstance().delegates.sensorValuesDelegate = nil
	}
  
//MARK: - HRSensorValuesDelegate
    
    func sensorValues(SolarValueResult devAddr: UInt32, lux: UInt16, tag: Byte) {
        if devAddr != self.solarDev.devAddr {
            return
        }
        if tag == HRFrameSn.QuerySensorValue.rawValue {
            _timer.invalidate()
        }
        runOnMainQueue({
            self.luxView.value = Float(lux)
            self.chartView.addValue(Float(lux), animation: true)
        })
    }

}
