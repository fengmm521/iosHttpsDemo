//
//  AppDelegate.h
//  HttpsDemo
//
//  Created by chen neng on 12-7-9.
//  Copyright (c) 2012年 ydtf. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) ViewController *viewController;
+ (AppDelegate *)sharedAppDelegate;
- (NSString *)pathForTemporaryFileWithPrefix:(NSString *)prefix;
@end
