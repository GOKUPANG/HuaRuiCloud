//
//  HomeViewController.swift
//  huarui
//
//  Created by sswukang on 15/1/14.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import UIKit
import Alamofire


/// 登陆之后的主界面
class HomeViewController: UIViewController, VoiceResultDelegate, HR8000HelperDelegate, UIAlertViewDelegate ,UITableViewDelegate , UITableViewDataSource {
//MARK: - 属性
	var buttons: HomeButtonsView!
	var voiceButton: VoiceButtonView!
    var ADImageView: UIImageView!
    var myTableView: UITableView!
    

    lazy private var registerCount = 0
//MARK: - 方法
	
	deinit { 
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}
	
	override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
		return UIInterfaceOrientationMask.Portrait
	}
	
	override func shouldAutorotate() -> Bool {
		return false
	}
	
    override func viewDidLoad() {
		super.viewDidLoad()
		
        
        self.getHttpImageData()
        
        self.edgesForExtendedLayout = UIRectEdge.None
        navigationController?.navigationBar.hidden = false
        navigationController?.navigationBar.barTintColor = APP.param.themeColor
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HomeViewController.didSocketDisconnected(_:)), name: kNotificationDidSocketDisconnected, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HomeViewController.didSocketConnected(_:)), name: kNotificationDidSocketConnected, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HomeViewController.userDidLogined(_:)), name: kNotificationUserDidLogined, object: nil)
		///navigationBar height
		let navBarHeight = self.navigationController!.navigationBar.bounds.height + UIApplication.sharedApplication().statusBarFrame.height
		
		//将View的高度减小一个导航栏高度
		self.view.frame = CGRectMake(view.frame.minX, view.frame.minY, view.frame.width, view.frame.height - navBarHeight)
		
        //设置标题栏中间的图标
        let bar = navigationController?.navigationBar
        if bar != nil {
			let titleView = UIImageView(frame: CGRectMake(0, 0, 40, 40))
			titleView.image = UIImage(named: "logo-无背景")
			titleView.contentMode = .ScaleAspectFit
			self.navigationItem.titleView = titleView
		}
		navigationItem.leftBarButtonItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
		
        
        //广告栏
        let viewW = self.view.frame.width
        let viewH = self.view.frame.width / 2.5
        let adView = ADScrollView(frame: CGRectMake(0, 0, viewW, viewH))
        adView.images = ["ad_image_1","ad_image_2"]
        
      //  adView.images = ["ad_image_1"]

        adView.changeImageTime = 4.0
        
        
        
       
        ADImageView = UIImageView(frame: CGRectMake(0, 0, viewW, viewH))
        self.view.addSubview(ADImageView)
        
        
        self.ADImageView.image = UIImage(named: "华睿云")

        
        
        
          //view.addSubview(adView)
         //oc 的写法
         //[self.view addSubview:adView];

        
		
		var tmpRate:CGFloat = 0.9
		var buttonsWidth = view.bounds.width * tmpRate
        
     //   print("水水水水\(cellHeight)")
		var voiceBtnHeight = buttonsWidth * 0.35
		while buttonsWidth + voiceBtnHeight + adView.frame.maxY + 10 > view.bounds.height {
			tmpRate -= 0.05
			buttonsWidth = view.bounds.width * tmpRate
			voiceBtnHeight = buttonsWidth * 0.35
		}
        let cellHeight = buttonsWidth * 0.25 - 0.25
        
        print("水水水水\(cellHeight)")


        
//        myTableView = UITableView(frame: CGRectMake(0, adView.frame.maxY + 10,self.view.bounds.width, buttonsWidth, style:))
        
        myTableView = UITableView.init(frame: CGRectMake(0, adView.frame.maxY, self.view.frame.size.width , buttonsWidth))
        
        myTableView.delegate = self
        
        myTableView.dataSource = self
        
        myTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "reuse")
        
        myTableView.rowHeight = cellHeight
        
        myTableView.scrollEnabled = false //设置tableview 不能滚动
        
        myTableView.tableFooterView = UIView.init()
        
        myTableView.backgroundColor = UIColor.clearColor()
        
        
        
        
       view.addSubview(myTableView)
		
		buttons = HomeButtonsView(frame: CGRectMake(0, adView.frame.maxY + 10, buttonsWidth, buttonsWidth))
		buttons.center.x = self.view.center.x
		//self.view.addSubview(buttons)
		buttons.homeManagerButton.addTarget(self, action: #selector(HomeViewController.onButtonClicked(_:)), forControlEvents: .TouchUpInside)
		buttons.viewCtrlButton.addTarget(self, action: #selector(HomeViewController.onButtonClicked(_:)), forControlEvents: .TouchUpInside)
		buttons.sceneManagerButton.addTarget(self, action: #selector(HomeViewController.onButtonClicked(_:)), forControlEvents: .TouchUpInside)
		buttons.settingsButton.addTarget(self, action: #selector(HomeViewController.onButtonClicked(_:)), forControlEvents: .TouchUpInside)
		
		
		voiceButton = VoiceButtonView(frame: CGRectMake(view.bounds.midX-50, buttons.frame.maxY, voiceBtnHeight, voiceBtnHeight))
		voiceButton.center.x = view.bounds.midX
		self.view.addSubview(voiceButton)
		view.tintColor = UIColor(R: 48, G: 188, B: 237, alpha: 0.5)
		voiceButton.voiceButton.addTarget(self, action: #selector(HomeViewController.onButtonClicked(_:)), forControlEvents: .TouchUpInside)
		
//		buttons.homeManagerButton.tag = 101
//		buttons.viewCtrlButton.tag = 102
//		buttons.sceneManagerButton.tag = 103
//		buttons.settingsButton.tag = 104
		voiceButton.voiceButton.tag = 105
		
        //背景图片 
        self.view.layer.contents = UIImage(named:"图层-0")?.CGImage
        
        
    //self.view.backgroundColor = UIColor.whiteColor()
        
		
		//注销按钮
		let  logoutButton = UIBarButtonItem(title: "注销", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(HomeViewController.tapLogoutButton(_:)))
		logoutButton.setTitleTextAttributes([NSForegroundColorAttributeName: APP.param.selectedColor], forState: UIControlState.Normal)
		self.navigationItem.rightBarButtonItem = logoutButton
		
		
        //Slide Menu: 设置左边菜单栏的第0行被选
//        let leftVC = SlideNavigationController.sharedInstance().leftMenu as! LeftMenuViewController
//        leftVC.tableView.selectRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), animated: true, scrollPosition: UITableViewScrollPosition.Top)
    }
    
    
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        
        
        return 4
        
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        
        /// 定义一个cell
        let str:String = "reuse"
        var cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier(str, forIndexPath: indexPath) 
        if cell.isEqual(nil){
            
            cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: str)
        }
        /**
         cell赋值
         */
        
        switch indexPath.row {
        case 0:
            
            
             cell.imageView?.image = UIImage.init(named: "家居控制")
             
             
             cell.textLabel?.text = "家居控制"
            
            
            break
            
        case 1 :
            
            
            cell.imageView?.image = UIImage.init(named: "可见可控")
            
            
            cell.textLabel?.text = "可见可控"

            
            break
            
        case 2 :
            
            
            cell.imageView?.image = UIImage.init(named: "情景管理")
            
            
            cell.textLabel?.text = "情景管理"

            
            break
            
        case 3 :
            cell.imageView?.image = UIImage.init(named: "系统设置")
            
            
            cell.textLabel?.text = "系统设置"

            
            break
            
            
            
        default:
            
            break
        }
        
        
        cell . backgroundColor = UIColor.clearColor()
        
       
        return cell
        
        
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath){
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        
        switch indexPath.row {
        case 0:   //家居管理
            self.performSegueWithIdentifier("showCommonViewController", sender: nil)
        case 1:   //可视对讲
            self.loginTo2cu()
        case 2:   //情景管理
            self.performSegueWithIdentifier("showSceneManager", sender: nil)
        //            self.performSegueWithIdentifier("showSceneViewController", sender: nil)
        case 3:	//系统设置
            self.performSegueWithIdentifier("showSettingViewController", sender: nil)
            
              default: break
        }
        
    }
    
    
	override func viewWillAppear(animated: Bool) {
		navigationController?.navigationBar.translucent = false
        HRProcessCenter.shareInstance().delegates.hr8000HelperDelegate = self
        VoiceUtils.shareInstance().delegate = self
		//如果没有设置RF参数
		if !HRDatabase.shareInstance().acount.haveSetRFParameter {
			let vc = UINavigationController(rootViewController: SetRFParameterViewController())
			self.presentViewController(vc, animated: true, completion: nil)
		}
    }
	
	override func viewDidAppear(animated: Bool) {
		self.voiceButton.startAnimation()
	}
	//与socket失去连接，视图标题显示未连接 斌注释
	@objc private func didSocketDisconnected(notification: NSNotification) {
        
       // print("socket未连接")
		Log.verbose("didSocketDisconnected")
		runOnMainQueue({
			let label = UILabel(frame: CGRectMake(0, 0, 100, 40))
			label.text = "(未连接)"
			label.textColor = .whiteColor()
			label.textAlignment = .Center
			self.navigationItem.titleView = label
		})
	}
	
	@objc private func didSocketConnected(notification: NSNotification) {
		Log.verbose("didSocketConnected")
        
      //  print("socket已经连接")
		
	}
	
	@objc private func userDidLogined(notification: NSNotification) {
		Log.verbose("userDidLogined")
		runOnMainQueue({
			let titleView = UIImageView(frame: CGRectMake(0, 0, 40, 40))
			titleView.image = UIImage(named: "logo-无背景")
			titleView.contentMode = .ScaleAspectFit
			titleView.alpha = 0
			self.navigationItem.titleView = titleView
		}) 
	}
	
	@objc private func tapLogoutButton(button: UIButton) {
		UIAlertView(title: "您确定要注销吗？", message: "", delegate: self, cancelButtonTitle: "取消", otherButtonTitles: "注销").show()
        
	}
    
	func alertView(alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
		if buttonIndex != alertView.cancelButtonIndex {
			navigationController?.popViewControllerAnimated(true)
			HR8000Service.shareInstance().logout()
//			AppDelegateYoosee.sharedDefault().mainController = nil
		}
	}
    
    //在这里点击四个按钮:家居管理 可见可控 情景管理 系统设置 进入相应的四个主界面 斌注释
	
    @objc private func onButtonClicked(button: UIButton) {
        switch button.tag {
        case 101:   //家居管理
            self.performSegueWithIdentifier("showCommonViewController", sender: nil)
        case 102:   //可视对讲
            self.loginTo2cu()
        case 103:   //情景管理
            self.performSegueWithIdentifier("showSceneManager", sender: nil)
//            self.performSegueWithIdentifier("showSceneViewController", sender: nil)
		case 104:	//系统设置
			self.performSegueWithIdentifier("showSettingViewController", sender: nil)
		case 105:   //语音助手
			VoiceUtils.shareInstance().startGramListening()
        default: break
        }
    }
    
    
    //MARK: -  获取图片数据
 
    
    func getHttpImageData() {
        
        
        
        Alamofire.request(.GET,"http://www.gzhuarui.cn/?q=huaruiapi/picture_advertising&pic_type=huaruicloud_main" ).responseJSON { response in
            
            
//            print(response.request)  // original URL request
//            print(response.response) // URL response
//            print(response.data)     // server data
            print(response.result)
            
           switch response.result
           {
           case.Success:
            
            
            if let JSON = response.result.value  as? NSArray{
                
                
                let dict = JSON[0]
                
                let item = dict.valueForKey("pic_url") as!String
                //let imageView = UIImageView.init()
                
                
                //广告栏
//                let viewW = self.view.frame.width
//                let viewH = self.view.frame.width / 2.5
//                let adView = UIImageView(frame: CGRectMake(0, 0, viewW, viewH))
//                self.view.addSubview(adView)
                //oc 的写法
                //[self.view addSubview:adView];
                
                self.ADImageView.setImageWithURL(NSURL.init(string: item))
                
                
                print("JSON: \(item)")
            }

            
           case .Failure(let error):
            print(error)
            
            
//            let viewW = self.view.frame.width
//            let viewH = self.view.frame.width / 2.5
//            let adView = UIImageView(frame: CGRectMake(0, 0, viewW, viewH))
//            self.view.addSubview(adView)
            
            self.ADImageView.image = UIImage(named: "华睿云")
            
            }
            
//        Alamofire.request("https://api.500px.com/v1/photos", method: .get).responseJSON {
//            response in
//            guard let JSON = response.result.value else { return }
//            print("JSON: \(JSON)")
//        }
//        
        }
        
       
    
    }
    
    
// MARK: - HR8000HelperDelegate 代理
    func hr8000Helper(finishedQueryDeviceInfo finish: Bool) {
		initVoiceModule()
    }
 
	// MARK: - 语音
	/**初始化语音模块*/
	private func initVoiceModule(){
		runOnGlobalQueue({
			
			var namesDic = Dictionary<String, Array<String>>()
			
			//设备列表
			var devices  = Array<String>()
			for relay in HRDatabase.shareInstance().getAllRelays() {
				devices.append(relay.elecName)
			}
			namesDic["device"] = devices
			
			//窗帘、电机列表
			var motors = Array<String>()
			for motor in HRDatabase.shareInstance().getAllMotorDev() {
				motors.append(motor.name)
			}
			namesDic["curtain"] = motors
			
			//情景列表
			var sceneNames = Array<String>()
			if let scenes = HRDatabase.shareInstance().getDevicesOfType(.Scene) as? [HRScene] {
				for scene in scenes {
					sceneNames.append(scene.name)
				}
			}
			namesDic["scene"] = sceneNames
			
			//房间列表和楼层列表
            var roomNames  = Array<String>()
            var floorNames = Array<String>()
			let floorRoomNames = HRDatabase.shareInstance().roomNames
			for (floor, room) in floorRoomNames {
				floorNames.append(floor)
				roomNames += room
			}
			
			namesDic["floor"] = floorNames
			namesDic["room"]  = roomNames
			
			VoiceUtils.shareInstance().namesDic = namesDic
			VoiceUtils.shareInstance().delegate = self
		})
	}
//MARK: - 语音结果回调
	
    //语音功能回调
    func voiceResult(onRelayResult floor: String?, room: String?, device: String?, action: String?, score: Int) {
        if device != nil && action != nil {
            for relay in HRDatabase.shareInstance().getAllRelays() {
                if relay.elecName == device {
                    var str = "正在打开\(device!)"
                    var operate = HRRelayOperateType.Open
                    if action! == "关" {
                        str = "正在关闭\(device!)"
                        operate = .Close
                    }
                    KVNProgress.showWithStatus(str)
                    relay.operate(operate,
                        result: { (error) in
                            if let err = error {
                                KVNProgress.showErrorWithStatus("失败：\(err.domain)")
                            } else {
                                KVNProgress.dismiss()
                            }
                    })
                }
            }

        }
    }
    
    //电机类型
    func voiceResult(onMotorResult floor: String?, room: String?, device: String?, action: String?, score: Int) {
        if device != nil && action != nil {
            for motor in HRDatabase.shareInstance().getAllMotorDev() {
                if motor.name == device {
                    var str = "正在打开\(device!)"
                    var operate = HRMotorOperateType.Open
                    if action == "关"{
                        str = "正在关闭\(device!)"
                        operate = .Close
                    }
                    else if action == "停" {
                        str = "正在停止\(device!)"
                        operate = .Stop
                    }
                    
                    KVNProgress.showWithStatus(str)
                    HR8000Service.shareInstance().operateCurtain(actionType: operate, motor: motor, callback: {
                        (error ) in
						if let err = error {
							KVNProgress.showErrorWithStatus(err.domain)
						} else {
							KVNProgress.dismiss()
                        }
                    })
                }
            }
        }
    }
    
    func voiceResult(onSceneResult scene: String?, score: Int) {
        if let scene = scene {
			if let sceneObjs = HRDatabase.shareInstance().getDevicesOfType(.Scene) as? [HRScene] {
				for sceneObj in sceneObjs where sceneObj.name == scene {
					KVNProgress.showWithStatus("正在启动\(scene)...")
					sceneObj.start({
						(error) in
						if let err = error {
							KVNProgress.showErrorWithStatus(err.domain)
						} else {
							KVNProgress.dismiss()
						}
					})
					return
				}
			}
        }
    }
    
    func voiceResult(onError errMsg: String, errCode: Int32) {
        Log.error("语音出错：\(errMsg)(\(errCode))")
	}
	
	private func loginTo2cu(){
		let (isReg, userName, passwd) = Connect2CUHelper.checkRegistration()
		Log.debug("user: \(userName)")
		if !isReg { //如果没有账号，则注册一个
			Log.debug("没有2cu账号，正在注册...")
			if self.registerCount == 0 {
				KVNProgress.showWithStatus("第一次使用，请稍后...")
			}
			Connect2CUHelper.register2cuAcount({ (error) in
				if error == nil { //注册成功
					KVNProgress.dismiss()
					self.loginTo2cu()
				}
				else{
					Log.error("注册2cu账号失败：\(error!.domain)(\(error!.code))")
					self.registerCount += 1
					if self.registerCount == 3{ //注册3次都失败，提示用户注册不了，稍后重试
						KVNProgress.showErrorWithStatus("注册账号失败(\(error!.code),请稍后重试)")
					} else {
						//再次登录
						self.loginTo2cu()
					}
				}
			})
			return
		}
//		KVNProgress.showWithStatus("正在载入...")
//		Log.info("登陆2cu：账号=\(username)")
//		Login2CU.login(username, password: passwd, callBack: {
//			(error) in
//			if error == nil {   //登陆成功
//				KVNProgress.dismiss()
//				runOnMainQueue({
//					AppDelegate2cu.sharedDefault().mainController = MainController()
//					self.presentViewController(AppDelegate2cu.sharedDefault().mainController, animated: true, completion: nil)
//				})
//				return
//			}
//			Log.warn("登陆失败：\(error!.domain)(\(error!.code))")
//			KVNProgress.showErrorWithStatus("暂时无法进入\(error!.code)")
//		})
		
		Login2CU.login(userName, password: passwd) { (error) -> Void in
			if let err = error {
				Log.debug("Login to Yoosee server: \(err.domain)")
			}
			if AppDelegateYoosee.sharedDefault().mainController == nil {
				AppDelegateYoosee.sharedDefault().mainController = MainController()
			}
			self.presentViewController(AppDelegateYoosee.sharedDefault().mainController, animated: true, completion: nil)
		}
	}

}
