//
//  AppDelegate.m
//  RDLiveSDKDemo
//
//  Created by Wuxiaoxia on 16/5/15.
//  Copyright © 2016年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self isFirstRun];
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.allowRotation = NO;
    self.orientationMask = UIInterfaceOrientationMaskPortrait;
    
    MainViewController *VC = [[MainViewController alloc] init];
    UINavigationController *nv = [[UINavigationController alloc] initWithRootViewController:VC];
    self.window.rootViewController = nv;
    
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(nullable UIWindow *)window
{
    if (self.allowRotation) {
        return self.orientationMask;
    }else {
        return UIInterfaceOrientationMaskPortrait;
    }
}

- (BOOL)isFirstRun {
    BOOL isFirstRun = [[NSUserDefaults standardUserDefaults] boolForKey:EVER_LAUCHED];
    if (![[NSUserDefaults standardUserDefaults] boolForKey:EVER_LAUCHED])
    {
        [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:@"isFrist"];//是否显示提示弹窗
    }
    
    return isFirstRun;
}

@end
