//
//  LivePlayerViewController.m
//  RDLiveSDKDemo
//
//  Created by Wuxiaoxia on 16/5/15.
//  Copyright © 2016年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "LivePlayerViewController.h"
#import "RDRTMPPlayer.h"
#import "RDRtspToRtmp.h"
#import "Reachability.h"
#import <CoreMotion/CoreMotion.h>
#import "AppDelegate.h"

@interface LivePlayerViewController ()<RDRTMPPlayerDelegate, UITextFieldDelegate>
{
    RDRTMPPlayer            * rtmpPlayer;
    BOOL                      _isPlaying;
    NetworkStatus             oldNetStatus;
    BOOL                      isNetworkReachable;
    BOOL                      isRtmpPlayerConnectFailed;
    int                       connectTime;
    NSTimer                 * connectTimer;//连接RTMPPlayer时间记录 Timer
    RDRTMPPlayerError         playerError;
    UIView                  * waitBackView;
    UIView                  * waitView;
    UILabel                 * waitLbl;
    UIImageView             * waitPointIV1;
    UIImageView             * waitPointIV2;
    UIImageView             * waitPointIV3;
    UIImageView             * livePauseIV;
    BOOL                      isLivePaused;
    UIButton                * zoomBtn;
    BOOL                      isLandscape;
    BOOL                      isFullScreen;
    BOOL                      isUserSetFullScreen;
    CGSize                    rtmpPlayerNaturalSize;
    
    //rtspToRtmp
    RDRtspToRtmp            * rtspToRtmp;
    UIButton                * startConvertBtn;
    BOOL                      isStartConvert;
    
    CMMotionManager         * motionManager;
    UIDeviceOrientation       lastOrientation;
    AppDelegate             * appDelegate;
    UIImageView             * upBack;
    UIButton                * backBtn;
}
@property (nonatomic, copy) NSDictionary    * videoInfoDic;

@end

@implementation LivePlayerViewController

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [UIView setAnimationsEnabled:NO];//禁止横竖屏切换动画
    [UIApplication sharedApplication].idleTimerDisabled = YES;//不自动锁屏
    self.navigationController.navigationBar.hidden = YES;
    [self.navigationItem setHidesBackButton:YES];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
    [self.navigationController.navigationBar setTranslucent:NO];
    [self checkReachability];
    appDelegate.allowRotation = YES;
    [self observeOrientation];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [UIView setAnimationsEnabled:YES];//恢复动画
    [motionManager stopAccelerometerUpdates];
    motionManager = nil;
    appDelegate.allowRotation = NO;
    [UIApplication sharedApplication].idleTimerDisabled = NO;//自动锁屏
    rtmpPlayer.rtmpPlayerDelegate = nil;
    rtmpPlayer = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    connectTime = 0;
    isRtmpPlayerConnectFailed = NO;
    _isPlaying = NO;
    lastOrientation = UIDeviceOrientationPortrait;
    [self initRTMPPlayer];
    
    //上边框渐变背景
    upBack = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 118)];
    upBack.image = [UIImage imageNamed:@"直播_渐变背景上"];
    [self.view addSubview:upBack];
    
    if (!_isWatchUidLive) {
        [rtmpPlayer play];
        if (_rtspUrl) {
            isStartConvert = NO;
            [self initRtspToRtmp];
        }
    }
    
    [self initWaitView];
    [self initLivePauseView];
    
    backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    backBtn.frame = CGRectMake(SCREEN_WIDTH - 44, 20, 44, 44);
    [backBtn setImage:[UIImage imageNamed:@"主界面-返回默认"] forState:UIControlStateNormal];
    [backBtn setImage:[UIImage imageNamed:@"主界面-返回点击"] forState:UIControlStateHighlighted];
    [backBtn addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backBtn];
    
    [self performSelector:@selector(beginChangeImage:) withObject:@"1" afterDelay:0.5];
}

#pragma mark - 初始化
- (void)initRTMPPlayer{
    rtmpPlayer = [[RDRTMPPlayer alloc] initWithAPPKey:APPKEY
                                         andSecretKey:SECRETKEY
                                              success:^{
                                                  NSLog(@"初始化SDK成功");
                                              } error:^(NSError *error) {
                                                  NSLog(@"初始化SDK失败:%@", error.localizedDescription);
                                                  waitView.hidden = YES;
                                                  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:error.localizedDescription
                                                                                                  message:nil
                                                                                                 delegate:self
                                                                                        cancelButtonTitle:@"确定"
                                                                                        otherButtonTitles:nil];
                                                  [alert show];
                                              }];

    if (_isWatchUidLive) {
        __weak LivePlayerViewController *weakSelf = self;
        [rtmpPlayer getLiveInfoWithUid:_userID
                               success:^(NSDictionary *liveInfoDic) {
                                   weakSelf.videoInfoDic = liveInfoDic;
                                   rtmpPlayer.contentRtmpURLStr = [_videoInfoDic objectForKey:@"liveRtmpUrl"];
                                   [rtmpPlayer play];
                               } error:^(NSError *error) {
                                   waitView.hidden = YES;
                                   UIAlertView *alert = [[UIAlertView alloc] initWithTitle:error.localizedDescription
                                                                                   message:nil
                                                                                  delegate:self
                                                                         cancelButtonTitle:@"确定"
                                                                         otherButtonTitles:nil];
                                   [alert show];
                               }];
    }else {
        if (_rtmpUrl) {
            rtmpPlayer.contentRtmpURLStr = _rtmpUrl;
        }else if (_rtspUrl) {
            rtmpPlayer.contentRtmpURLStr = _rtspUrl;
            rtmpPlayer.audioIsDisabled = YES;
            rtmpPlayer.frameIsDrop = YES;
            rtmpPlayer.transport = RTSP_TRANSPORT_UDP;
        }
    }
    rtmpPlayer.playerView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    rtmpPlayer.playerView.backgroundColor = [UIColor clearColor];
    rtmpPlayer.playerScalingMode = RDRTMPPlayerScalingModeAspectFill;
    rtmpPlayer.rtmpPlayerDelegate = self;
    rtmpPlayer.timeOut = 20;
    [self.view insertSubview:rtmpPlayer.playerView atIndex:0];
}

- (void)initRtspToRtmp{
    NSString *rtmpPath = @"rtmp://***";
    
    rtspToRtmp = [[RDRtspToRtmp alloc] initWithAPPKey:APPKEY
                                         andSecretKey:SECRETKEY
                                              success:^{
                                                  
                                              } error:^(NSError *error) {
                                                  NSLog(@"初始化RDRtspToRtmp失败:%@", error.localizedDescription);
                                              }];
    [rtspToRtmp prepareRtspToRtmpWithInputRTSP:_rtspUrl outputRTMP:rtmpPath];
    rtspToRtmp.errorCallBack = ^(RDRtspToRtmpState errorCode)
    {
        NSLog(@"errorCode:%ld",(long)errorCode);
    };
    
#if 0
    //rtsp转换为rtmp
    startConvertBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    startConvertBtn.frame = CGRectMake(SCREEN_WIDTH - 110, SCREEN_HEIGHT - 35, 100, 30);
    startConvertBtn.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    startConvertBtn.layer.cornerRadius = 5.0;
    [startConvertBtn setTitle:@"startConvert" forState:UIControlStateNormal];
    startConvertBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [startConvertBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [startConvertBtn addTarget:self action:@selector(startConvert:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:startConvertBtn];
#endif
}

- (void)initWaitView {
    waitBackView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    waitBackView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    [self.view addSubview:waitBackView];
    
    waitView = [[UIView alloc] initWithFrame:CGRectMake((SCREEN_WIDTH - 150)/2, (SCREEN_HEIGHT - 31 - 50)/2, 150, 81)];
    waitView.backgroundColor = [UIColor clearColor];
    [waitBackView addSubview:waitView];
    
    UIImageView *waitIV = [[UIImageView alloc] initWithFrame:CGRectMake((150 - 54 + 30)/2, 0, 54, 31)];
    waitIV.backgroundColor = [UIColor clearColor];
    waitIV.image = [UIImage imageNamed:@"播放_等待火箭"];
    [waitView addSubview:waitIV];
    
    waitLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, waitIV.frame.origin.y + 31 + 10, 150, 20)];
    waitLbl.backgroundColor = [UIColor clearColor];
    waitLbl.text = @"正在连接中，请稍候...";
    waitLbl.textAlignment = NSTextAlignmentCenter;
    waitLbl.textColor = [UIColor whiteColor];
    waitLbl.font = [UIFont systemFontOfSize:14.0];
    [waitView addSubview:waitLbl];
    
    waitPointIV1 = [[UIImageView alloc] initWithFrame:CGRectMake(waitIV.frame.origin.x - 10, (81 - 50 - 5)/2, 5, 5)];
    waitPointIV1.backgroundColor = [UIColor clearColor];
    waitPointIV1.image = [UIImage imageNamed:@"播放_等待点"];
    waitPointIV1.hidden = YES;
    [waitView addSubview:waitPointIV1];
    
    waitPointIV2 = [[UIImageView alloc] initWithFrame:CGRectMake(waitIV.frame.origin.x - 20, (81 - 50 - 5)/2, 5, 5)];
    waitPointIV2.backgroundColor = [UIColor clearColor];
    waitPointIV2.image = [UIImage imageNamed:@"播放_等待点"];
    waitPointIV2.hidden = YES;
    [waitView addSubview:waitPointIV2];
    
    waitPointIV3 = [[UIImageView alloc] initWithFrame:CGRectMake(waitIV.frame.origin.x - 30, (81 - 50 - 5)/2, 5, 5)];
    waitPointIV3.backgroundColor = [UIColor clearColor];
    waitPointIV3.image = [UIImage imageNamed:@"播放_等待点"];
    waitPointIV3.hidden = YES;
    [waitView addSubview:waitPointIV3];
}

- (void)initLivePauseView {
    livePauseIV = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    livePauseIV.backgroundColor = [UIColor clearColor];
    livePauseIV.image = [UIImage imageNamed:@"livePause.jpg"];
    livePauseIV.contentMode = UIViewContentModeScaleAspectFill;
    livePauseIV.hidden = YES;
    [self.view addSubview:livePauseIV];
}

-(void)beginChangeImage:(NSString *)pointCountsStr{
    if (!waitView.hidden) {
        int pointCounts = [pointCountsStr intValue];
        switch (pointCounts) {
            case 0:
                waitPointIV1.hidden = YES;
                waitPointIV2.hidden = YES;
                waitPointIV3.hidden = YES;
                [self performSelector:@selector(beginChangeImage:) withObject:@"1" afterDelay:0.5];
                break;
                
            case 1:
                waitPointIV1.hidden = NO;
                waitPointIV2.hidden = YES;
                waitPointIV3.hidden = YES;
                [self performSelector:@selector(beginChangeImage:) withObject:@"2" afterDelay:0.5];
                break;
                
            case 2:
                waitPointIV1.hidden = NO;
                waitPointIV2.hidden = NO;
                waitPointIV3.hidden = YES;
                [self performSelector:@selector(beginChangeImage:) withObject:@"3" afterDelay:0.5];
                break;
                
            case 3:
                waitPointIV1.hidden = NO;
                waitPointIV2.hidden = NO;
                waitPointIV3.hidden = NO;
                [self performSelector:@selector(beginChangeImage:) withObject:@"0" afterDelay:0.5];
                break;
                
            default:
                break;
        }
    }
}

#pragma mark - RTMPPlayerDelegate
- (void)RDRTMPPlayerStateChanged:(RDRTMPPlayerState)state errorCode:(RDRTMPPlayerError)errCode player:(id)player{
//    NSLog(@"播放器状态：%ld----播放器错误码：%ld", (long)state, (long)errCode);
    playerError = errCode;
    switch (state) {
        case kRDRTMPPlayerStateConnecting:
            _isPlaying = YES;
            if (!isLivePaused) {
                waitLbl.text = @"正在连接中，请稍候...";
                if (waitView.hidden) {
                    waitView.hidden = NO;
                    [self performSelector:@selector(beginChangeImage:) withObject:@"1" afterDelay:0.5];
                }
            }
            
            break;
            
        case kRDRTMPPlayerStateGotVideoStreamInfo:
            if (rtmpPlayer.contentNaturalSize.width > rtmpPlayer.contentNaturalSize.height) {
                if (rtmpPlayer.playerScalingMode != RDRTMPPlayerScalingModeAspectFit) {
                    rtmpPlayer.playerScalingMode = RDRTMPPlayerScalingModeAspectFit;
                }
                isLandscape = YES;
                if (!zoomBtn) {
                    rtmpPlayerNaturalSize = rtmpPlayer.contentNaturalSize;
                    
                    zoomBtn = [UIButton buttonWithType:UIButtonTypeCustom];
                    if (rtmpPlayerNaturalSize.width*9/16 <= rtmpPlayerNaturalSize.height + 10 && rtmpPlayerNaturalSize.width*9/16 >= rtmpPlayerNaturalSize.height - 10) {
                        zoomBtn.frame = CGRectMake(SCREEN_WIDTH - 40, (SCREEN_HEIGHT - SCREEN_WIDTH*9/16)/2 + SCREEN_WIDTH*9/16 - 40, 40, 40);
                    }
                    else if (rtmpPlayerNaturalSize.width*3/4 <= rtmpPlayerNaturalSize.height + 10 && rtmpPlayerNaturalSize.width*3/4 >= rtmpPlayerNaturalSize.height - 10) {
                        zoomBtn.frame = CGRectMake(SCREEN_WIDTH - 40, (SCREEN_HEIGHT - SCREEN_WIDTH*3/4)/2 + SCREEN_WIDTH*3/4 - 40, 40, 40);
                    }
                    else {
                        zoomBtn.frame = CGRectMake(SCREEN_WIDTH - 40, SCREEN_HEIGHT/2 + rtmpPlayer.contentNaturalSize.height/4 - 20, 40, 40);
                    }
                    if (isFullScreen) {
                        zoomBtn.frame = CGRectMake(SCREEN_WIDTH - 50, SCREEN_HEIGHT - 45*2, 40, 40);
                    }
                    zoomBtn.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
                    zoomBtn.layer.cornerRadius = 5.0;
                    [zoomBtn setImage:[UIImage imageNamed:@"播放-视频放大"] forState:UIControlStateNormal];
                    [zoomBtn addTarget:self action:@selector(zoomBtnAction:) forControlEvents:UIControlEventTouchUpInside];
                    [self.view addSubview:zoomBtn];
                }
                if (rtmpPlayer.playerScalingMode != RDRTMPPlayerScalingModeAspectFit) {
                    rtmpPlayer.playerScalingMode = RDRTMPPlayerScalingModeAspectFit;
                }
            }
            break;
            
        case kRDRTMPPlayerStatePlayed:
            livePauseIV.hidden = YES;
            isLivePaused = NO;
            _isPlaying = YES;
            connectTime = 0;
            [connectTimer invalidate];
            connectTimer  = nil;
            waitView.hidden = YES;
            
            break;
            
        case kRDRTMPPlayerStateConnectionFailed:
            if (!isLivePaused) {
                _isPlaying = NO;
                waitLbl.text = @"正在连接中，请稍候...";
                if (waitView.hidden) {
                    waitView.hidden = NO;
                    [self performSelector:@selector(beginChangeImage:) withObject:@"1" afterDelay:0.5];
                }
            }
            if (isNetworkReachable) {
                [self checkLiveState];
            }else {
                isRtmpPlayerConnectFailed = YES;
                if (!connectTimer) {
                    connectTime = 0;
                    [connectTimer invalidate];
                    connectTimer = nil;
                    connectTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(connectTimeCount) userInfo:nil repeats:YES];
                }
            }
            break;
            
        case kRDRTMPPlayerStatePacketLoading:
            if (!isLivePaused) {
                waitLbl.text = @"网络不佳，请稍候...";
                if (waitView.hidden) {
                    waitView.hidden = NO;
                    [self performSelector:@selector(beginChangeImage:) withObject:@"1" afterDelay:0.5];
                }
            }
            break;
            
        case kRDRTMPPlayerStatePacketLoaded:
            waitView.hidden = YES;
            break;
            
        default:
            break;
    }
    switch (errCode) {
        case kRDRTMPPlayerErrorNone:
            break;
            
        case kRDRTMPPlayerErrorStreamReadError:
            if (!isLivePaused) {
                _isPlaying = NO;
                waitLbl.text = @"正在连接中，请稍候...";
                if (waitView.hidden) {
                    waitView.hidden = NO;
                    [self performSelector:@selector(beginChangeImage:) withObject:@"1" afterDelay:0.5];
                }
            }
            if (isNetworkReachable) {
                [self checkLiveState];
            }else {
                isRtmpPlayerConnectFailed = YES;
                if (!connectTimer) {
                    connectTime = 0;
                    [connectTimer invalidate];
                    connectTimer = nil;
                    connectTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(connectTimeCount) userInfo:nil repeats:YES];
                }
            }
            break;
            
        case kRDRTMPPlayerErrorStreamEOFError:
            _isPlaying = NO;
            if (isNetworkReachable) {
                [self checkLiveState];
            }else {
                isRtmpPlayerConnectFailed = YES;
                if (!isLivePaused) {
                    waitLbl.text = @"正在连接中，请稍候...";
                    if (waitView.hidden) {
                        waitView.hidden = NO;
                        [self performSelector:@selector(beginChangeImage:) withObject:@"1" afterDelay:0.5];
                    }
                }
                if (!connectTimer) {
                    connectTime = 0;
                    [connectTimer invalidate];
                    connectTimer = nil;
                    connectTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(connectTimeCount) userInfo:nil repeats:YES];
                }
            }
            break;
            
        default:
            break;
    }
}

#pragma mark - 获取直播状态:0准备好，1废弃/出错，2直播中，3流断开，4直播结束
- (void)checkLiveState {
    __weak LivePlayerViewController *weakSelf = self;
    [rtmpPlayer getLiveInfoWithUid:_userID
                           success:^(NSDictionary *liveInfoDic) {
                               int liveStatus = [[liveInfoDic objectForKey:@"liveStatus"] intValue];
                               NSLog(@"直播状态：%d  playerError:%ld", liveStatus, (long)playerError);
                               [weakSelf reconnetRtmpPlayerWithStatus:liveStatus];
                           } error:^(NSError *error) {
                               _isPlaying = NO;
                               waitView.hidden = YES;
                               UIAlertView *alert = [[UIAlertView alloc] initWithTitle:error.localizedDescription
                                                                               message:nil
                                                                              delegate:self
                                                                     cancelButtonTitle:@"确定"
                                                                     otherButtonTitles:nil];
                               [alert show];
                           }];
}

- (void)reconnetRtmpPlayerWithStatus:(int)status {
    switch (status) {
        case 0:
        case 2:
            if (playerError == kRDRTMPPlayerErrorStreamReadError) {
                if (!connectTimer) {
                    connectTime = 0;
                    [connectTimer invalidate];
                    connectTimer = nil;
                    connectTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(connectTimeCount) userInfo:nil repeats:YES];
                    [rtmpPlayer play];
                }
            }else {
                [rtmpPlayer.playerView removeFromSuperview];
                rtmpPlayer.rtmpPlayerDelegate = nil;
                rtmpPlayer = nil;
                [self initRTMPPlayer];//需重新初始化播放器，再播放
                if (!_isWatchUidLive) {
                    [rtmpPlayer play];
                }
            }
            break;
            
        case 3:
            isLivePaused = YES;
            livePauseIV.hidden = NO;
            waitView.hidden = YES;
            if (playerError == kRDRTMPPlayerErrorStreamReadError) {
                if (!connectTimer) {
                    connectTime = 0;
                    [connectTimer invalidate];
                    connectTimer = nil;
                    connectTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(connectTimeCount) userInfo:nil repeats:YES];
                    [rtmpPlayer play];
                }
            }else {
                [rtmpPlayer.playerView removeFromSuperview];
                rtmpPlayer.rtmpPlayerDelegate = nil;
                rtmpPlayer = nil;
                [self initRTMPPlayer];
                if (!_isWatchUidLive) {
                    [rtmpPlayer play];
                }
            }
            break;
            
        case 4:
        {
            rtmpPlayer.rtmpPlayerDelegate = nil;
            waitView.hidden = YES;
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"该主播已退出房间！"
                                                            message:nil
                                                           delegate:self
                                                  cancelButtonTitle:@"确定"
                                                  otherButtonTitles:nil];\
            [alert show];
        }
            
        default:
            break;
    }
}

-(void)connectTimeCount
{
    if (connectTime > 8) {
        [connectTimer invalidate];
        connectTimer  = nil;
        _isPlaying = NO;
        waitView.hidden = YES;
        rtmpPlayer.rtmpPlayerDelegate = nil;
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"连接失败,无法加载视频"
                                                        message:nil
                                                       delegate:self
                                              cancelButtonTitle:@"确定"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }else {
        connectTime++;
        NSLog(@"connectTime:%d", connectTime);
    }
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self performSelector:@selector(back) withObject:nil afterDelay:0.25];
    }
}

#pragma mark - 按钮事件
-(void)back{
    if (lastOrientation != UIDeviceOrientationPortrait) {
        appDelegate.orientationMask = UIInterfaceOrientationMaskPortrait;
        NSNumber *orientationTarget = [NSNumber numberWithInt:UIDeviceOrientationPortrait];
        [[UIDevice currentDevice] setValue:orientationTarget forKey:@"orientation"];
        [UIViewController attemptRotationToDeviceOrientation];
        [self setViewPortrait];
    }
    
    [connectTimer invalidate];
    connectTimer  = nil;
    if (_isPlaying && rtmpPlayer) {
        [rtmpPlayer stop];
        _isPlaying = NO;
    }
    rtmpPlayer.rtmpPlayerDelegate = nil;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)startConvert:(UIButton *)sender {
    if (isStartConvert) {
        NSLog(@"stoping rtsp to rtmp");
        [rtspToRtmp stopRtspToRtmp:^(RDRtspToRtmpState errorCode) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (errorCode == kRDRtspToRtmpStateOK) {
                    [startConvertBtn setTitle:@"startConvert" forState:UIControlStateNormal];
                    isStartConvert = NO;
                    NSLog(@"stop成功");
                }else{
                    NSLog(@"stop error:%ld",(long)errorCode);
                }
            });
        }];
    }else {
        NSLog(@"starting rtsp to rtmp");
        [rtspToRtmp startRtspToRtmp:^(RDRtspToRtmpState errorCode) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (errorCode == kRDRtspToRtmpStateOK) {
                    [startConvertBtn setTitle:@"stopConvert" forState:UIControlStateNormal];
                    isStartConvert = YES;
                    NSLog(@"start成功");
                }else{
                    NSLog(@"start error:%ld",(long)errorCode);
                }
            });
        }];
    }
}

- (void)zoomBtnAction:(id)sender {
    if (isFullScreen) {
        isUserSetFullScreen = NO;
        [self deviceOrientationDidChangeTo:UIDeviceOrientationPortrait];
    }else {
        isUserSetFullScreen = YES;
        [self deviceOrientationDidChangeTo:UIDeviceOrientationLandscapeLeft];
    }
}

#pragma mark - 设备方向
- (void)observeOrientation{
    motionManager=[[CMMotionManager alloc]init];
    __block typeof(self) weakSelf = self;
    
    if (motionManager.accelerometerAvailable) {
        [motionManager setAccelerometerUpdateInterval:0.5f];
        NSOperationQueue *operationQueue = [NSOperationQueue mainQueue];
        [motionManager startAccelerometerUpdatesToQueue:operationQueue withHandler:^(CMAccelerometerData *data,NSError *error)
         {
//             if (!isLandscape || isUserSetFullScreen) {
//                 return ;
//             }
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
                     [selfBlock deviceOrientationDidChangeTo:orientation];
                     
                 });
             }
         }];
    }
}

- (void)deviceOrientationDidChangeTo:(UIDeviceOrientation )orientation{
    switch (orientation) {
        case  UIDeviceOrientationLandscapeLeft:
        {
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
            if (SYSTEM_VERSION >= 8.0) {
                [self setViewLandscape];
            }else {
                [self setViewLandscapeIOS7];
            }
            
            NSLog(@"UIDeviceOrientationLandscapeLeft");
        }
            break;
            
        case  UIDeviceOrientationLandscapeRight:
        {
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
            if (SYSTEM_VERSION >= 8.0) {
                [self setViewLandscape];
            }else {
                [self setViewLandscapeIOS7];
            }
            
            NSLog(@"UIDeviceOrientationLandscapeRight");
        }
            break;
            
        default:
        {
            appDelegate.orientationMask = UIInterfaceOrientationMaskPortrait;
            NSNumber *orientationTarget = [NSNumber numberWithInt:UIDeviceOrientationPortrait];
            [[UIDevice currentDevice] setValue:orientationTarget forKey:@"orientation"];
            [UIViewController attemptRotationToDeviceOrientation];
            
            lastOrientation = orientation;
            [self setViewPortrait];
            
            NSLog(@"UIDeviceOrientationPortrait");
        }
            break;
    }
}

//放大
- (void)setViewLandscape {    
    isFullScreen = YES;
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [self setViewLandscapeOrPortrait];
    
    if (!isLandscape) {
        rtmpPlayer.playerScalingMode = RDRTMPPlayerScalingModeAspectFit;
    }
}

- (void)setViewLandscapeIOS7 {
    isFullScreen = YES;
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    self.view.bounds = CGRectMake(0, 0, SCREEN_HEIGHT, SCREEN_WIDTH);
    upBack.frame = CGRectMake(0, 0, SCREEN_HEIGHT, 118);
    backBtn.frame = CGRectMake(SCREEN_HEIGHT - 44, 0, 44, 44);
    rtmpPlayer.playerView.frame = CGRectMake(0, 0, SCREEN_HEIGHT, SCREEN_WIDTH);
    
    if (rtmpPlayerNaturalSize.width*9/16 <= rtmpPlayerNaturalSize.height + 10 && rtmpPlayerNaturalSize.width*9/16 >= rtmpPlayerNaturalSize.height - 10) {
        zoomBtn.frame = CGRectMake(SCREEN_HEIGHT - 40, (SCREEN_WIDTH - SCREEN_HEIGHT*9/16)/2 + SCREEN_HEIGHT*9/16 - 40, 40, 40);
    }
    else if (rtmpPlayerNaturalSize.width*3/4 <= rtmpPlayerNaturalSize.height + 10 && rtmpPlayerNaturalSize.width*3/4 >= rtmpPlayerNaturalSize.height - 10) {
        zoomBtn.frame = CGRectMake(SCREEN_HEIGHT - 40, (SCREEN_WIDTH - SCREEN_HEIGHT*3/4)/2 + SCREEN_HEIGHT*3/4 - 40, 40, 40);
    }
    else {
        zoomBtn.frame = CGRectMake(SCREEN_HEIGHT - 40, SCREEN_WIDTH/2 + rtmpPlayerNaturalSize.height/4 - 20, 40, 40);
    }
    [zoomBtn setImage:[UIImage imageNamed:@"播放-视频放大"] forState:UIControlStateNormal];
    
    if (!isLandscape) {
        rtmpPlayer.playerScalingMode = RDRTMPPlayerScalingModeAspectFill;
    }
    waitBackView.frame = CGRectMake(0, 0, SCREEN_HEIGHT, SCREEN_WIDTH);
    waitView.frame = CGRectMake((SCREEN_HEIGHT - 150)/2, (SCREEN_WIDTH - 31 - 50)/2, 150, 81);
    livePauseIV.frame = CGRectMake(0, 0, SCREEN_HEIGHT, SCREEN_WIDTH);
    
    if (!isLandscape) {
        rtmpPlayer.playerScalingMode = RDRTMPPlayerScalingModeAspectFit;
    }
}

//缩小
- (void)setViewPortrait {
    isFullScreen = NO;
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [self setViewLandscapeOrPortrait];
    
    if (!isLandscape) {
        rtmpPlayer.playerScalingMode = RDRTMPPlayerScalingModeAspectFill;
    }
}

- (void)setViewLandscapeOrPortrait {
    self.view.bounds = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    upBack.frame = CGRectMake(0, 0, SCREEN_WIDTH, 118);
    backBtn.frame = CGRectMake(SCREEN_WIDTH - 44, 20, 44, 44);
    rtmpPlayer.playerView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    
    if (rtmpPlayerNaturalSize.width*9/16 <= rtmpPlayerNaturalSize.height + 10 && rtmpPlayerNaturalSize.width*9/16 >= rtmpPlayerNaturalSize.height - 10) {
        zoomBtn.frame = CGRectMake(SCREEN_WIDTH - 40, (SCREEN_HEIGHT - SCREEN_WIDTH*9/16)/2 + SCREEN_WIDTH*9/16 - 40, 40, 40);
    }
    else if (rtmpPlayerNaturalSize.width*3/4 <= rtmpPlayerNaturalSize.height + 10 && rtmpPlayerNaturalSize.width*3/4 >= rtmpPlayerNaturalSize.height - 10) {
        zoomBtn.frame = CGRectMake(SCREEN_WIDTH - 40, (SCREEN_HEIGHT - SCREEN_WIDTH*3/4)/2 + SCREEN_WIDTH*3/4 - 40, 40, 40);
    }
    else {
        zoomBtn.frame = CGRectMake(SCREEN_WIDTH - 40, SCREEN_HEIGHT/2 + rtmpPlayerNaturalSize.height/4 - 20, 40, 40);
    }
    [zoomBtn setImage:[UIImage imageNamed:@"播放-视频放大"] forState:UIControlStateNormal];
    
    if (!isLandscape) {
        rtmpPlayer.playerScalingMode = RDRTMPPlayerScalingModeAspectFill;
    }
    waitBackView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    waitView.frame = CGRectMake((SCREEN_WIDTH - 150)/2, (SCREEN_HEIGHT - 31 - 50)/2, 150, 81);
    livePauseIV.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
}

#pragma mark - 检查网络状态
- (void)checkReachability
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    oldNetStatus = [reachability currentReachabilityStatus];
    if (oldNetStatus == NotReachable) {
        isNetworkReachable = NO;
    }else if (oldNetStatus == ReachableViaWiFi || oldNetStatus == ReachableViaWWAN) {
        isNetworkReachable = YES;
    }
    [reachability startNotifier];
    [self updateInterfaceWithReachability:reachability];
}

/*!
 * Called by Reachability whenever status changes.
 */
- (void) reachabilityChanged:(NSNotification *)note
{
    Reachability* curReach = [note object];
    NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
    [self updateInterfaceWithReachability:curReach];
}

- (void)updateInterfaceWithReachability:(Reachability *)newReachability
{
    NetworkStatus status = [newReachability currentReachabilityStatus];
    
    if (oldNetStatus != status) {
        oldNetStatus = status;
        if(status == NotReachable)
        {
            NSLog(@"网络状态：No Internet");
            isNetworkReachable = NO;
        }
        else if (status == ReachableViaWiFi)
        {
            if (isRtmpPlayerConnectFailed && connectTime <= 8) {
                connectTime = 0;
                [rtmpPlayer.playerView removeFromSuperview];
                rtmpPlayer.rtmpPlayerDelegate = nil;
                rtmpPlayer = nil;
                [self initRTMPPlayer];
                if (!_isWatchUidLive) {
                    [rtmpPlayer play];
                }
            }
            NSLog(@"网络状态：Reachable WIFI");
            isNetworkReachable = YES;
        }
        else if (status == ReachableViaWWAN && connectTime <= 8)
        {
            if (isRtmpPlayerConnectFailed) {
                connectTime = 0;
                [rtmpPlayer.playerView removeFromSuperview];
                rtmpPlayer.rtmpPlayerDelegate = nil;
                rtmpPlayer = nil;
                [self initRTMPPlayer];
                if (!_isWatchUidLive) {
                    [rtmpPlayer play];
                }
            }
            NSLog(@"网络状态：Reachable 3G");
            isNetworkReachable = YES;
        }
    }
}

- (void)dealloc {
    NSLog(@"%s",__func__);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
