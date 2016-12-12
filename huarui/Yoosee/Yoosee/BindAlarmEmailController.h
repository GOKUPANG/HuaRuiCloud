//
//  BindAlarmEmailController.h
//  Yoosee
//
//  Created by guojunyi on 14-5-15.
//  Copyright (c) 2014年 guojunyi. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Contact;
@class  MBProgressHUD;
@class AlarmSettingController;
@class TableViewWithBlock;
@interface BindAlarmEmailController : UIViewController<UITextViewDelegate,UIAlertViewDelegate>{
    BOOL isOpened;
}

@property (strong, nonatomic) AlarmSettingController *alarmSettingController;
@property (strong, nonatomic) Contact *contact;
@property (strong, nonatomic) MBProgressHUD *progressAlert;
@property (strong, nonatomic) UIView *maskLayerView;

@property (nonatomic, strong) UITextField *field1;
@property (nonatomic, strong) UITextView *subjectTextView;
@property (nonatomic, strong) UITextView *contentTextView;
@property (nonatomic, strong) UITextField *smtpTextField;
@property (nonatomic, strong) UITextField *senderTextField;
@property (nonatomic, strong) UILabel *pwdPromptLabel;
@property (nonatomic, strong) UITextField *pwdTextField;
@property (nonatomic, strong) UIButton *dropDownBtn;
@property (nonatomic, strong) TableViewWithBlock *tableView;
@property (nonatomic) BOOL isUnbindEmail;//YES表示解除绑定邮箱
@property (nonatomic, strong) UIButton *unbindButton;
//YES表示取消保存或解除时的指示器，并不接收设备返回的任何数据
@property (nonatomic) BOOL isIndicatorCancelled;
//YES表示APP发送set/get命令成功，ack_receiveRemoteMessage里不用做任何处理
//防止频繁发送set/get命令
@property (nonatomic) BOOL isCommandSentOk;

@property (strong,nonatomic) NSArray *smtpServerArray;
@property (nonatomic, strong) NSString *smtpServer;
@property (strong,nonatomic) NSArray *smtpPortArray;
@property (nonatomic, strong) NSString *smtpPort;
@property (strong,nonatomic) NSArray *emailArray;

@end
