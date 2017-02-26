//
//  RDLiveSDK.h
//  LiveVideoDemo
//
//  Created by 周晓林 on 2016/9/22.
//  Copyright © 2016年 周晓林. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#pragma mark - RDLiveErrorCode 具体初始化锐动直播SDK错误码
typedef NS_ENUM(NSInteger, RDLiveErrorCode) {
    /*!
     传入的APPKEY为空
     */
    RDLIVE_PARA_APPKEY_NULL = 10000,
    
    /*!
     传入的SECRETKEY为空
     */
    RDLIVE_PARA_SECRETKEY_NULL,
    
    /*!
     传入的VIDEOSIZE(分辨率)为空
     */
    RDLIVE_PARA_LIVE_VIDEOSIZE_NULL,
    
    /*!
     传入的FPS(帧率)错误
     */
    RDLIVE_PARA_LIVE_FPS_INVALID,
    
    /*!
     传入的BPS(码率)为空
     */
    RDLIVE_PARA_LIVE_BPS_NULL,
    
    /*!
     传入的URL(直播地址)为空
     */
    RDLIVE_PARA_PLAYER_URL_NULL,
    
    /*!
     服务器连接异常
     */
    RDLIVE_CLIENT_INVALID,
    
    /*!
     服务已到期
     */
    RDLIVE_SERVICES_EXPIRED,
    
    /*!
     开始直播接口选择错误
     */
    RDLIVE_LIVE_INTERFACE_ERROR,
    
    /*!
     开始直播接口参数错误
     */
    RDLIVE_LIVE_PARA_ERROR
};

//申请的服务类型
typedef NS_ENUM(NSInteger, RDLiveAuthorizationType)
{
    RDLive_AT_URL,          //0:基础功能
    RDLive_AT_UID,          //1:云服务
    RDLive_AT_URL_OR_UID,   //2:基础功能、云服务均可
    RDLive_AT_INVALID       //3:服务已到期
};

//是否设置美颜
typedef NS_ENUM(NSInteger,RDRtmpPublishBeautifyState) {
    RDRTMPPUBLISH_BEAUTIFY_SELECTED,    //0:设置美颜
    RDRTMPPUBLISH_BEAUTIFY_NORMAL,      //1:不设置美颜
};

//摄像头类型
typedef NS_ENUM(NSInteger, RDRtmpPublishCameraState)
{
    RDRtmpPublishCameraStateFront,      //0:前置摄像头
    RDRtmpPublishCameraStateBack        //1:后置摄像头
};

//推流状态
typedef NS_ENUM(NSInteger, RDRtmpPublishState)
{
    RDRtmpPublishStateNone              =0,     //0
    RDRtmpPublishStateCameraStarted,            //1
    RDRtmpPublishStateStarting,                 //2
    RDRtmpPublishStateStarted,                  //3
    RDRtmpPublishStatePaused,                   //4
    RDRtmpPublishStateEnded,                    //5
    RDRtmpPublishStateError                     //6
};

//滤镜类型
typedef NS_ENUM(NSInteger, RDRtmpPublishFilterType) {
    RDRtmpPublishFilterNormal,         //0  原始
    RDRtmpPublishFilterGray,           //1  黑白
    RDRtmpPublishFilterInvertColors,   //2  反转颜色
    RDRtmpPublishFilterSepia,          //3  褐色
    RDRtmpPublishFilterFisheye,        //4  鱼眼
    RDRtmpPublishFilterGlow,           //5  辉光
    RDRtmpPublishFilterYouGe,          //6  优格
    RDRtmpPublishFilterLanSeShiKe,     //7  蓝色时刻
    RDRtmpPublishFilterLengYan,        //8  冷艳
    RDRtmpPublishFilterNuanYangYang,   //9 暖洋洋
    RDRtmpPublishFilterGuTongSe        //10 古铜色
};

//萌颜类型
typedef NS_ENUM(NSInteger, RDRtmpPublishFacueType) {
    RDRTMPPUBLISH_FACUE_NORMAL         = -1,
    RDRTMPPUBLISH_FACUE_CAT,
    RDRTMPPUBLISH_FACUE_FAWN,
    RDRTMPPUBLISH_FACUE_HAT,
    RDRTMPPUBLISH_FACUE_GARLAND,
    RDRTMPPUBLISH_FACUE_CROWN,
    RDRTMPPUBLISH_FACUE_BUTTERFLYGARLAND,
    RDRTMPPUBLISH_FACUE_LOVELYCAT,
    RDRTMPPUBLISH_FACUE_RABBIT,
    RDRTMPPUBLISH_FACUE_RABBITHAIRPIN
};

//水印添加位置
typedef NS_ENUM (NSInteger, RDRtmpPublishWaterMarkLocation) {
    RDRTMPPUBLISH_WATERMARK_LOCATION_LEFTUP,
    RDRTMPPUBLISH_WATERMARK_LOCATION_LEFTDOWN,
    RDRTMPPUBLISH_WATERMARK_LOCATION_RIGHTUP,
    RDRTMPPUBLISH_WATERMARK_LOCATION_RIGHTDOWN,
    RDRTMPPUBLISH_WATERMARK_LOCATION_CENTER,
};

@protocol RDRtmpPublishDelegate <NSObject>
@required

/**
 *  推送状态回调
 *
 *  @param liveState 推送状态
 */
- (void) RDRtmpPublishConnectionStatusChanged: (RDRtmpPublishState) liveState;

@end


@interface RDLiveSDK : NSObject

/**
 *  预览视图
 */
@property (nonatomic , strong, readonly) UIView* cameraView;

/**
 *  切换摄像头
 */
@property (nonatomic, assign) RDRtmpPublishCameraState cameraState;

/**
 *  美颜，默认为开启美颜(RDRTMPPUBLISH_BEAUTIFY_SELECTED)
 */
@property (nonatomic, assign) RDRtmpPublishBeautifyState beautifyState;

/**
 *  麦克风音量; Default is 1.0f
 */
@property (nonatomic, assign) float         micGain;

/**
 *  是否开启闪光灯
 */
@property (nonatomic, assign) BOOL          torch;

/**
 *  输出分辨率
 */
@property (nonatomic, assign) CGSize            videoSize;

/**
 *  码率
 */
@property (nonatomic, assign) int bitrate;

/**
 *  帧率
 */
@property (nonatomic, assign) int fps;

/**
 *  委托协议
 */
@property (nonatomic, assign) id<RDRtmpPublishDelegate> delegate;

/**
 *  是否根据设备方向调节摄像头方向
 */
@property (nonatomic, assign) BOOL          useInterfaceOrientation;

/**
 *  是否根据用户网络自动调节码率; Default is off
 */
@property (nonatomic, assign) BOOL          useAdaptiveBitrate;

@property (nonatomic, readonly) RDLiveAuthorizationType authType;

/**
 *  初始化RDLiveSDK，此方法在使用RDLiveSDK时在主线程中调用。
 *
 *  @param appKey                   在锐动SDK官网(http://www.rdsdk.com/ )中注册的应用Key。
 *  @param secretKey                在锐动SDK官网(http://www.rdsdk.com/ )中注册的应用秘钥。
 *  @param successBlock             初始化成功的回调［authType：在锐动SDK官网申请的服务类型］
 *  @param errorBlock               初始化失败的回调［error：初始化失败的错误码］
 */
- (instancetype) initWithAPPKey:(NSString *)appKey
                   andSecretKey:(NSString *)secretKey
                        success:(void (^)(RDLiveAuthorizationType authType))successBlock
                          error:(void (^)(NSError *error))errorBlock;

/**
 *  获取所有在线直播用户(uid)
 */
- (void)getAllLiveList:(void (^)(NSArray *allLiveInfoArray))successBlock
                 error:(void (^)(NSError *error))errorBlock;

/**
 *  直播之前准备，用于设置直播参数。
 *  @param  frame                   显示分辨率
 *  @param  videoSize               输出分辨率
 *  @param  bitrate                 码率
 *  @param  fps                     帧率(1-30)
 *  @param  useInterfaceOrientation 是否根据设备方向调节摄像头方向
 *  @param  cameraState             设置前后置摄像头,默认为前置
 */
- (void) preparePublishWithFrame: (CGRect) frame
                       videoSize: (CGSize) videoSize
                         bitrate: (int) bitrate
                             fps: (int) fps
         useInterfaceOrientation: (BOOL) useInterfaceOrientation
                     cameraState: (RDRtmpPublishCameraState) cameraState;

- (void) preparePublishWithFrame: (CGRect) frame
                       videoSize: (CGSize) videoSize
                         bitrate: (int) bitrate
                             fps: (int) fps;

- (void) preparePublishWithFrame: (CGRect) frame
                       videoSize: (CGSize) videoSize
                         bitrate: (int) bitrate
                             fps: (int) fps
         useInterfaceOrientation: (BOOL) useInterfaceOrientation;

/**
 *  开启摄像头:直播前需要先开启摄像头
 */
- (void) startCamera;

/**
 *  停止摄像头
 */
- (void) stopCamera;

/**
 *  在锐动SDK官网申请的服务类型是基础服务RDLive_AT_URL或RDLive_AT_URL_OR_UID时，才可使用此接口直播
 *  开始直播,推送摄像头到rtmp
 *
 *  @param rtmpUrl      rtmp服务器地址
 *  @param streamKey    rtmp流名称
 *  @param errorBlock   开始直播失败的回调［status：开始直播失败的错误码］
 */
- (void) startPublishWithUrl:(NSString *)rtmpUrl
                andStreamKey:(NSString *)streamKey
                     success:(void (^)())successBlock
                       error:(void (^)(RDLiveErrorCode status))errorBlock;

/**
 *  在锐动SDK官网申请的服务类型是云服务RDLive_AT_UID或RDLive_AT_URL_OR_UID时，才可使用此接口直播
 *  开始直播
 *
 *  @param userID       用户ID
 *  @param title        直播标题
 *  @param errorBlock   开始直播失败的回调［error：开始直播失败的错误码］
 */
- (void) startPublishWithUid:(NSString *)userID
                    andTitle:(NSString *)title
                     success:(void (^)())successBlock
                       error:(void (^)(NSError *error))errorBlock;

/**
 *  在锐动SDK官网申请的服务类型是云服务RDLive_AT_UID或RDLive_AT_URL_OR_UID时，才可使用此接口直播
 *  由于网络不好等情况，非用户主动停止直播时，可尝试重新开始直播
 *
 *  @param userID       用户ID
 *  @param errorBlock   开始直播失败的回调［error：开始直播失败的错误码］
 */
- (void) reStartPublishWithUid:(NSString *)userID
                       success:(void (^)())successBlock
                         error:(void (^)(NSError *error))errorBlock;

/**
 *  结束直播
 */
- (void) endPublish;

/**
 *  在锐动SDK官网申请的服务类型是云服务RDLive_AT_UID或RDLive_AT_URL_OR_UID时，才可使用此接口直播
 *  进入后台时结束直播
 *  按下Home键不需要调用该接口，可用于分享等情况
 */
- (void) endPublishEnterBackground;

/**
 *  在锐动SDK官网申请的服务类型是云服务RDLive_AT_UID或RDLive_AT_URL_OR_UID时，才可使用此接口直播
 *  回到前台重连直播
 *  按下Home键后返回不需要调用该接口，可用于分享等情况
 */
- (void) reStartPublishBecomeActive;

/**
 *  在锐动SDK官网申请的服务类型是云服务RDLive_AT_UID或RDLive_AT_URL_OR_UID时，才可使用此接口直播
 *  进入后台时结束直播
 *  按下Home键不需要调用该接口，可用于分享等情况
 */
- (void) endRtmpEnterBackground;

/**
 *  设置滤镜,默认：RDRtmpPublishFilterTypeNormal
 */
- (void) setFilter:(RDRtmpPublishFilterType) type;

/**
 *  设置美颜程度，默认美颜程度为2
 */
- (void) setBeautyLevel: (NSInteger ) level;

/**
 *  设置Facue,默认不设置
 */
- (void) setFacue:(RDRtmpPublishFacueType) type;

/**
 *  添加水印
 *
 *  @param waterView 水印(可支持UIImageView和UILabel)
 *  @param location  水印标准位置，左右上下，中心点
 *  设置位置：(1)位置均由设置的rect的origin决定
 *          (2)只设置竖屏时水印位置即可，横屏时的位置，SDK内会做处理
 */
- (void) addWaterMarkView:(id) waterView location:(RDRtmpPublishWaterMarkLocation)location;

/**
 *  手动设置摄像头方向
 */
- (void) setDeviceOrientation:(UIDeviceOrientation)deviceOrientation;

/**
 *  获取Facue缩略图
 */
- (UIImage *) getFacueImage: (RDRtmpPublishFacueType) type;

/**
 *  获取直播截屏
 */
- (UIImage *) getPublishScreenshot;

@end
