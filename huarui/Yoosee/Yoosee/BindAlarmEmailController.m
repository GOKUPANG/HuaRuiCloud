//
//  BindAlarmEmailController.m
//  Yoosee
//
//  Created by guojunyi on 14-5-15.
//  Copyright (c) 2014年 guojunyi. All rights reserved.
//

#import "BindAlarmEmailController.h"
#import "Constants.h"
#import "Contact.h"
#import "TopBar.h"
#import "Toast+UIView.h"
#import "Utils.h"
#import "AppDelegateYoosee.h"
#import "MBProgressHUD.h"
#import "AlarmSettingController.h"
#import "UITableView+DataSourceBlocks.h"
#import "TableViewWithBlock.h"

@interface BindAlarmEmailController ()
{
    int _getCounts;
    BOOL isTextViewOrTextField;//delete
}
@end

@implementation BindAlarmEmailController

-(void)dealloc{
    [self.alarmSettingController release];
    [self.contact release];
    [self.progressAlert release];
    [self.maskLayerView release];
    [self.field1 release];
    [self.subjectTextView release];
    [self.contentTextView release];
    [self.smtpTextField release];
    [self.senderTextField release];
    [self.pwdPromptLabel release];
    [self.pwdTextField release];
    [self.dropDownBtn release];
    [self.emailArray release];
    [self.smtpServerArray release];
    [self.smtpServer release];
    [self.smtpPortArray release];
    [self.smtpPort release];
    [self.unbindButton release];
    [super dealloc];
}
    
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
    }
    return self;
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    //write code here...
    [[NSNotificationCenter defaultCenter] removeObserver:self name:RECEIVE_REMOTE_MESSAGE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ACK_RECEIVE_REMOTE_MESSAGE object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];//delete
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];//delete
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    //write code here ...
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onKeyBoardWillShow:) name:UIKeyboardWillShowNotification object:nil];//delete
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onKeyBoardWillHide:) name:UIKeyboardWillHideNotification object:nil];//delete
    self.contentTextView.text = @"Dear User,\n Please check the attached picture for more information.";//delete
    self.subjectTextView.text = @"Attention: alarm";//delete
    
}

-(void)viewWillAppear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveRemoteMessage:) name:RECEIVE_REMOTE_MESSAGE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ack_receiveRemoteMessage:) name:ACK_RECEIVE_REMOTE_MESSAGE object:nil];
    
    //YES表示取消保存或解除时的指示器，并不接收设备返回的任何数据
    self.isIndicatorCancelled = YES;
    //YES表示APP发送set/get命令成功，ack_receiveRemoteMessage里不用做任何处理
    self.isCommandSentOk = YES;
    
    
    //上一界面获取到的报警邮箱相关信息
    int isSMTP = self.alarmSettingController.isSMTP;
    int isRightPwd = self.alarmSettingController.isRightPwd;
    int isEmailVerified = self.alarmSettingController.isEmailVerified;
    NSString *smtpServer = self.alarmSettingController.smtpServer;
    NSString *smtpPort = [NSString stringWithFormat:@"%d",self.alarmSettingController.smtpPort];
    NSString *smtpUser = self.alarmSettingController.smtpUser;
    NSString *smtpPwd = self.alarmSettingController.smtpPwd;
    NSString *bindEmail = self.alarmSettingController.bindEmail;
    if(isSMTP == 0){//只支持系统默认邮箱(旧设备)
        [self.senderTextField setHidden:YES];
        [self.smtpTextField setHidden:YES];
        [self.dropDownBtn setHidden:YES];
        [self.tableView setHidden:YES];
        [self.pwdPromptLabel setHidden:YES];
        [self.pwdTextField setHidden:YES];
        [self.field1 setHidden:NO];
        self.field1.text = bindEmail;
    }else{//既支持系统默认邮箱(去掉系统默认)，又支持非系统默认邮箱(新设备)
        [self.senderTextField setHidden:NO];
        [self.smtpTextField setHidden:NO];
        [self.dropDownBtn setHidden:NO];
        [self.tableView setHidden:NO];
        [self.pwdPromptLabel setHidden:YES];
        [self.pwdTextField setHidden:NO];
        [self.field1 setHidden:YES];
        
        
        if(bindEmail && bindEmail.length>0){
            NSRange range = [bindEmail rangeOfString:@"@" options:NSBackwardsSearch];
            NSString *preEmail = [bindEmail substringToIndex:range.location];
            NSString *sufEmail = [bindEmail substringFromIndex:range.location];
            
            //1. 发件框
            self.senderTextField.text = preEmail;
            
            //判断收件箱是不是有效的
            BOOL isIvalidEmail = YES;
            for (int i=0; i<self.emailArray.count; i++) {
                NSRange range1 = [bindEmail rangeOfString:self.emailArray[i]];
                if (range1.length>0) {
                    //2. 邮局框
                    self.smtpTextField.text = self.emailArray[i];//SMTP服务器
                    self.smtpServer = self.smtpServerArray[i];//SMTP服务器
                    self.smtpPort = self.smtpPortArray[i];//SMTP端口
                    isIvalidEmail = NO;
                    break;
                }
            }
            if (isIvalidEmail) {
                //2. 邮局框
                self.smtpTextField.text = sufEmail;//SMTP服务器
                self.smtpServer = self.smtpServerArray[0];//SMTP服务器
                self.smtpPort = self.smtpPortArray[0];//SMTP端口
            }
            
            //3. 密码框
            self.pwdTextField.text = smtpPwd;//发件密码
            
            
            if (smtpUser && smtpUser.length > 0) {
                //4. 提示栏
                if (isEmailVerified == 1) {//提示邮箱未验证
                    [self.pwdPromptLabel setHidden:NO];
                    self.pwdPromptLabel.text = NSLocalizedString(@"not_verified", nil);
                }
                if (isEmailVerified == 0 && isRightPwd == 0) {//提示密码不匹配
                    [self.pwdPromptLabel setHidden:NO];
                    self.pwdPromptLabel.text = NSLocalizedString(@"pwd_error", nil);
                }
            }
            
        }else{
            self.senderTextField.text = @"";
            self.pwdTextField.text = @"";
            self.smtpTextField.text = self.emailArray[0];//SMTP服务器
            self.smtpServer = self.smtpServerArray[0];//SMTP服务器
            self.smtpPort = self.smtpPortArray[0];//SMTP端口
        }
    }
    
    //解除绑定按钮
    if(bindEmail && bindEmail.length>0){
        [self.unbindButton setHidden:NO];
    }else{
        [self.unbindButton setHidden:YES];
    }
}

- (void)receiveRemoteMessage:(NSNotification *)notification{
    if (self.isIndicatorCancelled) {
        return;//YES表示取消保存或解除时的指示器，并不接收设备返回的任何数据
    }
    self.isCommandSentOk = YES;
    NSDictionary *parameter = [notification userInfo];
    int key   = [[parameter valueForKey:@"key"] intValue];
    switch(key){
            
        case RET_SET_ALARM_EMAIL:
        {
            
            NSInteger result = [[parameter valueForKey:@"result"] intValue];
            
            if(result==0){
                
                if(self.alarmSettingController.isSMTP == 0){//只支持系统默认邮箱(旧设备)
                    
                    if (self.isUnbindEmail) {
                        self.isUnbindEmail = NO;
                    }
                    
                    //YES表示返回上个界面，重新获取报警邮箱信息，进行更新
                    self.alarmSettingController.isRefreshAlarmEmail = YES;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.progressAlert hide:YES];
                        [self.maskLayerView setHidden:YES];
                        [self.view makeToast:NSLocalizedString(@"operator_success", nil)];
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            usleep(800000);
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self onBackPress];
                            });
                        });
                    });
                }else{//既支持系统默认邮箱(去掉系统默认)，又支持非系统默认邮箱(新设备)
                    if (self.isUnbindEmail) {
                        self.isUnbindEmail = NO;
                        
                        //YES表示返回上个界面，重新获取报警邮箱信息，进行更新
                        self.alarmSettingController.isRefreshAlarmEmail = YES;
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.progressAlert hide:YES];
                            [self.maskLayerView setHidden:YES];
                            [self.view makeToast:NSLocalizedString(@"operator_success", nil)];
                            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                usleep(800000);
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [self onBackPress];
                                });
                            });
                        });
                    }else{
                        //设置成功时，再次获取SMTP数据，取出邮箱密码，判断是否正确
                        //正确，则返回上一界面；错误，则在当前界面提示密码错误
                        dispatch_async(dispatch_get_main_queue(), ^{
                            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                usleep(3000000);//延时3秒，再获取
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    self.isCommandSentOk = NO;
                                    _getCounts = 1;
                                    [[P2PClient sharedClient] getAlarmEmailWithId:self.contact.contactId password:self.contact.contactPassword];
                                });
                            });
                        });
                    }
                }
                
            }else if(result==15){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.progressAlert hide:YES];
                    [self.maskLayerView setHidden:YES];
                    [self.view makeToast:NSLocalizedString(@"email_format_error", nil)];
                });
            }else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.progressAlert hide:YES];
                    [self.maskLayerView setHidden:YES];
                    [self.view makeToast:NSLocalizedString(@"operator_failure", nil)];
                });
            }
        }
            break;
        case RET_GET_ALARM_EMAIL:
        {
            int isRightPwd = [[parameter valueForKey:@"isRightPwd"] intValue];
            int isEmailVerified = [[parameter valueForKey:@"isEmailVerified"] intValue];
            
            
            if (isEmailVerified == 1) {
                if (_getCounts < 5) {
                    _getCounts++;
                    
                    //如果邮箱未验证，则再次获取邮箱信息；
                    dispatch_async(dispatch_get_main_queue(), ^{
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            usleep(3000000);//延时3秒，再获取
                            dispatch_async(dispatch_get_main_queue(), ^{
                                self.isCommandSentOk = NO;
                                [[P2PClient sharedClient] getAlarmEmailWithId:self.contact.contactId password:self.contact.contactPassword];
                            });
                        });
                    });
                }else{//如果获取了5次，邮箱还是未验证，则不再获取，提示邮箱未验证
                    
                    //YES表示返回上个界面，重新获取报警邮箱信息，进行更新
                    self.alarmSettingController.isNotVerifiedEmail = YES;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.progressAlert hide:YES];
                        [self.maskLayerView setHidden:YES];
                        [self.view makeToast:NSLocalizedString(@"not_verified", nil)];
                        [self.pwdPromptLabel setHidden:NO];
                        self.pwdPromptLabel.text = NSLocalizedString(@"not_verified", nil);
                    });
                }
            }else{
                //YES表示返回上个界面，重新获取报警邮箱信息，进行更新
                self.alarmSettingController.isRefreshAlarmEmail = YES;
                
                if (isRightPwd == 0) {//错误，则在当前界面提示密码错误
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.progressAlert hide:YES];
                        [self.maskLayerView setHidden:YES];
                        [self.view makeToast:NSLocalizedString(@"pwd_error", nil)];
                        [self.pwdPromptLabel setHidden:NO];
                        self.pwdPromptLabel.text = NSLocalizedString(@"pwd_error", nil);
                    });
                }else{//正确，则返回上一界面
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.progressAlert hide:YES];
                        [self.maskLayerView setHidden:YES];
                        [self.view makeToast:NSLocalizedString(@"operator_success", nil)];
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            usleep(800000);
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self onBackPress];
                            });
                        });
                    });
                }
            }
        }
            break;

        case RET_DEVICE_NOT_SUPPORT:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self.progressAlert hide:YES];
                [self.maskLayerView setHidden:YES];
                [self.view makeToast:NSLocalizedString(@"device_not_support", nil)];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    usleep(800000);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self onBackPress];
                    });
                });
            });
        }
            break;
    }
    
}

- (void)ack_receiveRemoteMessage:(NSNotification *)notification{
    if (self.isCommandSentOk) {
        return;//YES表示APP发送set/get命令成功，ack_receiveRemoteMessage里不用做任何处理
    }
    NSDictionary *parameter = [notification userInfo];
    int key   = [[parameter valueForKey:@"key"] intValue];
    int result   = [[parameter valueForKey:@"result"] intValue];
    switch(key){
        case ACK_RET_SET_ALARM_EMAIL:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(result==1){
                    [self.progressAlert hide:YES];
                    [self.maskLayerView setHidden:YES];
                    [self.view makeToast:NSLocalizedString(@"original_password_error", nil)];
                    
                }else if(result==2){
                    DLog(@"resend set alarm email");
                    
                    
                    if (self.alarmSettingController.isSMTP == 0) {
                        if(self.isUnbindEmail){//清除收件人
                            
                            [[P2PClient sharedClient] setAlarmEmailWithId:self.contact.contactId password:self.contact.contactPassword email:@"0" bOption:0 smtpServer:@"" smtpPort:0 smtpUser:@"" smtpPwd:@"" subject:@"" content:@"" isSupportSMTP:NO];
                        }else{
                            
                            [[P2PClient sharedClient] setAlarmEmailWithId:self.contact.contactId password:self.contact.contactPassword email:self.field1.text bOption:0 smtpServer:@"" smtpPort:0 smtpUser:@"" smtpPwd:@"" subject:@"" content:@"" isSupportSMTP:NO];
                        }
                    }else{
                        if(self.isUnbindEmail){//清除收件人
                            [[P2PClient sharedClient] setAlarmEmailWithId:self.contact.contactId password:self.contact.contactPassword email:@"0" bOption:1 smtpServer:@"" smtpPort:0 smtpUser:@"0" smtpPwd:@"" subject:@"" content:@"" isSupportSMTP:YES];
                            
                        }else{
                            NSString *smtpServer = self.smtpServer;//SMTP服务器
                            int smtpPort = [self.smtpPort intValue];//SMTP端口
                            NSString *senderEmail = [NSString stringWithFormat:@"%@%@",self.senderTextField.text,self.smtpTextField.text];//发件人
                            NSString *senderPwd = self.pwdTextField.text;//发件密码
                            NSString *reciEmail = senderEmail;//收件人
                            
                            [[P2PClient sharedClient] setAlarmEmailWithId:self.contact.contactId password:self.contact.contactPassword email:reciEmail bOption:1 smtpServer:smtpServer smtpPort:smtpPort smtpUser:senderEmail smtpPwd:senderPwd subject:self.subjectTextView.text content:self.contentTextView.text isSupportSMTP:YES];
                        }
                    }
                }
                
                
            });
            
        }
            break;
        case ACK_RET_GET_ALARM_EMAIL:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(result==1){
                    [self.progressAlert hide:YES];
                    [self.maskLayerView setHidden:YES];
                    [self.view makeToast:NSLocalizedString(@"original_password_error", nil)];
                }else if(result==2){
                    DLog(@"resend get alarm email");
                    [[P2PClient sharedClient] getAlarmEmailWithId:self.contact.contactId password:self.contact.contactPassword];
                }
                
                
            });
        }
            break;
            
    }
    
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.smtpServerArray = @[@"smtp.163.com",@"smtp.qq.com",@"smtp.sina.com.cn",@"smtp.mail.yahoo.com",@"smtp.gmail.com",@"smtp.189.cn",@"smtp.live.com"];
    self.smtpPortArray = @[@"25",@"25",@"25",@"587",@"587",@"25",@"587"];
    self.emailArray = @[@"@163.com",@"@qq.com",@"@sina.com",@"@yahoo.com",@"@gmail.com",@"@189.cn",@"@hotmail.com"];
    [self initComponent];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#define MARGIN_LEFT_RIGHT 5.0
-(void)initComponent{
    CGRect rect = [AppDelegateYoosee getScreenSize:YES isHorizontal:NO];
    CGFloat width = rect.size.width;
    CGFloat height = rect.size.height;
    [self.view setBackgroundColor:XBgColor];
    TopBar *topBar = [[TopBar alloc] initWithFrame:CGRectMake(0, 0, width, NAVIGATION_BAR_HEIGHT)];
    [topBar setBackButtonHidden:NO];
    [topBar setRightButtonHidden:NO];
    [topBar setRightButtonText:NSLocalizedString(@"save", nil)];
    [topBar.rightButton addTarget:self action:@selector(onSavePress) forControlEvents:UIControlEventTouchUpInside];
    [topBar.backButton addTarget:self action:@selector(onBackPress) forControlEvents:UIControlEventTouchUpInside];
    [topBar setTitle:NSLocalizedString(@"bind_email",nil)];
    [self.view addSubview:topBar];
    [topBar release];
    
    
    //报警邮箱
    UITextField *field1 = [[UITextField alloc] initWithFrame:CGRectMake(MARGIN_LEFT_RIGHT, NAVIGATION_BAR_HEIGHT+20, width-MARGIN_LEFT_RIGHT*2, TEXT_FIELD_HEIGHT)];
    
    if(CURRENT_VERSION>=7.0){
        field1.layer.borderWidth = 1;
        field1.layer.borderColor = [[UIColor colorWithRed:200.0/255.0 green:200.0/255.0 blue:200.0/255.0 alpha:1.0] CGColor];
        field1.layer.cornerRadius = 5.0;
    }
    field1.textAlignment = NSTextAlignmentLeft;
    field1.placeholder = NSLocalizedString(@"input_email", nil);
    field1.borderStyle = UITextBorderStyleRoundedRect;
    field1.returnKeyType = UIReturnKeyDone;
    field1.autocapitalizationType = UITextAutocapitalizationTypeNone;
    field1.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    [field1 addTarget:self action:@selector(onKeyBoardDown:) forControlEvents:UIControlEventEditingDidEndOnExit];
    self.field1 = field1;
    [self.view addSubview:field1];
    [field1 release];
    
    
    //发件人
    UITextField *senderTextField = [[UITextField alloc] initWithFrame:CGRectMake(MARGIN_LEFT_RIGHT, NAVIGATION_BAR_HEIGHT+20, width-MARGIN_LEFT_RIGHT*2-140.0, TEXT_FIELD_HEIGHT)];
    if(CURRENT_VERSION>=7.0){
        senderTextField.layer.borderWidth = 1;
        senderTextField.layer.borderColor = [[UIColor colorWithRed:200.0/255.0 green:200.0/255.0 blue:200.0/255.0 alpha:1.0] CGColor];
        senderTextField.layer.cornerRadius = 5.0;
    }
    senderTextField.textAlignment = NSTextAlignmentLeft;
    senderTextField.placeholder = NSLocalizedString(@"input_email", nil);
    senderTextField.font = XFontBold_16;
    senderTextField.borderStyle = UITextBorderStyleRoundedRect;
    senderTextField.returnKeyType = UIReturnKeyDone;
    senderTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    senderTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    [senderTextField addTarget:self action:@selector(onKeyBoardDown:) forControlEvents:UIControlEventEditingDidEndOnExit];
    [self.view addSubview:senderTextField];
    //左边的view
    CGFloat senderLeftLabelWidth = [Utils getStringWidthWithString:NSLocalizedString(@"sender", nil) font:XFontBold_16 maxWidth:width];
    UILabel *senderLeftLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, senderLeftLabelWidth+5.0, TEXT_FIELD_HEIGHT)];
    senderLeftLabel.backgroundColor = [UIColor clearColor];
    senderLeftLabel.text = NSLocalizedString(@"sender", nil);
    senderLeftLabel.textAlignment = NSTextAlignmentRight;
    senderLeftLabel.font = XFontBold_16;
    senderTextField.leftView = senderLeftLabel;
    senderTextField.leftViewMode = UITextFieldViewModeAlways;
    [senderLeftLabel release];
    self.senderTextField = senderTextField;
    [senderTextField release];
    
    //发件人邮局
    UITextField *smtpTextField = [[UITextField alloc] initWithFrame:CGRectMake(self.senderTextField.frame.origin.x+self.senderTextField.frame.size.width+5.0, NAVIGATION_BAR_HEIGHT+20, 140.0-5.0, TEXT_FIELD_HEIGHT)];
    if(CURRENT_VERSION>=7.0){
        smtpTextField.layer.borderWidth = 1;
        smtpTextField.layer.borderColor = [[UIColor colorWithRed:200.0/255.0 green:200.0/255.0 blue:200.0/255.0 alpha:1.0] CGColor];
        smtpTextField.layer.cornerRadius = 5.0;
    }
    smtpTextField.userInteractionEnabled = NO;
    smtpTextField.font = XFontBold_16;
    smtpTextField.textAlignment = NSTextAlignmentLeft;
    smtpTextField.borderStyle = UITextBorderStyleRoundedRect;
    smtpTextField.returnKeyType = UIReturnKeyDone;
    smtpTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    smtpTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    smtpTextField.text = self.emailArray[0];
    [self.view addSubview:smtpTextField];
    self.smtpTextField = smtpTextField;
    [smtpTextField release];
    //下拉按钮
    UIButton *dropDownBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    dropDownBtn.frame = CGRectMake(width-MARGIN_LEFT_RIGHT-TEXT_FIELD_HEIGHT, NAVIGATION_BAR_HEIGHT+20, TEXT_FIELD_HEIGHT, TEXT_FIELD_HEIGHT);
    [dropDownBtn setImage:[UIImage imageNamed:@"dropdown.png"] forState:UIControlStateNormal];
    [dropDownBtn addTarget:self action:@selector(changeOpenStatus:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:dropDownBtn];
    self.dropDownBtn = dropDownBtn;
    //下拉表格
    TableViewWithBlock *tableView = [[TableViewWithBlock alloc] initWithFrame:CGRectMake(self.smtpTextField.frame.origin.x, self.smtpTextField.frame.origin.y+TEXT_FIELD_HEIGHT, self.smtpTextField.frame.size.width, 0) style:UITableViewStylePlain];
    [self.view addSubview:tableView];
    self.tableView = tableView;
    [tableView release];
    [self.tableView initTableViewDataSourceAndDelegate:^(UITableView *tableView,NSInteger section){
        return (NSInteger)self.emailArray.count;//多少行
        
    } setCellForIndexPathBlock:^(UITableView *tableView,NSIndexPath *indexPath){
        //生成cell
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SelectionCell"];
        if (!cell) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SelectionCell"] autorelease];
            [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
        }
        
        [cell.textLabel setText:self.emailArray[indexPath.row]];
        [cell.textLabel setFont:XFontBold_16];
        return cell;
    } setDidSelectRowBlock:^(UITableView *tableView,NSIndexPath *indexPath){
        //选中cell回调
        UITableViewCell *cell=(UITableViewCell*)[tableView cellForRowAtIndexPath:indexPath];
        self.smtpTextField.text=cell.textLabel.text;
        self.smtpServer = self.smtpServerArray[indexPath.row];//SMTP服务器
        self.smtpPort = self.smtpPortArray[indexPath.row];//SMTP端口
        
        [self.dropDownBtn sendActionsForControlEvents:UIControlEventTouchUpInside];
    }];
    
    [self.tableView.layer setBorderColor:[UIColor lightGrayColor].CGColor];
    [self.tableView.layer setBorderWidth:1.0];
    
    //邮箱密码
    UITextField *pwdTextField = [[UITextField alloc] initWithFrame:CGRectMake(MARGIN_LEFT_RIGHT, self.senderTextField.frame.origin.y+TEXT_FIELD_HEIGHT+20, width-MARGIN_LEFT_RIGHT*2, TEXT_FIELD_HEIGHT)];
    
    if(CURRENT_VERSION>=7.0){
        pwdTextField.layer.borderWidth = 1;
        pwdTextField.layer.borderColor = [[UIColor colorWithRed:200.0/255.0 green:200.0/255.0 blue:200.0/255.0 alpha:1.0] CGColor];
        pwdTextField.layer.cornerRadius = 5.0;
    }
    pwdTextField.textAlignment = NSTextAlignmentLeft;
    pwdTextField.placeholder = NSLocalizedString(@"input_password", nil);
    pwdTextField.font = XFontBold_16;
    pwdTextField.borderStyle = UITextBorderStyleRoundedRect;
    pwdTextField.returnKeyType = UIReturnKeyDone;
    pwdTextField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    pwdTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    [pwdTextField addTarget:self action:@selector(onKeyBoardDown:) forControlEvents:UIControlEventEditingDidEndOnExit];
    pwdTextField.secureTextEntry = YES;
    [self.view addSubview:pwdTextField];
    //左边的view
    CGFloat pwdLeftLabelWidth = [Utils getStringWidthWithString:NSLocalizedString(@"password", nil) font:XFontBold_16 maxWidth:width];
    UILabel *pwdLeftLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, pwdLeftLabelWidth+5.0, TEXT_FIELD_HEIGHT)];
    pwdLeftLabel.backgroundColor = [UIColor clearColor];
    pwdLeftLabel.text = NSLocalizedString(@"password", nil);
    pwdLeftLabel.textAlignment = NSTextAlignmentRight;
    pwdLeftLabel.font = XFontBold_16;
    pwdTextField.leftView = pwdLeftLabel;
    pwdTextField.leftViewMode = UITextFieldViewModeAlways;
    [pwdLeftLabel release];
    self.pwdTextField = pwdTextField;
    [pwdTextField release];
    
    //邮箱密码错误提示或邮箱未验证
    UILabel *pwdPromptLabel = [[UILabel alloc] initWithFrame:CGRectMake(MARGIN_LEFT_RIGHT*2, self.pwdTextField.frame.origin.y+TEXT_FIELD_HEIGHT, width-MARGIN_LEFT_RIGHT*4, TEXT_FIELD_HEIGHT)];
    pwdPromptLabel.backgroundColor = [UIColor clearColor];
    pwdPromptLabel.text = @"";
    pwdPromptLabel.numberOfLines = 0;
    pwdPromptLabel.font = XFontBold_16;
    pwdPromptLabel.textColor = [UIColor redColor];
    [self.view addSubview:pwdPromptLabel];
    self.pwdPromptLabel = pwdPromptLabel;
    [pwdPromptLabel release];
    
    //解除绑定按钮
    CGFloat unbindBtn_Y = 0;
    if(self.alarmSettingController.isSMTP == 0){
        unbindBtn_Y = self.field1.frame.origin.y+TEXT_FIELD_HEIGHT+20;
    }else{
        unbindBtn_Y = self.pwdPromptLabel.frame.origin.y+TEXT_FIELD_HEIGHT+10;
    }
    UIButton *unbindButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [unbindButton setFrame:CGRectMake(MARGIN_LEFT_RIGHT, unbindBtn_Y, width-MARGIN_LEFT_RIGHT*2, 34)];
    UIImage *unbindButtonImage = [UIImage imageNamed:@"bg_blue_button"];
    UIImage *unbindButtonImage_p = [UIImage imageNamed:@"bg_blue_button_p"];
    unbindButtonImage = [unbindButtonImage stretchableImageWithLeftCapWidth:unbindButtonImage.size.width*0.5 topCapHeight:unbindButtonImage.size.height*0.5];
    unbindButtonImage_p = [unbindButtonImage_p stretchableImageWithLeftCapWidth:unbindButtonImage_p.size.width*0.5 topCapHeight:unbindButtonImage_p.size.height*0.5];
    [unbindButton setBackgroundImage:unbindButtonImage forState:UIControlStateNormal];
    [unbindButton setBackgroundImage:unbindButtonImage_p forState:UIControlStateHighlighted];
    [unbindButton addTarget:self action:@selector(onUnbindEmail) forControlEvents:UIControlEventTouchUpInside];
    [unbindButton setTitle:NSLocalizedString(@"unbind_email", nil) forState:UIControlStateNormal];
    [self.view addSubview:unbindButton];
    self.unbindButton = unbindButton;
    
    
    //Email主题
    UITextView *subjectTextView = [[UITextView alloc] initWithFrame:CGRectMake(MARGIN_LEFT_RIGHT, self.pwdTextField.frame.origin.y+TEXT_FIELD_HEIGHT+20, width-MARGIN_LEFT_RIGHT*2, 50)];
    if(CURRENT_VERSION>=7.0){
        subjectTextView.layer.borderWidth = 1;
        subjectTextView.layer.borderColor = [[UIColor colorWithRed:200.0/255.0 green:200.0/255.0 blue:200.0/255.0 alpha:1.0] CGColor];
        subjectTextView.layer.cornerRadius = 5.0;
    }
    subjectTextView.delegate = self;
    subjectTextView.returnKeyType = UIReturnKeyDone;//返回键的类型
    [subjectTextView setFont:XFontBold_16];
    self.subjectTextView.text = @"";
//    [self.view addSubview:subjectTextView];
    self.subjectTextView = subjectTextView;
    [subjectTextView release];
    
    //Email内容
    UITextView *contentTextView = [[UITextView alloc] initWithFrame:CGRectMake(MARGIN_LEFT_RIGHT, self.subjectTextView.frame.origin.y+self.subjectTextView.frame.size.height+20, width-MARGIN_LEFT_RIGHT*2, TEXT_FIELD_HEIGHT*2)];
    if(CURRENT_VERSION>=7.0){
        contentTextView.layer.borderWidth = 1;
        contentTextView.layer.borderColor = [[UIColor colorWithRed:200.0/255.0 green:200.0/255.0 blue:200.0/255.0 alpha:1.0] CGColor];
        contentTextView.layer.cornerRadius = 5.0;
    }
    contentTextView.delegate = self;
    contentTextView.returnKeyType = UIReturnKeyDone;//返回键的类型
    [contentTextView setFont:XFontBold_16];
    self.contentTextView.text = @"";
//    [self.view addSubview:contentTextView];
    self.contentTextView = contentTextView;
    [contentTextView release];
    
    [self.view bringSubviewToFront:self.tableView];
    
    
    
    //指示器
    self.progressAlert = [[[MBProgressHUD alloc] initWithView:self.view] autorelease];
    self.progressAlert.labelText = NSLocalizedString(@"validating",nil);
    [self.view addSubview:self.progressAlert];
    
    //添加手势，点击view时，取消旋转提示
    UIView *maskLayerView = [[UIView alloc] initWithFrame:CGRectMake(0, NAVIGATION_BAR_HEIGHT, width, height-NAVIGATION_BAR_HEIGHT)];
    UITapGestureRecognizer *singleTapG = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSingleTap)];
    [singleTapG setNumberOfTapsRequired:1];
    [maskLayerView addGestureRecognizer:singleTapG];
    [self.view addSubview:maskLayerView];
    [maskLayerView setHidden:YES];
    self.maskLayerView = maskLayerView;
    [maskLayerView release];
    [singleTapG release];
}

#pragma mark - 下拉按钮触发调用函数
- (void)changeOpenStatus:(id)sender {
    if (isOpened) {
        [UIView animateWithDuration:0.3 animations:^{
            UIImage *closeImage=[UIImage imageNamed:@"dropdown.png"];
            [self.dropDownBtn setImage:closeImage forState:UIControlStateNormal];
            
            CGRect frame=self.tableView.frame;
            
            frame.size.height=0.0;
            [self.tableView setFrame:frame];
            
        } completion:^(BOOL finished){
            
            isOpened=NO;
        }];
        
    }else{
        [UIView animateWithDuration:0.3 animations:^{
            UIImage *openImage=[UIImage imageNamed:@"dropup.png"];
            [self.dropDownBtn setImage:openImage forState:UIControlStateNormal];
            
            CGRect frame=self.tableView.frame;
            
            frame.size.height=200.0;
            [self.tableView setFrame:frame];
        } completion:^(BOOL finished){
            
            isOpened=YES;
        }];
        
        
    }
}

-(void)onKeyBoardDown:(id)sender{
    [sender resignFirstResponder];
}

-(void)onBackPress{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:RECEIVE_REMOTE_MESSAGE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ACK_RECEIVE_REMOTE_MESSAGE object:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)onSavePress{
    
    if(self.alarmSettingController.isSMTP == 0){
        [self.field1 resignFirstResponder];
        
        NSString *reciEmail = self.field1.text;//收件人
        
        //邮箱不可以为空
        if(!reciEmail||!reciEmail.length>0){
            [self.view makeToast:NSLocalizedString(@"input_email", nil)];
            return;
        }
        
        
        //邮箱长度应为5~31
        if(reciEmail.length<5||reciEmail.length>31){
            [self.view makeToast:NSLocalizedString(@"email_length_error", nil)];
            return;
        }
        
        //邮箱格式错误
        NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
        NSPredicate *emailFormat = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
        if(![emailFormat evaluateWithObject:reciEmail]){
            [self.view makeToast:NSLocalizedString(@"email_format_error", nil)];
            return;
        }
        
        
        //开始设置邮箱
        self.progressAlert.dimBackground = YES;
        [self.progressAlert show:YES];
        [self.maskLayerView setHidden:NO];
        
        //YES表示取消保存或解除时的指示器，并不接收设备返回的任何数据
        self.isIndicatorCancelled = NO;
        //YES表示APP发送set/get命令成功，ack_receiveRemoteMessage里不用做任何处理
        self.isCommandSentOk = NO;
        
        
        //发件人为系统默认邮箱
        //参数bOption值为0，参数smtpServer、smtpPort、smtpUser、smtpPwd不用理会
        [[P2PClient sharedClient] setAlarmEmailWithId:self.contact.contactId password:self.contact.contactPassword email:reciEmail bOption:0 smtpServer:@"" smtpPort:0 smtpUser:@"" smtpPwd:@"" subject:@"" content:@"" isSupportSMTP:NO];
    }else{
        [self.senderTextField resignFirstResponder];
        [self.pwdTextField resignFirstResponder];
        
        NSString *smtpServer = self.smtpServer;//SMTP服务器
        int smtpPort = [self.smtpPort intValue];//SMTP端口
        NSString *senderEmail = [NSString stringWithFormat:@"%@%@",self.senderTextField.text,self.smtpTextField.text];//发件人
        NSString *senderPwd = self.pwdTextField.text;//发件密码
        NSString *reciEmail = senderEmail;//收件人
        
        
        //邮箱不可以为空
        if(!self.senderTextField.text||!self.senderTextField.text.length>0){
            [self.view makeToast:NSLocalizedString(@"input_email", nil)];
            return;
        }
        
        
        //邮箱长度应为5~31
        if(reciEmail.length<5||reciEmail.length>31){
            [self.view makeToast:NSLocalizedString(@"email_length_error", nil)];
            return;
        }
        
        
        //邮箱格式错误
        NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
        NSPredicate *emailFormat = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
        if(![emailFormat evaluateWithObject:reciEmail]){
            [self.view makeToast:NSLocalizedString(@"email_format_error", nil)];
            return;
        }
        
        
        //密码不可以为空
        if(!senderPwd||!senderPwd.length>0){
            [self.view makeToast:NSLocalizedString(@"input_password", nil)];
            return;
        }
        
        
        //判断是否支持此邮箱,不在数组里，则表示不支持
        BOOL isIvalidEmail = YES;
        for (int i=0; i<self.emailArray.count; i++) {
            if ([self.smtpTextField.text isEqualToString:self.emailArray[i]]) {
                isIvalidEmail = NO;
                break;
            }
        }
        if (isIvalidEmail) {
            NSString *errorString = [NSString stringWithFormat:@"%@%@",NSLocalizedString(@"not_support", nil),self.smtpTextField.text];
            [self.view makeToast:errorString];
            return;
        }
        
        
        //开始设置邮箱
        self.progressAlert.dimBackground = YES;
        [self.progressAlert show:YES];
        [self.maskLayerView setHidden:NO];
        
        //YES表示取消保存或解除时的指示器，并不接收设备返回的任何数据
        self.isIndicatorCancelled = NO;
        //YES表示APP发送set/get命令成功，ack_receiveRemoteMessage里不用做任何处理
        self.isCommandSentOk = NO;
        
        
        //发件人为非系统默认邮箱
        //参数bOption值为1，传入相应参数smtpServer、smtpPort、smtpUser、smtpPwd
        [[P2PClient sharedClient] setAlarmEmailWithId:self.contact.contactId password:self.contact.contactPassword email:reciEmail bOption:1 smtpServer:smtpServer smtpPort:smtpPort smtpUser:senderEmail smtpPwd:senderPwd subject:self.subjectTextView.text content:self.contentTextView.text isSupportSMTP:YES];
    }
}

-(void)onUnbindEmail{
    NSString *message = [NSString stringWithFormat:@"%@%@?",NSLocalizedString(@"unbind_email", nil),self.alarmSettingController.bindEmail];
    UIAlertView *unBindEmailAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"unbind_email", nil) message:message delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:NSLocalizedString(@"ok", nil),nil];
    [unBindEmailAlert show];
    [unBindEmailAlert release];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(buttonIndex==1){
        self.isUnbindEmail = YES;
        
        self.progressAlert.dimBackground = YES;
        [self.progressAlert show:YES];
        [self.maskLayerView setHidden:NO];
        
        //YES表示取消保存或解除时的指示器，并不接收设备返回的任何数据
        self.isIndicatorCancelled = NO;
        //YES表示APP发送set/get命令成功，ack_receiveRemoteMessage里不用做任何处理
        self.isCommandSentOk = NO;
        
        if(self.alarmSettingController.isSMTP == 0){
            //发件人为系统默认邮箱
            //参数bOption值为0，参数smtpServer、smtpPort、smtpUser、smtpPwd不用理会
            [[P2PClient sharedClient] setAlarmEmailWithId:self.contact.contactId password:self.contact.contactPassword email:@"0" bOption:0 smtpServer:@"" smtpPort:0 smtpUser:@"" smtpPwd:@"" subject:@"" content:@"" isSupportSMTP:NO];
        }else{
            //发件人为非系统默认邮箱
            //参数bOption值为1，传入相应参数smtpServer、smtpPort、smtpUser、smtpPwd
            [[P2PClient sharedClient] setAlarmEmailWithId:self.contact.contactId password:self.contact.contactPassword email:@"0" bOption:1 smtpServer:@"" smtpPort:0 smtpUser:@"0" smtpPwd:@"" subject:@"" content:@"" isSupportSMTP:YES];
        }
    }
}

#pragma mark - UITextViewDelegate
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView{//delete
    isTextViewOrTextField = YES;
    return YES;
}

-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    return YES;
}

#pragma mark - UIKeyboardWillShowNotification
-(void)onKeyBoardWillShow:(NSNotification*)notification{//delete
    NSDictionary *userInfo = [notification userInfo];
    CGRect rect = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    if (!isTextViewOrTextField) {
        return;
    }else{
        isTextViewOrTextField = NO;
    }
    [UIView transitionWithView:self.view duration:0.2 options:UIViewAnimationOptionCurveEaseInOut
                    animations:^{
                        CGFloat offset1 = self.view.frame.size.height-(self.contentTextView.frame.origin.y+self.contentTextView.frame.size.height);
                        CGFloat finalOffset;
                        if(offset1-rect.size.height<0){
                            finalOffset = rect.size.height-offset1+20;
                        }else {
                            if(offset1-rect.size.height>=20){
                                finalOffset = 0;
                            }else{
                                finalOffset = 20-(offset1-rect.size.height);
                            }
                            
                        }
                        self.view.transform = CGAffineTransformMakeTranslation(0, -finalOffset);
                    }
                    completion:^(BOOL finished) {
                        
                    }
     ];
}

#pragma mark - UIKeyboardWillHideNotification
-(void)onKeyBoardWillHide:(NSNotification*)notification{//delete

    [UIView transitionWithView:self.view duration:0.2 options:UIViewAnimationOptionCurveEaseInOut
                    animations:^{
                        self.view.transform = CGAffineTransformMakeTranslation(0, 0);
                    }
                    completion:^(BOOL finished) {
                        
                    }
     ];
}

#pragma mark - 取消旋转提示
-(void)onSingleTap{
   [self.progressAlert hide:YES];
   [self.maskLayerView setHidden:YES];
    self.isIndicatorCancelled = YES;
}

-(BOOL)shouldAutorotate{
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interface {
    return (interface == UIInterfaceOrientationPortrait );
}

#ifdef IOS6

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}
#endif

-(NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}

-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    return UIInterfaceOrientationPortrait;
}
@end
