//
//  UserModel.swift
//  huarui
//
//  Created by sswukang on 15/11/12.
//  Copyright © 2015年 huarui. All rights reserved.
//

import Foundation
import CoreData


class UserModel: NSManagedObject {
 
	///未加密的明码。建议保存和读取password都通过操作此属性来完成，不要直接操作password属性
	var realPassword: String? {
		set{
			self.password = AESCrypt.encrypt(newValue, password: "Don't_Hack_Me")
		}
		get{
			return AESCrypt.decrypt(self.password, password: "Don't_Hack_Me")
		}
	}
	
}

enum UserPermission: Int {
	case Normal
	case Administrator = 2
	case Super = 3
}
