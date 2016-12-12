//
//  CreateSceneViewController.swift
//  viewTest
//
//  Created by sswukang on 15/7/17.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import UIKit


class CreateSceneViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource, PickDeviceViewControllerDelegate, TimePickerActionViewDelegate {
	
	private  enum SceneTodo {
		case View
		case Edit
		case Create
	}
	
	//MARK: - 属性
	//MARK: --公开属性
	var sceneDevice: HRScene?
	
	//MARK: --常量
	private let scrollTitleHeight: CGFloat = 46
	private let bottomActionBarHeight: CGFloat = 50
	private let tableViewRowHeight: CGFloat = 50
	private let tableViewSectionHeaderHeight: CGFloat = 50
	private let imageCollectionViewHeight: CGFloat = 260
	private let iconNames = [
		"ico_scene_athome",
		"ico_scene_leavehome",
		"ico_scene_gettingup",
		"ico_scene_sleeping",
		"ico_scene_curtainopen",
		"ico_scene_curtainclose",
		"ico_scene_curtainstop",
		"ico_scene_repast",
		"ico_scene_media",
		"ico_scene_birthday",
		"ico_scene_recreation",
		"ico_scene_romance",
		"ico_scene_relaxation",
		"ico_scene_sports",
		"ico_scene_reading",
		"ico_scene_working",
		"ico_scene_meeting",
		"ico_scene_receive"
	]

	//MARK: --views
	private var topContainer: UIView!
	private var tailContainer: UIView!
	private var shadowView: UIView!
	private var backContainer: UIView!
	private var nameTextField: UITextField!
	private var scrollTitleView: ScrollTitleView!
	private var tableView: UITableView!
	private var imageView: UIImageView!
	private var imageCollection: UICollectionView!
	private var changeImageButton: UIButton!
	private var actionBarView: BottomActionBar?
	private var bottomContainerToolbar: UIToolbar?
	
	//MARK: --其他属性
	private var newScene: HRScene!
	private var currentImageName: String = ""
	///用户手动选择了图标
	private var didUserSeletedImage: Bool = false
	///选择图标CollectionView展开的标志
	private var isImageCollectionExpand: Bool = false {
		didSet{
			tableView.scrollEnabled = !isImageCollectionExpand
		}
	}
	///每一个Section的frame的最大Y值
	private var sectionFrameMaxYs = [CGFloat]()
	///游标当前位置，继电器、电机、应用设备？
	private var scrollCurrentPos = -1
	private var todo = SceneTodo.View
	private var deviceTypes: [PickDeviceType] = [.Relay, .Motor, .Apply, .RGB]
	private var deviceDatas: [PickDeviceType: [HRDevsInTask]]!
	
	//MARK: - ViewController 
	
	override func viewDidLoad() {
		super.viewDidLoad()
		if sceneDevice == nil {
			todo = .Create
			self.title = "添加情景"
		} else if HRDatabase.isEditPermission {
			todo = .Edit
			self.title = "编辑情景"
		} else {
			todo = .View
			self.title = "查看情景"
		}
		initData()
		initViews()
	}
	
	override func viewDidDisappear(animated: Bool) {
		for cell in tableView.visibleCells {
			(cell as! SceneBindCell).free()
		}
	}
	
	private func initData() {
		switch todo {
		case .View:
			newScene = sceneDevice
		case .Create:
			newScene = HRScene()
			newScene.hostAddr = HRDatabase.shareInstance().server.hostAddr
		case .Edit:
			newScene = sceneDevice!.copy() as! HRScene
		}
		deviceDatas = [PickDeviceType:[HRDevsInTask]]()
		for type in deviceTypes {
			deviceDatas[type] = [HRDevsInTask]()
		}
		for devInScene in newScene.devices {
			//数据库中查找设备
			guard let devInDatabase = HRDatabase.shareInstance().getDevice(devInScene.devType, devAddr: devInScene.devAddr) else {
				continue
			}
			switch devInScene.devType {
			case HRDeviceType.relayTypes():
				if let relayComplexes = devInDatabase as? HRRelayComplexes{
					for relay in relayComplexes.relays {
						if Int(relay.relaySeq) < devInScene.actBinds.count && devInScene.actBinds[Int(relay.relaySeq)] < 0x03 {
							devInScene.device = relay
							deviceDatas[.Relay]?.append(devInScene)
						}
					}
				}
			default:
				devInScene.device = devInDatabase
				for ptype in PickDeviceType.allTypes {
					if let hrtype = HRDeviceType(rawValue: devInScene.devType) where ptype.hrDeviceTypes.contains(hrtype) {
						deviceDatas[ptype]?.append(devInScene)
					}
				}
			}
		}
	}
	
	func initViews() {
		if todo != .View {
			let barSaveButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Save, target: self, action: #selector(CreateSceneViewController.onBarSaveButtonClicked(_:)))
			self.navigationItem.rightBarButtonItem = barSaveButton
			let barCancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: #selector(CreateSceneViewController.onBarCancelButtonClicked(_:)))
			self.navigationItem.leftBarButtonItem = barCancelButton
		}
		self.edgesForExtendedLayout = UIRectEdge.None
		let navBarHeight = self.navigationController!.navigationBar.frame.height + UIApplication.sharedApplication().statusBarFrame.height
		self.view.frame = CGRectMake(0, 0, self.view.frame.width, self.view.frame.height - navBarHeight)
		//顶部
		topContainer = UIView(frame: CGRectMake(0, 0, self.view.frame.width, self.view.frame.width*0.4))
		topContainer.backgroundColor = UIColor.whiteColor()
		topContainer.layer.shadowRadius = 8
		topContainer.layer.shadowOffset = CGSizeMake(0, 2)
		//背后
		backContainer = UIView(frame: CGRectMake(0, topContainer.frame.maxY-10, self.view.frame.width, 20))
		backContainer.backgroundColor = UIColor(R: 250, G: 250, B: 250, alpha: 1)
		backContainer.clipsToBounds = true
		
		//尾部
		tailContainer = UIView(frame: CGRectMake(0, topContainer.frame.maxY, self.view.frame.width, 100))
		tailContainer.backgroundColor = UIColor.whiteColor()
		
		//下半部分的阴影
		shadowView = UIView(frame: CGRectMake(0, tailContainer.frame.minY, self.view.frame.width, 4))
        shadowView.backgroundColor     = UIColor.whiteColor()
        shadowView.layer.shadowPath    = UIBezierPath(rect: shadowView.bounds).CGPath
        shadowView.layer.shadowOpacity = 0
        shadowView.layer.shadowRadius  = 8
        shadowView.layer.shadowOffset  = CGSizeMake(0, -2)
		
		//tableView垫底
		tableView = UITableView(frame: self.view.bounds, style: UITableViewStyle.Grouped)
		tableView.sectionFooterHeight = 0
        tableView.delegate            = self
        tableView.dataSource          = self
        tableView.scrollsToTop        = true
        tableView.contentInset.bottom = bottomActionBarHeight
        tableView.backgroundColor     = UIColor.tableBackgroundColor()
        tableView.separatorColor      = UIColor.tableSeparatorColor()
		
		self.view.addSubview(tableView)
		self.view.insertSubview(backContainer, aboveSubview: tableView)
		self.view.insertSubview(topContainer, aboveSubview: backContainer)
		self.view.insertSubview(tailContainer, aboveSubview: topContainer)
		self.view.insertSubview(shadowView, belowSubview: tailContainer)
		
		
		imageView = UIImageView(frame: CGRectMake(0, topContainer.frame.height/2 - self.view.frame.width/6, self.view.frame.width/3, self.view.frame.width/3))
		imageView.center.x = self.view.center.x
		currentImageName = iconNames[Int(newScene.icon-1)]
		imageView.image = UIImage(named: currentImageName)
		topContainer.addSubview(imageView)
		
		if todo != .View {
			changeImageButton = UIButton(frame: CGRectMake(0, 0, imageView.frame.width, imageView.frame.width/3))
			changeImageButton.center = CGPointMake(self.imageView.center.x, imageView.frame.maxY-changeImageButton.frame.height/2)
			changeImageButton.setTitle("更换图标", forState: .Normal)
			changeImageButton.backgroundColor = UIColor(red: 105/255.0, green: 181/255.0, blue: 1, alpha: 0.4)
			changeImageButton.addTarget(self, action: #selector(CreateSceneViewController.changeImage(_:)), forControlEvents: UIControlEvents.TouchUpInside)
			topContainer.addSubview(changeImageButton)
		}
		
		let layout = UICollectionViewFlowLayout()
		layout.itemSize = CGSizeMake(90, 90)
		layout.minimumLineSpacing = 5
		layout.minimumInteritemSpacing = 5
		layout.sectionInset = UIEdgeInsetsMake(15, 15, 105, 15)
		imageCollection = UICollectionView(frame: CGRectMake(0, 0, self.view.frame.width, imageCollectionViewHeight), collectionViewLayout: layout)
		imageCollection.registerNib(UINib(nibName: "SingleImageViewCell", bundle: nil), forCellWithReuseIdentifier: "imageCell")
		imageCollection.delegate   = self
		imageCollection.dataSource = self
		imageCollection.scrollsToTop = false
		imageCollection.contentInset.bottom = 0
		imageCollection.scrollIndicatorInsets.bottom = tailContainer.bounds.midY
		imageCollection.backgroundColor = UIColor.clearColor()
		backContainer.addSubview(imageCollection)
		
		
		let line1 = UIView(frame: CGRectMake(self.view.frame.width*0.05, 5, self.view.frame.width*0.9, 0.5))
		line1.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
		
		nameTextField = UITextField(frame: CGRectMake(line1.frame.minX, line1.frame.maxY+5, line1.frame.width, 40))
		nameTextField.text = newScene.name
		nameTextField.textAlignment = .Center
		nameTextField.placeholder = "输入情景名称"
		nameTextField.clearButtonMode = .WhileEditing
		nameTextField.returnKeyType = UIReturnKeyType.Done
		nameTextField.font = UIFont.systemFontOfSize(20)
		nameTextField.addTarget(self, action: #selector(CreateSceneViewController.editDone(_:)), forControlEvents: UIControlEvents.EditingDidEndOnExit)
		nameTextField.addTarget(self, action: #selector(CreateSceneViewController.editingName(_:)), forControlEvents: UIControlEvents.EditingChanged)
		nameTextField.addTarget(self, action: #selector(CreateSceneViewController.editBegin(_:)), forControlEvents: UIControlEvents.EditingDidBegin)
		if todo == .View {
			nameTextField.enabled = false
		}
		
		let line2 = UIView(frame: CGRectMake(line1.frame.minX, nameTextField.frame.maxY+5, line1.frame.width, line1.frame.height))
		line2.backgroundColor = line1.backgroundColor
		
		scrollTitleView = ScrollTitleView(frame: CGRectMake(0, line2.frame.maxY, view.bounds.width, scrollTitleHeight))
		scrollTitleView.titles = deviceTypes.map{$0.description}
		scrollTitleView.tintColor = APP.param.themeColor
		scrollTitleView.setHandler(scrollTitleDidSelectedItem)
		tailContainer.frame = CGRectMake(tailContainer.frame.minX, tailContainer.frame.minY, tailContainer.frame.width, scrollTitleView.frame.maxY)
        tableView.contentInset.top          = tailContainer.frame.maxY
        tableView.scrollIndicatorInsets.top = tailContainer.frame.maxY
		
		tailContainer.addSubview(line1)
		tailContainer.addSubview(nameTextField)
		tailContainer.addSubview(line2)
		tailContainer.addSubview(scrollTitleView)
		
		//bottomToolbar
		if todo != .View {
			bottomContainerToolbar = UIToolbar(frame: CGRectMake(0, view.bounds.height - bottomActionBarHeight, view.bounds.width, bottomActionBarHeight))
			actionBarView = BottomActionBar(frame: bottomContainerToolbar!.bounds)
			actionBarView?.tintColor = APP.param.themeColor
			actionBarView?.addButton.addTarget(self, action: #selector(CreateSceneViewController.tapBottomAddButton), forControlEvents: .TouchUpInside)
			actionBarView?.editButton.addTarget(self, action: #selector(CreateSceneViewController.tapBottomEditButton), forControlEvents: .TouchUpInside)
			actionBarView?.doneButton.addTarget(self, action: #selector(CreateSceneViewController.tapBottomDoneButton), forControlEvents: .TouchUpInside)
			bottomContainerToolbar!.addSubview(actionBarView!)
			self.view.addSubview(bottomContainerToolbar!)
			
			if tailContainer.frame.maxY > view.frame.height * 0.7 {
				//topFrontView超过屏幕的70%，隐藏bottomContainerToolbar
				bottomContainerToolbar!.center.y = self.view.bounds.height + bottomContainerToolbar!.frame.height*0.6
			} else {
				tableView.scrollIndicatorInsets.bottom = actionBarView!.bounds.height
			}
		}
	}
	
	//MARK: - UI事件
	
	func onBarSaveButtonClicked(sender : AnyObject) {
		if nameTextField.text == nil || nameTextField.text!.isEmpty {
			UIAlertView(title: "提示", message: "情景名不能为空!", delegate: nil, cancelButtonTitle: "确定").show()
			return
		}
		if !nameTextField.text!.isDeviceName {
			UIAlertView(title: "提示", message: "情景名不能有除了字母、数字、中文和空格外的其他字符", delegate: nil, cancelButtonTitle: "确定").show()
			return
		}
		newScene.devices = [HRDevInScene]()
		for (_, devs) in self.deviceDatas {
			newScene.devices += devs
		}
		if newScene.devices.count == 0 {
			UIAlertView(title: "提示", message: "情景中至少包含一个设备", delegate: nil, cancelButtonTitle: "确定").show()
			return
		}
		newScene.devCount = Byte(newScene.devices.count)

		for i in 1...iconNames.count {
			if iconNames[i-1] == currentImageName {
				newScene.icon = Byte(i)
				break
			}
		}
		newScene.name = nameTextField.text!
		KVNProgress.showWithStatus("正在保存...")
		HR8000Service.shareInstance().createOrModifyScene(newScene, isCreate: todo == .Create, result: {	(error) in
			if let err = error {
				KVNProgress.showErrorWithStatus("添加失败：\(err.domain)(\(err.code))")
			} else {
				KVNProgress.showSuccessWithStatus("添加情景成功")
				runOnMainQueueDelay(500, block: {
					self.navigationController?.popViewControllerAnimated(true)
				})
			}
		})
	}
	
	func onBarCancelButtonClicked(sender: AnyObject) {
		self.navigationController?.popViewControllerAnimated(true)
	}
	
	//MARK: --点击bottom action toolbar
	@objc private func tapBottomAddButton() {
		PickDeviceViewController.show(self, delegate: self)
	}
	
	@objc private func tapBottomEditButton() {
		self.tableView.setEditing(true, animated: true)
	}
	
	@objc private func tapBottomDoneButton() {
		self.tableView.setEditing(false, animated: true)
		//延迟500ms刷新tableView
		runOnMainQueueDelay(500, block: {
			self.tableView.reloadData()
		})
	}
	
	//MARK: --nameTextField
	func editBegin(textField: UITextField) {
		closeImageCollectionView()
	}
	
	func editDone(textField: UITextField ) {
		textField.resignFirstResponder()
	}
	
	func editingName(textField: UITextField) {
		if self.didUserSeletedImage || sceneDevice != nil { return }
		let sentence = textField.text
		
		runOnGlobalQueue({
			let dic = [
				["回家", "下班", "回来", "hui"]	: "ico_scene_athome",
				["离", "出走", "上班", "出门", "li"] : "ico_scene_leavehome",
				["起床", "开灯", "阳光", "早", "morning"] : "ico_scene_gettingup",
				["阅读", "书", "看报", "read"]: "ico_scene_reading",
				["睡", "晚安", "晚上", "眠", "shui", "sleep"]: "ico_scene_sleeping",
				["吃", "饭", "餐", "食", "chi", "eat"]: "ico_scene_repast",
				["娱乐", "音乐", "派对", "party"]: "ico_scene_media",
				["唱", "歌", "ktv", "k歌", "麦", "chang", "sing"]: "ico_scene_recreation",
				["开会", "会议", "聊", "讨论", "辩论", "talk"]: "ico_scene_receive",
				["运动", "锻炼", "跑", "瑜伽", "yun", "sport"]: "ico_scene_sports",
				["放松", "茶", "午", "休", "wu", "cha", "nap"]: "ico_scene_relaxation",
				["生日", "蛋糕", "sheng"]: "ico_scene_birthday"
			]
			
			func getImageNameFromWord(text: String) -> String? {
				for (words, img) in dic {
					for word in words as! Array<String> {
						if text.rangeOfString(word, options: NSStringCompareOptions.CaseInsensitiveSearch) != nil {
							return img
						}
					}
				}
				return nil
			}
			
			if let imgName = getImageNameFromWord(sentence!) {
				if self.currentImageName == imgName {
					return
				}
				self.currentImageName = imgName
				runOnMainQueueDelay(0, block: {
					self.setImageWithAnimation(self.currentImageName)
				})
			}
		})
	}
	
	func changeImage(button: UIButton) {
		self.isImageCollectionExpand = true
		editDone(nameTextField)
		let gesture = UIPanGestureRecognizer(target: self, action: #selector(CreateSceneViewController.touchMoveTail(_:)))
		tailContainer.addGestureRecognizer(gesture)
		self.topContainer.layer.shadowOpacity = 0.8
		UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.95, initialSpringVelocity: 0, options: .CurveLinear, animations: {
			button.alpha = 0
			self.shadowView.layer.shadowOpacity = 0.8
            self.tailContainer.center.y    = self.tailContainer.center.y + self.imageCollectionViewHeight - self.tailContainer.bounds.midY
            self.shadowView.center.y       = self.tailContainer.frame.minY + self.shadowView.bounds.midY
            self.tableView.contentOffset.y = -self.tailContainer.frame.maxY
            self.backContainer.frame       = CGRectMake(0, self.backContainer.frame.minY, self.backContainer.bounds.width, self.imageCollectionViewHeight)
			}) { (completed) -> Void in
		}
	}
	
	func touchMoveTail(gesture: UIPanGestureRecognizer){
		switch gesture.state {
		case .Changed:	//如果展开了imageCollection
			let point = gesture.translationInView(tailContainer)
			if tailContainer.frame.minY > topContainer.frame.maxY {
				if tailContainer.frame.minY+point.y > backContainer.frame.minY + imageCollectionViewHeight - tailContainer.bounds.midY && point.y > 0 {
					//弹簧效果
					let k:CGFloat = 60000
					let f = tailContainer.frame.minY+point.y - backContainer.frame.maxY-tailContainer.bounds.midY
					let deltaY = (f * f) / k
					tailContainer.center.y += deltaY
				} else {
					tailContainer.center.y += point.y
				}
                self.shadowView.center.y       = self.tailContainer.frame.minY + self.shadowView.bounds.midY
                self.tableView.contentOffset.y = -self.tailContainer.frame.maxY
                self.backContainer.frame       = CGRectMake(0, backContainer.frame.minY, backContainer.bounds.width, tailContainer.center.y - backContainer.frame.minY)
				gesture.setTranslation(CGPoint.zero, inView: tailContainer)
			}
		case .Ended:
			let velocity = gesture.velocityInView(tailContainer)
			if tailContainer.frame.minY > backContainer.frame.maxY - tailContainer.bounds.midY || velocity.y > 0{
				Log.verbose("\(velocity.y)")
				//展开
				UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.95, initialSpringVelocity: velocity.y/1000, options: .CurveLinear, animations: {
                    self.tailContainer.center.y    = self.topContainer.frame.maxY + self.imageCollectionViewHeight
                    self.shadowView.center.y       = self.tailContainer.frame.minY + self.shadowView.bounds.midY
                    self.tableView.contentOffset.y = -self.tailContainer.frame.maxY
                    self.backContainer.frame       = CGRectMake(0, self.backContainer.frame.minY, self.backContainer.bounds.width, self.imageCollectionViewHeight)
					}, completion: nil)
			} else {
				//收缩
				closeImageCollectionView()
			}
		default: break
		}
	}
	
	private func closeImageCollectionView(){
		self.isImageCollectionExpand = false
		if tailContainer.frame.minY == topContainer.frame.maxY { return }
		UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.95, initialSpringVelocity: 0, options: .CurveLinear, animations: {
			self.changeImageButton.alpha = 1
			self.shadowView.layer.shadowOpacity = 0
			self.tailContainer.frame = CGRectMake(0, self.topContainer.frame.maxY, self.view.frame.width, self.tailContainer.frame.height)
			self.shadowView.center.y = self.tailContainer.frame.minY + self.shadowView.bounds.midY
			self.backContainer.frame = CGRectMake(0, self.backContainer.frame.minY, self.backContainer.bounds.width, 1)
			self.tableView.contentOffset.y = -self.tailContainer.frame.maxY
			}, completion: {
				(complete) in
                self.topContainer.layer.shadowOpacity = 0
				if let gestures = self.tailContainer.gestureRecognizers {
					for gesture in gestures {
						self.tailContainer.removeGestureRecognizer(gesture )
					}
				}
		})
	}
	
	private func setImageWithAnimation(name: String, duration: NSTimeInterval = 1) {
		
		UIView.transitionWithView(imageView, duration: duration, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
			self.imageView.image = UIImage(named: name)
			}, completion: nil)
	}
	
	private func setImageWithAnimation(id: Byte, duration: NSTimeInterval = 1) {
		setImageWithAnimation(iconNames[Int(id)], duration: duration)
	}
	
	lazy var scrollTitleDidSelectedItem: (Int, String)->Void = {
		[unowned self] (index, title) in
		var height: CGFloat = 0
		for section in 0..<index {
			let rows = self.tableView.numberOfRowsInSection(section)
			height += self.tableViewRowHeight * CGFloat(rows)
			height += self.tableViewSectionHeaderHeight
		}
		self.sectionFrameMaxYs.removeAll()
		self.tableView.setContentOffset(CGPointMake(0, -self.scrollTitleHeight + height), animated: true)
	}
	
	//MARK: - UIScrollViewDelegate
	
	func scrollViewWillBeginDragging(scrollView: UIScrollView) {
		sectionFrameMaxYs = [CGFloat]()
		sectionFrameMaxYs.append(0)
		for section in 0..<tableView.numberOfSections {
			let rows = tableView.numberOfRowsInSection(section)
			sectionFrameMaxYs.append(sectionFrameMaxYs[section] + tableViewRowHeight * CGFloat(rows) + tableViewSectionHeaderHeight)
		}
	}
	
	func scrollViewDidScroll(scrollView: UIScrollView) {
		//如果图标选择的CollectionView打开，则返回
		if isImageCollectionExpand { return }
		
//		let topFiledHeight = tailContainer.bounds.height + topContainer.bounds.height
		//移动topContainer、backContainer、tailContainer
		if (tailContainer.frame.maxY > scrollTitleHeight || scrollView.contentOffset.y < -scrollTitleHeight)
//			&&
//			(-scrollView.contentOffset.y - topFiledHeight > scrollTitleHeight - topContainer.frame.height)
		{
				let offsetY = -scrollView.contentOffset.y - tailContainer.frame.maxY
				
				//移动
            tailContainer.frame = CGRectOffset(tailContainer.frame, 0, offsetY)
            backContainer.frame = CGRectOffset(backContainer.frame, 0, offsetY)
            topContainer.frame  = CGRectOffset(topContainer.frame, 0, offsetY)
            shadowView.center.y = self.tailContainer.frame.minY + self.shadowView.bounds.midY
				//改变滚动条
				tableView.scrollIndicatorInsets.top = tailContainer.frame.maxY
		} else if tailContainer.frame.maxY != scrollTitleHeight {
			tailContainer.frame = CGRect(
				x: 0,
				y: scrollTitleHeight - tailContainer.frame.height,
				width: tailContainer.frame.width,
				height: tailContainer.frame.height
			)
			//移动
			topContainer.frame = CGRect(
				x: 0,
				y: tailContainer.frame.minY - topContainer.bounds.height,
				width: topContainer.bounds.width,
				height: topContainer.bounds.height
			)
			backContainer.frame = CGRect(
				x: 0,
				y: topContainer.frame.maxY,
				width: backContainer.bounds.width,
				height: backContainer.bounds.height
			)
			shadowView.center.y = self.tailContainer.frame.minY + self.shadowView.bounds.midY
		}
		
		//根据tableView的移动设置scrollTitles中游标的位置
		if sectionFrameMaxYs.count > 0 {
			for i in 1..<sectionFrameMaxYs.count {
				if tableView.contentOffset.y + scrollTitleHeight
					> sectionFrameMaxYs[i] {
						continue
				} else {
					if scrollTitleView.currentPos != i-1 {
						scrollTitleView.setSelectedItem(i-1, animated: true)
					}
					break
				}
			}
		}
		
		//显示Add Device Button
		if let bottomContainerToolbar = self.bottomContainerToolbar {
			let delta = view.bounds.height * 0.7 - tailContainer.frame.maxY
			if delta > 0 && bottomContainerToolbar.frame.minY >= view.bounds.height {
				//topFrontView位置往上低于70%, 且toobar已经隐藏, 则显示toolbar
				UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.95, initialSpringVelocity: 0, options: .CurveLinear, animations: {
					bottomContainerToolbar.center.y = self.view.bounds.height - bottomContainerToolbar.frame.height/2
					}, completion: nil)
			} else if  delta <= 0 && bottomContainerToolbar.frame.minY < view.bounds.height {
				//topFrontView位置往下超过70%, 且toobar已经显示, 则隐藏toolbar
				UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.95, initialSpringVelocity: 0, options: .CurveLinear, animations: {
					bottomContainerToolbar.center.y = self.view.bounds.height + bottomContainerToolbar.frame.height * 0.55
					}, completion: nil)
			}
		}
	}
	
	//MARK: - 选择图标的CollectionView
	
	func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
		return 1
	}
	
	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return iconNames.count
	}
	
	func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier("imageCell", forIndexPath: indexPath) as! SingleImageViewCell
		cell.backgroundColor = UIColor.clearColor()
		cell.image = UIImage(named: iconNames[indexPath.row])
		return cell
	}
	
	func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
		currentImageName = iconNames[indexPath.row]
		setImageWithAnimation(iconNames[indexPath.row], duration: 0.3)
		imageView.tag = indexPath.row
		
		closeImageCollectionView()
		didUserSeletedImage = true
	}
	
	//MARK: - UITableViewDataSource and delegate.
	
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return deviceTypes.count
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let type = deviceTypes[section]
		return deviceDatas[type]?.count ?? 0
	}
	
	func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return tableViewRowHeight
	}
	
	func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return tableViewSectionHeaderHeight
	}
	
	func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		let type = deviceTypes[section]
		let count = deviceDatas[type]?.count ?? 0
		return count == 0 ? "":"\(type.description): \(count)"
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		var cell:SceneBindCell!  = tableView.dequeueReusableCellWithIdentifier("section\(indexPath.section)_cell") as? SceneBindCell
		let devInScene = getDevInScene(indexPath)!
		
		if cell == nil {
			cell = SceneBindCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "section\(indexPath.section)_cell", devInTask: devInScene)
		} else {
			cell.sceneBind = devInScene
		}
		cell.enabled = todo != .View
		return cell
	}
	
	func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
		return todo != .View ? .Delete:.None
	}
	
	func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
		let type = deviceTypes[indexPath.section]
		deviceDatas[type]?.removeAtIndex(indexPath.row)
		let cell = tableView.cellForRowAtIndexPath(indexPath) as? SceneBindCell
		cell?.free()
		tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Top)
		runOnMainQueueDelay(500, block: {
			self.tableView.reloadData()
		})
	}
	
	private func getDevInScene(indexPath: NSIndexPath) -> HRDevsInTask? {
		let type = deviceTypes[indexPath.section]
		return deviceDatas[type]?[indexPath.row]
	}
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		if todo == .View {
			tableView.deselectRowAtIndexPath(indexPath, animated: true)
			return
		}
		let dev   = getDevInScene(indexPath)!
		let title = dev.device!.name
		let delay = Float(dev.delayCode[0])/10
		TimePickerActionView(title: title, initSecond: delay, delegate: self).show()
	}
	
	
	//MARK: - delegates 
	
	func timePickerActionView(dismissWithoutTime picker: TimePickerActionView) {
		guard let indexPath = tableView.indexPathForSelectedRow else { return }
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
	}
	
	func timePickerActionView(picker: TimePickerActionView, dismissWithTimeInSecond second: Float) {
		guard let indexPath = tableView.indexPathForSelectedRow else { return }
		let devsInTask = getDevInScene(indexPath)!
		if let relay = devsInTask.device as? HRRelayInBox
			where Int(relay.relaySeq) < devsInTask.delayCode.count {
				devsInTask.delayCode = [
					Byte(second * 10),
					Byte(second * 10),
					Byte(second * 10),
					Byte(second * 10)
				]
		} else {
			devsInTask.delayCode[0] = second <= 25.5 ? Byte(second * 10):0
		}
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
		tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
	}
	
	func pickDeviceVC(shouldShowDeviceTypes vc: PickDeviceViewController) -> [PickDeviceType] {
		return deviceTypes
	}
	
	func pickDeviceVC(vc: PickDeviceViewController, type: PickDeviceType, devices: [HRDevInScene]) {
		self.deviceDatas[type]? += devices
		self.tableView.reloadData()
	}
}

