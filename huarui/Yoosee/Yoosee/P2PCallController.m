//
//  P2PCallController.m
//  Yoosee
//
//  Created by guojunyi on 14-3-26.
//  Copyright (c) 2014年 guojunyi. All rights reserved.
//

#import "P2PCallController.h"
#import "P2PClient.h"
#import "Constants.h"
#import "Toast+UIView.h"
#import "AppDelegateYoosee.h"
#import "P2PMonitorController.h"
#import "TopBar.h"
#import "Utils.h"
#import "ContactDAO.h"
#import "FListManager.h"
#import "CameraManager.h"

@interface P2PCallController ()

@end

@implementation P2PCallController
-(void)dealloc{
    [self.address release];
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

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    //write code here ...
    [AppDelegateYoosee sharedDefault].monitoredContactId = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    //[[P2PClient sharedClient] setDelegate:self];
    
    [self initComponent];
    
    [[P2PClient sharedClient] setP2pCallState:P2PCALL_STATE_CALLING];
    BOOL isBCalled = [[P2PClient sharedClient] isBCalled];
    P2PCallType type = [[P2PClient sharedClient] p2pCallType];
    NSString *callId = [[P2PClient sharedClient] callId];
    NSString *callPassword = [[P2PClient sharedClient] callPassword];
    
    //过滤当前被监控帐号的推送显示
    [AppDelegateYoosee sharedDefault].monitoredContactId = callId;
    if([[P2PClient sharedClient] p2pCallType]==P2PCALL_TYPE_VIDEO){
        /*
         * 1. 未进入视频通话界面时，设置为YES（一旦进入，摄像已开始，此时设置为NO）
         * 2. 避免各种原因导致通话连接失败，未能进入视频通话界面，而造成while死循环
         */
        [[CameraManager sharedManager] setIsFinishCaptureOutput:YES];
    }
    
    [AppDelegateYoosee sharedDefault].isMonitoring = YES;//当前是监控、视频通话或呼叫状态下
    
    if(!isBCalled){
        if(self.address&&[self.address length]>0){
            NSArray *array = [self.address componentsSeparatedByString:@"."];
            [[P2PClient sharedClient] p2pCallWithId:[array objectAtIndex:3] password:callPassword callType:type];
        }else{
            [[P2PClient sharedClient] p2pCallWithId:callId password:callPassword callType:type];
        }
        
    }
    
    
    self.isReject = NO;
    self.isAccept = NO;
   
    // Dispose of any resources that can be recreated.
    
	// Do any additional setup after loading the view.
}

#define CALL_BTN_HEIGHT (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 70:40)
#define ANIM_VIEW_HEIGHT 60
#define HEADER_VIEW_HEIGHT 75
-(void)initComponent{
    
    P2PCallType p2pCallType = [[P2PClient sharedClient] p2pCallType];
    BOOL isBCalled = [[P2PClient sharedClient] isBCalled];
    NSString *callId = [[P2PClient sharedClient] callId];
    
    [self.view setBackgroundColor:XBlack];
    CGRect rect = [AppDelegateYoosee getScreenSize:YES isHorizontal:NO];
    CGFloat width = rect.size.width;
    CGFloat height = rect.size.height;

    TopBar *topBar = [[TopBar alloc] initWithFrame:CGRectMake(0, 0, width, NAVIGATION_BAR_HEIGHT)];
    if(p2pCallType==P2PCALL_TYPE_MONITOR){
        
        [topBar setTitle:self.contactName];
    }else if(p2pCallType==P2PCALL_TYPE_VIDEO){
       
        [topBar setTitle:NSLocalizedString(@"call",nil)];
    }
    
    [self.view addSubview:topBar];
    [topBar release];
    
    DLog(@"screenSize:%f-%f",width,height);

    //accept button
    UIButton *acceptBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *acceptBtnImg = [UIImage imageNamed:@"bg_btn_accept.png"];
    acceptBtnImg = [acceptBtnImg stretchableImageWithLeftCapWidth:acceptBtnImg.size.width*0.5 topCapHeight:acceptBtnImg.size.height*0.5];
    
    UIImage *acceptBtnImg_p = [UIImage imageNamed:@"bg_btn_accept_p.png"];
    acceptBtnImg_p = [acceptBtnImg_p stretchableImageWithLeftCapWidth:acceptBtnImg_p.size.width*0.5 topCapHeight:acceptBtnImg_p.size.height*0.5];
    [acceptBtn setBackgroundImage:acceptBtnImg forState:UIControlStateNormal];
    [acceptBtn setBackgroundImage:acceptBtnImg_p forState:UIControlStateHighlighted];
    
    //reject button
    UIButton *rejectBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *rejectBtnImg = [UIImage imageNamed:@"bg_btn_reject.png"];
    rejectBtnImg = [rejectBtnImg stretchableImageWithLeftCapWidth:rejectBtnImg.size.width*0.5 topCapHeight:rejectBtnImg.size.height*0.5];
    
    UIImage *rejectBtnImg_p = [UIImage imageNamed:@"bg_btn_reject_p.png"];
    rejectBtnImg_p = [rejectBtnImg_p stretchableImageWithLeftCapWidth:rejectBtnImg_p.size.width*0.5 topCapHeight:rejectBtnImg_p.size.height*0.5];
    [rejectBtn setBackgroundImage:rejectBtnImg forState:UIControlStateNormal];
    [rejectBtn setBackgroundImage:rejectBtnImg_p forState:UIControlStateHighlighted];
    UILabel *rejectLabel = [[UILabel alloc] init];
    rejectLabel.textAlignment = NSTextAlignmentCenter;
    rejectLabel.textColor = XWhite;
    rejectLabel.backgroundColor = XBGAlpha;
    [rejectLabel setFont:XFontBold_16];
    rejectLabel.text = NSLocalizedString(@"reject", nil);
     
    UILabel *acceptLabel = [[UILabel alloc] init];
    acceptLabel.frame = CGRectMake(0, 0, width/2-NORMAL_BUTTON_MARGIN_LEFT_AND_RIGHT-NORMAL_BUTTON_MARGIN_LEFT_AND_RIGHT/2, CALL_BTN_HEIGHT);
    acceptLabel.textAlignment = NSTextAlignmentCenter;
    acceptLabel.textColor = XWhite;
    acceptLabel.backgroundColor = XBGAlpha;
    [acceptLabel setFont:XFontBold_16];
    acceptLabel.text = NSLocalizedString(@"accept", nil);
    
    if(p2pCallType==P2PCALL_TYPE_MONITOR){
        rejectBtn.frame = CGRectMake(NORMAL_BUTTON_MARGIN_LEFT_AND_RIGHT, height-CALL_BTN_HEIGHT-10, width-NORMAL_BUTTON_MARGIN_LEFT_AND_RIGHT*2, CALL_BTN_HEIGHT);
        acceptBtn.hidden = YES;
        rejectLabel.frame = CGRectMake(0, 0, width-NORMAL_BUTTON_MARGIN_LEFT_AND_RIGHT*2, CALL_BTN_HEIGHT);
        
    }else if(p2pCallType==P2PCALL_TYPE_VIDEO){
        if(isBCalled){
            rejectBtn.frame = CGRectMake(width/2+NORMAL_BUTTON_MARGIN_LEFT_AND_RIGHT/2, height-CALL_BTN_HEIGHT-10, width/2-NORMAL_BUTTON_MARGIN_LEFT_AND_RIGHT-NORMAL_BUTTON_MARGIN_LEFT_AND_RIGHT/2, CALL_BTN_HEIGHT);
            acceptBtn.hidden = NO;
            rejectLabel.frame = CGRectMake(0, 0, width/2-NORMAL_BUTTON_MARGIN_LEFT_AND_RIGHT-NORMAL_BUTTON_MARGIN_LEFT_AND_RIGHT/2, CALL_BTN_HEIGHT);
        }else{
            rejectBtn.frame = CGRectMake(NORMAL_BUTTON_MARGIN_LEFT_AND_RIGHT, height-CALL_BTN_HEIGHT-10, width-NORMAL_BUTTON_MARGIN_LEFT_AND_RIGHT*2, CALL_BTN_HEIGHT);
            acceptBtn.hidden = YES;
            rejectLabel.frame = CGRectMake(0, 0, width-NORMAL_BUTTON_MARGIN_LEFT_AND_RIGHT*2, CALL_BTN_HEIGHT);
        }
        
    }
    
    
    acceptBtn.frame = CGRectMake(NORMAL_BUTTON_MARGIN_LEFT_AND_RIGHT, height-CALL_BTN_HEIGHT-10, width/2-NORMAL_BUTTON_MARGIN_LEFT_AND_RIGHT-NORMAL_BUTTON_MARGIN_LEFT_AND_RIGHT/2, CALL_BTN_HEIGHT);
         
    
     
    [acceptBtn addSubview:acceptLabel];
    [rejectBtn addSubview:rejectLabel];
    [acceptBtn addTarget:self action:@selector(onAcceptPress:) forControlEvents:UIControlEventTouchUpInside];
    [rejectBtn addTarget:self action:@selector(onRejectPress:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:acceptBtn];
    [self.view addSubview:rejectBtn];
    
    
    UIView *mainView = [[UIView alloc] initWithFrame:CGRectMake(0, NAVIGATION_BAR_HEIGHT, width, acceptBtn.frame.origin.y-NAVIGATION_BAR_HEIGHT)];
    
    
    CGFloat headerViewWidth = HEADER_VIEW_HEIGHT*4/3;
    UIImageView *headerView = [[UIImageView alloc] initWithFrame:CGRectMake((width-headerViewWidth)/2, ((mainView.frame.size.height/2)-HEADER_VIEW_HEIGHT)/2-30, headerViewWidth, HEADER_VIEW_HEIGHT)];
    
    NSString *filePath = [NSString stringWithFormat:@"%@",[Utils getHeaderFilePathWithId:callId]];
    UIImage *headerViewImg = [UIImage imageWithContentsOfFile:filePath];
    
    if(headerViewImg==nil){
        headerViewImg = [UIImage imageNamed:@"ic_header.png"];
    }
    
    headerView.image = headerViewImg;
    headerView.contentMode = UIViewContentModeScaleAspectFit;
    [mainView addSubview:headerView];
    
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, headerView.frame.size.height+headerView.frame.origin.y, width, 30)];
    headerLabel.textAlignment = NSTextAlignmentCenter;
    headerLabel.textColor = XWhite;
    headerLabel.font = XFontBold_14;
    headerLabel.backgroundColor = XBGAlpha;
    if(p2pCallType==P2PCALL_TYPE_VIDEO){
        if(isBCalled){
            headerLabel.text = [NSString stringWithFormat:@"%@%@",NSLocalizedString(@"call_in_prompt", nil),callId];
        }else{
            headerLabel.text = [NSString stringWithFormat:@"%@%@",NSLocalizedString(@"call_out_prompt", nil),callId];
        }
    }else{
//        headerLabel.text = [NSString stringWithFormat:@"%@%@",NSLocalizedString(@"monitor_out_prompt", nil),callId];
        headerLabel.text = NSLocalizedString(@"monitor_out_prompt", nil);
    }
    
    [mainView addSubview:headerLabel];
    [headerLabel release];    [headerView release];
    
    UIImageView *animView = [[UIImageView alloc] initWithFrame:CGRectMake(0, (mainView.frame.size.height/2-ANIM_VIEW_HEIGHT)/2+mainView.frame.size.height/2, width, ANIM_VIEW_HEIGHT)];
    animView.contentMode = UIViewContentModeScaleAspectFit;
    if(p2pCallType==P2PCALL_TYPE_VIDEO){
        NSArray *imagesArray = nil;
        if(isBCalled){
            imagesArray = [NSArray arrayWithObjects:[UIImage imageNamed:@"anim_call_in1.png"],[UIImage imageNamed:@"anim_call_in2.png"],[UIImage imageNamed:@"anim_call_in3.png"],nil];
        }else{
            imagesArray = [NSArray arrayWithObjects:[UIImage imageNamed:@"anim_call_out1.png"],[UIImage imageNamed:@"anim_call_out2.png"],[UIImage imageNamed:@"anim_call_out3.png"],nil];
        }
        
        animView.animationImages = imagesArray;
        animView.animationDuration = ((CGFloat)[imagesArray count])*400.0f/1000.0f;
        animView.animationRepeatCount = 0;
        [animView startAnimating];
    }else{
        NSArray *imagesArray = [NSArray arrayWithObjects:[UIImage imageNamed:@"anim_monitor1.png"],[UIImage imageNamed:@"anim_monitor2.png"],[UIImage imageNamed:@"anim_monitor3.png"],nil];
        animView.animationImages = imagesArray;
        animView.animationDuration = ((CGFloat)[imagesArray count])*400.0f/1000.0f;
        animView.animationRepeatCount = 0;
        [animView startAnimating];
    }
    
    
    [mainView addSubview:animView];
    [animView release];
    [self.view addSubview:mainView];
    [mainView release];
    
    [acceptLabel release];
    [rejectLabel release];
    
}
     
-(void)onAcceptPress:(id)sender{
    if(!self.isAccept){
        self.isAccept = YES;
        [[P2PClient sharedClient] p2pAccept];
    }
}
     
-(void)onRejectPress:(id)sender{
    if(!self.isReject){
        self.isReject = YES;
        [[P2PClient sharedClient] p2pHungUp];
        if ([AppDelegateYoosee sharedDefault].isMonitoring) {//监控、视频通话或呼叫状态下主动挂断
            [AppDelegateYoosee sharedDefault].isMonitoring = NO;//挂断，不处于监控状态
            [AppDelegateYoosee sharedDefault].isHungUpActively = YES;
        }
        
    }
    MainController *mainController = [AppDelegateYoosee sharedDefault].mainController;
    [mainController dismissP2PView];
}

     


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
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
