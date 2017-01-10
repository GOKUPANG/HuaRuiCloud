//
//  AcountInputView.swift
//  viewTest
//
//  Created by sswukang on 15/11/10.
//  Copyright © 2015年 huarui. All rights reserved.
//用户名密码整块的view

import UIKit

class AcountInputView: UIView, UITableViewDelegate, UITableViewDataSource {
 
	var users: [UserModel]?
	
	var userTextField: UITextField!
	var passwdTextField: UITextField!
	var dropPickerButton: UIButton!
	weak var delegate: AcountInputViewDelegate?
	var dropViewExtendHeight:CGFloat = 150
	
	var userName: String {
		if userTextField.text == nil {
			return ""
		}
		return userTextField.text!
	}
	
	var password: String {
		if passwdTextField.text == nil {
			return ""
		}
		return passwdTextField.text!
	}
	
	//下拉账号选择的view是否弹出
	var dropPickerShowed = false
	private var dropPickerView: UITableView!
	private var isAnimationStop = true
	
	private var userImageView: UIImageView!
	private var passwdImageView: UIImageView!
	private var lineView: UIView!
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		self.opaque = false
		self.layer.backgroundColor = UIColor.whiteColor().CGColor
		self.layer.cornerRadius = 5
		userImageView = UIImageView()
		passwdImageView = UIImageView()
		userTextField = UITextField()
		passwdTextField = UITextField()
		dropPickerButton = UIButton()
		
		userTextField.returnKeyType = .Next
		userTextField.clearButtonMode = .WhileEditing
		passwdTextField.returnKeyType = .Join
		passwdTextField.clearButtonMode = .WhileEditing
		passwdTextField.clearsOnBeginEditing = false
		passwdTextField.secureTextEntry = true
		
		userTextField.addTarget(self, action: #selector(AcountInputView.onUserTextFieldDidEndOnExit(_:)), forControlEvents: UIControlEvents.EditingDidEndOnExit)
		passwdTextField.addTarget(self, action: #selector(AcountInputView.onPasswdTextFieldDidEndOnExit(_:)), forControlEvents: UIControlEvents.EditingDidEndOnExit)
		
		dropPickerButton.setImage(UIImage(named: "ico_user_pick"), forState: .Normal)
		dropPickerButton.addTarget(self, action: #selector(AcountInputView.onDropPickerButtonClicked(_:)), forControlEvents: .TouchUpInside)
        
        
		userImageView.image = UIImage(named: "ico_user")?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
		passwdImageView.image = UIImage(named: "ico_passwd")?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        
        userImageView.tintColor = UIColorFromRGB("#0fa7d6")
        passwdImageView.tintColor = UIColorFromRGB("#0fa7d6")
        
        
        
		lineView = UIView()
		lineView.backgroundColor = UIColor.lightGrayColor()
		
		addSubview(lineView)
		addSubview(userTextField)
		addSubview(passwdTextField)
		addSubview(dropPickerButton)
		addSubview(userImageView)
		addSubview(passwdImageView)
	}

	required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
    
    func UIColorFromRGB (hex:String) -> UIColor {
        
        var cString:String = hex.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).uppercaseString
        
        
        
        if (cString.hasPrefix("#")) {
            
            cString = (cString as NSString).substringFromIndex(1)
            
        }
        
        let rString = (cString as NSString).substringToIndex(2)
        
        let gString = ((cString as NSString).substringFromIndex(2) as NSString).substringToIndex(2)
        
        let bString = ((cString as NSString).substringFromIndex(4) as NSString).substringToIndex(2)
        
        
        
        var r:CUnsignedInt = 0, g:CUnsignedInt = 0, b:CUnsignedInt = 0;
        
        NSScanner(string: rString).scanHexInt(&r)
        
        NSScanner(string: gString).scanHexInt(&g)
        
        NSScanner(string: bString).scanHexInt(&b)
        
        return UIColor(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: CGFloat(1))
        
    }
    
    override func drawRect(rect: CGRect) {
		userImageView.frame = CGRectMake(0, 0, rect.midY, rect.midY)
		passwdImageView.frame = CGRectMake(0, rect.midY, rect.midY, rect.midY)
		userTextField.frame = CGRectMake(userImageView.frame.maxX, 0, rect.width - rect.height, rect.midY)
		passwdTextField.frame = CGRectMake(passwdImageView.frame.maxX, rect.midY, rect.width - rect.midY, rect.midY)
		dropPickerButton.frame = CGRectMake(rect.width-rect.midY, 0, rect.midY, rect.midY)
		
		let adjustOffset = ((1/UIScreen.mainScreen().scale)/2)
		lineView.frame = CGRectMake(1, rect.midY - adjustOffset, rect.width-2, 1 / UIScreen.mainScreen().scale)
    }
	
	//显示下拉菜单
	func showDropPickerView(show: Bool) {
		if show == dropPickerShowed || !isAnimationStop { return }
		self.dropPickerShowed = !self.dropPickerShowed
		isAnimationStop = false
		//旋转button
		let anim = CABasicAnimation(keyPath: "transform.rotation.z")
		anim.fromValue = show ? CGFloat(0) : CGFloat(M_PI)
		anim.toValue = show ? CGFloat(M_PI) : CGFloat(0)
		anim.duration = 0.35
		anim.removedOnCompletion = false
		anim.fillMode = kCAFillModeForwards
		dropPickerButton.layer.addAnimation(anim, forKey: "rotaion_anim")
		
		//显示账号列表
		if dropPickerView == nil {
			dropPickerView = getDropPickerView()
			dropPickerView.layer.cornerRadius = self.layer.cornerRadius
			dropPickerView.layer.backgroundColor = self.layer.backgroundColor
			dropPickerView.hidden = true
		}
		if show {
			//隐藏键盘
			userTextField.resignFirstResponder()
			passwdTextField.resignFirstResponder()
			
			self.superview?.addSubview(dropPickerView)
			dropPickerView.frame = CGRectMake(
				self.frame.minX,
				self.frame.minY + self.bounds.midY - 2,
				self.bounds.width,
				0
			)
			dropPickerView.hidden = false
			dropPickerView.contentOffset = CGPointZero
			dropPickerView.reloadData()
		}
		UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveLinear, animations: {
			if show {
				self.dropPickerView.frame = CGRectMake(
					self.dropPickerView.frame.minX,
					self.dropPickerView.frame.minY,
					self.dropPickerView.frame.width,
					self.bounds.midY + 2 + self.dropViewExtendHeight)
			} else {
				self.dropPickerView.frame = CGRectMake(
					self.dropPickerView.frame.minX,
					self.dropPickerView.frame.minY,
					self.dropPickerView.frame.width,
					0)
			}
			}, completion: { completed in
				if !show {
					self.dropPickerView.removeFromSuperview()
				}
				self.isAnimationStop = true
		})
	}
	
	func setActiveUser(user: UserModel) {
		self.userTextField.text = user.name
		self.passwdTextField.text = user.realPassword
		delegate?.acountInputView?(self, didSelectedUser: user)
	}
	
	func reloadData() {
		showDropPickerView(false)
		dropPickerView.reloadData()
	}
	
	
	private func getDropPickerView() -> UITableView {
		let tableView = UITableView()
		tableView.showsVerticalScrollIndicator = false
		tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 10)
		tableView.tableFooterView = UIView()
		if users == nil || users!.count == 0 { return tableView }
		tableView.dataSource = self
		tableView.delegate = self
		
		return tableView
	}
	
	//MARK: - UITableView
	
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if users == nil { return 0 }
		return users!.count
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		var cell: UITableViewCell! = tableView.dequeueReusableCellWithIdentifier("cell")
		
		if cell == nil {
			cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "cell")
			cell.tintColor = self.tintColor
			let removeButton = UIButton(frame: CGRectMake(0,0,cell.frame.height, cell.frame.height))
			removeButton.setImage(UIImage(named: "ico_remove"), forState: .Normal)
			removeButton.addTarget(self, action: #selector(AcountInputView.onRemoveButtonClicked(_:)), forControlEvents: .TouchUpInside)
			cell.accessoryView = removeButton
		}
		if let gestures = cell.gestureRecognizers {
			for gesture in gestures {
				cell.removeGestureRecognizer(gesture)
			}
		}
		cell.textLabel?.text = users![indexPath.row].name
		cell.textLabel?.font = UIFont.systemFontOfSize(UIFont.systemFontSize())
		let imageName: String
		
		if users![indexPath.row].permission == UserPermission.Administrator.rawValue
			|| users![indexPath.row].permission == UserPermission.Super.rawValue {
			imageName = "ico_user"
		} else {
			imageName = "ico_user_normal"
		}
		
		cell.imageView?.image = UIImage(named: imageName)?.imageWithRenderingMode(.AlwaysTemplate)
		
		cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(AcountInputView.onCellTap(_:))))
		cell.accessoryView?.tag = indexPath.row + 100
		cell.tag = indexPath.row
		
		return cell
	}
	
//MARK: - UI事件
	
	@objc private func onDropPickerButtonClicked(button: UIButton) {
		showDropPickerView(!dropPickerShowed)
	}
	
	@objc private func onUserTextFieldDidEndOnExit(textField: UITextField) {
		showDropPickerView(false)
		passwdTextField.becomeFirstResponder()
	}
	
	@objc private func onPasswdTextFieldDidEndOnExit(textField: UITextField) {
		showDropPickerView(false)
		guard let userName = userTextField.text else {
			return
		}
		guard let password = passwdTextField.text else {
			return
		}
		delegate?.acountInputView?(self, didEndEditing: userName, password: password)
	}
	
	
	
	@objc private func onCellTap(gesture: UITapGestureRecognizer) {
		if let index = gesture.view?.tag {
			userTextField.text = users![index].name
			passwdTextField.text = users![index].realPassword
			onDropPickerButtonClicked(dropPickerButton)
			delegate?.acountInputView?(self, didSelectedUser: users![index])
		}
	}
	
	@objc private func onRemoveButtonClicked(button: UIButton) {
		let index = button.tag-100
		
		if users == nil || index >= users!.count { return }
		delegate?.acountInputView?(self, didTapRemoveAcount: button.tag-100, userName: users![index].name!, password: users![index].realPassword)
	}
}

//MARK: - AcountInputViewDelegate

@objc protocol AcountInputViewDelegate {
	optional func acountInputView(acountView: AcountInputView, didEndEditing userName: String, password: String)
	optional func acountInputView(acountView: AcountInputView, didTapRemoveAcount index: Int, userName: String, password: String?)
	//选择了某个用户
	optional func acountInputView(acountView: AcountInputView, didSelectedUser user: UserModel)
}
