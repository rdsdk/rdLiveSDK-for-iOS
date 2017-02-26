//
//  LiveViewController.h
//  RDLiveSDKDemo
//
//  Created by Wuxiaoxia on 16/5/15.
//  Copyright © 2016年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LiveViewController : UIViewController

@property (nonatomic, strong) NSString      * userID;
@property (nonatomic, strong) NSString      * rtmpUrl;
@property (nonatomic, assign) BOOL            isUidLive;         //YES:UID直播  NO:URL直播
@property (nonatomic, assign) BOOL            isHighQuality;
@property (nonatomic, assign) BOOL            isFrontCamera;
@property (nonatomic, assign) BOOL            isOpenBeauty;

@end
