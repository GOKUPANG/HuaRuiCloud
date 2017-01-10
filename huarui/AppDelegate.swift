//
//  AppDelegate.swift
//  huarui
//
//  Created by sswukang on 15/1/9.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UIAlertViewDelegate {

    var window: UIWindow?
	
	//MARK: - Yoosee的appDelegate需要的属性
	
	//Yoosee的AppDelegate
    var yooseeAppDelegate: AppDelegateYoosee
	
//MARK: - Application delegate functions
    
    override init(){
        yooseeAppDelegate = AppDelegateYoosee()
        super.init()
    }
    
    
   
    

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		
		//DDLog日志打印，发布APP时，注释掉
    #if DEBUG
		setLogger()
    #endif
        //setLogger()
        
        //显示SDK的版本号  
        //print("version=\(IFlySetting.getVersion())")
     //设置sdk的log等级，log保存在下面设置的工作路径中
        
        IFlySetting.setLogFile(LOG_LEVEL.LVL_ALL)
        
        //打开输出在console的log开关
        
        IFlySetting.showLogcat(true)
        
        
      
//
        

        
		
		//使用友盟统计
		setUMeng()
		
        //初始化对设置进行检查
        checkSettings()
		
		//设置App的风格样式
		setAppStyle()
        
     
        
        /*
        if #available(iOS 8.0, *) {
            registerForPushNotifications(application)
        } else {
            // Fallback on earlier versions
        }
        
        
      */
        
        
        

		
		
        yooseeAppDelegate.application(application, didFinishLaunchingWithOptions: launchOptions)
        return true
    }

    func applicationDidEnterBackground(application: UIApplication) {
        yooseeAppDelegate.applicationDidEnterBackground(application)
    }

    func applicationWillEnterForeground(application: UIApplication) {
		Log.verbose("applicationWillEnterForeground")
        yooseeAppDelegate.applicationWillEnterForeground(application)
    }
	
	func applicationWillResignActive(application: UIApplication) {
		Log.verbose("applicationWillResignActive")
		yooseeAppDelegate.applicationWillResignActive(application)
	}
	
	func applicationWillTerminate(application: UIApplication) {
		self.saveContext()
		yooseeAppDelegate.applicationWillTerminate(application)
	}

    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        Log.verbose("RemoteNotifications Deivce Token:\(deviceToken)")
        
       print("RemoteNotifications Deivce Token:\(deviceToken)")
        
//        var alertView = UIAlertView()
//        alertView.title = "系统提示"
//        alertView.message = "dtoken\(deviceToken)"
//        alertView.addButtonWithTitle("取消")
//        alertView.addButtonWithTitle("确定")
//        alertView.cancelButtonIndex=0
//        alertView.delegate=self;
//        alertView.show()
//        
//        
//        
//        let textView = UITextView.init(frame: CGRectMake(100, 101, 500, 30))
//        
//        textView.text = "dtoken\(deviceToken)"
//        
//        
//        self.window?.addSubview(textView)
//        
        
        
        
      
        
        
        yooseeAppDelegate.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }

    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        Log.verbose("Fail To Register For Remote Notifications: \(error.description)(\(error.code))")
       // print("接收不到推送")
        
        
		yooseeAppDelegate.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        Log.verbose("didReceiveRemoteNotification")
        //print("已经接收到推送")
        yooseeAppDelegate.application(application, didReceiveRemoteNotification: userInfo)
        
    
    }
    
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        Log.verbose("didReceiveLocalNotification")
        yooseeAppDelegate.application(application, didReceiveLocalNotification: notification)
    }

	func application(application: UIApplication, supportedInterfaceOrientationsForWindow window: UIWindow?) -> UIInterfaceOrientationMask {
		return .All
	}
	
	//MARK: - 处理方法
	
	private func setUMeng() {
//		MobClick.setLogEnabled(true)
		MobClick.startWithAppkey(UMENG_APP_KEY, reportPolicy: BATCH, channelId: nil)
		MobClick.setAppVersion(NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"] as! String)
		MobClick.setCrashReportEnabled(true)
	}
	
	func checkSettings(){
		let ud = NSUserDefaults.standardUserDefaults()
		
		//检查是否设置了背景图片
		if ud.valueForKey("backgroundPicture") == nil{
			ud.setValue("bg_default", forKey: "backgroundPicture")
		}
		//		APP.param.backgroundImgName = ud.valueForKey("backgroundPicture") as! String
		APP.param.backgroundImgName = "bg_default"
		APP.param.selectedColor = UIColor(R: 171, G: 66, B: 51, alpha: 1)
		//检查主题颜色
		if ud.valueForKey("themeColorRed") == nil {
/******************************使用默认的颜色*********************************/
			let red:Float     = 52/255.0
			let green:Float   = 188/255.0
			let blue:Float    = 236/255.0
			let alpha:Float   = 1
			ud.setValue(red, forKey: "themeColorRed")
			ud.setValue(green, forKey: "themeColorGreen")
			ud.setValue(blue, forKey: "themeColorBlue")
			ud.setValue(alpha, forKey: "themeColorAlpha") 
/***************************************************************************/
			
			APP.param.themeColor = UIColor(red: CGFloat(red), green: CGFloat(green),blue: CGFloat(blue), alpha: CGFloat(alpha))
		} else {
            let red   = ud.valueForKey("themeColorRed") as! Float
            let green = ud.valueForKey("themeColorGreen") as! Float
            let blue  = ud.valueForKey("themeColorBlue") as! Float
            let alpha = ud.valueForKey("themeColorAlpha") as! Float
			APP.param.themeColor = UIColor(red: CGFloat(red), green: CGFloat(green),blue: CGFloat(blue), alpha: CGFloat(alpha))
		}
		
		/*****************************启动变量**************************************/
		//启动次数
		if ud.valueForKey("launchCount") == nil{
			ud.setValue(0, forKey: "launchCount")
		}
		if let launchCount = ud.valueForKey("launchCount") as? Int {
			if launchCount < Int.max {
				ud.setValue(launchCount + 1, forKey: "launchCount")
			} else {
				ud.setValue(0, forKey: "launchCount")
			}
		} else {
			ud.setValue(0, forKey: "launchCount")
		}
	}
	
	///设置App的风格样式
	private func setAppStyle() {
		//状态栏
		UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true)
		//导航栏
		UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
		UINavigationBar.appearance().tintColor = UIColor.whiteColor()
		//设置Tabbar样式
		UITabBar.appearance().barTintColor = APP.param.themeColor
		UITabBar.appearance().tintColor = APP.param.selectedColor
		UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.whiteColor()], forState: .Normal)
		UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: APP.param.selectedColor], forState: .Selected)
		
	}
	
	private func setLogger() {
		let log = DDTTYLogger.sharedInstance()
		log.colorsEnabled = true
		log.setForegroundColor(UIColor(R: 219, G: 44, B: 56, alpha: 1), backgroundColor: nil, forFlag: DDLogFlag.Error)
		log.setForegroundColor(UIColor.orangeColor(), backgroundColor: nil, forFlag: DDLogFlag.Warning)
		log.setForegroundColor(UIColor(R: 91, G: 149, B: 207, alpha: 1), backgroundColor: nil, forFlag: DDLogFlag.Info)
		log.setForegroundColor(UIColor(R: 133, G: 208, B: 107, alpha: 1), backgroundColor: nil, forFlag: DDLogFlag.Debug)
		
		DDLog.addLogger(log)
		defaultDebugLevel = DDLogLevel.Verbose
		
		/*  是否使Log保存到文件中，保存的Log文件可以发送到服务器上，方便远程调试 */
		if (NSUserDefaults.standardUserDefaults().valueForKey("canSendDebugLog") as? Bool) == true {
			//print("canSendDebugLog")
			let fileLog = DDFileLogger()
			DDLog.addLogger(fileLog)
		}
		
		/********************打印初始log****************/
		Log.debug("################## 应用启动信息 #####################")
		//启动计数
		if let launchCount = NSUserDefaults.standardUserDefaults().valueForKey("launchCount") as? Int {
			Log.debug("启动计数：\t\(launchCount)")
		}
		Log.debug("北京时间：\t\(NSDate().descriptionWithLocale(NSLocale(localeIdentifier: "+8"))))")
		//设备模型
		Log.debug("Device name: \t\(UIDevice.currentDevice().name)")
		Log.debug("Device model: \t\(UIDevice.currentDevice().model)")
		Log.debug("iOS version: \t\(UIDevice.currentDevice().systemVersion)")
		Log.debug("Screen size: \t\(UIScreen.mainScreen().bounds.size)")
		Log.debug("UUID:\t\(UIDevice.currentDevice().identifierForVendor?.UUIDString)")
		let locVersionStr = NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"] as! String
		Log.debug("App version: \t\(locVersionStr)")
		Log.debug("##################################################\n")
		
	}
	
	func mustPopToRootViewController(reason: String?) {
		if let _reason = reason {
			UIAlertView(title: _reason, message: nil, delegate: self, cancelButtonTitle: "确定").show()
			return
		}
		doPopToRootViewController()
	}
	
	private func doPopToRootViewController() {
		//注销
		HR8000Service.shareInstance().logout()
		(window?.rootViewController as? UINavigationController)?.popToRootViewControllerAnimated(true)
	}
	
	func alertView(alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
		doPopToRootViewController()
	}
	
	
	
	// MARK: - Core Data stack
	
	lazy var applicationDocumentsDirectory: NSURL = {
		// The directory the application uses to store the Core Data store file. This code uses a directory named "com.huarui.CoredataTest" in the application's documents Application Support directory.
		let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
		
		return urls[urls.count-1]
	}()
	
	lazy var managedObjectModel: NSManagedObjectModel = {
		// The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
		let modelURL = NSBundle.mainBundle().URLForResource("AppData", withExtension: "momd")!
		return NSManagedObjectModel(contentsOfURL: modelURL)!
	}()
	
	lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
		// The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
		// Create the coordinator and store
		let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
		let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("SingleViewCoreData.sqlite")
		var failureReason = "There was an error creating or loading the application's saved data."
		do {
			try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
		} catch {
			// Report any error we got.
			var dict = [String: AnyObject]()
			dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
			dict[NSLocalizedFailureReasonErrorKey] = failureReason
			
			dict[NSUnderlyingErrorKey] = error as NSError
			let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
			// Replace this with code to handle the error appropriately.
			// abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
			NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
			abort()
		}
		
		return coordinator
	}()
	
	lazy var managedObjectContext: NSManagedObjectContext = {
		// Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
		let coordinator = self.persistentStoreCoordinator
		var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
		managedObjectContext.persistentStoreCoordinator = coordinator
		return managedObjectContext
	}()
	
	// MARK: - Core Data Saving support
	
	func saveContext () {
		if managedObjectContext.hasChanges {
			do {
				try managedObjectContext.save()
			} catch {
				// Replace this implementation with code to handle the error appropriately.
				// abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
				let nserror = error as NSError
				NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
				abort()
                
                
             
			}
		}
	}
}

