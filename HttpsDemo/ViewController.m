//
//  ViewController.m
//  HttpsDemo
//
//  Created by chen neng on 12-7-9.
//  Copyright (c) 2012年 ydtf. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"

@implementation ViewController
@synthesize lbMessage;
@synthesize webView;
@synthesize btGo;


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    url=[NSURL URLWithString:@"https://127.0.0.1:4443/index.html"];
    baseUrl=[NSURL URLWithString:@"https://localhost:8443/AnyMail/"];
    enc=CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
}

- (void)viewDidUnload
{
    [self setLbMessage:nil];
    [self setWebView:nil];
    [self setBtGo:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (IBAction)goAction:(id)sender {
    filePath = [[AppDelegate sharedAppDelegate] pathForTemporaryFileWithPrefix:@"Get"];
    NSLog(@"filePath=%@",filePath);
    fileStream = [[NSOutputStream alloc]initToFileAtPath:filePath append:NO];
    assert(fileStream != nil);
    
    [fileStream open];
    _request = [NSURLRequest requestWithURL:url];
    assert(_request != nil);
    
    connection = [NSURLConnection connectionWithRequest:_request delegate:self];
    [self _receiveDidStart];
//    [_request setRequestMethod:@"GET"];
//    _request.delegate=self;
//    [_request setValidatesSecureCertificate:NO];
//    [_request setShouldPresentCredentialsBeforeChallenge:NO];
//    [_request startSynchronous];
}
#pragma mark - AlertView delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
     // Accept=0,Cancel=1;
    if(buttonIndex==0){
        NSURLCredential *   credential;
        
        NSURLProtectionSpace *  protectionSpace;
        SecTrustRef             trust;
        NSString *              host;
        SecCertificateRef       serverCert;
        //assert(_challenge !=nil);
        protectionSpace = [_challenge protectionSpace];
        assert(protectionSpace != nil);
        
        trust = [protectionSpace serverTrust];
        assert(trust != NULL);
        
        credential = [NSURLCredential credentialForTrust:trust];
        assert(credential != nil);
        host = [[_challenge protectionSpace] host];
        if (SecTrustGetCertificateCount(trust) > 0) {
            serverCert = SecTrustGetCertificateAtIndex(trust, 0);
        } else {
            serverCert = NULL;
        }
        [[_challenge sender] useCredential:credential forAuthenticationChallenge:_challenge]; 
    }else{
//        NSLog(@"xxx:%@,%@",_challenge,_challenge.sender];
//        [[_challenge sender] cancelAuthenticationChallenge:_challenge];
    }
    
}
#pragma mark - Tell the UI we are receiving or received.
- (void)_receiveDidStart
{
    // Clear the current webview.
    [self.webView loadHTMLString:nil baseURL:nil];
    [lbMessage setText:@"Receiving"];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)_receiveDidStopWithStatus:(NSString *)statusString
{
    if (statusString == nil) {
        NSLog(@"filepath=%@",filePath);
        BOOL b=[[NSFileManager defaultManager]fileExistsAtPath:filePath];
        if (b) {
            [webView loadHTMLString:[NSString stringWithContentsOfFile:filePath encoding:enc error:nil]baseURL:baseUrl];
        }
        statusString= @"Get succeeded";
    }
    [lbMessage setText: statusString];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}
- (void)_stopReceiveWithStatus:(NSString *)statusString
{
    if (connection != nil) {
        [connection cancel];
        connection = nil;
    }
    if (fileStream != nil) {
        [fileStream close];
        fileStream = nil;
    }

    [self _receiveDidStopWithStatus:statusString];
    filePath = nil;
}
#pragma mark - URLConnection delegate
- (BOOL)connection:(NSURLConnection *)conn canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    NSLog(@"authenticate method:%@",protectionSpace.authenticationMethod);
    return [protectionSpace.authenticationMethod isEqualToString:
            NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)conn didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    
#if 1
    //忽略证书验证
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]){
        
        [[challenge sender]  useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
        
        [[challenge sender]  continueWithoutCredentialForAuthenticationChallenge: challenge];
        
    }
    //下边为不忽略证书
#else
    
    _challenge = challenge;
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"服务器证书"
                                                         message:@"这个网站有一个服务器证书，点击“接受”，继续访问该网站，如果你不确定，请点击“取消”。" 
                                                        delegate:self 
                                               cancelButtonTitle:@"接受" 
                                               otherButtonTitles:@"取消", nil];
    
    [alertView show];
#endif
}

- (void)connection:(NSURLConnection *)conn didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse * httpResponse;
    
    httpResponse = (NSHTTPURLResponse *) response;
    assert( [httpResponse isKindOfClass:[NSHTTPURLResponse class]] );
    
    if ((httpResponse.statusCode / 100) != 2) {
        [self _stopReceiveWithStatus:[NSString stringWithFormat:@"HTTP error %zd", (ssize_t) httpResponse.statusCode]];
    } else {
        lbMessage.text = @"Response OK.";
        NSLog(@"status: %@", lbMessage.text);
    }    
}

- (void)connection:(NSURLConnection *)conn didReceiveData:(NSData *)data
{
#pragma unused(conn)
    NSInteger       dataLength;
    const uint8_t * dataBytes;
    NSInteger       bytesWritten;
    NSInteger       bytesWrittenSoFar;
    
    
    dataLength = [data length];
    dataBytes  = [data bytes];
    
    bytesWrittenSoFar = 0;
    do {
        bytesWritten = [fileStream write:&dataBytes[bytesWrittenSoFar] maxLength:dataLength - bytesWrittenSoFar];
        assert(bytesWritten != 0);
        if (bytesWritten == -1) {
            [self _stopReceiveWithStatus:@"File write error"];
            break;
        } else {
            bytesWrittenSoFar += bytesWritten;
        }
    } while (bytesWrittenSoFar != dataLength);
}

- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError %@", error);
    
    [self _stopReceiveWithStatus:@"Connection failed"];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)conn
{
#pragma unused(conn)
    
    NSLog(@"connectionDidFinishLoading");
    
    [self _stopReceiveWithStatus:nil];
}

@end
