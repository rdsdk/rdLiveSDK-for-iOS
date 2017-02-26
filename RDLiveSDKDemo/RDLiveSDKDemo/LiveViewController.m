//
//  LiveViewController.m
//  RDLiveSDKDemo
//
//  Created by Wuxiaoxia on 16/5/15.
//  Copyright © 2016年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "LiveViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import <AVFoundation/AVAsset.h>
#import <CoreMotion/CoreMotion.h>
#import "AppDelegate.h"
#import "RDLiveSDK.h"

#define kFacueBtnTag    100

const NSUInteger    filterNumImages	= 7;
const int           videoFrameRate_default = 15;
const int           videoBitRate_high = 600*1000;
const int           videoBitRate_low = 400*1000;

@interface LiveViewController () <RDRtmpPublishDelegate, UITextFieldDelegate, UIAlertViewDelegate, UITableViewDelegate, UITableViewDataSource>
{
    CMMotionManager                 * motionManager;
    UIDeviceOrientation               lastOrientation;
    UIDeviceOrientation               livingOrientation;
    AppDelegate                     * appDelegate;
    NSInteger                         filterIndex;
    UIView                          * topView;
    UIButton                        * torchBtn;
    UIButton                        * beautyBtn;
    UIButton                        * backBtn;
    UIView                          * bottomView;
    UIView                          * setBeautyLevelView;
    float                             beautyViewHeight;
    UILabel                         * beautyLbl;
    UISlider                        * beautySlider;
    NSInteger                         beautyLevel;
    UIButton                        * beautyConfirmBtn;
    UIView                          * hintView;
    UIButton                        * liveBtn;
    UITextField                     * liveTitleTF;
    UIView                          * previewView;
    UIImageView                     * upBack;
    BOOL                              isRecording;
    BOOL                              isStopLive;
    NSTimer                         * reStartLiveTimer; //网络不佳等导致的直播失败时，重新直播Timer
    double                            reStartLiveTime;
    int                               reStartSenconds;
    BOOL                              isBackground;
    BOOL                              isBeginLive;
    
    UIButton                        * audioBtn;
    AVAudioPlayer                   * audioPlayer;
    UIButton                        * musicBtn;
    UIView                          * musicView;
    UITableView                     * musicTableView;
    NSMutableArray                  * musicArray;
    NSInteger                         selectedMusicIndex;
    UIButton                        * screenShotBtn;
    UIButton                        * setFacueBtn;
    UIView                          * facueView;
    UIButton                        * hideFacueViewBtn;
    UIView                          * selectedFacueView;
    int                               selectedFacueIndex;
    UIButton                        * waterMarkBtn;
    
    UIView                          * orientationHintView;
}

@property (nonatomic, strong) RDLiveSDK     * rdLiveSDK;
@property (nonatomic, assign) int             videoBitRate;
@property (nonatomic, assign) CGSize          videoOutputSize;

@end

@implementation LiveViewController

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [UIView setAnimationsEnabled:NO];//禁止横竖屏切换动画
    [self.navigationController.navigationBar setHidden:YES];
    [self.navigationController.navigationBar setTranslucent:NO];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    UIApplication *app = [UIApplication sharedApplication];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(pressHome:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:app];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(becomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:app];
    appDelegate.allowRotation = YES;
    [self observeOrientation];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [UIView setAnimationsEnabled:YES];//恢复动画
    [motionManager stopAccelerometerUpdates];
    motionManager = nil;
    appDelegate.allowRotation = NO;
    [UIApplication sharedApplication].idleTimerDisabled = NO;//自动锁屏
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideSetBeautyView) object:nil];
    if (isRecording) {
        isRecording = NO;
        [_rdLiveSDK endPublish];
    }else {
        [_rdLiveSDK stopCamera];//没开始直播，但已开启摄像头，需要关闭摄像头
    }
    if (reStartLiveTimer) {
        [reStartLiveTimer invalidate];
        reStartLiveTimer = nil;
    }
    _rdLiveSDK.delegate = nil;
    _rdLiveSDK = nil;
    
    if (audioPlayer && audioPlayer.isPlaying) {
        [audioPlayer stop];
    }
    audioPlayer = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    isBackground = NO;
    isRecording = NO;
    isStopLive = NO;
    filterIndex = 1;
    beautyLevel = 2;//默认美颜强度为2
    selectedFacueIndex = 0;
    lastOrientation = UIDeviceOrientationPortrait;
    
    [self getLiveConfigure];
    [self initPreviewView];
    [self initTopView];
    [self initMainView];
    [self initBeautySlider];
    [self initBottomView];
    [self initFacueView];
    [self initMusicView];
    
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"isFrist"] isEqualToString:@"1"]) {
        [[NSUserDefaults standardUserDefaults] setObject:@"0" forKey:@"isFrist"];
        [self initHintView];
    }
}

#pragma mark - 初始化
- (void)initTopView {
    topView = [[UIView alloc]initWithFrame:CGRectMake(0, 20, SCREEN_WIDTH, 44)];
    topView.backgroundColor = [UIColor clearColor];
    topView.userInteractionEnabled = YES;
    [self.view addSubview:topView];
    
    //切换前／后置摄像头
    UIButton *switchCameraBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    switchCameraBtn.frame = CGRectMake(15, 2, 40, 40);
    [switchCameraBtn setBackgroundImage:[UIImage imageNamed:@"直播_镜头翻转默认"] forState:UIControlStateNormal];
    [switchCameraBtn setBackgroundImage:[UIImage imageNamed:@"直播_镜头翻转点击"] forState:UIControlStateHighlighted];
    [switchCameraBtn addTarget:self action:@selector(switchCameraBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [topView addSubview:switchCameraBtn];
    
    //开启／关闭闪光灯
    torchBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    torchBtn.frame = CGRectMake(10 + 40 + 20, 2, 40, 40);
    [torchBtn setBackgroundImage:[UIImage imageNamed:@"直播_闪光关闭默认"] forState:UIControlStateNormal];
    [torchBtn setBackgroundImage:[UIImage imageNamed:@"直播_闪光关闭点击"] forState:UIControlStateHighlighted];
    [torchBtn addTarget:self action:@selector(torchBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [topView addSubview:torchBtn];
    
    //1.开启美颜，设置美颜强度 2.关闭美颜
    beautyBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    if (_isFrontCamera) {
        torchBtn.hidden = YES;
        beautyBtn.frame = CGRectMake(10 + 40 + 20, 2, 40, 40);
    }else {
        beautyBtn.frame = CGRectMake(10 + (40 + 20)*2, 2, 40, 40);
    }
    if (_isOpenBeauty) {
        [beautyBtn setBackgroundImage:[UIImage imageNamed:@"直播_美颜已选"] forState:UIControlStateNormal];
    }else {
        [beautyBtn setBackgroundImage:[UIImage imageNamed:@"直播_美颜默认"] forState:UIControlStateNormal];
    }
    [beautyBtn addTarget:self action:@selector(beautyBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [topView addSubview:beautyBtn];
    
    backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    backBtn.frame = CGRectMake(SCREEN_WIDTH - 40, 2, 40, 40);
    [backBtn setImage:[UIImage imageNamed:@"主界面-返回默认"] forState:UIControlStateNormal];
    [backBtn setImage:[UIImage imageNamed:@"主界面-返回点击"] forState:UIControlStateHighlighted];
    [backBtn addTarget:self action:@selector(backToTopVC) forControlEvents:UIControlEventTouchUpInside];
    [topView addSubview:backBtn];
}

- (void)initMainView{
    if (_isUidLive) {
        //使用锐动服务器时，需设置直播标题
        liveTitleTF = [[UITextField alloc]initWithFrame:CGRectMake(10, (SCREEN_HEIGHT/2 - 30)/2, SCREEN_WIDTH - 20, 30)];
        liveTitleTF.backgroundColor = [UIColor clearColor];
        liveTitleTF.textColor = [UIColor whiteColor];
        liveTitleTF.textAlignment = NSTextAlignmentCenter;
        liveTitleTF.placeholder = @"给你的直播写个标题吧";
        liveTitleTF.returnKeyType = UIReturnKeyDone;
        liveTitleTF.delegate = self;
        [self.view addSubview:liveTitleTF];
    }
    
    //开始直播
    liveBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    liveBtn.frame = CGRectMake((SCREEN_WIDTH - 145)/2, (SCREEN_HEIGHT - 44)/2, 145, 44);
    [liveBtn setBackgroundColor:UIColorFromRGB(CommonColor)];
    liveBtn.layer.cornerRadius = 22;
    [liveBtn setTitle:@"开始直播" forState:UIControlStateNormal];
    [liveBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    liveBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [liveBtn addTarget:self action:@selector(liveBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:liveBtn];
#if 0
    //左右滑动屏幕切换滤镜
    UISwipeGestureRecognizer *filterGesture = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipeFrom:)];
    [filterGesture setDirection:(UISwipeGestureRecognizerDirectionRight)];
    [self.view addGestureRecognizer:filterGesture];
    
    filterGesture = nil;
    filterGesture = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipeFrom:)];
    [filterGesture setDirection:(UISwipeGestureRecognizerDirectionLeft)];
    [self.view addGestureRecognizer:filterGesture];
#endif
}

- (void)getLiveConfigure {
    if (_isHighQuality) {
        _videoOutputSize = CGSizeMake(360, 640);
        _videoBitRate = videoBitRate_high;
    }else {
        _videoOutputSize = CGSizeMake(180, 320);
        _videoBitRate = videoBitRate_low;
    }
    NSLog(@"直播配置:\n分辨率:%0.f*%0.f\n帧率:%d\n码率:%d\n", _videoOutputSize.width, _videoOutputSize.height, videoFrameRate_default, _videoBitRate);
}

//预览视图
- (void)initPreviewView{
    previewView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    [self.view addSubview:previewView];

    _rdLiveSDK = [[RDLiveSDK alloc] initWithAPPKey:APPKEY
                                      andSecretKey:SECRETKEY
                                           success:^(RDLiveAuthorizationType authType) {
                                               switch (authType) {
                                                   case RDLive_AT_URL:
                                                       NSLog(@"基础功能:推流到第三方服务器(只Url直播可用)");
                                                       break;
                                                       
                                                   case RDLive_AT_UID:
                                                       NSLog(@"云服务:推流到锐动服务器(只Uid直播可用)");
                                                       break;
                                                       
                                                   case RDLive_AT_URL_OR_UID:
                                                       NSLog(@"基础功能、云服务均可(Url、Uid直播均可用)");
                                                       break;
                                                       
                                                   default:
                                                       break;
                                               }
                                           } error:^(NSError *error) {
                                               NSLog(@"initRDLiveSDK error:%@", error.localizedDescription);
                                           }];
    [_rdLiveSDK preparePublishWithFrame:previewView.bounds
                              videoSize:_videoOutputSize
                                bitrate:_videoBitRate
                                    fps:videoFrameRate_default];
    if (!_isFrontCamera) {
        _rdLiveSDK.cameraState = RDRtmpPublishCameraStateBack;
    }
    [_rdLiveSDK startCamera];
    _rdLiveSDK.delegate = self;
    if (!_isOpenBeauty) {
        [_rdLiveSDK setBeautifyState:RDRTMPPUBLISH_BEAUTIFY_NORMAL];//关闭美颜，默认开启
    }
    [previewView addSubview:_rdLiveSDK.cameraView];
        
    //上边框渐变背景
    upBack = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 118)];
    upBack.image = [UIImage imageNamed:@"直播_渐变背景上"];
    [self.view addSubview:upBack];
}

//第一次安装，显示设置滤镜提示信息
- (void)initHintView {
    UITapGestureRecognizer *tapGesture  = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(removeHintView)];
    
    hintView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    hintView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    hintView.userInteractionEnabled = YES;
    [hintView addGestureRecognizer:tapGesture];
    [self.view addSubview:hintView];
    
    UIImage *hintImage = [UIImage imageNamed:@"直播滤镜提示"];
    UIImageView *hintIV = [[UIImageView alloc] initWithFrame:CGRectMake((SCREEN_WIDTH - hintImage.size.width)/2, 44 + (SCREEN_HEIGHT - hintImage.size.height)/2, hintImage.size.width, hintImage.size.height)];
    hintIV.backgroundColor = [UIColor clearColor];
    hintIV.image = hintImage;
    hintIV.tag = 1;
    [hintView addSubview:hintIV];
}

- (void)removeHintView{
    [hintView removeFromSuperview];
    hintView = nil;
}

//设置美颜强度：1-5
- (void)initBeautySlider {
    beautyViewHeight = 100.0;
    
    setBeautyLevelView = [[UIView alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT - beautyViewHeight, SCREEN_WIDTH, beautyViewHeight)];
    setBeautyLevelView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    setBeautyLevelView.hidden = YES;
    [self.view addSubview:setBeautyLevelView];
    
    beautyLbl = [[UILabel alloc] initWithFrame:CGRectMake((SCREEN_WIDTH - 100)/2, beautyViewHeight - 30, 100, 20)];
    beautyLbl.text = [NSString stringWithFormat:@"美颜强度(%ld)", (long)beautyLevel];
    beautyLbl.textColor = UIColorFromRGB(0x888888);
    beautyLbl.font = [UIFont systemFontOfSize:15.0];
    beautyLbl.textAlignment = NSTextAlignmentCenter;
    [setBeautyLevelView addSubview:beautyLbl];
    
    beautySlider = [[UISlider alloc]initWithFrame:CGRectMake(44, 20, SCREEN_WIDTH - 44*2, 20)];
    beautySlider.maximumValue = 5.0;
    beautySlider.value = beautyLevel;
    beautySlider.continuous = NO;
    beautySlider.thumbTintColor = UIColorFromRGB(0x007aff);
    [beautySlider addTarget:self action:@selector(beautySliderChange:) forControlEvents:UIControlEventAllEvents];
    [setBeautyLevelView addSubview:beautySlider];
    
    UIButton *beautyCancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    beautyCancelBtn.frame = CGRectMake(10, beautyViewHeight - 30, 26, 26);
    [beautyCancelBtn setImage:[UIImage imageNamed:@"直播_美颜关闭默认"] forState:UIControlStateNormal];
    [beautyCancelBtn addTarget:self action:@selector(setBeautyCancelBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [setBeautyLevelView addSubview:beautyCancelBtn];
    
    beautyConfirmBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    beautyConfirmBtn.frame = CGRectMake(SCREEN_WIDTH - 36, beautyViewHeight - 30, 26, 26);
    [beautyConfirmBtn setImage:[UIImage imageNamed:@"直播_美颜确定默认"] forState:UIControlStateNormal];
    [beautyConfirmBtn addTarget:self action:@selector(setBeautyConfirmBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [setBeautyLevelView addSubview:beautyConfirmBtn];
}

- (void)initBottomView {
    bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT - 65, SCREEN_WIDTH, 60)];
    bottomView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:bottomView];
    
    float spaceWidth = (SCREEN_WIDTH - 40*5)/6;
    
    //是否推音频
    audioBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    audioBtn.frame = CGRectMake(spaceWidth, 0, 40, 60);
    audioBtn.backgroundColor = [UIColor clearColor];
    [audioBtn setImage:[UIImage imageNamed:@"直播麦默认_"] forState:UIControlStateNormal];
    [audioBtn setImage:[UIImage imageNamed:@"直播麦点击_"] forState:UIControlStateHighlighted];
    [audioBtn setImage:[UIImage imageNamed:@"直播麦默认_"] forState:UIControlStateSelected];
    [audioBtn setTitle:@"非静音" forState:UIControlStateNormal];
    [audioBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [audioBtn setTitleColor:UIColorFromRGB(CommonColor) forState:UIControlStateHighlighted];
    audioBtn.titleLabel.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.3];
    audioBtn.titleLabel.font = [UIFont systemFontOfSize:12.0];
    audioBtn.imageEdgeInsets = UIEdgeInsetsMake(-20, 0, 0, 0);
    audioBtn.titleEdgeInsets = UIEdgeInsetsMake(40, -40, 0, 0);
    [audioBtn addTarget:self action:@selector(audioBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    audioBtn.selected = YES;
    [bottomView addSubview:audioBtn];
    
    //可播放音乐，同时推出
    musicBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    musicBtn.frame = CGRectMake(spaceWidth*2 + 40, 0, 40, 60);
    musicBtn.backgroundColor = [UIColor clearColor];
    [musicBtn setImage:[UIImage imageNamed:@"直播无音乐默认_"] forState:UIControlStateNormal];
    [musicBtn setImage:[UIImage imageNamed:@"直播无音乐点击_"] forState:UIControlStateHighlighted];
    [musicBtn setTitle:@"无伴乐" forState:UIControlStateNormal];
    [musicBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [musicBtn setTitleColor:UIColorFromRGB(CommonColor) forState:UIControlStateHighlighted];
    musicBtn.titleLabel.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.3];
    musicBtn.titleLabel.font = [UIFont systemFontOfSize:12.0];
    musicBtn.imageEdgeInsets = UIEdgeInsetsMake(-20, 0, 0, 0);
    musicBtn.titleEdgeInsets = UIEdgeInsetsMake(40, -40, 0, 0);
    [musicBtn addTarget:self action:@selector(musicBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:musicBtn];
    
    //截取摄像头图片
    screenShotBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    screenShotBtn.frame = CGRectMake(spaceWidth*3 + 40*2, 0, 40, 60);
    screenShotBtn.backgroundColor = [UIColor clearColor];
    [screenShotBtn setImage:[UIImage imageNamed:@"直播截屏默认"] forState:UIControlStateNormal];
    [screenShotBtn setImage:[UIImage imageNamed:@"直播截屏点击"] forState:UIControlStateHighlighted];
    [screenShotBtn setTitle:@"截屏" forState:UIControlStateNormal];
    [screenShotBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [screenShotBtn setTitleColor:UIColorFromRGB(CommonColor) forState:UIControlStateHighlighted];
    screenShotBtn.titleLabel.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.3];
    screenShotBtn.titleLabel.font = [UIFont systemFontOfSize:12.0];
    screenShotBtn.imageEdgeInsets = UIEdgeInsetsMake(-20, 0, 0, 0);
    screenShotBtn.titleEdgeInsets = UIEdgeInsetsMake(40, -40, 0, 0);
    [screenShotBtn addTarget:self action:@selector(screenShotBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:screenShotBtn];
    
    //设置萌颜
    setFacueBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    setFacueBtn.frame = CGRectMake(spaceWidth*4 + 40*3, 0, 40, 60);
    setFacueBtn.backgroundColor = [UIColor clearColor];
    [setFacueBtn setImage:[UIImage imageNamed:@"直播表情默认_"] forState:UIControlStateNormal];
    [setFacueBtn setImage:[UIImage imageNamed:@"直播表情点击_"] forState:UIControlStateHighlighted];
    [setFacueBtn setTitle:@"无萌颜" forState:UIControlStateNormal];
    [setFacueBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [setFacueBtn setTitleColor:UIColorFromRGB(CommonColor) forState:UIControlStateHighlighted];
    setFacueBtn.titleLabel.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.3];
    setFacueBtn.titleLabel.font = [UIFont systemFontOfSize:12.0];
    setFacueBtn.imageEdgeInsets = UIEdgeInsetsMake(-20, 0, 0, 0);
    setFacueBtn.titleEdgeInsets = UIEdgeInsetsMake(40, -40, 0, 0);
    [setFacueBtn addTarget:self action:@selector(setFacueBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:setFacueBtn];
    
    //设置水印
    waterMarkBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    waterMarkBtn.frame = CGRectMake(spaceWidth*5 + 40*4, 0, 40, 60);
    waterMarkBtn.backgroundColor = [UIColor clearColor];
    [waterMarkBtn setImage:[UIImage imageNamed:@"直播无水印默认_"] forState:UIControlStateNormal];
    [waterMarkBtn setImage:[UIImage imageNamed:@"直播无水印点击_"] forState:UIControlStateHighlighted];
    [waterMarkBtn setImage:[UIImage imageNamed:@"直播无水印默认_"] forState:UIControlStateSelected];
    [waterMarkBtn setTitle:@"无水印" forState:UIControlStateNormal];
    [waterMarkBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [waterMarkBtn setTitleColor:UIColorFromRGB(CommonColor) forState:UIControlStateHighlighted];
    waterMarkBtn.titleLabel.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.3];
    waterMarkBtn.titleLabel.font = [UIFont systemFontOfSize:12.0];
    waterMarkBtn.imageEdgeInsets = UIEdgeInsetsMake(-20, 0, 0, 0);
    waterMarkBtn.titleEdgeInsets = UIEdgeInsetsMake(40, -40, 0, 0);
    [waterMarkBtn addTarget:self action:@selector(waterMarkBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:waterMarkBtn];
}

//音乐列表
- (void)initMusicView {
    selectedMusicIndex = 0;
    
    musicView = [[UIView alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT - 150, SCREEN_WIDTH, 150)];
    musicView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    musicView.hidden = YES;
    [self.view addSubview:musicView];
    
    musicTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, musicView.frame.size.height)];
    musicTableView.backgroundColor  = [UIColor clearColor];
    musicTableView.separatorStyle  = UITableViewCellSeparatorStyleNone;
    musicTableView.separatorColor  = [UIColor lightGrayColor];
    musicTableView.showsVerticalScrollIndicator = NO;
    musicTableView.delegate = self;
    musicTableView.dataSource = self;
    [musicView addSubview:musicTableView];
    
    musicArray = [[NSMutableArray alloc]initWithObjects:
                  [[NSDictionary alloc] initWithObjectsAndKeys:@"无",@"musicName",@"",@"musicUrl", nil],
                  [[NSDictionary alloc] initWithObjectsAndKeys:@"Like A Bullet",@"musicName",[self musicURL:0],@"musicUrl", nil],
                  [[NSDictionary alloc] initWithObjectsAndKeys:@"Better Times Ahead",@"musicName",[self musicURL:1],@"musicUrl", nil],
                  [[NSDictionary alloc] initWithObjectsAndKeys:@"Bouncy Party",@"musicName",[self musicURL:2],@"musicUrl", nil],
                  nil];

    [musicTableView reloadData];
}

//萌颜列表
- (void)initFacueView{
    facueView = [[UIView alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT - 195, SCREEN_WIDTH, 195)];
    facueView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    facueView.hidden = YES;
    [self.view addSubview:facueView];
    
    hideFacueViewBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    hideFacueViewBtn.frame = CGRectMake(0, 0, 40, 40);
    hideFacueViewBtn.center = CGPointMake(SCREEN_WIDTH/2, 20);
    [hideFacueViewBtn setImage:[UIImage imageNamed:@"直播表情收起默认_"] forState:UIControlStateNormal];
    [hideFacueViewBtn setImage:[UIImage imageNamed:@"直播表情收起点击_"] forState:UIControlStateHighlighted];
    [hideFacueViewBtn addTarget:self action:@selector(hideFacueViewBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [facueView addSubview:hideFacueViewBtn];
    
    selectedFacueView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH/5.0*0.8, SCREEN_WIDTH/5.0*0.8)];
    selectedFacueView.center = CGPointMake(SCREEN_WIDTH/10., SCREEN_WIDTH*((int)(0/5.))/5. + SCREEN_WIDTH/10. + 30);
    selectedFacueView.backgroundColor = [UIColor whiteColor];
    selectedFacueView.layer.cornerRadius = (SCREEN_WIDTH/5.*0.8)/2.;
    selectedFacueView.layer.masksToBounds = YES;
    selectedFacueView.alpha = 0.5;
    [facueView addSubview:selectedFacueView];
    
    UIButton *facueBtn;
    for (int i = 0; i < 10; i++) {
        facueBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        facueBtn.backgroundColor = [UIColor clearColor];
        facueBtn.layer.cornerRadius = (SCREEN_WIDTH/5.*0.7)/2.;
        facueBtn.layer.masksToBounds = YES;
        facueBtn.frame = CGRectMake(0, 0, SCREEN_WIDTH/5.*0.7, SCREEN_WIDTH/5.*0.7);
        facueBtn.center = CGPointMake((i%5)*SCREEN_WIDTH/5. + SCREEN_WIDTH/10., SCREEN_WIDTH*((int)(i/5.))/5. + SCREEN_WIDTH/10. + 30);
        facueBtn.tag = kFacueBtnTag + i;
        [facueBtn addTarget:self action:@selector(selectFacueBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        if (i == 0) {
            [facueBtn setTitle:@"无" forState:UIControlStateNormal];
        }else{
            [facueBtn setImage:[_rdLiveSDK getFacueImage:(RDRtmpPublishFacueType)(i - 1)] forState:UIControlStateNormal];
        }
        [facueView addSubview:facueBtn];
    }
}

- (void)playMusic:(NSURL *)musicUrl {
    audioPlayer = nil;
    NSError *error = nil;
    audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:musicUrl error:&error];
    audioPlayer.numberOfLoops = -1;
    [audioPlayer play];
}

#pragma mark - 获取所有在线直播用户(uid)
- (void)getAllLiveUidBtnAction:(UIButton *)sender {
    [_rdLiveSDK getAllLiveList:^(NSArray *allLiveInfoArray) {
        NSLog(@"%lu", (unsigned long)allLiveInfoArray.count);
    } error:^(NSError *error) {
        NSLog(@"error:%@", error.localizedDescription);
    }];
}

#pragma mark - 通知
-(void)pressHome:(NSNotification *) notification{
    isBackground = YES;
    if (audioPlayer && audioPlayer.isPlaying) {
        [audioPlayer pause];
    }
}

-(void)becomeActive:(NSNotification *) notification{
    isBackground = NO;
    if (audioPlayer) {
        [audioPlayer play];
    }
}

#pragma mark - 改变滤镜
-(void)handleSwipeFrom:(UISwipeGestureRecognizer *)recognizer{
    if(recognizer.direction==UISwipeGestureRecognizerDirectionLeft) {
        if (filterIndex < filterNumImages) {
            filterIndex++;
            [self changeFilter:filterIndex];
        }else if (filterIndex == filterNumImages) {
            filterIndex = 1;
            [self changeFilter:filterIndex];
        }
    }
    else if(recognizer.direction==UISwipeGestureRecognizerDirectionRight) {
        if (filterIndex > 1) {
            filterIndex--;
            [self changeFilter:filterIndex];
        }else {
            filterIndex = 7;
            [self changeFilter:filterIndex];
        }
    }
}

- (void) changeFilter : (NSInteger) index
{
    NSString *filterTypeStr;
    switch (index)
    {
        case 1:
            [_rdLiveSDK setFilter:RDRtmpPublishFilterNormal];
            filterTypeStr = @"原图";
            break;
        case 2:
            [_rdLiveSDK setFilter:RDRtmpPublishFilterYouGe];
            filterTypeStr = @"优格";
            break;
        case 3:
            [_rdLiveSDK setFilter:RDRtmpPublishFilterLengYan];
            filterTypeStr = @"冷艳";
            break;
        case 4:
            [_rdLiveSDK setFilter:RDRtmpPublishFilterLanSeShiKe];
            filterTypeStr = @"蓝色时刻";
            break;
        case 5:
            [_rdLiveSDK setFilter:RDRtmpPublishFilterNuanYangYang];
            filterTypeStr = @"暖洋洋";
            break;
        case 6:
            [_rdLiveSDK setFilter:RDRtmpPublishFilterGuTongSe];
            filterTypeStr = @"古铜色";
            break;
        case 7:
            [_rdLiveSDK setFilter:RDRtmpPublishFilterGray];
            filterTypeStr = @"黑白";
            break;
        case 8:
            [_rdLiveSDK setFilter:RDRtmpPublishFilterInvertColors];
            filterTypeStr = @"反转";
            break;
        case 9:
            [_rdLiveSDK setFilter:RDRtmpPublishFilterSepia];
            filterTypeStr = @"怀旧";
            break;
        case 10:
            [_rdLiveSDK setFilter:RDRtmpPublishFilterFisheye];
            filterTypeStr = @"扭曲";
            break;
        case 11:
            [_rdLiveSDK setFilter:RDRtmpPublishFilterGlow];
            filterTypeStr = @"照亮边缘";
            break;
        default:
            [_rdLiveSDK setFilter:RDRtmpPublishFilterNormal];
            filterTypeStr = @"原图";
            break;
    }
    NSLog(@"滤镜：%@", filterTypeStr);
}

#pragma mark - 按钮事件
-(void)backToTopVC{
    if (isRecording) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"确定要停止直播吗？"
                                                            message:@""
                                                           delegate:self
                                                  cancelButtonTitle:@"取消"
                                                  otherButtonTitles:@"确定", nil];
        [alertView show];
    }else {
        if (lastOrientation != UIDeviceOrientationPortrait) {
            appDelegate.orientationMask = UIInterfaceOrientationMaskPortrait;
            NSNumber *orientationTarget = [NSNumber numberWithInt:UIDeviceOrientationPortrait];
            [[UIDevice currentDevice] setValue:orientationTarget forKey:@"orientation"];
            [UIViewController attemptRotationToDeviceOrientation];
            previewView.transform = CGAffineTransformMakeRotation(0);
            [self setViewPortrait];
        }
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)switchCameraBtnAction:(UIButton *)sender{
    if (_rdLiveSDK.cameraState ==  RDRtmpPublishCameraStateBack) {
        _rdLiveSDK.cameraState =  RDRtmpPublishCameraStateFront;
        torchBtn.hidden = YES;
        beautyBtn.frame = CGRectMake(10 + 40 + 20, 2, 40, 40);
    }else{
        _rdLiveSDK.cameraState =  RDRtmpPublishCameraStateBack;
        torchBtn.hidden = NO;
        beautyBtn.frame = CGRectMake(10 + (40 + 20)*2, 2, 40, 40);
    }
}

- (void)liveBtnAction:(UIButton *)sender {
    if (isRecording) {
        [UIApplication sharedApplication].idleTimerDisabled = NO;//自动锁屏
        isRecording = NO;
        isBeginLive = NO;
        [_rdLiveSDK endPublish];
    }else{
        [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideSetBeautyView) object:nil];
        
        if (bottomView.hidden) {
            setBeautyLevelView.hidden = YES;
            facueView.hidden = YES;
            musicView.hidden = YES;
            bottomView.hidden = NO;
        }
        if (_isUidLive && liveTitleTF.text.length == 0) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"亲，请给你的直播写个标题吧！"
                                                                message:nil
                                                               delegate:self
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:@"确定", nil];
            [alertView show];
        }else {
            [liveTitleTF resignFirstResponder];
            livingOrientation = lastOrientation;
//            if (_rdLiveSDK.authType == RDLive_AT_UID || _rdLiveSDK.authType == RDLive_AT_URL_OR_UID) {//应该用权限判断
            if (_isUidLive) {
                [_rdLiveSDK startPublishWithUid:_userID
                                       andTitle:liveTitleTF.text
                                        success:^{
                                            [UIApplication sharedApplication].idleTimerDisabled = YES;//不自动锁屏
                                            
                                            isBeginLive = YES;
                                            isRecording = YES;
                                            liveTitleTF.hidden = YES;
                                            liveBtn.hidden = YES;
                                        }
                                          error:^(NSError *error) {
                                              NSLog(@"startPublish status:%@", error.localizedDescription);
                                              UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:error.localizedDescription
                                                                                                  message:nil
                                                                                                 delegate:self
                                                                                        cancelButtonTitle:nil
                                                                                        otherButtonTitles:@"确定", nil];
                                              [alertView show];
                                          }];
//            }else if (_rdLiveSDK.authType == RDLive_AT_URL || _rdLiveSDK.authType == RDLive_AT_URL_OR_UID) {//应该用权限判断
            }else {
                NSRange range = [_rtmpUrl rangeOfString:@"/" options:NSBackwardsSearch];
                NSString *url = [_rtmpUrl substringToIndex:range.location];
                NSString *streamKey = [_rtmpUrl substringFromIndex:range.location + 1];
                [_rdLiveSDK startPublishWithUrl:url
                                   andStreamKey:streamKey
                                        success:^{
                                            [UIApplication sharedApplication].idleTimerDisabled = YES;//不自动锁屏
                                            
                                            isBeginLive = YES;
                                            isRecording = YES;
                                            liveTitleTF.hidden = YES;
                                            liveBtn.hidden = YES;
                                            //如需要，可获取直播截屏作为缩略图，上传至第三方服务器
                                            [self getThumbnail];
                                        }
                                          error:^(RDLiveErrorCode status) {
                                              NSLog(@"startPublish status:%ld", (long)status);
                                          }];
            }
        }
    }
}

- (void)getThumbnail {
    UIImage *thumbnail = [_rdLiveSDK getPublishScreenshot];
    NSLog(@"thumbnail:%@", thumbnail);
}

- (void)torchBtnAction:(UIButton *)sender {
    if (_rdLiveSDK.cameraState ==  RDRtmpPublishCameraStateBack) {
        if (_rdLiveSDK.torch) {
            _rdLiveSDK.torch = NO;
            [torchBtn setBackgroundImage:[UIImage imageNamed:@"直播_闪光关闭默认"] forState:UIControlStateNormal];
            [torchBtn setBackgroundImage:[UIImage imageNamed:@"直播_闪光关闭点击"] forState:UIControlStateHighlighted];
        }else {
            _rdLiveSDK.torch = YES;
            [torchBtn setBackgroundImage:[UIImage imageNamed:@"直播_闪光默认"] forState:UIControlStateNormal];
            [torchBtn setBackgroundImage:[UIImage imageNamed:@"直播_闪光点击"] forState:UIControlStateHighlighted];
        }
    }
}

- (void)beautyBtnAction:(UIButton *)sender {
    musicView.hidden = YES;
    facueView.hidden = YES;
    if (_rdLiveSDK.beautifyState == RDRTMPPUBLISH_BEAUTIFY_NORMAL) {
        [_rdLiveSDK setBeautifyState:RDRTMPPUBLISH_BEAUTIFY_SELECTED];
        
        bottomView.hidden = YES;
        setBeautyLevelView.hidden = NO;
        beautySlider.value = beautyLevel;
        beautyLbl.text = [NSString stringWithFormat:@"美颜强度(%ld)", (long)beautyLevel];
        [beautyBtn setBackgroundImage:[UIImage imageNamed:@"直播_美颜已选"] forState:UIControlStateNormal];
        
        [self performSelector:@selector(hideSetBeautyView) withObject:nil afterDelay:5.0];
    }else {
        [_rdLiveSDK setBeautifyState:RDRTMPPUBLISH_BEAUTIFY_NORMAL];
        
        [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideSetBeautyView) object:nil];
        bottomView.hidden = NO;
        setBeautyLevelView.hidden = YES;
        [beautyBtn setBackgroundImage:[UIImage imageNamed:@"直播_美颜默认"] forState:UIControlStateNormal];
    }
}

- (void)hideSetBeautyView {
    setBeautyLevelView.hidden = YES;
    bottomView.hidden = NO;
}

- (void) beautySliderChange: (UISlider*)sender{
    NSInteger level = (NSInteger)roundf(beautySlider.value);
    if (level == beautyLevel) {
        return;
    }
    beautyLevel = level;
    beautyLbl.text = [NSString stringWithFormat:@"美颜强度(%ld)", (long)level];
    if (level == 0) {
        if (_rdLiveSDK.beautifyState == RDRTMPPUBLISH_BEAUTIFY_SELECTED) {
            [_rdLiveSDK setBeautifyState:RDRTMPPUBLISH_BEAUTIFY_NORMAL];
            [beautyBtn setBackgroundImage:[UIImage imageNamed:@"直播_美颜默认"] forState:UIControlStateNormal];
        }
    }else {
        [beautyBtn setBackgroundImage:[UIImage imageNamed:@"直播_美颜已选"] forState:UIControlStateNormal];
        if (_rdLiveSDK.beautifyState == RDRTMPPUBLISH_BEAUTIFY_NORMAL) {
            [_rdLiveSDK setBeautifyState:RDRTMPPUBLISH_BEAUTIFY_SELECTED];
        }
        [_rdLiveSDK setBeautyLevel:level];
    }
}

- (void)setBeautyCancelBtnAction:(UIButton *)sender {
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideSetBeautyView) object:nil];
    setBeautyLevelView.hidden = YES;
    bottomView.hidden = NO;
    
    beautySlider.value = beautyLevel;
    beautyLbl.text = [NSString stringWithFormat:@"美颜强度(%ld)", (long)beautyLevel];
    if (beautyLevel > 0) {
        [_rdLiveSDK setBeautyLevel:beautyLevel];
        [beautyBtn setBackgroundImage:[UIImage imageNamed:@"直播_美颜已选"] forState:UIControlStateNormal];
    }else {
        [_rdLiveSDK setBeautifyState:RDRTMPPUBLISH_BEAUTIFY_NORMAL];
        [beautyBtn setBackgroundImage:[UIImage imageNamed:@"直播_美颜默认"] forState:UIControlStateNormal];
    }
}

- (void)setBeautyConfirmBtnAction:(UIButton *)sender {
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideSetBeautyView) object:nil];
    setBeautyLevelView.hidden = YES;
    bottomView.hidden = NO;
    beautyLevel = (int)roundf(beautySlider.value);
}

- (void)audioBtnAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) {
        [sender setImage:[UIImage imageNamed:@"直播麦默认_"] forState:UIControlStateNormal];
        [sender setImage:[UIImage imageNamed:@"直播麦点击_"] forState:UIControlStateHighlighted];
        [sender setImage:[UIImage imageNamed:@"直播麦默认_"] forState:UIControlStateSelected];
        [sender setTitle:@"非静音" forState:UIControlStateNormal];
        _rdLiveSDK.micGain = 1.0;
        if (audioPlayer) {
            [audioPlayer play];
        }
    }else {
        [sender setImage:[UIImage imageNamed:@"直播麦静音默认_"] forState:UIControlStateNormal];
        [sender setImage:[UIImage imageNamed:@"直播麦静音点击_"] forState:UIControlStateHighlighted];
        [sender setImage:[UIImage imageNamed:@"直播麦静音默认_"] forState:UIControlStateSelected];
        [sender setTitle:@"静音" forState:UIControlStateNormal];
        _rdLiveSDK.micGain = 0.0;
        if (audioPlayer && audioPlayer.isPlaying) {
            [audioPlayer pause];
        }
    }
}

- (void)musicBtnAction:(UIButton *)sender {
    musicView.hidden = NO;
    bottomView.hidden = YES;
}

- (void)screenShotBtnAction:(UIButton *)sender {
    [_rdLiveSDK getPublishScreenshot];//SDK内已保存图片到相册
}

- (void)setFacueBtnAction:(UIButton *)sender {
    facueView.hidden = NO;
    bottomView.hidden = YES;
}

- (void)hideFacueViewBtnAction:(UIButton *)sender {
    facueView.hidden = YES;
    bottomView.hidden = NO;
}

- (void)selectFacueBtnAction:(UIButton *)sender {
    selectedFacueIndex = (int)sender.tag - kFacueBtnTag;
    
    selectedFacueView.center = sender.center;
    if (selectedFacueIndex == 0) {
        facueView.hidden = YES;
        bottomView.hidden = NO;
        [_rdLiveSDK setFacue:RDRTMPPUBLISH_FACUE_NORMAL];
        [setFacueBtn setTitle:@"无萌颜" forState:UIControlStateNormal];
    }else{
        [_rdLiveSDK setFacue:(RDRtmpPublishFacueType)(selectedFacueIndex - 1)];
        [setFacueBtn setTitle:@"萌颜" forState:UIControlStateNormal];
    }
}

- (void)waterMarkBtnAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) {
        [sender setImage:[UIImage imageNamed:@"直播水印默认_"] forState:UIControlStateNormal];
        [sender setImage:[UIImage imageNamed:@"直播水印点击_"] forState:UIControlStateHighlighted];
        [sender setImage:[UIImage imageNamed:@"直播水印默认_"] forState:UIControlStateSelected];
        [sender setTitle:@"水印" forState:UIControlStateNormal];
        
#if 0
        UIImage *waterImage = [UIImage imageNamed:@"直播_水印"];
        CGRect rect = CGRectMake(previewView.frame.size.width - waterImage.size.width/2 - 10, 70, waterImage.size.width/2, waterImage.size.height/2);
        UIImageView *waterIV = [[UIImageView alloc] initWithFrame:rect];
        waterIV.image = waterImage;
        waterIV.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.3];
        [_rdLiveSDK addWaterMarkView:waterIV location:RDRTMPPUBLISH_WATERMARK_LOCATION_RIGHTUP];
#else
        UILabel *waterLbl = [[UILabel alloc] init];
        waterLbl.text = @"锐动直播";
        waterLbl.textColor = [UIColor whiteColor];
        waterLbl.font = [UIFont systemFontOfSize:17.0];
        waterLbl.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.3];
        waterLbl.layer.masksToBounds = YES;
        waterLbl.layer.cornerRadius = 15;
        waterLbl.textAlignment = NSTextAlignmentCenter;
        
        int setWaterLocation = 1;
        switch (setWaterLocation) {
            case 0://左上角
                waterLbl.frame = CGRectMake(20, 70, 80, 30);
                [_rdLiveSDK addWaterMarkView:waterLbl location:RDRTMPPUBLISH_WATERMARK_LOCATION_LEFTUP];
                break;
                
            case 1://右上角
                if (lastOrientation == UIDeviceOrientationPortrait || SYSTEM_VERSION < 8.0) {
                    waterLbl.frame = CGRectMake(SCREEN_WIDTH - 80 - 20, 70, 80, 30);

                }else {
                    waterLbl.frame = CGRectMake(SCREEN_HEIGHT - 80 - 20, 70, 80, 30);
                }
                [_rdLiveSDK addWaterMarkView:waterLbl location:RDRTMPPUBLISH_WATERMARK_LOCATION_RIGHTUP];
                break;
                
            case 2://左下角
                if (lastOrientation == UIDeviceOrientationPortrait || SYSTEM_VERSION < 8.0) {
                    waterLbl.frame = CGRectMake(20, SCREEN_HEIGHT - 70 - 30, 80, 30);
                }else {
                    waterLbl.frame = CGRectMake(20, SCREEN_WIDTH - 70 - 30, 80, 30);
                }
                [_rdLiveSDK addWaterMarkView:waterLbl location:RDRTMPPUBLISH_WATERMARK_LOCATION_LEFTDOWN];
                break;
                
            case 3://右下角
                if (lastOrientation == UIDeviceOrientationPortrait || SYSTEM_VERSION < 8.0) {
                    waterLbl.frame = CGRectMake(SCREEN_WIDTH - 80 - 20, SCREEN_HEIGHT - 70 - 30, 80, 30);
                }else {
                    waterLbl.frame = CGRectMake(SCREEN_HEIGHT - 80 - 20, SCREEN_WIDTH - 70 - 30, 80, 30);
                }
                [_rdLiveSDK addWaterMarkView:waterLbl location:RDRTMPPUBLISH_WATERMARK_LOCATION_RIGHTDOWN];
                break;
                
            default:
                waterLbl.frame = CGRectMake(0, 0, 80, 30);
                waterLbl.center = self.view.center;
                [_rdLiveSDK addWaterMarkView:waterLbl location:RDRTMPPUBLISH_WATERMARK_LOCATION_CENTER];
                break;
        }
#endif
    }else {
        [sender setImage:[UIImage imageNamed:@"直播无水印默认_"] forState:UIControlStateNormal];
        [sender setImage:[UIImage imageNamed:@"直播无水印点击_"] forState:UIControlStateHighlighted];
        [sender setImage:[UIImage imageNamed:@"直播无水印默认_"] forState:UIControlStateSelected];
        [sender setTitle:@"无水印" forState:UIControlStateNormal];

        [_rdLiveSDK addWaterMarkView:nil location:RDRTMPPUBLISH_WATERMARK_LOCATION_CENTER];//location设置没有影响
    }
}

- (NSURL *)musicURL:(NSInteger)index {
    NSURL *musicURL = nil;
    NSString *musicPath = [self musicPath:index];
    if (musicPath)
    {
        musicURL = [NSURL fileURLWithPath:musicPath];
    }
    return musicURL;
}

- (NSString *)musicPath:(NSInteger)index{
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *musicPath = nil;
    
    if (bundle)
    {
        switch (index) {
            case 0:
                musicPath = [bundle pathForResource:@"Like A Bullet" ofType:@"mp3"];
                break;
            case 1:
                musicPath = [bundle pathForResource:@"Better Times Ahead" ofType:@"m4a"];
                break;
            case 2:
                musicPath = [bundle pathForResource:@"Bouncy Party" ofType:@"m4a"];
                break;
            default:
                break;
        }
    }
    return  musicPath;
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    if (textField.text.length > 0) {
        [self liveBtnAction:nil];
    }
    
    return YES;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [liveTitleTF resignFirstResponder];
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideSetBeautyView) object:nil];
    
    if (bottomView.hidden) {
        setBeautyLevelView.hidden = YES;
        facueView.hidden = YES;
        musicView.hidden = YES;
        bottomView.hidden = NO;
    }
}

#pragma mark - RDLiveDelegate
- (void) RDRtmpPublishConnectionStatusChanged:(RDRtmpPublishState)liveState{
    NSLog(@"直播状态:%ld", (long)liveState);
    switch (liveState) {
        case RDRtmpPublishStateStarted:
            reStartSenconds = 0;
            [reStartLiveTimer invalidate];
            reStartLiveTimer  = nil;

            break;
        
        case RDRtmpPublishStateEnded:
            if (isStopLive) {
                [UIApplication sharedApplication].idleTimerDisabled = NO;//自动锁屏
                isRecording = NO;
                liveTitleTF.text = @"";
            }else {
                if (!isBackground) {
                    reStartLiveTime = CFAbsoluteTimeGetCurrent();
                    [reStartLiveTimer invalidate];
                    reStartLiveTimer = nil;
                    reStartLiveTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(reStartLiveTime) userInfo:nil repeats:YES];
                }
            }
            break;
            
        default:
            
            break;
    }
}

#pragma mark - 重连时间
-(void)reStartLiveTime
{
    double nowTime = CFAbsoluteTimeGetCurrent();
    int secondsTime = lround(floor((nowTime - reStartLiveTime)/1.)) % 60;
    reStartSenconds += secondsTime;
    reStartLiveTime = CFAbsoluteTimeGetCurrent();
    NSLog(@"重连时间:%d",reStartSenconds);
    if (reStartSenconds <= 60) {
        [_rdLiveSDK reStartPublishWithUid:_userID success:^{
            isRecording = YES;
        } error:^(NSError *error) {
            reStartSenconds = 61;
        }];
    }else {
        [reStartLiveTimer invalidate];
        reStartLiveTimer = nil;
        
        [UIApplication sharedApplication].idleTimerDisabled = NO;//自动锁屏
        isRecording = NO;
        liveTitleTF.text = @"";
        liveTitleTF.hidden = NO;
        liveBtn.hidden = NO;
    }
}

#pragma mark - UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return musicArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UIView *spanView = [[UIView alloc] initWithFrame:CGRectMake(0, 49, SCREEN_WIDTH, 0.5)];
        spanView.backgroundColor = [UIColor lightGrayColor];
        spanView.tag = 1;
        [cell.contentView addSubview:spanView];
        
        cell.contentView.backgroundColor = [UIColor clearColor];
        
        NSDictionary *dic = [musicArray objectAtIndex:indexPath.row];
        
        UILabel *musicDurationLbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 50, 30)];
        musicDurationLbl.backgroundColor = [UIColor clearColor];
        musicDurationLbl.text = @"";
        musicDurationLbl.font = [UIFont systemFontOfSize:14];
        musicDurationLbl.textColor = UIColorFromRGB(0x888888);
        [cell.contentView addSubview:musicDurationLbl];
        
        UILabel *musicNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(60, 10, tableView.frame.size.width-60, 30)];
        musicNameLabel.backgroundColor = [UIColor clearColor];
        musicNameLabel.text = [dic objectForKey:@"musicName"];
        if (indexPath.row == selectedMusicIndex) {
            musicNameLabel.textColor = UIColorFromRGB(CommonColor);
        }else {
            musicNameLabel.textColor = [UIColor whiteColor];
        }
        musicNameLabel.font = [UIFont systemFontOfSize:14];
        musicNameLabel.tag = 2;
        [cell.contentView addSubview:musicNameLabel];
        
        if (indexPath.row != 0) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                AVURLAsset *musicAsset = [AVURLAsset assetWithURL:[dic objectForKey:@"musicUrl"]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    musicDurationLbl.text = [self timeToStringNoSecFormat:CMTimeGetSeconds(musicAsset.duration)];
                });
            });
        }
    }
    UIView *spanView = [cell.contentView viewWithTag:1];
    spanView.frame = CGRectMake(0, 49, SCREEN_WIDTH, 0.5);
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.row == 0) {
        [musicBtn setImage:[UIImage imageNamed:@"直播无音乐默认_"] forState:UIControlStateNormal];
        [musicBtn setImage:[UIImage imageNamed:@"直播无音乐点击_"] forState:UIControlStateHighlighted];
        [musicBtn setTitle:@"无伴乐" forState:UIControlStateNormal];
        if (audioPlayer && audioPlayer.isPlaying) {
            [audioPlayer stop];
        }
        audioPlayer = nil;
        musicView.hidden = YES;
        bottomView.hidden = NO;
    }else {
        if (selectedMusicIndex == 0) {//默认选中cell
            UITableViewCell * cell_default = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            UILabel *musicNameLbl_default = (UILabel*)[cell_default.contentView viewWithTag:2];
            musicNameLbl_default.textColor = [UIColor whiteColor];
        }
        [musicBtn setImage:[UIImage imageNamed:@"直播音乐默认_"] forState:UIControlStateNormal];
        [musicBtn setImage:[UIImage imageNamed:@"直播音乐点击_"] forState:UIControlStateHighlighted];
        [musicBtn setTitle:@"伴乐" forState:UIControlStateNormal];
        [self playMusic:[[musicArray objectAtIndex:indexPath.row] objectForKey:@"musicUrl"]];
    }
    UITableViewCell * cell = [tableView cellForRowAtIndexPath:indexPath];
    UILabel *musicNameLbl = (UILabel*)[cell.contentView viewWithTag:2];
    musicNameLbl.textColor = UIColorFromRGB(CommonColor);
    
    selectedMusicIndex = indexPath.row;
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell * cell = [tableView cellForRowAtIndexPath:indexPath];
    UILabel *musicNameLbl = (UILabel*)[cell.contentView viewWithTag:2];
    musicNameLbl.textColor = [UIColor whiteColor];
}

- (NSString *)timeToStringNoSecFormat:(float)time{
    if(time <= 0){
        time = 0;
    }
    int secondsInt      = floorf(time);
    float millisecond   = time - secondsInt;
    int hour            = secondsInt/3600;
    secondsInt          -= hour*3600;
    int minutes         = (int)secondsInt/60;
    secondsInt          -= minutes * 60;
    NSString *strText;
    if(millisecond == 1){
        secondsInt ++;
        millisecond = 0.f;
    }
    if (hour > 0)
    {
        strText = [NSString stringWithFormat:@"%02i:%02i:%02if",hour,minutes, secondsInt];
    }else{
        
        strText = [NSString stringWithFormat:@"%02i:%02i",minutes, secondsInt];
    }
    return strText;
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        isStopLive = YES;
        [self liveBtnAction:nil];
        [self performSelector:@selector(backToTopVC) withObject:nil afterDelay:0.25];
    }
}

- (void)observeOrientation{
    motionManager=[[CMMotionManager alloc]init];
    __block typeof(self) weakSelf = self;
    
    if (motionManager.accelerometerAvailable) {
        [motionManager setAccelerometerUpdateInterval:0.5f];
        NSOperationQueue *operationQueue = [NSOperationQueue mainQueue];
        [motionManager startAccelerometerUpdatesToQueue:operationQueue withHandler:^(CMAccelerometerData *data,NSError *error)
         {
             typeof(self) selfBlock = weakSelf;
             
             CGFloat xx = data.acceleration.x;
             
             CGFloat yy = -data.acceleration.y;
             
             CGFloat zz = data.acceleration.z;
             
             UIDeviceOrientation orientation = UIDeviceOrientationUnknown;

             CGFloat device_angle = M_PI / 2.0f - atan2(yy, xx);
             if (device_angle > M_PI)
                 
                 device_angle -= 2 * M_PI;
             
             if ((zz < -.60f) || (zz > .60f)) {
                 
                 if ( UIDeviceOrientationIsLandscape(lastOrientation) )
                     
                     orientation = lastOrientation;
                 
                 else
                     
                     orientation = UIDeviceOrientationUnknown;
                 
             } else {
                 
                 if ( (device_angle > -M_PI_4) && (device_angle < M_PI_4) )
                     
                     orientation = UIDeviceOrientationPortrait;
                 
                 else if ((device_angle < -M_PI_4) && (device_angle > -3 * M_PI_4))
                     
                     orientation = UIDeviceOrientationLandscapeLeft;
                 
                 else if ((device_angle > M_PI_4) && (device_angle < 3 * M_PI_4))
                     
                     orientation = UIDeviceOrientationLandscapeRight;
                 
                 else
                     
                     orientation = UIDeviceOrientationPortraitUpsideDown;
                 
             }
             if (orientation == UIDeviceOrientationUnknown) {
                 return ;
             }
             if (orientation != lastOrientation) {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     if (!isBeginLive) {
                         [selfBlock deviceOrientationDidChangeTo:orientation];
                     }else{
                         lastOrientation = orientation;
                         [selfBlock showOrHideOrientationHintView];
                     }
                 });
             }
         }];
    }
}

- (void)deviceOrientationDidChangeTo:(UIDeviceOrientation)orientation{
    switch (orientation) {
        case  UIDeviceOrientationLandscapeLeft:
        {
            NSLog(@"UIDeviceOrientationLandscapeLeft");

            appDelegate.orientationMask = UIInterfaceOrientationMaskLandscapeRight;
            NSNumber *orientationTarget = [NSNumber numberWithInt:UIDeviceOrientationLandscapeLeft];
            [[UIDevice currentDevice] setValue:orientationTarget forKey:@"orientation"];
            [UIViewController attemptRotationToDeviceOrientation];
            
            if (SCREEN_WIDTH < SCREEN_HEIGHT && SYSTEM_VERSION >= 8.0) {
                NSNumber *orientationTarget1 = [NSNumber numberWithInt:UIDeviceOrientationUnknown];
                [[UIDevice currentDevice] setValue:orientationTarget1 forKey:@"orientation"];
                [UIViewController attemptRotationToDeviceOrientation];
                
                appDelegate.orientationMask = UIInterfaceOrientationMaskPortrait;
                NSNumber *orientationTarget = [NSNumber numberWithInt:UIDeviceOrientationPortrait];
                [[UIDevice currentDevice] setValue:orientationTarget forKey:@"orientation"];
                [UIViewController attemptRotationToDeviceOrientation];
                
                return;
            }
            lastOrientation = orientation;
            previewView.transform = CGAffineTransformMakeRotation(-M_PI_2);

            if (SYSTEM_VERSION >= 8.0) {
                [self setViewLandscape];
            }else {
                [self setViewLandscapeIOS7];
            }
        }
            break;
            
        case  UIDeviceOrientationLandscapeRight:
        {
            NSLog(@"UIDeviceOrientationLandscapeRight");

            appDelegate.orientationMask = UIInterfaceOrientationMaskLandscapeLeft;
            NSNumber *orientationTarget = [NSNumber numberWithInt:UIDeviceOrientationLandscapeRight];
            [[UIDevice currentDevice] setValue:orientationTarget forKey:@"orientation"];
            [UIViewController attemptRotationToDeviceOrientation];
            
            if (SCREEN_WIDTH < SCREEN_HEIGHT && SYSTEM_VERSION >= 8.0) {
                NSNumber *orientationTarget1 = [NSNumber numberWithInt:UIDeviceOrientationUnknown];
                [[UIDevice currentDevice] setValue:orientationTarget1 forKey:@"orientation"];
                [UIViewController attemptRotationToDeviceOrientation];
                
                appDelegate.orientationMask = UIInterfaceOrientationMaskPortrait;
                NSNumber *orientationTarget = [NSNumber numberWithInt:UIDeviceOrientationPortrait];
                [[UIDevice currentDevice] setValue:orientationTarget forKey:@"orientation"];
                [UIViewController attemptRotationToDeviceOrientation];
                
                return;
            }
            lastOrientation = orientation;
            previewView.transform = CGAffineTransformMakeRotation(M_PI_2);
            if (SYSTEM_VERSION >= 8.0) {
                [self setViewLandscape];
            }else {
                [self setViewLandscapeIOS7];
            }
        }
            break;

        default:
        {
            NSLog(@"UIDeviceOrientationPortrait");

            appDelegate.orientationMask = UIInterfaceOrientationMaskPortrait;
            NSNumber *orientationTarget = [NSNumber numberWithInt:UIDeviceOrientationPortrait];
            [[UIDevice currentDevice] setValue:orientationTarget forKey:@"orientation"];
            [UIViewController attemptRotationToDeviceOrientation];
            
            lastOrientation = orientation;
            previewView.transform = CGAffineTransformMakeRotation(0);
            [self setViewPortrait];
  
        }
            break;
    }
    [_rdLiveSDK setDeviceOrientation:lastOrientation];
}

- (void)setViewLandscape {
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    topView.frame = CGRectMake(0, 0, SCREEN_WIDTH, 44);
    [self setViewLandscapeOrPortrait];

    int maxCount = SCREEN_WIDTH/(SCREEN_HEIGHT/5.);
    UIButton *facueBtn;
    for (int i = 0; i < 10; i++) {
        facueBtn = [facueView viewWithTag:kFacueBtnTag + i];
        facueBtn.center = CGPointMake((i%maxCount)*SCREEN_HEIGHT/5. + SCREEN_HEIGHT/10., SCREEN_HEIGHT*((int)(i/maxCount))/5. + SCREEN_HEIGHT/10. + 30);
    }
    selectedFacueView.center = ((UIButton *)[facueView viewWithTag:kFacueBtnTag+selectedFacueIndex]).center;
}

- (void)setViewLandscapeIOS7 {
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    self.view.bounds = CGRectMake(0, 0, SCREEN_HEIGHT, SCREEN_WIDTH);
    previewView.frame = CGRectMake(0, 0, SCREEN_HEIGHT, SCREEN_WIDTH);
    upBack.frame = CGRectMake(0, 0, SCREEN_HEIGHT, 118);
    hintView.frame = CGRectMake(0, 0, SCREEN_HEIGHT, SCREEN_WIDTH);
    [hintView viewWithTag:1].frame = CGRectMake((SCREEN_WIDTH - 215)/2, 44 + (SCREEN_HEIGHT - 38)/2, 215, 38);
    
    backBtn.frame = CGRectMake(SCREEN_HEIGHT - 40, 2, 40, 40);
    liveTitleTF.frame = CGRectMake(10, (SCREEN_WIDTH/2 - 30)/2, SCREEN_HEIGHT - 20, 30);
    liveBtn.frame = CGRectMake((SCREEN_HEIGHT - 145)/2, (SCREEN_WIDTH - 44)/2, 145, 44);
    setBeautyLevelView.frame = CGRectMake(0, SCREEN_WIDTH - beautyViewHeight, SCREEN_HEIGHT, beautyViewHeight);
    beautyLbl.frame = CGRectMake((SCREEN_HEIGHT - 100)/2, beautyViewHeight - 30, 100, 20);
    beautySlider.frame = CGRectMake(44, 20, SCREEN_HEIGHT - 44*2, 20);
    beautyConfirmBtn.frame = CGRectMake(SCREEN_HEIGHT - 36, beautyViewHeight - 30, 26, 26);
    
    bottomView.frame = CGRectMake(0, SCREEN_WIDTH - 65, SCREEN_HEIGHT, 60);
    float spaceWidth = (SCREEN_HEIGHT - 40*5)/6;
    audioBtn.frame = CGRectMake(spaceWidth, 0, 40, 60);
    musicBtn.frame = CGRectMake(spaceWidth*2 + 40, 0, 40, 60);
    screenShotBtn.frame = CGRectMake(spaceWidth*3 + 40*2, 0, 40, 60);
    setFacueBtn.frame = CGRectMake(spaceWidth*4 + 40*3, 0, 40, 60);
    waterMarkBtn.frame = CGRectMake(spaceWidth*5 + 40*4, 0, 40, 60);
    
    musicView.frame = CGRectMake(0, SCREEN_WIDTH - 150, SCREEN_HEIGHT, 150);
    musicTableView.frame = CGRectMake(0, 0, SCREEN_HEIGHT, musicView.frame.size.height);
    [musicTableView reloadData];
    facueView.frame = CGRectMake(0, SCREEN_WIDTH - 195, SCREEN_HEIGHT, 195);
    hideFacueViewBtn.center = CGPointMake(SCREEN_HEIGHT/2, 20);
    topView.frame = CGRectMake(0, 0, SCREEN_WIDTH, 44);
    
    int maxCount = SCREEN_HEIGHT/(SCREEN_WIDTH/5.);
    UIButton *facueBtn;
    for (int i = 0; i < 10; i++) {
        facueBtn = [facueView viewWithTag:kFacueBtnTag + i];
        facueBtn.center = CGPointMake((i%maxCount)*SCREEN_WIDTH/5. + SCREEN_WIDTH/10., SCREEN_WIDTH*((int)(i/maxCount))/5. + SCREEN_WIDTH/10. + 30);
    }
    selectedFacueView.center = ((UIButton *)[facueView viewWithTag:kFacueBtnTag+selectedFacueIndex]).center;
}

- (void)setViewPortrait {
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    topView.frame = CGRectMake(0, 20, SCREEN_WIDTH, 44);
    [self setViewLandscapeOrPortrait];
    
    UIButton *facueBtn;
    for (int i = 0; i < 10; i++) {
        facueBtn = [facueView viewWithTag:kFacueBtnTag + i];
        facueBtn.center = CGPointMake((i%5)*SCREEN_WIDTH/5. + SCREEN_WIDTH/10., SCREEN_WIDTH*((int)(i/5.))/5. + SCREEN_WIDTH/10. + 30);
    }
    selectedFacueView.center = ((UIButton *)[facueView viewWithTag:kFacueBtnTag+selectedFacueIndex]).center;
}

- (void)setViewLandscapeOrPortrait {
    self.view.bounds = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    previewView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    upBack.frame = CGRectMake(0, 0, SCREEN_WIDTH, 118);
    hintView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    [hintView viewWithTag:1].frame = CGRectMake((SCREEN_WIDTH - 215)/2, 44 + (SCREEN_HEIGHT - 38)/2, 215, 38);
    
    backBtn.frame = CGRectMake(SCREEN_WIDTH - 40, 2, 40, 40);
    liveTitleTF.frame = CGRectMake(10, (SCREEN_HEIGHT/2 - 30)/2, SCREEN_WIDTH - 20, 30);
    liveBtn.frame = CGRectMake((SCREEN_WIDTH - 145)/2, (SCREEN_HEIGHT - 44)/2, 145, 44);
    setBeautyLevelView.frame = CGRectMake(0, SCREEN_HEIGHT - beautyViewHeight, SCREEN_WIDTH, beautyViewHeight);
    beautyLbl.frame = CGRectMake((SCREEN_WIDTH - 100)/2, beautyViewHeight - 30, 100, 20);
    beautySlider.frame = CGRectMake(44, 20, SCREEN_WIDTH - 44*2, 20);
    beautyConfirmBtn.frame = CGRectMake(SCREEN_WIDTH - 36, beautyViewHeight - 30, 26, 26);
    
    bottomView.frame = CGRectMake(0, SCREEN_HEIGHT - 65, SCREEN_WIDTH, 60);
    float spaceWidth = (SCREEN_WIDTH - 40*5)/6;
    audioBtn.frame = CGRectMake(spaceWidth, 0, 40, 60);
    musicBtn.frame = CGRectMake(spaceWidth*2 + 40, 0, 40, 60);
    screenShotBtn.frame = CGRectMake(spaceWidth*3 + 40*2, 0, 40, 60);
    setFacueBtn.frame = CGRectMake(spaceWidth*4 + 40*3, 0, 40, 60);
    waterMarkBtn.frame = CGRectMake(spaceWidth*5 + 40*4, 0, 40, 60);
    
    musicView.frame = CGRectMake(0, SCREEN_HEIGHT - 150, SCREEN_WIDTH, 150);
    musicTableView.frame = CGRectMake(0, 0, SCREEN_WIDTH, musicView.frame.size.height);
    [musicTableView reloadData];
    facueView.frame = CGRectMake(0, SCREEN_HEIGHT - 195, SCREEN_WIDTH, 195);
    hideFacueViewBtn.center = CGPointMake(SCREEN_WIDTH/2, 20);
}

- (void)showOrHideOrientationHintView {
    if (livingOrientation != lastOrientation) {
        if (livingOrientation == UIDeviceOrientationPortrait || livingOrientation == UIDeviceOrientationPortraitUpsideDown)
        {
            if (!orientationHintView) {
                orientationHintView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
                orientationHintView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
                if (lastOrientation == UIDeviceOrientationLandscapeLeft) {
                    orientationHintView.transform = CGAffineTransformMakeRotation(M_PI_2);
                }else {
                    orientationHintView.transform = CGAffineTransformMakeRotation(-M_PI_2);
                }
                orientationHintView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
                [self.view addSubview:orientationHintView];
                
                UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, (SCREEN_WIDTH - 160)/2, SCREEN_HEIGHT, 160)];
                contentView.backgroundColor = [UIColor clearColor];
                [orientationHintView addSubview:contentView];
                
                UIImageView *imageView = [[UIImageView alloc] init];
                imageView.frame = CGRectMake((SCREEN_HEIGHT - 91)/2, 0, 91, 91);
                imageView.image = [UIImage imageNamed:@"直播竖屏提示_"];
                [contentView addSubview:imageView];
                
                UILabel *label1 = [[UILabel alloc] init];
                label1.frame = CGRectMake(0, 160 - 35 - 30, SCREEN_HEIGHT, 30);
                label1.text = @"现在是竖屏直播模式";
                label1.textAlignment = NSTextAlignmentCenter;
                [label1 setFont:[UIFont systemFontOfSize:20]];
                [label1 setTextColor:[UIColor colorWithWhite:1.0 alpha:0.5]];
                [contentView addSubview:label1];
                
                UILabel *label2 = [[UILabel alloc] init];
                label2.frame = CGRectMake(0, 160 - 35, SCREEN_HEIGHT, 35);
                label2.text = @"请保持竖屏";
                label2.textAlignment = NSTextAlignmentCenter;
                [label2 setFont:[UIFont systemFontOfSize:25]];
                [label2 setTextColor:[UIColor colorWithWhite:1.0 alpha:1.0]];
                [contentView addSubview:label2];
            }
        }else {
            if (!orientationHintView) {
                orientationHintView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
                orientationHintView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
                if (livingOrientation == UIDeviceOrientationLandscapeLeft) {
                    orientationHintView.transform = CGAffineTransformMakeRotation(-M_PI_2);
                }else {
                    orientationHintView.transform = CGAffineTransformMakeRotation(M_PI_2);
                }
                orientationHintView.frame = CGRectMake(0, 0, SCREEN_HEIGHT, SCREEN_WIDTH);
                [self.view addSubview:orientationHintView];
                
                UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, (SCREEN_HEIGHT - 160)/2, SCREEN_HEIGHT, 160)];
                [orientationHintView addSubview:contentView];
                
                UIImageView *imageView = [[UIImageView alloc] init];
                imageView.frame = CGRectMake((SCREEN_WIDTH - 91)/2, 0, 91, 91);
                imageView.image = [UIImage imageNamed:@"直播横屏提示_"];
                [contentView addSubview:imageView];
                
                UILabel* label1 = [[UILabel alloc] init];
                label1.frame = CGRectMake(0, 160 - 35 - 30, SCREEN_WIDTH, 30);
                label1.text = @"现在是横屏直播模式";
                label1.textAlignment = NSTextAlignmentCenter;
                [label1 setFont:[UIFont systemFontOfSize:20]];
                [label1 setTextColor:[UIColor colorWithWhite:1.0 alpha:0.5]];
                [contentView addSubview:label1];
                
                UILabel* label2 = [[UILabel alloc] init];
                label2.frame = CGRectMake(0, 160 - 35, SCREEN_WIDTH, 35);
                label2.text = @"请保持横屏";
                label2.textAlignment = NSTextAlignmentCenter;
                [label2 setFont:[UIFont systemFontOfSize:25]];
                [label2 setTextColor:[UIColor colorWithWhite:1.0 alpha:1.0]];
                [contentView addSubview:label2];
            }
        }
    }else {
        if (orientationHintView) {
            [orientationHintView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [obj removeFromSuperview];
            }];
            [orientationHintView removeFromSuperview];
            orientationHintView = nil;
        }
    }
}

- (void)dealloc{
    NSLog(@"%s",__func__);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

