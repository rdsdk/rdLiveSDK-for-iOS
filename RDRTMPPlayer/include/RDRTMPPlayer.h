//
//  RDRTMPPlayer.h
//  RDRTMPPlayer
//
//  Created by Wuxiaoxia on 16/9/19.
//  Copyright © 2016年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#pragma mark - RDRTMPPlayerErrorCode 具体初始化锐动直播SDK错误码
typedef NS_ENUM(NSInteger, RDRTMPPlayerErrorCode) {
    /*!
     传入的APPKEY为空
     */
    RDRTMPPLAYER_PARA_APPKEY_NULL = 10000,
    
    /*!
     传入的SECRETKEY为空
     */
    RDRTMPPLAYER_PARA_SECRETKEY_NULL,
    
    /*!
     服务器连接异常
     */
    RDRTMPPLAYER_CLIENT_INVALID,
    
    /*!
     服务已到期
     */
    RDRTMPPLAYER_SERVICES_EXPIRED
};

typedef NS_ENUM(NSInteger, RDRTMPPlayerScalingMode) {
    RDRTMPPlayerScalingModeAspectFit,
    RDRTMPPlayerScalingModeAspectFill,
    RDRTMPPlayerScalingModeFill
};

typedef NS_ENUM(NSInteger, RDRTMPPlayerState) {
    kRDRTMPPlayerStateNone = 0,                   // 0
    kRDRTMPPlayerStateConnecting,                 // 1
    kRDRTMPPlayerStateConnected,                  // 2
    kRDRTMPPlayerStateConnectionFailed,           // 3
    kRDRTMPPlayerStateGotStreamDuration,          // 4
    kRDRTMPPlayerStateGotAudioStreamInfo,         // 5
    kRDRTMPPlayerStateGotVideoStreamInfo,         // 6
    kRDRTMPPlayerStateInitialLoading,             // 7
    kRDRTMPPlayerStateReadyToPlay,                // 8
    kRDRTMPPlayerStateBuffering,                  // 9
    kRDRTMPPlayerStatePlaying,                    // 10
    kRDRTMPPlayerStatePlayed,                     // 11
    kRDRTMPPlayerStateStoppedByUser,              // 12
    kRDRTMPPlayerStateStoppedWithError,           // 13
    kRDRTMPPlayerStatePacketLoading,              // 14
    kRDRTMPPlayerStatePacketLoaded                // 15
};

typedef NS_ENUM(NSInteger, RDRTMPPlayerError) {
    kRDRTMPPlayerErrorNone = 0,                   // 0
    kRDRTMPPlayerErrorUnsupportedProtocol,        // 1
    kRDRTMPPlayerErrorStreamURLParseError,        // 2
    kRDRTMPPlayerErrorOpenStream,                 // 3
    kRDRTMPPlayerErrorStreamInfoNotFound,         // 4
    kRDRTMPPlayerErrorStreamsNotAvailable,        // 5
    kRDRTMPPlayerErrorStreamDurationNotFound,     // 6
    kRDRTMPPlayerErrorAudioStreamNotFound,        // 7
    kRDRTMPPlayerErrorVideoStreamNotFound,        // 8
    kRDRTMPPlayerErrorAudioCodecNotFound,         // 9
    kRDRTMPPlayerErrorVideoCodecNotFound,         // 10
    kRDRTMPPlayerErrorAudioCodecNotOpened,        // 11
    kRDRTMPPlayerErrorUnsupportedAudioFormat,     // 12
    kRDRTMPPlayerErrorAudioStreamAlreadyOpened,   // 13
    kRDRTMPPlayerErrorVideoCodecNotOpened,        // 14
    kRDRTMPPlayerErrorAudioAllocateMemory,        // 15
    kRDRTMPPlayerErrorVideoAllocateMemory,        // 16
    kRDRTMPPlayerErrorStreamReadError,            // 17
    kRDRTMPPlayerErrorStreamEOFError,             // 18
    kRDRTMPPlayerErroSetupScaler                  // 19
};


typedef NS_ENUM(NSInteger, RTSPTRANSPORT)
{
    RTSP_TRANSPORT_UDP,    //0:UDP协议
    RTSP_TRANSPORT_TCP     //1:TCP协议
};

@protocol RDRTMPPlayerDelegate <NSObject>

@optional

- (void)RDRTMPPlayerStateChanged:(RDRTMPPlayerState)state errorCode:(RDRTMPPlayerError)errCode player:(id)player;

@end

@interface RDRTMPPlayer : NSObject

/**
 *  初始化RDRTMPPlayer，此方法在使用RDRTMPPlayer时在主线程中调用。
 *
 *  @param appKey                   在锐动SDK官网(http://www.rdsdk.com/ )中注册的应用Key。
 *  @param secretKey                在锐动SDK官网(http://www.rdsdk.com/ )中注册的应用秘钥。
 *  @param successBlock             初始化成功的回调
 *  @param errorBlock               初始化失败的回调［error：初始化失败的错误码］
 */
- (instancetype) initWithAPPKey:(NSString *)appKey
                   andSecretKey:(NSString *)secretKey
                        success:(void (^)())successBlock
                          error:(void (^)(NSError *error))errorBlock;

/**
 *  播放器预览视图
 */
@property (nonatomic, readonly) UIView *playerView;

/**
 *  播放视频地址
 */
@property (nonatomic, retain) NSString *contentRtmpURLStr;

/**
 *  播放视频的实际大小
 */
@property (nonatomic, readonly) CGSize contentNaturalSize;

/**
 *  播放器适应模式
 */
@property (nonatomic, assign) RDRTMPPlayerScalingMode playerScalingMode;

/**
 *  播放器超时时间(单位：秒)，默认：10s
 */
@property (nonatomic, assign) int timeOut;

/**
 * 是否视频聊天，默认：NO
 * 视频聊天时，必须设置为YES
 */
@property (nonatomic, assign) BOOL isVideoChat;

/**************播放RTSP时，相关的属性****************/

/**
 * 传输数据协议:TCP/UDP，默认：TCP
 */
@property (nonatomic, assign) RTSPTRANSPORT transport;

/**
 * 是否屏蔽音频,实时同步画面,调用play 之前赋值生效
 * 默认：NO
 */
@property (nonatomic, assign) BOOL audioIsDisabled;

/**
 * 是否丢帧，默认：YES
 */
@property (nonatomic, assign) BOOL frameIsDrop;

/**************************************************/

/**
 *  播放委托协议
 */
@property (nonatomic, assign) id<RDRTMPPlayerDelegate> rtmpPlayerDelegate;

/*
 *  获取用户直播详细信息
 *  @param successBlock 获取用户直播详细信息成功的回调 [liveInfoDic:获取到的用户直播详细信息]
 *                      title:直播标题
 *                      description：直播描述
 *                      thumbnailUrl：缩略图地址
 *                      liveRtmpUrl：直播rtmp地址
 *                      liveM3u8Url：直播M3u8地址
 *                      liveStatus：直播状态:0准备好，1废弃/出错，2直播中，3流断开，4直播结束
 *  @param errorBlock   获取用户直播详细信息失败的回调 error：获取用户直播详细信息失败的错误码］
 */
- (void)getLiveInfoWithUid:(NSString *)userID
                   success:(void (^)(NSDictionary *liveInfoDic))successBlock
                     error:(void (^)(NSError *error))errorBlock;

/**
 *  播放
 *  如播放器返回错误状态，需要重新初始化播放器，再play
 */
- (void)play;

/**
 *  停止  ：如果没有开始播放（还没有返回状态kRDRTMPPlayerStateConnecting），或者播放器出错，不需要调用此接口。
 */
- (void)stop;

/**
 *  设置播放器是否静音
 */
- (void)setMute:(BOOL)value;

/**
 *  获取播放视频缩略图
 */
- (UIImage *)rtmpPlayerSnapshot;

@end
