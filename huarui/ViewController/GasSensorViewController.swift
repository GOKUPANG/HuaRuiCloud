//
//  GasSensorViewController.swift
//  huarui
//
//  Created by sswukang on 15/6/2.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import UIKit

class GasSensorViewController: UIViewController, HRSensorValuesDelegate{
    private let TAG: Byte = 27
    private var circleView  : CircleView!
    private var chartView: ChartView!
    private var tipsView : TipsView!
    private var _timer   : NSTimer!
    
    var gasDev : HRGasSensor!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if gasDev != nil {
            self.navigationItem.title = gasDev!.name
        }
        view.backgroundColor = getColorFromLEL(0)
//        let topH = navigationController!.navigationBar.frame.height + UIApplication.sharedApplication().statusBarFrame.height
		let topH: CGFloat = 0
		let containerH: CGFloat = self.view.frame.height - navigationController!.navigationBar.frame.height - UIApplication.sharedApplication().statusBarFrame.height
        circleView = CircleView(frame: CGRectMake(0, topH, view.frame.width, containerH/2-topH))
        chartView = ChartView(frame: CGRectMake(0, containerH/2 + topH - 2, view.frame.width, (containerH-topH*2)/2))
        tipsView = TipsView(frame: CGRectMake(0, topH, view.frame.width, 30))
        
        view.addSubview(circleView)
        view.addSubview(chartView)
        view.addSubview(tipsView)
        
        //右上角刷新按钮
        let customView = UIButton(frame: CGRectMake(0, 0, 25, 25))
        customView.setImage(UIImage(named: "ico_refresh"), forState: .Normal)
        customView.tintColor = UIColor.whiteColor()
        customView.addTarget(self, action: #selector(GasSensorViewController.onRefreshButtonClicked(_:)), forControlEvents: .TouchUpInside)
        let refreshBtn = UIBarButtonItem(customView: customView)
        self.navigationItem.rightBarButtonItem = refreshBtn
        
        var gesture = UITapGestureRecognizer(target: self, action: #selector(GasSensorViewController.onChartTap(_:)))
        chartView.addGestureRecognizer(gesture)
        gesture = UITapGestureRecognizer(target: self, action: #selector(GasSensorViewController.onLELTap(_:)))
        circleView.addGestureRecognizer(gesture)
        
        circleView.valueUseInt = false
        circleView.unitText = "%LEL"
        circleView.maxValue = 100
        circleView.mainColor = UIColor.whiteColor()
        circleView.isNumLabelColorGradient = false
        circleView.showPoint = false
		
        HRProcessCenter.shareInstance().delegates.sensorValuesDelegate = self
        
        _timer = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: #selector(GasSensorViewController.timeUp(_:)), userInfo: nil, repeats: false)

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
        gasDev.queryValue()
        _timer.invalidate()
        _timer = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: #selector(GasSensorViewController.timeUp(_:)), userInfo: nil, repeats: false)
    }
    
    func onLELTap(gesture: UITapGestureRecognizer){
        switch gesture.state {
        case .Ended:
            gasDev.queryValue()
            _timer.invalidate()
            _timer = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: #selector(GasSensorViewController.timeUp(_:)), userInfo: nil, repeats: false)
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

	override func viewDidAppear(animated: Bool){
		if gasDev == nil {
			self.navigationController?.popViewControllerAnimated(true)
			HRProcessCenter.shareInstance().delegates.sensorValuesDelegate = nil
			return
		}
		gasDev.queryValue()
	}
	
	override func viewDidDisappear(animated: Bool) {
		HRProcessCenter.shareInstance().delegates.sensorValuesDelegate = nil
	}

	
    func displayLink(link: CADisplayLink){
        if circleView.currentValue == circleView.value {
            link.invalidate()
            link.removeFromRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        }
        self.view.backgroundColor = getColorFromLEL(circleView.currentValue)
    }
    
    private func getColorFromLEL(lel: Float) -> UIColor {
        let x = lel / 100.0
        let h = CGFloat((111.0/360.0) * (1-pow(x, 0.45)))
        return UIColor(hue: h, saturation: 1, brightness: 0.6, alpha: 1)
        
        
    }
    
    
//    override func viewDidDisappear(animated: Bool) {
//        testing = false
//    }
//    
//    var testing = true
//    
//    func test(){
//        APP.runOnGlobalQueue({
//            APP.runOnMainQueue({
//                let num = Float(arc4random() % 10000) / 100.0
//                self.onGasLELValueResult(self.gasDev.devAddr, lel: num, tag: 27)
//            })
//            sleep(2)
//            if self.testing {
//                self.test()
//            }
//        })
//    }
    
    
//MARK: - HRSensorValuesDelegate
    
    func sensorValues(gasLELValueResult devAddr: UInt32, lel: Float, tag: Byte) {
        if devAddr != self.gasDev.devAddr {
            return
        }
        if tag == HRFrameSn.QuerySensorValue.rawValue {
            _timer.invalidate()
        }
        runOnMainQueue({
            self.circleView.value = lel
            self.chartView.addValue(lel, animation: true)
            //默认每秒60次
            CADisplayLink(target: self, selector: #selector(GasSensorViewController.displayLink(_:))).addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        })
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
