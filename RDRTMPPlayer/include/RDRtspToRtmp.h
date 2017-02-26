//
//  RDRtspToRtmp.h
//  RDRtspToRtmp
//
//  Created by Wuxiaoxia on 16/9/19.
//  Copyright © 2016年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, RDRtspToRtmpErrorCode) {
    /*!
     传入的APPKEY为空
     */
    RDRTSPTORTMP_PARA_APPKEY_NULL = 10000,
    
    /*!
     传入的SECRETKEY为空
     */
    RDRTSPTORTMP_PARA_SECRETKEY_NULL,
    
    /*!
     服务器连接异常
     */
    RDRTSPTORTMP_CLIENT_INVALID,
    
    /*!
     服务已到期
     */
    RDRTSPTORTMP_SERVICES_EXPIRED
};

typedef NS_ENUM(NSInteger, RDRtspToRtmpState) {
    kRDRtspToRtmpStateOK = 0,                                   // 0
    kRDRtspToRtmpStateUNKNOW,                                   // 1
    kRDRtspToRtmpStateCONNECT_RTMP_SERVER,                      // 2
    kRDRtspToRtmpStateUPLOAD_RTMP_PACKET,                       // 3
    kRDRtspToRtmpStateOPEN_VIDEO_ENCODER,                       // 4
    kRDRtspToRtmpStateOPEN_AUDIO_ENCODER,                       // 5
    kRDRtspToRtmpStateOPEN_VIDEO_DECODER,                       // 6
    kRDRtspToRtmpStateOPEN_AUDIO_DECODER,                       // 7
    kRDRtspToRtmpStateENCODE_VIDEO,                             // 8
    kRDRtspToRtmpStateENCODE_AUDIO,                             // 9
    kRDRtspToRtmpStateDECODE_VIDEO,                             // 10
    kRDRtspToRtmpStateDECODE_AUDIO,                             // 11
    kRDRtspToRtmpStateWRITE_FRAME,                              // 12
    kRDRtspToRtmpStateALLOC_MEMORY,                             // 13
    kRDRtspToRtmpStateINVALID_PARAM,                            // 14
    kRDRtspToRtmpStateNOT_SUPPORT_FORAMT,                       // 15
    kRDRtspToRtmpStateWRITE_FILE,                               // 16
    kRDRtspToRtmpStateRTSP_CONNECT_SERVER,                      // 17
    kRDRtspToRtmpStateRTSP_READ_DATA,                           // 18
    kRDRtspToRtmpStateNOT_SUPPORT_RESAMPLE,                     // 19
};

typedef void(^ErrorCallBack) (RDRtspToRtmpState errorCode);

@interface RDRtspToRtmp : NSObject

/**
 *  初始化RDRtspToRtmp，此方法在使用RDRtspToRtmp时在主线程中调用。
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

@property (nonatomic,assign) ErrorCallBack errorCallBack;

/**
 *  转换前设置
 *
 *  @param rtspStr        rtsp url path
 *  @param rtmpStr        rtmp url path
 */
- (void) prepareRtspToRtmpWithInputRTSP:(NSString *)rtspStr
                             outputRTMP:(NSString *)rtmpStr;
/**
 *  开始转换
 */

- (void) startRtspToRtmp:(ErrorCallBack) errorCode;

/**
 *  结束转换
 */
- (void) stopRtspToRtmp:(ErrorCallBack) errorCode;

@end
