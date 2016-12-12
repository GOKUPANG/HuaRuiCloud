//
//  PopTestViewController.swift
//  viewTest
//
//  Created by sswukang on 15/9/11.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import UIKit


/// 红外码库匹配界面
class LearningInfraredViewController: UITableViewController, UINavigationControllerDelegate,UIPickerViewDelegate, UIPickerViewDataSource, HRInfraredDelegate {
	
	var appDevice: HRApplianceApplyDev!
	
	/// 当前选择的品牌
	private var currentBrand: String?
	/// 当前选择的码库索引
	private var currentlibIndex: Int? {
		if indexsPicker == nil { return nil }
		if currentBrandIndexs == nil { return nil }
		return currentBrandIndexs![indexsPicker!.selectedRowInComponent(0)]
	}
	
	/// 当前品牌的红外码库索引集
	private var currentBrandIndexs: [Int]?
	/// 红外码库
	private var infLib: NSArray?
	private var indexsPicker: UIPickerView!
	private var tipsView: TipsView!
	///发送帧的tag
	private var _tag: Byte = 0

	//MARK: - UIViewController
	
	init() {
		super.init(style: UITableViewStyle.Grouped)
	}
	
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
	}
	
	required init!(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
    override func viewDidLoad() {
		super.viewDidLoad()
		self.title = "红外学习"
		tableView.backgroundColor = UIColor.tableBackgroundColor()
		tableView.separatorColor = UIColor.tableSeparatorColor()
		if appDevice == nil {
			tableView.dataSource = nil
			return
		}
		if HRDatabase.shareInstance().acount.permission == 2 || HRDatabase.shareInstance().acount.permission == 3 {
			let saveButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Save, target: self, action: #selector(LearningInfraredViewController.onSaveButtonClicked(_:)))
			self.navigationItem.rightBarButtonItem = saveButton
		}
		
		tipsView = TipsView(frame: CGRectMake(0, 0, self.view.frame.width, 30))
		self.view.addSubview(tipsView)
		_tag = Byte(arc4random() % 128)
		
		runOnGlobalQueue({
			//从plist中读出空调型号
			self.infLib = NSArray(contentsOfURL: NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("air_infrared_library", ofType: "plist")!))
			if self.infLib == nil { return }
			let libIndex = self.appDevice.learnKeys.count > 0 ? self.appDevice.learnKeys[0].codeLibIndex : 0
			var row = 0
			if let brand = self.codelibIndexToBrand(Int(libIndex)) {
				self.currentBrand = brand
				self.currentBrandIndexs = self.getBrandIndexs(brand)
				for i in 0..<self.currentBrandIndexs!.count {
					if self.currentBrandIndexs![i] == Int(libIndex) {
						row = i
						break
					}
				}
			} else {
				self.currentBrand = self.getAllBrands()[0]
				self.currentBrandIndexs = self.getBrandIndexs(self.currentBrand!)
			}
			runOnMainQueue({
				self.tableView.reloadData()
				self.indexsPicker.reloadComponent(0)
				self.indexsPicker.selectRow(row, inComponent: 0, animated: false)
			})
		})
    }
	
	override func viewDidAppear(animated: Bool) {
		if appDevice == nil {
			self.navigationController?.popViewControllerAnimated(true)
			return
		}
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
		
    }
	
	//MARK: - UI事件
	@objc private func subAddButtonClicked(button: UIButton) {
		let nextOrPrev: Int
		let currentRow = indexsPicker.selectedRowInComponent(0)
		if button.tag < 0 && currentRow != 0{
			nextOrPrev = currentRow - 1
		} else if button.tag > 0 && currentRow != indexsPicker.numberOfRowsInComponent(0) - 1 {
			nextOrPrev = currentRow + 1
		} else {
			nextOrPrev = currentRow
		}
		indexsPicker.selectRow(nextOrPrev, inComponent: 0, animated: true)
	}
	
	@objc private func onSaveButtonClicked(button: UIBarButtonItem) {
		guard let index = self.currentlibIndex else {
			UIAlertView(title: "提示", message: "请选择一个型号码库！", delegate: nil, cancelButtonTitle: "确定").show()
			return
		}
		KVNProgress.showWithStatus("正在保存...")
		HR8000Service.shareInstance().learningInfraredUseLibrary(
			self.appDevice,
			codeLibIndex: UInt16(index),
			result: { error in
			if let err = error {
				KVNProgress.showErrorWithStatus("失败：\(err.domain)")
			} else {
				KVNProgress.showSuccessWithStatus("学习成功!")
				runOnMainQueueDelay(800, block: {
					self.navigationController?.popViewControllerAnimated(true)
				})
			}
		})
		
	}
	
	//MARK: - UITableViewController
	private var footerView: UIView!
	
	override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		if section != 0 {
			return nil
		}
		if self.footerView == nil {
			self.footerView = getFooterView()
		}
		return self.footerView
	}
	
	override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		if self.footerView == nil {
			self.footerView = getFooterView()
		}
		return footerView!.frame.height
	}
	
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 2
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "cell")
		cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
		switch indexPath.row {
		case 0:
			cell.textLabel?.text = "类型"
			if let type = HRAppDeviceType(rawValue: appDevice.appDevType) {
				switch  type {
				case .AirCtrl:
					cell.detailTextLabel?.text = "空调"
				case .None:
					cell.detailTextLabel?.text = "自定义"
				case .TV:
					cell.detailTextLabel?.text = "电视机"
				default: break
				}
			}
		case 1:
			cell.textLabel?.text = "品牌"
			if let index = currentlibIndex {
				cell.detailTextLabel?.text = codelibIndexToBrand(index)
			} else {
				cell.detailTextLabel?.text = ""
			}
		default: break
		}
		
		return cell
	}
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let cell = tableView.cellForRowAtIndexPath(indexPath)
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
		
		if indexPath.row == 1 {
			currentBrand = cell?.detailTextLabel?.text
		}
		switch indexPath.row {
		case 0:
			ValuePickerActionView(title: "选择类型", values: ["空调"], currentRow: nil, delegate: nil).show()
		case 1:
			let brands = getAllBrands()
			var currentRow = 0
			for i in 0..<brands.count where brands[i] == self.currentBrand {
				currentRow = i
			}
			ValuePickerActionView(title: "选择品牌", values: brands, currentRow: currentRow, delegate: nil).showWithHandler({
				(brand, index) in
				let brand = brands[index]
				if brand != self.currentBrand {
					self.currentBrand = brand
					self.currentBrandIndexs = self.getBrandIndexs(brand)
					self.indexsPicker.reloadComponent(0)
					self.indexsPicker.selectRow(0, inComponent: 0, animated: false)
					cell?.detailTextLabel?.text = self.currentBrand!
				}
			})
		default: break
		}
	
	}
	
	private func getFooterView() -> UIView {
		
		let footerView = UIView(frame: CGRectMake(0, 0, tableView.frame.width, 100))
		
		let line1 = UIView(frame: CGRectMake(15, 25, tableView.frame.width-30, 0.5))
		line1.backgroundColor = UIColor.lightGrayColor()
		footerView.addSubview(line1)
		
		let modelTitle = "型号"
		var titleSize = NSString(string: modelTitle).sizeWithAttributes([NSFontAttributeName: UIFont.systemFontOfSize(UIFont.systemFontSize())])
		let modelTitleLabel = UILabel(frame: CGRectMake(0, 0, titleSize.width+20, titleSize.height))
		modelTitleLabel.center = CGPointMake(footerView.frame.width/2, line1.center.y)
		modelTitleLabel.text = modelTitle
		modelTitleLabel.font = UIFont.systemFontOfSize(UIFont.systemFontSize())
		modelTitleLabel.textAlignment = .Center
		modelTitleLabel.textColor = UIColor.lightGrayColor()
		modelTitleLabel.backgroundColor = tableView.backgroundColor
		footerView.addSubview(modelTitleLabel)
		
		let buttonSub = UIButton(type: UIButtonType.System)
		buttonSub.frame = CGRectMake(0, 0, 60, 60)
		buttonSub.center = CGPointMake(footerView.frame.width*0.2, line1.frame.maxY + 70)
		buttonSub.layer.cornerRadius = 30
		buttonSub.layer.borderWidth = 1
		buttonSub.layer.borderColor = UIColor.grayColor().CGColor
		buttonSub.setTitle("-", forState: UIControlState.Normal)
		buttonSub.titleLabel?.font = UIFont.systemFontOfSize(50)
		buttonSub.setTitleColor(UIColor.grayColor(), forState: UIControlState.Normal)
		buttonSub.tag = -1
		buttonSub.addTarget(self, action: #selector(LearningInfraredViewController.subAddButtonClicked(_:)), forControlEvents: .TouchUpInside)
		footerView.addSubview(buttonSub)
		
		indexsPicker = UIPickerView(frame: CGRectMake(0, 0, 100, 120))
		indexsPicker.center = CGPointMake(footerView.frame.width/2, buttonSub.center.y)
		indexsPicker.dataSource = self
		indexsPicker.delegate = self
		footerView.insertSubview(indexsPicker, belowSubview: modelTitleLabel)
		
		
		let buttonAdd = UIButton(type: UIButtonType.System)
		buttonAdd.frame = CGRectMake(0, 0, 60, 60)
		buttonAdd.center = CGPointMake(footerView.frame.width * 0.8, buttonSub.center.y)
		buttonAdd.layer.cornerRadius = 30
		buttonAdd.layer.borderWidth = 1
		buttonAdd.layer.borderColor = UIColor.grayColor().CGColor
		buttonAdd.setTitle("+", forState: UIControlState.Normal)
		buttonAdd.titleLabel?.font = UIFont.systemFontOfSize(50)
		buttonAdd.setTitleColor(UIColor.grayColor(), forState: UIControlState.Normal)
		buttonAdd.tag = 1
		buttonAdd.addTarget(self, action: #selector(LearningInfraredViewController.subAddButtonClicked(_:)), forControlEvents: .TouchUpInside)
		footerView.addSubview(buttonAdd)
		
		let line2 = UIView(frame: CGRectMake(line1.frame.minX, 2*buttonSub.center.y - line1.center.y, line1.frame.width, 0.5))
		line2.backgroundColor = line1.backgroundColor
		footerView.addSubview(line2)
		
		let testTitle = "测试按键"
		titleSize = NSString(string: testTitle).sizeWithAttributes([NSFontAttributeName: UIFont.systemFontOfSize(UIFont.systemFontSize())])
		let testTitleLabel = UILabel(frame: CGRectMake(0, 0, titleSize.width+20, titleSize.height))
		testTitleLabel.center = CGPointMake(footerView.frame.width/2, line2.center.y)
		testTitleLabel.text = testTitle
		testTitleLabel.font = UIFont.systemFontOfSize(UIFont.systemFontSize())
		testTitleLabel.textAlignment = .Center
		testTitleLabel.textColor = UIColor.lightGrayColor()
		testTitleLabel.backgroundColor = tableView.backgroundColor
		footerView.addSubview(testTitleLabel)
		
		let gapH = (footerView.frame.width - 70*3) / 4
		let buttonCool = PrettyButton(frame: CGRectMake(gapH, 0, 70, 70))
		buttonCool.center.y = line2.frame.maxY + 80
		buttonCool.backgroundColor = APP.param.themeColor.colorWithAlphaComponent(0.6)
		buttonCool.hightLightColor = APP.param.themeColor.colorWithAdjustBrightness(-0.3)
		buttonCool.cornerRadius = buttonCool.frame.height/2
		buttonCool.setTitle("制冷", forState: .Normal)
		buttonCool.tag = Int(HRAirKeyCode.ModeCooling.rawValue)
		buttonCool.addTarget(self, action: #selector(LearningInfraredViewController.testButtonTouchUpInside(_:)), forControlEvents: .TouchUpInside)
		footerView.addSubview(buttonCool)
		
		let buttonPower = PrettyButton(frame: CGRectMake(gapH*2 + 60, 0, 80, 80))
		buttonPower.center.y = buttonCool.center.y
		buttonPower.cornerRadius = buttonPower.frame.height/2
		buttonPower.backgroundColor = UIColor.redColor().colorWithAlphaComponent(0.6)
		buttonPower.hightLightColor = UIColor.redColor().colorWithAdjustBrightness(-0.3)
		buttonPower.setImage(UIImage(named: "ico_power_bai"), forState: UIControlState.Normal)
		buttonPower.tag = Int(HRAirKeyCode.PowerOn.rawValue)
		buttonPower.addTarget(self, action: #selector(LearningInfraredViewController.testButtonTouchUpInside(_:)), forControlEvents: .TouchUpInside)
		footerView.addSubview(buttonPower)
		
		let buttonTemp = PrettyButton(frame: CGRectMake(gapH*3 + 60*2, 0, 70, 70))
		buttonTemp.center.y = buttonCool.center.y
		buttonTemp.cornerRadius = buttonTemp.frame.height/2
		buttonTemp.backgroundColor = APP.param.themeColor.colorWithAlphaComponent(0.6)
		buttonTemp.hightLightColor = APP.param.themeColor.colorWithAdjustBrightness(-0.3)
		buttonTemp.setTitle("26℃", forState: .Normal)
		buttonTemp.tag = Int(HRAirKeyCode.Celsius26.rawValue)
		buttonTemp.addTarget(self, action: #selector(LearningInfraredViewController.testButtonTouchUpInside(_:)), forControlEvents: .TouchUpInside)
		footerView.addSubview(buttonTemp)
		footerView.frame = CGRect(
			x:footerView.frame.minX,
			y: footerView.frame.minY,
			width: footerView.frame.width,
			height: buttonPower.frame.maxY+10
		)
		return footerView
	}
	
	@objc private func testButtonTouchUpInside(button: UIButton) {
		if currentlibIndex == nil {
			Log.error("testButtonTouchUpInside：没有选择码库索引！")
			return
		}
		let key: HRInfraredKey!
		switch Byte(button.tag) {
		case HRAirKeyCode.ModeCooling.rawValue:
			key = getInfraredKey(HRAirKeyCode.ModeCooling.rawValue)!
		case HRAirKeyCode.PowerOn.rawValue:
			key = getInfraredKey(HRAirKeyCode.PowerOn.rawValue)!
		case HRAirKeyCode.Celsius26.rawValue:
			key = getInfraredKey(HRAirKeyCode.Celsius26.rawValue)!
		default: return
		}
		HRProcessCenter.shareInstance().delegates.infraredDelegate = self
		self.tipsView.show("正在发送...", duration: 5)
		appDevice.sendInfrared(infraredKey: key, ctrlType: .MatchLibrary, tag: _tag, result: { (error) in
			if let err = error {
				self.tipsView.show("控制失败：\(err.domain)", duration: 2)
			}
		})
		
	}
	
	///获取按键编码
	///
	///-parameter keyCode 按键码
	private func getInfraredKey(keyCode: Byte) -> HRInfraredKey? {
		guard let index = currentlibIndex else {
			Log.error("getInfraredKey：没有选择码库索引！")
			return nil
		}
		let key = HRInfraredKey()
        key.keyCode      = keyCode
        key.codeLibType  = HRInfraredKeyCodeLibType.AirCtrl.rawValue
		key.codeLibIndex = UInt16(index)
        key.operateCode  = keyCode
		return key
	}
	
//MARK: - HRInfraredDelegate
	
	func infraredTransmit(codeMatching appDevID: UInt16, devType: Byte, tag: Byte, keyCode: Byte, codeIndex: UInt32, result: Bool) {
		Log.info("codeIndex: \(codeIndex.getBytes())")
		if tag != _tag { return }
		self.tipsView.show("红外已发送，请注意观察设备是否响应！", duration: 4)
	}
	
	
//MARK: - UIPickerView
	
	func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
		return 1
	}
	
	func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		if let indexs = currentBrandIndexs {
			return indexs.count
		}
		return 0
	}
	
	func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		return String(format: "%.3d", currentBrandIndexs![row])
	}
	
	
//MARK: - 处理方法
	
	private func getAllBrands() -> [String] {
		if infLib == nil { return [] }
		var brands = [String]()
		for brandObj in infLib! {
			if let brandDic = brandObj as? NSDictionary {
				if let brand = brandDic["brand"] as? String {
					brands.append(brand)
				}
			}
		}
		return brands
	}
	
	private func getBrandIndexs(brand: String) -> [Int] {
		if infLib == nil { return []}
//		var indexs = [Int]()
		for brandObj in infLib! {
			if let brandDic = brandObj as? NSDictionary {
				if brand == brandDic["brand"] as? String {
					return brandDic["indexs"] as! [Int]
				}
			}
		}
		return []
	}
	
	private func getBrandIndexStrings(brand: String) -> [String] {
		var indexs = [String]()
		for index in self.getBrandIndexs(brand) {
			indexs.append("\(index)")
		}
		return indexs
	}

	/// 根据码库索引查找品牌
	private func codelibIndexToBrand(index: Int) -> String? {
		if let lib = infLib {
			for brandObj in lib {
				if let brandDic = brandObj as? NSDictionary {
					if let indexs = brandDic["indexs"] as? NSArray {
						for _index in indexs where index == _index as? Int {
							return brandDic["brand"] as? String
						}
					}
				}
			}
		}
		return nil
	}
}
