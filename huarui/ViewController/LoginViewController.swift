//
//  NewLoginViewController.swift
//  huarui
//
//  Created by sswukang on 15/11/10.
//  Copyright © 2015年 huarui. All rights reserved.
//

import UIKit
import CoreData

class LoginViewController: UIViewController, AcountInputViewDelegate, UIAlertViewDelegate {
    //存储账号
	private var savedUsers: [UserModel]!
    
	private var acountView: AcountInputView!
	private var rememberButton: UIButton!
	private var autoLoginButton: UIButton!
	private var loginButton: PrettyButton!
	
	private var isRememberPasswd: Bool {
		if rememberButton == nil { return false }
		return rememberButton.selected
	}
	
	private var isAutoLogin: Bool {
		if autoLoginButton == nil { return false }
		return autoLoginButton.selected
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		initDatas()
		addViews()
		initViews()
	}
	
	override func viewWillAppear(animated: Bool) {
        
        //隐藏导航条 斌
		self.navigationController?.navigationBar.hidden = true
	}
	
	private func initDatas() {
		//从coreData中获取用户信息
		savedUsers = getUsersFromDatabase()
		self.view.tintColor = UIColor(R: 171, G: 66, B: 51, alpha: 1)
	}
	
	private func addViews() {
		//添加用户名密码输入框
		if self.view.frame.width == 320 {
			acountView = AcountInputView(frame: CGRectMake(0, 0, view.bounds.width*0.95, 90))
		} else {
			acountView = AcountInputView(frame: CGRectMake(0, 0, view.bounds.width*0.9, 90))
		}
		acountView.layer.cornerRadius = 5
		acountView.center = CGPointMake(view.bounds.midX, view.bounds.height*(1-0.618))
		self.view.addSubview(acountView)
		acountView.delegate = self
		acountView.userTextField.placeholder = "用户名"
		acountView.passwdTextField.placeholder = "密码"
		
		//添加品牌logo
		let brandImageView = UIImageView(frame: CGRectMake(0, acountView.frame.minY - 90, self.view.bounds.width, 50))
		brandImageView.contentMode = .ScaleAspectFit
		brandImageView.image = UIImage(named: "华睿云中文")
		self.view.addSubview(brandImageView)
		
		//记住密码与自动登录
		rememberButton = UIButton(frame: CGRectMake(0, acountView.frame.maxY + 10, 100, 45))
		rememberButton.center.x = self.view.frame.width*0.3
		rememberButton.setImage(UIImage(named: "ico_remenber")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Selected)
		rememberButton.setImage(UIImage(named: "ico_unremenber")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
		rememberButton.imageView?.contentMode = .ScaleAspectFit
		rememberButton.setTitle("记住密码", forState: .Normal)
		rememberButton.titleLabel?.font = UIFont.systemFontOfSize(UIFont.systemFontSize())
		rememberButton.setTitleColor(UIColor(R: 80, G: 80, B: 80, alpha: 1), forState: .Normal)
		rememberButton.addTarget(self, action: #selector(LoginViewController.onRememberButtonClicked(_:)), forControlEvents: .TouchUpInside)
		self.view.addSubview(rememberButton)
		
		
		autoLoginButton = UIButton(frame: CGRectMake(0, acountView.frame.maxY + 10, 100, 45))
		autoLoginButton.center.x = self.view.frame.width*0.7
		autoLoginButton.setImage(UIImage(named: "ico_remenber")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Selected)
		autoLoginButton.setImage(UIImage(named: "ico_unremenber")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
		autoLoginButton.imageView?.contentMode = .ScaleAspectFit
		autoLoginButton.setTitle("自动登录", forState: .Normal)
		autoLoginButton.titleLabel?.font = UIFont.systemFontOfSize(UIFont.systemFontSize())
		autoLoginButton.setTitleColor(UIColor(R: 80, G: 80, B: 80, alpha: 1), forState: .Normal)
		autoLoginButton.addTarget(self, action: #selector(LoginViewController.onAutoLoginButtonClicked(_:)), forControlEvents: .TouchUpInside)
		self.view.addSubview(autoLoginButton)
		
		//登录按钮
		loginButton = PrettyButton(frame: CGRectMake(0, rememberButton.frame.maxY + 60, self.view.bounds.width*0.9, 45))
		loginButton.center.x = self.view.bounds.midX
		loginButton.center.y = autoLoginButton.center.y + (self.view.bounds.height - autoLoginButton.center.y) * (1-0.7)
		loginButton.backgroundColor = self.view.tintColor
		loginButton.hightLightColor = self.view.tintColor.colorWithAdjustBrightness(-0.3)
		loginButton.cornerRadius = 5
		loginButton.setTitle("登 录", forState: .Normal)
		loginButton.addTarget(self, action: #selector(LoginViewController.onLoginButtonClicked(_:)), forControlEvents: .TouchUpInside)
		self.view.addSubview(loginButton)
		//改变acountView的下拉长度，让它接近登录按钮上端
		acountView.dropViewExtendHeight = loginButton.frame.minY - acountView.frame.maxY - 5
		
		//公司logo
		let logoImageView = UIImageView(frame: CGRectMake(0, self.view.bounds.height-60, 100, 45))
		logoImageView.center.x = self.view.bounds.midX
		logoImageView.image = UIImage(named: "华睿logo")
		logoImageView.contentMode = .ScaleAspectFit
		self.view.addSubview(logoImageView)
		
		//获取当前App版本
		let label = UILabel(frame: CGRectMake(0, self.view.frame.maxY-20, self.view.frame.width/2, 20))
		label.center.x = self.view.center.x
		label.textAlignment = .Center
		label.textColor = UIColor(red:0.24, green:0.74, blue:0.93, alpha:1)
		label.font = UIFont.systemFontOfSize(13)
		label.text = "v" + appVersionStr
		self.view.addSubview(label)
	}
	
	
	
	private func initViews() {
		self.view.layer.contents = UIImage(named: APP.param.backgroundImgName)?.CGImage
		self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(LoginViewController.onViewTap(_:))))
		acountView.users = savedUsers
		if savedUsers.count > 0 {
			acountView.setActiveUser(savedUsers[0])
			if savedUsers[0].isAutoLogin != nil && savedUsers[0].isAutoLogin!.boolValue {
				self.onLoginButtonClicked(loginButton)
			}
		}
	}
	
	
	//MARK: - UI事件
	
	func onViewTap(gesture: UITapGestureRecognizer) {
		acountView.showDropPickerView(false)
		acountView.userTextField.resignFirstResponder()
		acountView.passwdTextField.resignFirstResponder()
	}
	
	@objc private func onRememberButtonClicked(button: UIButton) {
		button.selected = !button.selected
		if !button.selected {
			autoLoginButton.selected = false
		}
	}
	
	@objc private func onAutoLoginButtonClicked(button: UIButton) {
		button.selected = !button.selected
		if button.selected {
			rememberButton.selected = true
		}
	}
	
	@objc private func onLoginButtonClicked(button: UIButton) {
		acountView.passwdTextField.resignFirstResponder()
		acountView.userTextField.resignFirstResponder()
		//用户名除去空格
		let userName = acountView.userName.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
		let password = acountView.password
		guard !userName.isEmpty else {
			acountView.userTextField.becomeFirstResponder()
			return
		}
		guard !password.isEmpty else {
			acountView.passwdTextField.becomeFirstResponder()
			return
		}
		
		runOnGlobalQueue({
			self.saveUserToDatabase(
				userName,
				password: self.isRememberPasswd ? password : nil,
				permission: nil,
				autoLogin: self.isAutoLogin,
				rememberPasswd:  self.isRememberPasswd
			)
			self.savedUsers = self.getUsersFromDatabase()
			self.acountView.users = self.savedUsers
		})
		
		KVNProgress.showWithStatus("正在登陆...")
		
		Log.debug("################################")
		HR8000Service.shareInstance().login(userName, password: password, result:{
			(error) in
			if let err = error {
				Log.warn("登陆失败：\(err.domain), code=\(err.code)")
				KVNProgress.showErrorWithStatus("\(err.domain)(\(err.code))")
			} else {
				KVNProgress.dismiss()
                
                //查询所有设备 斌
				HR8000Service.shareInstance().queryAllDevice()
               print("正在查询所有设备")
                
                
				//登陆成功，跳到HomeViewController界面
                self.performSegueWithIdentifier("showHomeViewController", sender: nil)
                
				runOnGlobalQueue({
					self.saveUserToDatabase(
						userName,
						password: password,
						permission: Int(HRDatabase.shareInstance().acount.permission),
						autoLogin: self.isAutoLogin,
						rememberPasswd: self.isRememberPasswd
					)
				})
			}
		})
		
		
	}
	
	func acountInputView(acountView: AcountInputView, didEndEditing userName: String, password: String) {
		self.onLoginButtonClicked(self.loginButton)
	}
	
	func acountInputView(acountView: AcountInputView, didTapRemoveAcount index: Int, userName: String, password: String?) {
		let alert = UIAlertView(title: "提示", message: "您确定要删除“" + userName + "”的记录吗？", delegate: self, cancelButtonTitle: "取消", otherButtonTitles: "删除")
		alert.tag = index
		alert.show()
	}
	
	func acountInputView(acountView: AcountInputView, didSelectedUser user: UserModel) {
		if let rememb = user.isRememberPasswd {
			self.rememberButton.selected = rememb.boolValue
		}
		if let autoLogin = user.isAutoLogin {
			self.autoLoginButton.selected = autoLogin.boolValue
		}
	}
	
	func alertView(alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
		if buttonIndex != alertView.cancelButtonIndex {
			//务必先删除密码再删除用户名，因为删除用户名同时要判断删除的用户是不是当前使用的
			if alertView.tag < savedUsers.count {
				let user = savedUsers.removeAtIndex(alertView.tag)
				acountView.users = savedUsers
				//如果删除的是当前使用的，则用新的替换
				if user.name == acountView.userTextField.text {
					if savedUsers.count == 0 {
						acountView.userTextField.text = ""
						acountView.passwdTextField.text = ""
						rememberButton.selected = false
						autoLoginButton.selected = false
					} else {
						acountView.setActiveUser(savedUsers[0])
					}
				}
				removeUserFromDatabase(user)
			}
			acountView.reloadData()
		}
	}
	
	//MARK: - 操作数据库
	
	private func getUsersFromDatabase() -> [UserModel] {
		let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
		let request = NSFetchRequest(entityName: "Users")
		request.sortDescriptors = [
			NSSortDescriptor(key: "lastLogin", ascending: false), //最后一次登录的时间
			NSSortDescriptor(key: "hits", ascending: false)	//登录次数
            
            
		]
        
        //print(request)
		do {
			if let results = try context.executeFetchRequest(request) as? [UserModel] {
				return results
			}
		} catch let error as NSError {
			Log.warn("Login: getAcountsFromDataBase()发生异常: \(error.description)")
		}
		return [UserModel]()
	}
	
	//保存账户到数据库中
	private func saveUserToDatabase(userName: String, password: String?, permission: Int?, autoLogin: Bool, rememberPasswd: Bool) {
		//从数据库中查找相同的用户名
        
   // print("从数据库中查找相同的用户名")
		let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
		let request = NSFetchRequest(entityName: "Users")
		request.predicate = NSPredicate(format: "name == '\(userName)'")
		do {
			let results = try context.executeFetchRequest(request)
			if results.count == 0 {	//未找到记录，插入新记录
				if let userModel = NSEntityDescription.insertNewObjectForEntityForName("Users", inManagedObjectContext: context) as? UserModel {
					userModel.name = userName
					userModel.realPassword = password
					userModel.permission = permission
					userModel.isAutoLogin = autoLogin
					userModel.isRememberPasswd = rememberPasswd
					userModel.hits = 0
					userModel.lastLogin = NSDate().timeIntervalSince1970
					try context.save()
//					Log.debug("插入“\(userName)”")
				}
			} else {		//找到了记录，更新数据
                
               // print("找到了记录，更新数据")
				let user = results[0] as! UserModel
				user.realPassword = password
				user.permission = permission
                
				user.isAutoLogin = autoLogin
				user.isRememberPasswd = rememberPasswd
				user.hits = user.hits == nil ? 0:user.hits!.integerValue + 1
				if user.hits!.integerValue == Int.max {
					user.hits = 0
				}
				user.lastLogin = NSDate().timeIntervalSince1970
                
              //  print(user.lastLogin)
				try context.save()
//				Log.debug("更新“\(userName)”")
			}
			
		} catch let error as NSError {
			Log.warn("Login: 数据库操作（\(userName)）发生异常: \(error.description)")
		}
	}

	private func removeUserFromDatabase(user: UserModel) {
		let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
		do {
			context.deleteObject(user)
			try context.save()
		} catch let error as NSError {
			Log.warn("removeAcountFromDatabase发生异常：\(error.description)")
		}
	}
	
}
