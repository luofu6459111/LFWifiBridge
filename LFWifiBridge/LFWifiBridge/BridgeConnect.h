//
//  BridgeConnect.h
//  UAVGSBMAP
//
//  Created by admin on 15/9/7.
//  Copyright © 2015年 luofu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"
@class SSIDListTableViewController;

@interface BridgeConnect : NSObject
- (id)init;
/**
 *  @author luofu, 15-09-15 15:09:48
 *
 *  当需要扫描的时候调用
 *
 *  @param wTag        设置写参数
 *  @param alertContrl 弹出的wifilist窗口
 *
 */
-(void)scannerNetwork:(int)wTag alertController:(SSIDListTableViewController*) alertContrl;
/**
 *  @author luofu, 15-09-15 15:09:17
 *
 *  链接选中的wifi
 *
 *  @param ssid     ssid
 *  @param security
 *  @param pwd      密码
 *  @param wTag     设置写参数
 */
-(void)connectNetwork:(NSString *) ssid security:(NSString *) security password:(NSString *) pwd tag:(int) wTag;
/**
 *  @author luofu, 15-09-15 15:09:53
 *
 *  创建tcp链接
 */
-(void)createConnectWithHost : (NSString *)hostName;
@end