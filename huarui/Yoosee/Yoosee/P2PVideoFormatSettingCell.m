//
//  P2PVideoFormatSettingCell.m
//  Yoosee
//
//  Created by guojunyi on 14-5-14.
//  Copyright (c) 2014年 guojunyi. All rights reserved.
//

#import "P2PVideoFormatSettingCell.h"
#import "Constants.h"
#import "RadioButton.h"
@implementation P2PVideoFormatSettingCell
-(void)dealloc{
    [self.leftLabelText release];
    [self.leftLabelView release];
    [self.rightLabelText release];
    [self.rightLabelView release];
    [self.customView release];
    [self.progressView release];
    [self.radio1 release];
    [self.radio2 release];
    [super dealloc];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

#define LEFT_LABEL_WIDTH 150
#define PROGRESS_WIDTH_HEIGHT 32
-(void)layoutSubviews{
    [super layoutSubviews];
    CGFloat cellWidth = self.backgroundView.frame.size.width;
    CGFloat cellHeight = self.backgroundView.frame.size.height;
    
    if(!self.leftLabelView){
        UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(30, 0, LEFT_LABEL_WIDTH, BAR_BUTTON_HEIGHT)];
        textLabel.textAlignment = NSTextAlignmentLeft;
        textLabel.textColor = XBlack;
        textLabel.backgroundColor = XBGAlpha;
        [textLabel setFont:XFontBold_16];
        textLabel.text = self.leftLabelText;
        [self.contentView addSubview:textLabel];
        self.leftLabelView = textLabel;
        [textLabel release];
        [self.leftLabelView setHidden:self.isLeftLabelHidden];
    }else{
        self.leftLabelView.frame = CGRectMake(30, 0, LEFT_LABEL_WIDTH, BAR_BUTTON_HEIGHT);
        self.leftLabelView.textAlignment = NSTextAlignmentLeft;
        self.leftLabelView.textColor = XBlack;
        self.leftLabelView.backgroundColor = XBGAlpha;
        [self.leftLabelView setFont:XFontBold_16];
        self.leftLabelView.text = self.leftLabelText;
        [self.contentView addSubview:self.leftLabelView];
        [self.leftLabelView setHidden:self.isLeftLabelHidden];
    }
    
    
    if(!self.rightLabelView){
        UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(30+LEFT_LABEL_WIDTH, 0, cellWidth-30*2-LEFT_LABEL_WIDTH, BAR_BUTTON_HEIGHT)];
        textLabel.textAlignment = NSTextAlignmentRight;
        textLabel.textColor = XBlue;
        textLabel.backgroundColor = XBGAlpha;
        [textLabel setFont:XFontBold_14];
        textLabel.text = self.rightLabelText;
        [self.contentView addSubview:textLabel];
        self.rightLabelView = textLabel;
        [textLabel release];
        [self.rightLabelView setHidden:self.isRightLabelHidden];
    }else{
        self.rightLabelView.frame = CGRectMake(30+LEFT_LABEL_WIDTH, 0, cellWidth-30*2-LEFT_LABEL_WIDTH, BAR_BUTTON_HEIGHT);
        self.rightLabelView.textAlignment = NSTextAlignmentRight;
        self.rightLabelView.textColor = XBlue;
        self.rightLabelView.backgroundColor = XBGAlpha;
        [self.rightLabelView setFont:XFontBold_14];
        self.rightLabelView.text = self.rightLabelText;
        [self.contentView addSubview:self.rightLabelView];
        [self.rightLabelView setHidden:self.isRightLabelHidden];
    }
    
    if(!self.customView){
        DLog(@"%f %f",cellWidth,cellHeight);
        UIView *customView = [[UIView alloc] initWithFrame:CGRectMake(30,5, cellWidth-30*2, cellHeight-5*2)];
        
        RadioButton *radio1 = [[RadioButton alloc] initWithFrame:CGRectMake(0, (customView.frame.size.height-40)/2, customView.frame.size.width/2, 40)];
        
        
        RadioButton *radio2 = [[RadioButton alloc] initWithFrame:CGRectMake(customView.frame.size.width/2, (customView.frame.size.height-40)/2, customView.frame.size.width/2, 40)];
        
        [radio1 setText:NSLocalizedString(@"video_format_pal", nil)];
        [radio2 setText:NSLocalizedString(@"video_format_ntsc", nil)];
        [customView addSubview:radio1];
        [customView addSubview:radio2];
        
        self.radio1 = radio1;
        self.radio2 = radio2;
        [radio1 release];
        [radio2 release];
        
        self.customView = customView;
        
        [customView release];
        [self.contentView addSubview:self.customView];
        
        [self.customView setHidden:self.isCustomViewHidden];
        
        
    }else{
        
        self.customView.frame = CGRectMake(30,5, cellWidth-30*2, cellHeight-5*2);
        self.radio1.frame = CGRectMake(0, (self.customView.frame.size.height-40)/2, self.customView.frame.size.width/2, 40);
        self.radio2.frame = CGRectMake(self.customView.frame.size.width/2, (self.customView.frame.size.height-40)/2, self.customView.frame.size.width/2, 40);
        [self.contentView addSubview:self.customView];
        
        [self.customView setHidden:self.isCustomViewHidden];
        
    }
    
    if(!self.progressView){
        UIActivityIndicatorView *progressView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        progressView.frame = CGRectMake(cellWidth-30-PROGRESS_WIDTH_HEIGHT, (cellHeight-PROGRESS_WIDTH_HEIGHT)/2, PROGRESS_WIDTH_HEIGHT, PROGRESS_WIDTH_HEIGHT);
        [self.contentView addSubview:progressView];
        [progressView startAnimating];
        self.progressView = progressView;
        [progressView release];
        [self.progressView setHidden:self.isProgressViewHidden];
    }else{
        self.progressView.frame = CGRectMake(cellWidth-30-PROGRESS_WIDTH_HEIGHT, (cellHeight-PROGRESS_WIDTH_HEIGHT)/2, PROGRESS_WIDTH_HEIGHT, PROGRESS_WIDTH_HEIGHT);
        [self.contentView addSubview:self.progressView];
        [self.progressView startAnimating];
        [self.progressView setHidden:self.isProgressViewHidden];
    }
    
    if(self.selectedIndex==0){
        [self.radio1 setSelected:YES];
        [self.radio2 setSelected:NO];
    }else if(self.selectedIndex==1){
        [self.radio1 setSelected:NO];
        [self.radio2 setSelected:YES];
    }
}

-(void)setProgressViewHidden:(BOOL)hidden{
    self.isProgressViewHidden = hidden;
    if(self.progressView){
        [self.progressView setHidden:hidden];
    }
}

-(void)setLeftLabelHidden:(BOOL)hidden{
    self.isLeftLabelHidden = hidden;
    if(self.leftLabelView){
        [self.leftLabelView setHidden:hidden];
    }
}

-(void)setRightLabelHidden:(BOOL)hidden{
    self.isRightLabelHidden = hidden;
    if(self.rightLabelView){
        [self.rightLabelView setHidden:hidden];
    }
}

-(void)setCustomViewHidden:(BOOL)hidden{
    self.isCustomViewHidden = hidden;
    if(self.customView){
        [self.customView setHidden:hidden];
    }
}

@end
