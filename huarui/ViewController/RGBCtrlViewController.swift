//
//  RGBCtrlViewController.swift
//  huarui
//
//  Created by sswukang on 16/1/5.
//  Copyright © 2016年 huarui. All rights reserved.
//

import UIKit

class RGBCtrlViewController: UIViewController, ColorPickerViewDelegate, HRRGBLampDelegate {
	var rgbDevice: HRRGBLamp!
	var todo = SHARETODO_NOTHING
	var actionHandler: ((mode: Byte, r: Byte, g: Byte, b: Byte)->Void)?
	
	@IBOutlet weak var stepButton: UIButton!
	@IBOutlet weak var gradientButton: UIButton!
	@IBOutlet weak var rainbowButton: UIButton!
	@IBOutlet weak var lightButton: UIButton!
	@IBOutlet weak var nightButton: UIButton!
	@IBOutlet weak var powerButton: UIButton!
	@IBOutlet weak var colorPickerView: ColorPickerView!
	
	private var tipsView: TipsView!
	@IBOutlet weak var stepBadge: UILabel!
	@IBOutlet weak var gradientBadge: UILabel!
	@IBOutlet weak var rainbowBadge: UILabel!
	private var _speeds: [Byte] = [1, 1, 1]
	private var stepSpeed: Byte {
		get { return _speeds[0] }
		set { _speeds[0] = newValue > 3 ? 1 : newValue }
	}
	private var gradSpeed: Byte {
		get { return _speeds[1] }
		set { _speeds[1] = newValue > 3 ? 1 : newValue }
	}
	private var rainSpeed: Byte {
		get { return _speeds[2] }
		set { _speeds[2] = newValue > 3 ? 1 : newValue }
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		if rgbDevice == nil { return }
		self.title = rgbDevice.name
		colorPickerView.delegate = self 
		tipsView = TipsView(frame: CGRectMake(0, 0, self.view.bounds.width, 30))
		self.view.addSubview(tipsView)
		HRProcessCenter.shareInstance().delegates.rgbLampDelegate = self
		initViews()
    }
	
	override func viewDidAppear(animated: Bool) {
		if rgbDevice == nil {
			self.navigationController?.popViewControllerAnimated(true)
			return
		}
	}
	
	private func initViews() {
		
        stepBadge.text               = getSpeedText(stepSpeed)
        stepBadge.backgroundColor    = UIColor.redColor().colorWithAlphaComponent(0.8)
        stepBadge.clipsToBounds      = true
        stepBadge.layer.cornerRadius = stepBadge.bounds.height/2
		
		gradientBadge.text               = getSpeedText(gradSpeed)
        gradientBadge.backgroundColor    = UIColor.redColor().colorWithAlphaComponent(0.8)
        gradientBadge.clipsToBounds      = true
        gradientBadge.layer.cornerRadius = gradientBadge.bounds.height/2
		
		rainbowBadge.text               = getSpeedText(rainSpeed)
        rainbowBadge.backgroundColor    = UIColor.redColor().colorWithAlphaComponent(0.8)
        rainbowBadge.clipsToBounds      = true
        rainbowBadge.layer.cornerRadius = rainbowBadge.bounds.height/2
		
		if todo == SHARETODO_RECORD_RGB_COLOR {
			let cancelButton = UIBarButtonItem(title: "取消", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(RGBCtrlViewController.tapCancelButton))
			navigationItem.leftBarButtonItem = cancelButton
			let doneButton = UIBarButtonItem(title: "完成", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(RGBCtrlViewController.tapDoneButton))
			navigationItem.rightBarButtonItem = doneButton
		}
		
		//初始化状态
		if let mode = HRRGBCtrlMode(rawValue: rgbDevice.mode) {
			rgbLampDelegate(rgbDevice, valueChanged: mode, oldRGB: rgbDevice.rgbValue)
		}
	}
	
	@IBAction func tapButton(button: UIButton) {
		if todo == SHARETODO_RECORD_RGB_COLOR {
			recordRGBMode(button)
			return
		}
		tipsView.show("发送中...", duration: 5)
		switch button.tag {
		case 100:
			rgbDevice.setToStepMode(stepSpeed, duration: 0, result: { (error) -> Void in
				if let err = error {
					self.tipsView.show("设置“跳变模式”失败：\(err.domain)", duration: 2)
				} else {
					self.tipsView.show("设置“跳变模式”成功", duration: 1)
					self.stepBadge.text = self.getSpeedText(self.stepSpeed)
				}
			})
			stepSpeed += 1
		case 101:
			rgbDevice.setToGradientMode(gradSpeed, duration: 0, result: { (error) -> Void in
				if let err = error {
					self.tipsView.show("设置“渐变模式”失败：\(err.domain)", duration: 2)
				} else {
					self.tipsView.show("设置“渐变模式”成功", duration: 1)
					self.gradientBadge.text = self.getSpeedText(self.gradSpeed)
				}
			})
			gradSpeed += 1
		case 102:
			rgbDevice.setToRainbowMode(rainSpeed, duration: 0, result: { (error) -> Void in
				if let err = error {
					self.tipsView.show("设置“彩虹模式”失败：\(err.domain)", duration: 2)
				} else {
					self.tipsView.show("设置“彩虹模式”成功", duration: 1)
					self.rainbowBadge.text = self.getSpeedText(self.rainSpeed)
				}
			})
			rainSpeed += 1
		case 103:
			rgbDevice.setToLightingMode({ (error) -> Void in
				if let err = error {
					self.tipsView.show("设置“照明模式”失败：\(err.domain)", duration: 2)
				} else {
					self.tipsView.show("设置“照明模式”成功", duration: 1)
				}
			})
		case 104:
			rgbDevice.setToNightMode({ (error) -> Void in
				if let err = error {
					self.tipsView.show("设置“夜起模式”失败：\(err.domain)", duration: 2)
				} else {
					self.tipsView.show("设置“夜起模式”成功", duration: 1)
				}
			})
		case 105:
			rgbDevice.turnOnOff(!self.powerButton.selected, result: { (error) -> Void in
				let actString = self.powerButton.selected ? "关闭": "打开"
				if let err = error {
					self.tipsView.show("灯光\(actString)失败：\(err.domain)", duration: 2)
				} else {
					self.tipsView.show("灯光已\(actString)", duration: 1)
				}
			})
		default: break
		}
	}
	
	private func deselectAllModeButton() {
        self.stepButton.selected     = false
        self.gradientButton.selected = false
        self.rainbowButton.selected  = false
        self.lightButton.selected    = false
		self.nightButton.selected    = false
		if todo == SHARETODO_RECORD_RGB_COLOR {
			self.powerButton.selected = false
		}
	}
	
	private func getSpeedText(speed: Byte) -> String{
		return speed == 1 ? "慢": speed == 2 ? "中": speed == 3 ? "快":"\(speed)"
	}
	
	//完成了颜色的选择
	func colorPickerView(pickerView: ColorPickerView, didPickedColor color: UIColor) {
		var R: CGFloat = 0
		var G: CGFloat = 0
		var B: CGFloat = 0
		color.getRed(&R, green: &G, blue: &B, alpha: nil)
		R *= 255
		G *= 255
		B *= 255
		
		if todo == SHARETODO_RECORD_RGB_COLOR {
			deselectAllModeButton()
			recordValues = [0x01	, Byte(R), Byte(G), Byte(B)]
		} else {
			tipsView.show("发送中...", duration: 5)
			rgbDevice.setRGB(Byte(R), G: Byte(G), B: Byte(B)) { (error) -> Void in
				if let err = error {
					self.tipsView.show("设置失败：\(err.domain)", duration: 2)
				} else {
					self.tipsView.show("设置成功", duration: 1)
				}
			}
		}
	}
	
	//选择了左边的旧颜色
	func colorPickerView(pickerView: ColorPickerView, didSelectedOldColor color: UIColor) {
		self.colorPickerView(pickerView, didPickedColor: color)
	}
	
	func rgbLampDelegate(lamp: HRRGBLamp, valueChanged oldMode: HRRGBCtrlMode, oldRGB: HRRGBValue) {
		if lamp.devAddr != self.rgbDevice.devAddr {
			return
		}
		self.rgbDevice = lamp
		guard let newMode = HRRGBCtrlMode(rawValue: lamp.mode) else {
			return
		}
		let R = lamp.rgbValue.r
		let G = lamp.rgbValue.g
		let B = lamp.rgbValue.b
		switch newMode {
		case .RGB where R==0 && G==0 && B==0:	//关闭
			self.deselectAllModeButton()
			self.powerButton.selected = false
		case .RGB where R==1 && G==1 && B==1:	//打开
			self.deselectAllModeButton()
			self.powerButton.selected = true
		case .RGB:
			self.deselectAllModeButton()
			self.powerButton.selected = true
			colorPickerView.newColor = lamp.rgbValue.color
			colorPickerView.oldColor = oldRGB.color
		case .Step:
			self.deselectAllModeButton()
            self.stepButton.selected  = true
            self.powerButton.selected = true
//            self.stepBadge.text       = getSpeedText(R)
		case .Gradient:
			self.deselectAllModeButton()
            self.gradientButton.selected = true
            self.powerButton.selected    = true
//            self.gradientBadge.text      = getSpeedText(R)
		case .Rainbow:
			self.deselectAllModeButton()
            self.rainbowButton.selected = true
            self.powerButton.selected   = true
//            self.rainbowBadge.text      = getSpeedText(R)
		case .Lighting:
			self.deselectAllModeButton()
			self.lightButton.selected = true
			self.powerButton.selected = true
		case .Night:
			self.deselectAllModeButton()
			self.nightButton.selected = true
			self.powerButton.selected = true
		}
		
	}
	
	//MARK: - Record Color
	private var recordValues:[Byte]?
	
	@objc private func tapCancelButton() {
		if self.navigationController?.popViewControllerAnimated(true) == nil {
			self.dismissViewControllerAnimated(true, completion: nil)
		}
	}
	
	@objc private func tapDoneButton() {
		if let values = recordValues{
			actionHandler?(mode: values[0], r: values[1], g: values[2], b: values[3])
		}
		tapCancelButton()
	}
	
	private func recordRGBMode(button: UIButton) {
		if recordValues == nil { recordValues = [0, 0, 0, 0] }
		//设置colorPickerView的颜色为空, 设置两次
		colorPickerView.newColor = nil
		colorPickerView.newColor = nil
		switch button.tag {
		case 100:	//跳变模式
            recordValues   = [HRRGBCtrlMode.Step.rawValue, stepSpeed, 0, 0]
			stepBadge.text = self.getSpeedText(self.stepSpeed)
			self.stepSpeed += 1
			self.deselectAllModeButton()
			button.selected = true
		case 101: //渐变模式
            recordValues       = [HRRGBCtrlMode.Gradient.rawValue, gradSpeed, 0, 0]
			gradientBadge.text = self.getSpeedText(self.gradSpeed)
			self.gradSpeed += 1
			self.deselectAllModeButton()
			button.selected = true
		case 102: //彩虹模式
            recordValues      = [HRRGBCtrlMode.Rainbow.rawValue, rainSpeed, 0, 0]
			rainbowBadge.text = self.getSpeedText(self.rainSpeed)
			self.rainSpeed += 1
			self.deselectAllModeButton()
			button.selected = true
		case 103: //照明模式
			recordValues = [HRRGBCtrlMode.Lighting.rawValue, 0xCC, 0xCC, 0xCC]
			self.deselectAllModeButton()
			button.selected = true
		case 104: //夜起模式
			recordValues = [HRRGBCtrlMode.Night.rawValue, 0x44, 0x44, 0x44]
			self.deselectAllModeButton()
			button.selected = true
		case 105: //开关
			recordValues = [HRRGBCtrlMode.RGB.rawValue, 0, 0, 0]
			recordValues![1] = self.powerButton.selected ? 0x00:0xFF
			recordValues![2] = recordValues![1]
			recordValues![3] = recordValues![1]
			self.stepButton.selected     = false
			self.gradientButton.selected = false
			self.rainbowButton.selected  = false
			self.lightButton.selected    = false
			self.nightButton.selected    = false
			self.powerButton.selected = !powerButton.selected
		default: return
		}
	}
}
