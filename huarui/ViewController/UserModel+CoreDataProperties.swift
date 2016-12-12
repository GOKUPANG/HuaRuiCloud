//
//  UserModel+CoreDataProperties.swift
//  huarui
//
//  Created by sswukang on 15/11/12.
//  Copyright © 2015年 huarui. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension UserModel {

    @NSManaged var name: String?
	///密码，请使用realPassword来读写password，以便加密保存
	@NSManaged var password: String?
	@NSManaged var permission: NSNumber?
	///是否记住密码
	@NSManaged var isRememberPasswd: NSNumber?
	///是否自动登录
	@NSManaged var isAutoLogin: NSNumber?
	///使用频率计数
	@NSManaged var hits: NSNumber?
	///最后一次登录
	@NSManaged var lastLogin: NSNumber?
	
	
}
