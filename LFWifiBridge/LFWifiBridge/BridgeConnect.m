//
//  BridgeConnect.m
//  UAVGSBMAP
//
//  Created by admin on 15/9/7.
//  Copyright © 2015年 luofu. All rights reserved.
//
#import "BridgeConnect.h"
#import "GCDAsyncSocket.h"
#import "SSIDListTableViewController.h"
#define REQUEST_NETWORK_URL @"/goform/ser2netconfigAT"

@interface BridgeConnect()
{
    SSIDListTableViewController * alertCtrl;
    int            writeTag;        //写参数，0表示scannerwifi，1表示connectwifi
    NSString       *sendmMsgConnect;
    NSMutableArray * scannerarr; //将请求的数据进行分割之后的数据
    GCDAsyncSocket *reqsocket;   //监听套接字
    BOOL           isconnect;//服务器链接是否成功
    NSString       *scannerInfo;//请求扫描后读回的数据
    NSString       *connectInfo;//请求链接后读回的数据
    NSString       *_hostName;
    BOOL           isBridge;//wifi桥接是否成功
}

@end

@implementation BridgeConnect
-(id)init{
    
    self = [super init];
    if (!self) {
        return nil;
    }
    isBridge = NO;
    return self;
}
-(void)scannerNetwork:(int)wTag alertController:(SSIDListTableViewController*) alertContrl{
    writeTag = wTag;
    alertCtrl=alertContrl;
    }
-(void)connectNetwork:(NSString *) ssid security:(NSString *) security password:(NSString *) pwd tag:(int)  wTag{
    NSString *content=[[NSString alloc] initWithFormat:@"nRstaWIFI=%@,%@,%@&RCommit=1",ssid,security,pwd];
    NSUInteger len=[content length]-1;
    sendmMsgConnect = [[NSString alloc]initWithFormat:@"POST /goform/ser2netconfigAT HTTP/1.1\r\nHost: %@\r\nConnection: keep-alive\r\nAuthorization: Basic YWRtaW46QzI5V1JBUlRKSUdXSDlHOUZCRUQ=\r\nContent-Length: %lu\r\n\r\nRstaWIFI=%@,%@,%@&RCommit=1\r\n\r\n",_hostName,(unsigned long)len,ssid,security,pwd];
    NSLog(@"%@",sendmMsgConnect);
    writeTag=wTag;
}
-(void)createConnectWithHost:(NSString *)hostName{
    if([reqsocket isConnected]){
        [reqsocket disconnect];
    }
    //创建socket嵌套字
    reqsocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    //建立连接
    NSError *err=nil;
    _hostName = hostName;
    if (![reqsocket connectToHost:hostName onPort:80 error:&err]) {
        NSLog(@"connect remote server failed,%@",err);
    }
}

#pragma mark -----socket delegate-----
//链接成功之后回调
-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString * )host port:(uint16_t)port{
    if (writeTag==0) {
        //链接成功之后会自动发送向服务器的写请求
        NSString *sendMsg = [[NSString alloc]initWithFormat:@"POST /goform/ser2netconfigAT HTTP/1.1\r\nHost: %@\r\nConnection: keep-alive\r\nAuthorization: Basic YWRtaW46QzI5V1JBUlRKSUdXSDlHOUZCRUQ=\r\nContent-Length: 11\r\n\r\nwifi_Scan=?\r\n\r\n",_hostName];
        NSLog(@"%@",sendMsg);
        NSData *data = [sendMsg dataUsingEncoding:NSUTF8StringEncoding];
        //向服务器发送写请求
        [reqsocket writeData:data withTimeout:-1 tag:0];
    }
    else if (writeTag==1){
        NSData *data = [sendmMsgConnect dataUsingEncoding:NSUTF8StringEncoding];
        //向服务器发送写请求
        [reqsocket writeData:data withTimeout:-1 tag:1];
        //启动计时器
        [NSTimer scheduledTimerWithTimeInterval:30.0f target:self selector:@selector(showConnectFail:) userInfo:nil repeats:NO];
    }
}
//读成功之后回调
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    if (tag==0) {
        //获取读回的数据
        scannerInfo = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"scanner wifi datas is :%@",scannerInfo);
        //将数据进行分割
        scannerarr=[self pareseString:scannerInfo];
        //为uitableview设置cell数据
        [alertCtrl setCelldata:scannerarr];
        //因为tcp消息包可能是连续发送为了区分返回的包可以对包进行分割，此处用</html>分割
        NSData* sperateData = [@"</html>" dataUsingEncoding:NSUTF8StringEncoding];
        //继续监听
        [reqsocket readDataToData:sperateData withTimeout:-1 tag:0];
    }
    if(tag == 1){

    }
    
}
//写成功后回调的函数
 -(void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    if (tag==0) {
        NSData* sperateData = [@"</html>" dataUsingEncoding:NSUTF8StringEncoding];
        //发送读请求
        [reqsocket readDataToData:sperateData withTimeout:-1 tag:0];
    }
   else if (tag==1){
       isBridge = YES;
       
    }
}
- (void)showConnectFail:(NSTimer*)theTimer
{
    if (!isBridge) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"连接失败！" delegate:self cancelButtonTitle:@"确定" otherButtonTitles: nil];
        [alertView show];
    }
}
//链接断开的时候回调
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
    if (isBridge) {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"连接成功！" delegate:self cancelButtonTitle:@"确定" otherButtonTitles: nil];
        [alert show];
    }
}
//处理读取的数据
-(NSMutableArray *)pareseString:(NSString*) str{
    //定义分割后的wifi列表
    NSArray *list=[str componentsSeparatedByString:@"\r\n"];
    NSUInteger len=[list count];
    NSMutableArray *result=[NSMutableArray arrayWithCapacity:len];
    if ([str hasPrefix:@"HTTP/1.0 200 OK"]==NO) {
        return result;
    }else{
    NSString *temp;
    int j=0;
    for (int i=0; i<len; i++) {
        temp = [list objectAtIndex:i];
        if ([temp hasPrefix:@"<html>"]==NO&&[temp hasPrefix:@"<head>"]==NO&&[temp hasPrefix:@"<title>"]==NO&&[temp hasPrefix:@"<at+>"]==NO&&[temp hasPrefix:@"<body>"]==NO&&[temp hasPrefix:@"</body>"]==NO&&[temp hasPrefix:@"</html>"]==NO&&[temp hasPrefix:@"Body"]==NO&&[temp hasPrefix:@"HTTP"]==NO&&[temp hasPrefix:@"Pragma"]==NO&&![temp isEqualToString:@""]) {
            [result insertObject:temp atIndex:j];
            j++;
        }
    }
    return result;
    }
}
@end
