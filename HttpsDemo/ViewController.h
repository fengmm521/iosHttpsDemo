//
//  ViewController.h
//  HttpsDemo
//
//  Created by chen neng on 12-7-9.
//  Copyright (c) 2012年 ydtf. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
{
    NSURLRequest* _request;
    NSURLConnection *  connection;
    NSString* filePath;
    NSOutputStream *  fileStream;
    NSURL* url,*baseUrl;
    NSStringEncoding enc;
    NSURLAuthenticationChallenge *_challenge;
}
@property (retain, nonatomic) IBOutlet UILabel *lbMessage;
@property (retain, nonatomic) IBOutlet UIWebView *webView;
@property (retain, nonatomic) IBOutlet UIButton *btGo;
@property (retain, nonatomic) IBOutlet UIButton *btcPost;
@property (readonly, nonatomic, strong) NSOperationQueue *operationQueue;

- (IBAction)goAction:(id)sender;
- (IBAction)postAction:(id)sender;
- (void)_receiveDidStart;
- (void)_receiveDidStopWithStatus:(NSString *)statusString;
@end
