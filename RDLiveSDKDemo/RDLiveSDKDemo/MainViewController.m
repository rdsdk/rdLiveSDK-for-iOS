//
//  MainViewController.m
//  RDLiveSDKDemo
//
//  Created by Wuxiaoxia on 2017/1/17.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "MainViewController.h"
#import "RDLiveSDK.h"
#import "RDRTMPPlayer.h"
#import "LiveViewController.h"
#import "LivePlayerViewController.h"
#import "AppDelegate.h"

#define RDServerStr @"使用锐动服务器"
#define ThirdPartyServerStr @"使用第三方服务器"

@interface MainViewController ()<UITextFieldDelegate, UIAlertViewDelegate>
{
    UILabel         * hintLbl;
    UITextField     * contentTextField;
    UIView          * selectedServerView;
    UIButton        * useRDServerBtn;
    UIButton        * useThirdPartyServerBtn;
    
    UIView          * setLiveParasBackView;
    UIButton        * highQualityBtn;
    UIButton        * mediumQualityBtn;
    
    UIButton        * frontCameraBtn;
    UIButton        * backCameraBtn;
    
    UIButton        * openBeautyBtn;
    UIButton        * closeBeautyBtn;
}

@end

@implementation MainViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController.navigationBar setHidden:NO];
    [self.navigationController.navigationBar setTranslucent:NO];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:EVER_LAUCHED];
    self.title = RDServerStr;
    self.view.backgroundColor = [UIColor whiteColor];
    
    hintLbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 100, 30)];
    hintLbl.backgroundColor = [UIColor clearColor];
    hintLbl.text = @"UID:";
    hintLbl.textColor = [UIColor blackColor];
    [self.view addSubview:hintLbl];
    
    //使用锐动服务器时，请输入直播UID
    //使用第三方服务器时，请输入直播地址
    contentTextField = [[UITextField alloc]initWithFrame:CGRectMake(10, 40, SCREEN_WIDTH - 20, 40)];
    contentTextField.backgroundColor = [UIColor clearColor];
    contentTextField.layer.borderWidth = 1.0;
    contentTextField.layer.borderColor = UIColorFromRGB(CommonColor).CGColor;
    contentTextField.layer.cornerRadius = 5.0;
    contentTextField.font = [UIFont systemFontOfSize:16.0];
    contentTextField.textColor = [UIColor blackColor];
    contentTextField.textAlignment = NSTextAlignmentLeft;
    contentTextField.placeholder = @"请输入UID(数字或小写字母、3-32个字节)";
    contentTextField.returnKeyType = UIReturnKeyDone;
    contentTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    contentTextField.delegate = self;
    [self.view addSubview:contentTextField];
    
    UIButton *liveBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    liveBtn.frame = CGRectMake(20, (SCREEN_HEIGHT - 64 - 40)/2 - 50, (SCREEN_WIDTH - 20*3)/2, 40);
    liveBtn.backgroundColor = UIColorFromRGB(CommonColor);
    liveBtn.layer.masksToBounds = YES;
    liveBtn.layer.cornerRadius = 5.0;
    liveBtn.titleLabel.font = [UIFont systemFontOfSize:19];
    [liveBtn setTitle:@"发起直播" forState:UIControlStateNormal];
    liveBtn.tag = 11;
    [liveBtn addTarget:self action:@selector(liveOrPlayBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:liveBtn];
    
    UIButton *playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    playBtn.frame = CGRectMake(SCREEN_WIDTH - (SCREEN_WIDTH - 20*3)/2 - 20, (SCREEN_HEIGHT - 64 - 40)/2 - 50, (SCREEN_WIDTH - 20*3)/2, 40);
    playBtn.backgroundColor = UIColorFromRGB(CommonColor);
    playBtn.layer.masksToBounds = YES;
    playBtn.layer.cornerRadius = 5.0;
    playBtn.titleLabel.font = [UIFont systemFontOfSize:19];
    [playBtn setTitle:@"看直播" forState:UIControlStateNormal];
    playBtn.tag = 12;
    [playBtn addTarget:self action:@selector(liveOrPlayBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:playBtn];
    
    UIView *spanView = [[UIView alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT - 64 - 51, SCREEN_WIDTH, 3)];
    spanView.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:spanView];
    
    selectedServerView = [[UIView alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT - 64 - 51, SCREEN_WIDTH/2, 3)];
    selectedServerView.backgroundColor = UIColorFromRGB(CommonColor);
    [self.view addSubview:selectedServerView];
    
    //使用锐动服务器
    useRDServerBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    useRDServerBtn.frame = CGRectMake(0, SCREEN_HEIGHT - 64 - 50, SCREEN_WIDTH/2, 50);
    useRDServerBtn.backgroundColor = [UIColor clearColor];
    [useRDServerBtn setTitle:RDServerStr forState:UIControlStateNormal];
    [useRDServerBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [useRDServerBtn setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
    useRDServerBtn.titleLabel.font = [UIFont systemFontOfSize:17.0];
    useRDServerBtn.selected = YES;
    useRDServerBtn.tag = 21;
    [useRDServerBtn addTarget:self action:@selector(serverSelectBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:useRDServerBtn];
    
    //使用第三方服务器
    useThirdPartyServerBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    useThirdPartyServerBtn.frame = CGRectMake(SCREEN_WIDTH/2, SCREEN_HEIGHT - 64 - 50, SCREEN_WIDTH/2, 50);
    useThirdPartyServerBtn.backgroundColor = [UIColor clearColor];
    [useThirdPartyServerBtn setTitle:ThirdPartyServerStr forState:UIControlStateNormal];
    [useThirdPartyServerBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [useThirdPartyServerBtn setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
    useThirdPartyServerBtn.titleLabel.font = [UIFont systemFontOfSize:17.0];
    useThirdPartyServerBtn.tag = 22;
    [useThirdPartyServerBtn addTarget:self action:@selector(serverSelectBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:useThirdPartyServerBtn];
    
    [self initSetLiveParasView];
}

- (void)initSetLiveParasView {
    setLiveParasBackView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT - 64)];
    setLiveParasBackView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    setLiveParasBackView.hidden = YES;
    [self.view addSubview:setLiveParasBackView];
    
    UIView *setLiveParasView = [[UIView alloc] initWithFrame:CGRectMake(20, (SCREEN_HEIGHT - 64 - 300)/2, SCREEN_WIDTH - 40, 300)];
    setLiveParasView.backgroundColor = [UIColor whiteColor];
    setLiveParasView.layer.cornerRadius = 5.0;
    setLiveParasView.layer.masksToBounds = YES;
    [setLiveParasBackView addSubview:setLiveParasView];
    
    UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, setLiveParasView.frame.size.width, 40)];
    titleLbl.backgroundColor = [UIColor clearColor];
    titleLbl.text = @"直播设置";
    titleLbl.font = [UIFont boldSystemFontOfSize:19.0];
    titleLbl.textColor = [UIColor blackColor];
    titleLbl.textAlignment = NSTextAlignmentCenter;
    [setLiveParasView addSubview:titleLbl];
    
    UIView *spanView1 = [[UIView alloc] initWithFrame:CGRectMake(0, 40, setLiveParasView.frame.size.width, 1)];
    spanView1.backgroundColor = [UIColor lightGrayColor];
    [setLiveParasView addSubview:spanView1];
    
    UILabel *qualityLbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 50, 100, 30)];
    qualityLbl.backgroundColor = [UIColor clearColor];
    qualityLbl.text = @"清晰度选择:";
    qualityLbl.font = [UIFont systemFontOfSize:17.0];
    qualityLbl.textColor = [UIColor blackColor];
    [setLiveParasView addSubview:qualityLbl];
    
    highQualityBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    highQualityBtn.frame = CGRectMake(110, 50, 50, 30);
    highQualityBtn.backgroundColor = [UIColor clearColor];
    [highQualityBtn setTitle:@"高清" forState:UIControlStateNormal];
    [highQualityBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    highQualityBtn.titleLabel.font = [UIFont systemFontOfSize:17.0];
    [highQualityBtn setImage:[UIImage imageNamed:@"选项未选中"] forState:UIControlStateNormal];
    [highQualityBtn setImage:[UIImage imageNamed:@"选项选中"] forState:UIControlStateSelected];
    highQualityBtn.tag = 31;
    highQualityBtn.selected = YES;
    [highQualityBtn addTarget:self action:@selector(qualityBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [setLiveParasView addSubview:highQualityBtn];
    
    mediumQualityBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    mediumQualityBtn.frame = CGRectMake(110 + 70, 50, 50, 30);
    mediumQualityBtn.backgroundColor = [UIColor clearColor];
    [mediumQualityBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    mediumQualityBtn.titleLabel.font = [UIFont systemFontOfSize:17.0];
    [mediumQualityBtn setTitle:@"标清" forState:UIControlStateNormal];
    [mediumQualityBtn setImage:[UIImage imageNamed:@"选项未选中"] forState:UIControlStateNormal];
    [mediumQualityBtn setImage:[UIImage imageNamed:@"选项选中"] forState:UIControlStateSelected];
    mediumQualityBtn.tag = 32;
    [mediumQualityBtn addTarget:self action:@selector(qualityBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [setLiveParasView addSubview:mediumQualityBtn];
    
    UILabel *cameraLbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 50 + 40, 100, 30)];
    cameraLbl.backgroundColor = [UIColor clearColor];
    cameraLbl.text = @"摄像头选择:";
    cameraLbl.font = [UIFont systemFontOfSize:17.0];
    cameraLbl.textColor = [UIColor blackColor];
    [setLiveParasView addSubview:cameraLbl];
    
    frontCameraBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    frontCameraBtn.frame = CGRectMake(110, 50 + 40, 50, 30);
    frontCameraBtn.backgroundColor = [UIColor clearColor];
    [frontCameraBtn setTitle:@"前置" forState:UIControlStateNormal];
    [frontCameraBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    frontCameraBtn.titleLabel.font = [UIFont systemFontOfSize:17.0];
    [frontCameraBtn setImage:[UIImage imageNamed:@"选项未选中"] forState:UIControlStateNormal];
    [frontCameraBtn setImage:[UIImage imageNamed:@"选项选中"] forState:UIControlStateSelected];
    frontCameraBtn.tag = 41;
    frontCameraBtn.selected = YES;
    [frontCameraBtn addTarget:self action:@selector(cameraBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [setLiveParasView addSubview:frontCameraBtn];
    
    backCameraBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    backCameraBtn.frame = CGRectMake(110 + 70, 50 + 40, 50, 30);
    backCameraBtn.backgroundColor = [UIColor clearColor];
    [backCameraBtn setTitle:@"后置" forState:UIControlStateNormal];
    [backCameraBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    backCameraBtn.titleLabel.font = [UIFont systemFontOfSize:17.0];
    [backCameraBtn setImage:[UIImage imageNamed:@"选项未选中"] forState:UIControlStateNormal];
    [backCameraBtn setImage:[UIImage imageNamed:@"选项选中"] forState:UIControlStateSelected];
    backCameraBtn.tag = 42;
    [backCameraBtn addTarget:self action:@selector(cameraBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [setLiveParasView addSubview:backCameraBtn];
    
    UILabel *beautyLbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 50 + 40*2, 100, 30)];
    beautyLbl.backgroundColor = [UIColor clearColor];
    beautyLbl.text = @"美颜选择:";
    beautyLbl.font = [UIFont systemFontOfSize:17.0];
    beautyLbl.textColor = [UIColor blackColor];
    [setLiveParasView addSubview:beautyLbl];
    
    openBeautyBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    openBeautyBtn.frame = CGRectMake(110, 50 + 40*2, 50, 30);
    openBeautyBtn.backgroundColor = [UIColor clearColor];
    [openBeautyBtn setTitle:@"开启" forState:UIControlStateNormal];
    [openBeautyBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    openBeautyBtn.titleLabel.font = [UIFont systemFontOfSize:17.0];
    [openBeautyBtn setImage:[UIImage imageNamed:@"选项未选中"] forState:UIControlStateNormal];
    [openBeautyBtn setImage:[UIImage imageNamed:@"选项选中"] forState:UIControlStateSelected];
    openBeautyBtn.tag = 51;
    openBeautyBtn.selected = YES;
    [openBeautyBtn addTarget:self action:@selector(beautyBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [setLiveParasView addSubview:openBeautyBtn];
    
    closeBeautyBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBeautyBtn.frame = CGRectMake(110 + 70, 50 + 40*2, 50, 30);
    closeBeautyBtn.backgroundColor = [UIColor clearColor];
    [closeBeautyBtn setTitle:@"关闭" forState:UIControlStateNormal];
    [closeBeautyBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    closeBeautyBtn.titleLabel.font = [UIFont systemFontOfSize:17.0];
    [closeBeautyBtn setImage:[UIImage imageNamed:@"选项未选中"] forState:UIControlStateNormal];
    [closeBeautyBtn setImage:[UIImage imageNamed:@"选项选中"] forState:UIControlStateSelected];
    closeBeautyBtn.tag = 52;
    [closeBeautyBtn addTarget:self action:@selector(beautyBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [setLiveParasView addSubview:closeBeautyBtn];
    
    UIView *spanView2 = [[UIView alloc] initWithFrame:CGRectMake(0, setLiveParasView.frame.size.height - 41, setLiveParasView.frame.size.width, 1)];
    spanView2.backgroundColor = [UIColor lightGrayColor];
    [setLiveParasView addSubview:spanView2];
    
    UIButton *confirmBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    confirmBtn.frame = CGRectMake(0, setLiveParasView.frame.size.height - 40, setLiveParasView.frame.size.width/2 - 0.5, 40);
    confirmBtn.backgroundColor = UIColorFromRGB(CommonColor);
    [confirmBtn setTitle:@"确认" forState:UIControlStateNormal];
    [confirmBtn addTarget:self action:@selector(confirmBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [setLiveParasView addSubview:confirmBtn];
    
    UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelBtn.frame = CGRectMake(setLiveParasView.frame.size.width/2 + 0.5, setLiveParasView.frame.size.height - 40, setLiveParasView.frame.size.width/2 - 0.5, 40);
    cancelBtn.backgroundColor = UIColorFromRGB(CommonColor);
    [cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
    [cancelBtn addTarget:self action:@selector(cancelBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [setLiveParasView addSubview:cancelBtn];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [contentTextField resignFirstResponder];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return YES;
}

#pragma mark - 按钮事件
- (void)serverSelectBtnAction:(UIButton *)sender {
    self.title = sender.titleLabel.text;
    if (sender.tag == 21) {
        useRDServerBtn.selected = YES;
        useThirdPartyServerBtn.selected = NO;
        hintLbl.text = @"UID:";
        contentTextField.placeholder = @"请输入UID(数字或小写字母、3-32个字节)";
        contentTextField.text = @"";
    }else {
        useRDServerBtn.selected = NO;
        useThirdPartyServerBtn.selected = YES;
        hintLbl.text = @"URL:";
        contentTextField.placeholder = @"请输入rtmp流地址";
        contentTextField.text = @"rtmp://";
    }
    
    CGRect newFrame = selectedServerView.frame;
    newFrame.origin.x = sender.frame.origin.x;
    selectedServerView.frame = newFrame;
}

- (void)liveOrPlayBtnAction:(UIButton *)sender {
    [contentTextField resignFirstResponder];
    
    if (sender.tag == 11) {
        setLiveParasBackView.hidden = NO;
    }else {
        if (contentTextField.text.length == 0) {
            NSString *message;
            if (useRDServerBtn.selected) {
                message = @"请输入UID(数字或小写字母、3-32个字节)";
            }else {
                message = @"请输入rtmp/rtsp流地址";
            }
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@""
                                                                message:message
                                                               delegate:nil
                                                      cancelButtonTitle:@"确定"
                                                      otherButtonTitles:nil];
            [alertView show];
        }else {
            LivePlayerViewController *livePlayerVC = [[LivePlayerViewController alloc] init];
            if (useRDServerBtn.selected) {
                livePlayerVC.isWatchUidLive = YES;
                livePlayerVC.userID = contentTextField.text;
            }else {
                livePlayerVC.isWatchUidLive = NO;
                NSURL *url = [NSURL URLWithString:contentTextField.text];
                if ([[url scheme] isEqualToString:@"rtmp"]) {//rtmp://
                    livePlayerVC.rtmpUrl = contentTextField.text;
                }else {//rtsp://
                    livePlayerVC.rtspUrl = contentTextField.text;
                }
            }
            
            [self performSelector:@selector(pushNextViewController:) withObject:livePlayerVC afterDelay:0.25];
        }
    }
}

- (void)qualityBtnAction:(UIButton *)sender {
    if (sender.tag == 31) {
        highQualityBtn.selected = YES;
        mediumQualityBtn.selected = NO;
    }else {
        highQualityBtn.selected = NO;
        mediumQualityBtn.selected = YES;
    }
}

- (void)cameraBtnAction:(UIButton *)sender {
    if (sender.tag == 41) {
        frontCameraBtn.selected = YES;
        backCameraBtn.selected = NO;
    }else {
        frontCameraBtn.selected = NO;
        backCameraBtn.selected = YES;
    }
}

- (void)beautyBtnAction:(UIButton *)sender {
    if (sender.tag == 51) {
        openBeautyBtn.selected = YES;
        closeBeautyBtn.selected = NO;
    }else {
        openBeautyBtn.selected = NO;
        closeBeautyBtn.selected = YES;
    }
}

- (void)confirmBtnAction:(UIButton *)sender {
    setLiveParasBackView.hidden = YES;
    if (contentTextField.text.length == 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@""
                                                            message:@"请输入直播地址"
                                                           delegate:nil
                                                  cancelButtonTitle:@"确定"
                                                  otherButtonTitles:nil];
        [alertView show];
    }else {
        LiveViewController *liveVC = [[LiveViewController alloc] init];
        if (useRDServerBtn.selected) {
            liveVC.isUidLive = YES;
            liveVC.userID = contentTextField.text;
        }else {
            liveVC.isUidLive = NO;
            liveVC.rtmpUrl = contentTextField.text;
        }
        liveVC.isHighQuality = highQualityBtn.selected;
        liveVC.isFrontCamera = frontCameraBtn.selected;
        liveVC.isOpenBeauty = openBeautyBtn.selected;
        [self performSelector:@selector(pushNextViewController:) withObject:liveVC afterDelay:0.25];
    }
}

- (void)cancelBtnAction:(UIButton *)sender {
    setLiveParasBackView.hidden = YES;
}

- (void)pushNextViewController:(id)nextViewController {
    [self presentViewController:nextViewController animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
