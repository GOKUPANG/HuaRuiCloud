//
//  Login2CU.m
//  huarui
//
//  Created by sswukang on 15/5/13.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetManager.h"
#import "UDManager.h"
#import "RegisterResult.h"
#import "AppDelegateYoosee.h"
#import "LoginResult.h"
#import "Login2CU.h"
#import "GlobalThread.h"
#import "FListManager.h"
#import "AccountResult.h"

@implementation Login2CU

+(void)login:(NSString *)username password:(NSString *)password callBack:(void (^)(NSError * error))callBack {
	if ([UDManager isLogin]) {
		if (callBack) callBack(nil);
        
		return;
	}
    
	[[NetManager sharedManager] loginWithUserName:username password:password token:[AppDelegateYoosee sharedDefault].token callBack:^(id result){
		
		LoginResult *loginResult = (LoginResult*)result;
      
       
        

		
		switch(loginResult.error_code){
			case NET_RET_LOGIN_SUCCESS:
			{
                
               
                
				//re-registerForRemoteNotifications
				if(CURRENT_VERSION>=8.0){//8.0以后使用这种方法来注册推送通知
					[[UIApplication sharedApplication] registerForRemoteNotifications];
					
					UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeBadge|UIUserNotificationTypeSound|UIUserNotificationTypeAlert categories:nil];
					[[UIApplication sharedApplication] registerUserNotificationSettings:settings];
					
					UIRemoteNotificationType myTypes = UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound;
					[[UIApplication sharedApplication] registerForRemoteNotificationTypes:myTypes];
				}else{
					[[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeBadge)];
				}
				
				DLog(@"contactId:%@",loginResult.contactId);
				DLog(@"Email:%@",loginResult.email);
				DLog(@"Phone:%@",loginResult.phone);
				DLog(@"CountryCode:%@",loginResult.countryCode);
                
                NSLog(@"邮箱%@",loginResult.email);
                
                
				[UDManager setIsLogin:YES];
				[UDManager setLoginInfo:loginResult];
				[[NSUserDefaults standardUserDefaults] setObject:username forKey:@"USER_NAME"];
				[[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"LOGIN_TYPE"];
				
				[[NetManager sharedManager] getAccountInfo:loginResult.contactId sessionId:loginResult.sessionId callBack:^(id JSON){
					AccountResult *accountResult = (AccountResult*)JSON;
					loginResult.email = accountResult.email;
					loginResult.phone = accountResult.phone;
					loginResult.countryCode = accountResult.countryCode;
					[UDManager setLoginInfo:loginResult];
				}];
				
				if (callBack) callBack(nil);
			}
				break;
			case NET_RET_LOGIN_USER_UNEXIST:
			{
				NSError *error = [NSError errorWithDomain:NSLocalizedString(@"user_unexist", nil) code:1102 userInfo:nil];
				if (callBack) callBack(error);
				
			}
				break;
			case NET_RET_LOGIN_PWD_ERROR:
			{
				NSError *error = [NSError errorWithDomain:NSLocalizedString(@"password_error", nil) code:1103 userInfo:nil];
				if (callBack) callBack(error);
			}
				break;
			case NET_RET_UNKNOWN_ERROR:
			{
				NSError *error = [NSError errorWithDomain:NSLocalizedString(@"login_failure", nil) code:1104 userInfo:nil];
				if (callBack) callBack(error);
			}
				break;
				
			default:
			{
				NSError *error = [NSError errorWithDomain:NSLocalizedString(@"login_failure", nil) code:1104 userInfo:nil];
				if (callBack) callBack(error);
			}
				break;
		}
		
	}];
}


+(void)registerAcount:(NSString*)email passwd:(NSString*)password callback:(void (^)(NSError *error))callback{
	
    [[NetManager sharedManager] registerWithVersionFlag:@"1" email:email countryCode:@"" phone:@"" password:password repassword:password phoneCode:@"" callBack:^(id JSON) {
		
		
        RegisterResult *registerResult = (RegisterResult*)JSON;
		switch(registerResult.error_code){
			case NET_RET_REGISTER_SUCCESS:
			{
				callback(nil);
			}
				break;
			case NET_RET_REGISTER_EMAIL_FORMAT_ERROR:
			{
				NSError *error = [NSError errorWithDomain:NSLocalizedString(@"email_format_error", nil) code:1100 userInfo:nil];
				callback(error);
			}
				break;
			case NET_RET_REGISTER_EMAIL_USED:
			{
				NSError *error = [NSError errorWithDomain:NSLocalizedString(@"email_used", nil) code:1101 userInfo:nil];
				callback(error);
			}
				break;
				
			default:
			{
				NSError *error = [NSError errorWithDomain:NSLocalizedString(@"unknown_error", nil) code:112233 userInfo:nil];
				callback(error);
			}
		}
    }];
}

+(void)logout {
	[UDManager setIsLogin:NO];
	
	[[GlobalThread sharedThread:NO] kill];
	[[FListManager sharedFList] setIsReloadData:YES];
	[[UIApplication sharedApplication] unregisterForRemoteNotifications];
	
	dispatch_queue_t queue = dispatch_queue_create(NULL, NULL);
	dispatch_async(queue, ^{
		[[P2PClient sharedClient] p2pDisconnect];
	});
}
@end