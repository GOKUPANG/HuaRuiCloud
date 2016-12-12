//
//  AppDelegateYoosee.h
//  Yoosee
//
//  Created by guojunyi on 14-3-20.
//  Copyright (c) 2014年 guojunyi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MainController.h"
#import "Reachability.h"
#import "Contact.h"//重新调整监控画面

#define NET_WORK_CHANGE @"NET_WORK_CHANGE"
#define ALERT_TAG_ALARMING 0
#define ALERT_TAG_MONITOR 1
#define ALERT_TAG_APP_UPDATE 2
@interface AppDelegateYoosee : UIResponder <UIApplicationDelegate,UIAlertViewDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) MainController *mainController;
@property (strong, nonatomic) Contact *contact;//重新调整监控画面
@property (nonatomic) NetworkStatus networkStatus;
+(CGRect)getScreenSize:(BOOL)isNavigation isHorizontal:(BOOL)isHorizontal;
+(AppDelegateYoosee*)sharedDefault;

@property (strong, nonatomic) NSString *token;
@property (strong, nonatomic) NSString *alarmContactId;
@property (strong, nonatomic) NSString *monitoredContactId;
//currentPushedContactId当前推送的ID，作用是，和下一个推送ID比较，若相等则不弹出推送框
@property (strong, nonatomic) NSString *currentPushedContactId;
//YES表示接收到推送，正在输入密码准备进行监控，此时不弹出任何推送
@property (nonatomic) BOOL isInputtingPwdToMonitor;
@property (nonatomic) long lastShowAlarmTimeInterval;
@property (nonatomic) BOOL isDoorBellAlarm;//在监控界面使用,区分门铃推送，其他推送
//YES表示正显示门铃推送界面，不弹出任何推送
@property (nonatomic) BOOL isShowingDoorBellAlarm;
//YES表示APP端主动挂断监控、视频通话或呼叫状态，而且前提应该是只有监控、视频通话或呼叫状态下，才为YES
@property (nonatomic) BOOL isHungUpActively;
@property (nonatomic) BOOL isMonitoring;//而且前提应该是只有监控、视频通话或呼叫状态下

+(NSString*)getAppVersion;
@property (nonatomic) BOOL isGoBack;
@property (nonatomic) BOOL isNotificationBeClicked;//YES表示点击系统消息推送通知，将显示系统消息表

@end
