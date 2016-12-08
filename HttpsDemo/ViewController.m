//
//  ViewController.m
//  HttpsDemo
//
//  Created by chen neng on 12-7-9.
//  Copyright (c) 2012年 ydtf. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import "AFNetworking.h"

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
- (IBAction)postAction:(id)sender
{
    [self postFile];
    //[self getFile2];
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
    //忽略证书验证
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]){
        
        [[challenge sender]  useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
        
        [[challenge sender]  continueWithoutCredentialForAuthenticationChallenge: challenge];
        
    }
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


-(void)getRequest
{
    //1。创建管理者对象
    NSString *urlString = @"https://127.0.0.1:4443/";
    
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:urlString]];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.securityPolicy.allowInvalidCertificates = YES;
    manager.securityPolicy.validatesDomainName = NO;
    
    [manager GET:@"" parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        
    }
         success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
             
             NSLog(@"这里打印请求成功要做的事");
             
         }
     
         failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull   error) {
             
             NSLog(@"%@",error);  //这里打印错误信息
             
         }];
}

-(void) postRequest
{
    //1。创建管理者对象
    NSString *urlString = @"https://127.0.0.1:4443/";
    
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:urlString]];
    //manager.securityPolicy = securityPolicy;
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.securityPolicy.allowInvalidCertificates = YES;
    manager.securityPolicy.validatesDomainName = NO;
    
    NSMutableDictionary *parameters = (NSMutableDictionary*)@{@"":@"",@"":@""};
    
    [manager POST:@"" parameters:parameters progress:^(NSProgress * _Nonnull uploadProgress) {
        
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
    }];
}


//下载文件

- (void)downLoad{
    
    //1.创建管理者对象
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    //2.确定请求的URL地址
    NSURL *urltmp = [NSURL URLWithString:@""];
    
    //3.创建请求对象
    NSURLRequest *request = [NSURLRequest requestWithURL:urltmp];
    
    //下载任务
    NSURLSessionDownloadTask *task = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        //打印下下载进度
        NSLog(@"%lf",1.0 * downloadProgress.completedUnitCount / downloadProgress.totalUnitCount);
        
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        //下载地址
        NSLog(@"默认下载地址:%@",targetPath);
        
        //设置下载路径，通过沙盒获取缓存地址，最后返回NSURL对象
        NSString *pfilePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)lastObject];
        return [NSURL URLWithString:pfilePath];
        
        
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable pfilePath, NSError * _Nullable error) {
        
        //下载完成调用的方法
        NSLog(@"下载完成：");
        NSLog(@"%@--%@",response,pfilePath);
        
    }];
    
    //开始启动任务
    [task resume];
    
}

//post上传文件
-(void)postFile
{

    //1。创建管理者对象
    NSString *urlString = @"https://127.0.0.1:4443/";

    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:urlString]];
    //manager.securityPolicy = securityPolicy;
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.securityPolicy.allowInvalidCertificates = YES;
    manager.securityPolicy.validatesDomainName = NO;
    //2.上传文件
    [manager POST:@"upload" parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        //上传文件参数
        UIImage *iamge = [UIImage imageNamed:@"computer.png"];
        NSData *data = UIImagePNGRepresentation(iamge);
        //这个就是参数
        [formData appendPartWithFileData:data name:@"file" fileName:@"computer.png" mimeType:@"image/png"];
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
        //打印下上传进度
        NSLog(@"%lf",1.0 *uploadProgress.completedUnitCount / uploadProgress.totalUnitCount);
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        //请求成功
        NSLog(@"请求成功：%@",responseObject);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        //请求失败
        NSLog(@"请求失败：%@",error);
    }];
}
//get
-(void)getFile2
{


}

//网络类型
- (void)AFNetworkStatus{
    
    //1.创建网络监测者
    AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
    
    /*枚举里面四个状态  分别对应 未知 无网络 数据 WiFi
     typedef NS_ENUM(NSInteger, AFNetworkReachabilityStatus) {
     AFNetworkReachabilityStatusUnknown          = -1,      未知
     AFNetworkReachabilityStatusNotReachable     = 0,       无网络
     AFNetworkReachabilityStatusReachableViaWWAN = 1,       蜂窝数据网络
     AFNetworkReachabilityStatusReachableViaWiFi = 2,       WiFi
     };
     */
    
    [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        //这里是监测到网络改变的block  可以写成switch方便
        //在里面可以随便写事件
        switch (status) {
            case AFNetworkReachabilityStatusUnknown:
                NSLog(@"未知网络状态");
                break;
            case AFNetworkReachabilityStatusNotReachable:
                NSLog(@"无网络");
                break;
                
            case AFNetworkReachabilityStatusReachableViaWWAN:
                NSLog(@"蜂窝数据网");
                break;
                
            case AFNetworkReachabilityStatusReachableViaWiFi:
                NSLog(@"WiFi网络");
                
                break;
                
            default:
                break;
        }
        
    }] ;
}


@end
