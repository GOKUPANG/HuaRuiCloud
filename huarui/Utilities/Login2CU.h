//
//  Login2CU.h
//  huarui
//
//  Created by sswukang on 15/5/13.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

#ifndef huarui_Login2CU_h
#define huarui_Login2CU_h

@interface Login2CU : NSObject 

+(void)login:(NSString *)userName password:(NSString *)passwd callBack:(void (^)(NSError * error))callBack;

/**
注册2cu账号
callback 注册成功error为nil，注册失败error为错误内容
 */
+(void)registerAcount:(NSString*)email passwd:(NSString*)password callback:(void (^)(NSError *error))callback;

+(void)logout;
@end

#endif
