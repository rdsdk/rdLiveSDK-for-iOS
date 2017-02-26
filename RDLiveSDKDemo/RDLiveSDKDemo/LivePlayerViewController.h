//
//  LivePlayerViewController.h
//  RDLiveSDKDemo
//
//  Created by Wuxiaoxia on 16/5/15.
//  Copyright © 2016年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface LivePlayerViewController : UIViewController

@property (nonatomic, strong) NSString      * userID;
@property (nonatomic, strong) NSString      * rtmpUrl;
@property (nonatomic, strong) NSString      * rtspUrl;
@property (nonatomic, assign) BOOL            isWatchUidLive; //YES:看UID直播  NO:看URL直播

@end
