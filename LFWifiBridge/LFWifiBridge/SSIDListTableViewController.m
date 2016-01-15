//
//  SSIDListTableViewController.m
//  LFWifiBridge
//
//  Created by admin on 16/1/15.
//  Copyright © 2016年 luofu. All rights reserved.
//

#import "SSIDListTableViewController.h"
#import "BridgeConnect.h"
@interface SSIDListTableViewController ()
{
    UIRefreshControl * refreshControl;//drop down and refresh data;
    BridgeConnect * bridgeConnect;
    
    NSMutableArray* settings;//cell的数据集合
    NSMutableArray* securityArr;//security集合
    NSString      *securityStr;//选中的security字符串
    BridgeConnect* Alertbridge;
    
}
@end

@implementation SSIDListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self refreshWifiData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void) viewWillAppear:(BOOL)animated
{
    
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return [settings count];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier=@"_tabeCell";
    UITableViewCell *cell= nil;
    cell =  (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell ==nil) {
        cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    cell.textLabel.text = [settings objectAtIndex:[indexPath row]];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger selectNum=[indexPath row];//返回点击的是第几行
    NSString *tempStr=securityArr[selectNum];//security的转换字符串
    if ([tempStr rangeOfString:@"WPA2PSK/AES" options:NSCaseInsensitiveSearch].length>0) {
        securityStr = @"wpa2_aes";
    }
    else if([tempStr rangeOfString:@"WPA2PSK/TKIP" options:NSCaseInsensitiveSearch].length>0){
        securityStr = @"wpa2_tkip";
    }
    else if ([tempStr rangeOfString:@"WPAPSK/AES" options:NSCaseInsensitiveSearch].length>0){
        securityStr = @"wpa_aes";
    }
    else if ([tempStr rangeOfString:@"WPAPSK/TKIP" options:NSCaseInsensitiveSearch].length>0) {
        securityStr = @"wpa_tkip";
    }
    else if ([tempStr rangeOfString:@"WEP" options:NSCaseInsensitiveSearch].length>0){
        securityStr = @"wep_shared";
    }
    else if ([tempStr rangeOfString:@"NONE" options:NSCaseInsensitiveSearch].length>0){
        securityStr = @"none";
    }
    
    UITableViewCell * selectCell = [tableView cellForRowAtIndexPath:indexPath];
    NSString * cellText = selectCell.textLabel.text;
    //点击的选中wifi名称的时候提示用户输入密码
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"密码输入" message:cellText delegate:self cancelButtonTitle:@"取消"   otherButtonTitles:@"确定", nil];
    alert.alertViewStyle = UIAlertViewStyleSecureTextInput;
    UITextField *passWordField = [alert textFieldAtIndex:0];
    passWordField.placeholder = @"请输入密码";
    [alert show];
}
#pragma mark - alertView delegate function
//用户点击确定的时候的回调函数
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if (buttonIndex == alertView.firstOtherButtonIndex) {
        UITextField *PWDField = [alertView textFieldAtIndex:0];
        NSString * textPWD=PWDField.text;//获取输入的密码
        NSString * textMsg=alertView.message;
        //请求链接
        if (Alertbridge==nil) {
            Alertbridge=[[BridgeConnect alloc] init];
        }
        [Alertbridge createConnectWithHost:@"192.168.16.254"];
        [Alertbridge connectNetwork:textMsg security:securityStr password:textPWD tag:1];
    }
}
#pragma mark - get and refresh data
- (void) setCelldata:(NSMutableArray *) data
{
    NSArray *tempArr;
    NSString * tempStr;
    int j=0;//用来记录插入集合的位置
    int p=0;
    NSUInteger len=[data count];
    settings = [[NSMutableArray alloc] initWithCapacity:len];
    securityArr = [[NSMutableArray alloc] initWithCapacity:len];
    if (data ==nil) {
        settings = nil;
        securityArr = nil;
    }else{
        for (int i=0; i<[data count]; i++) {
            tempStr=[data objectAtIndex:i];
            if (![tempStr isEqualToString:@""]) {
                tempArr=[tempStr componentsSeparatedByString:@" "];
                int k=0;//用来记录是第几个不为空的字符
                NSString *tempSetStr;//用来存储分割出来的字符串
                NSString *appendStr;//存储在第二个不为空字符后到assid地址之前的字符串
                int insertPos=1;//表示assid地址之后的一个不为空的字符串是第几个位置
                for (int l=0; l<[tempArr count]; l++) {
                    tempSetStr=tempArr[l];
                    if (![tempSetStr isEqualToString:@""]) {
                        k++;
                        if(k>=2&&[tempSetStr rangeOfString:@":" options:NSCaseInsensitiveSearch].length==0&&insertPos==1){
                            if (k==2) {
                                appendStr=tempSetStr;
                            }else{
                                appendStr=[appendStr stringByAppendingString:@" "];
                                appendStr=[appendStr stringByAppendingString:tempSetStr];
                            }
                        }
                        else if (k>2&&[tempSetStr rangeOfString:@":" options:NSCaseInsensitiveSearch].length>0){
                            [settings insertObject:appendStr atIndex:j];
                            j++;
                            insertPos=k+1;
                        }
                        else if(k==insertPos&&insertPos!=1){
                            [securityArr insertObject:tempSetStr atIndex:p];
                            p++;
                            break;
                        }
                    }
                }
                
            }
            
        }
        [refreshControl endRefreshing];
        [self.tableView reloadData];//刷新数据
    }
}
- (void)refreshWifiData{
    if (refreshControl == nil) {
        refreshControl = [[UIRefreshControl alloc] init];
    }
    [refreshControl addTarget:self action:@selector(refreshViewData:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];
    // start refresh
    [refreshControl beginRefreshing];
}
-(void)refreshViewData:(UIRefreshControl *)control{
    if (bridgeConnect == nil) {
        bridgeConnect = [[BridgeConnect alloc] init];
    }
    //this is our test address
    [bridgeConnect createConnectWithHost:@"192.168.16.254"];
    [bridgeConnect scannerNetwork:0 alertController:self];
}

@end
