//
//  ViewController.m
//  SonopTekBLEDemo
//
//  Created by mrq on 16/9/20.
//  Copyright © 2016年 MrQ. All rights reserved.
//

#import "ViewController.h"
#import "SVProgressHUD.h"
#import "TableViewCell.h"

#import "BLEManager.h"

@interface ViewController ()<BLEManagerDelegate,UITableViewDataSource,UITableViewDelegate>
{
    BLEManager *bleManager;
}
@property (nonatomic,strong)NSArray *ListPeripheral;

@property (nonatomic,strong)UITableView *tableView;

@property (nonatomic,strong)UILabel *headTitle;


@property (weak, nonatomic) IBOutlet UITextField *deviceTextF;

@property (weak, nonatomic) IBOutlet UITextView *recvText;

@property (weak, nonatomic) IBOutlet UITextField *sendText;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;

@property (weak, nonatomic) IBOutlet UILabel *connectedList;

// 已连接设备
@property (nonatomic,copy) NSMutableString *ConnectedlistStr;

@property (nonatomic,strong) NSArray *connectedArray;
@property (nonatomic,strong) NSArray *disconnectedArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // 监听键盘改变
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
    [self initWithLeftBarButton];
    [self initWithRightBarButton];
    [self initWithTableView];
    
    /// Manager
    bleManager = [BLEManager sharedInstance];
    // 设置观察者
    [bleManager registeObserver:self];
    
    self.ListPeripheral = [NSArray array];
    
    self.tableView.tableHeaderView = self.headTitle;
    self.headTitle.text = @"请开始搜索设备...";
    
    _connectedArray = [NSArray array];
    _disconnectedArray = [NSArray array];
}

// 搜索按钮点击事件
- (void)startScanPeripherals{
    [self scanDevice];
}

- (void)scanDevice{
    if (![bleManager BLEAvailable]) {
        NSLog(@"蓝牙未打开");
        return;
    }
    // 开始扫描 设置过滤
    [bleManager scanForDevice:0];
    
    NSLog(@"scan state %lu ",(unsigned long)bleManager.BLEAvailable);
    
    NSLog(@"conneted device %lu",(unsigned long)bleManager.connectedDeviceList.count);
}

// 断开连接点击事件
- (void)closeAllConnect{
    
    /// 关闭所有链接
    [bleManager disconnectAllDevices];
    self.deviceTextF.text = @"";
    
    [SVProgressHUD showInfoWithStatus:@"关闭所有连接"];
    [bleManager cancelScan];
    
    self.connectedList.text = @"已连接设备:";
}

- (IBAction)sendMsg:(id)sender {
    if(bleManager.connectedDeviceList.count>0){
        BLEDevice *device = bleManager.connectedDeviceList.firstObject;
        [bleManager sendMsg:self.sendText.text device:device response:YES];
        
//        NSString *UUID = @"FFEE";
//        NSData *data = [self.sendText.text dataUsingEncoding:[NSString defaultCStringEncoding]];
//        [bleManager sendData:data device:device UUID:UUID response:YES];
        
    }
}


#pragma mark - BLEManager Delegate
- (void)onManagerBLEAvailable:(BLEAvailableState)state{
    NSLog(@"state %lu",(unsigned long)state);
    if (state == BLE_STATE_ON) {
        [bleManager scanForDevice:0];
    }else{
        [SVProgressHUD showInfoWithStatus:@"蓝牙未打开或不支持"];
    }
}
/// 获取周边设备
- (void)onManagerDevicesFound:(NSArray *)deviceArray{
    
    if (deviceArray.count) {
        self.headTitle.text = @"选择要连接的设备";
    }else{
        self.headTitle.text = @"请开始搜索设备...";
    }
    
    NSLog(@"%@",deviceArray);
    
    self.ListPeripheral = [NSArray arrayWithArray:deviceArray];
    
    [self.tableView reloadData];
}

/// 链接设备的回调
- (void)onManagerDeviceConnected:(BLEDevice *)device{
    [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"%@连接成功",device.name]];
    self.deviceTextF.text = [NSString stringWithFormat:@"%@//%@",device.name,device.mac];
    self.connectedList.text = self.ConnectedlistStr;
}

- (void)onManagerDeviceConnectFailed:(BLEDevice *)device{
    [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@连接失败",device.name]];

}

/// 断开连接的回调
-(void)onManagerDeviceDisconnected:(BLEDevice *)device{
    [SVProgressHUD showInfoWithStatus:[NSString stringWithFormat:@"%@断开连接",device.name]];
    self.connectedList.text = self.ConnectedlistStr;
    
    self.deviceTextF.text = @"";
}

- (void)onReceivedMsg:(NSString *)msg withDevice:(BLEDevice *)device{
    NSLog(@"recv %@", msg);
    self.recvText.text = [self.recvText.text stringByAppendingFormat:@"%@\n",msg];
}

#pragma mark - tableView dataSource &&  Delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return self.ListPeripheral.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *cellID = @"cellID";
    
    TableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[TableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
    }
    /// 获取设备
    BLEDevice *device = self.ListPeripheral[indexPath.row];
    /// 设置属性
    [cell setDevice:device];
    
    return cell;
}


// 选择要链接的设备, 然后显示数据
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    /// 获取设备
    BLEDevice *device = [self.ListPeripheral objectAtIndex:indexPath.row];
    
    [bleManager connectDevice:device];

}

#pragma mark - 懒加载
// 已连接设备
-(NSMutableString *)ConnectedlistStr{
    
    _ConnectedlistStr = [NSMutableString stringWithFormat:@"已连接设备: "];
    
    for (BLEDevice *device in bleManager.connectedDeviceList) {
        [_ConnectedlistStr appendString:device.name];
        [_ConnectedlistStr appendString:@"/"];
    }
    return _ConnectedlistStr;
}


#pragma mark - UI
- (void)initWithTableView
{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, self.view.bounds.size.width, 200) style:UITableViewStylePlain];
        
        [_tableView setDelegate:self];
        [_tableView setDataSource:self];
        [_tableView setBackgroundColor:[UIColor clearColor]];
        [_tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
        [_tableView setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        _tableView.rowHeight = 40;
        [self.view addSubview:_tableView];
    }
}

- (UILabel *)headTitle{
    if (!_headTitle) {
        UILabel *title = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 100, 40)];
        
        [title setTextAlignment:NSTextAlignmentCenter];
        [title setTextColor:[UIColor whiteColor]];
        [title setBackgroundColor:[UIColor darkGrayColor]];
        
        _headTitle = title;
    }
    return _headTitle;
}

- (void)initWithLeftBarButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setFrame:CGRectMake(0.0, 0.0, 60.0, 40.0)];
    [button setBackgroundColor:[UIColor clearColor]];
    [button setTitle:@"搜索设备" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(startScanPeripherals) forControlEvents:UIControlEventTouchUpInside];
    [button sizeToFit];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:button];
    
    [self.navigationItem setLeftBarButtonItem:item];
    
}

- (void)initWithRightBarButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setFrame:CGRectMake(0.0, 0.0, 60.0, 40.0)];
    [button setBackgroundColor:[UIColor clearColor]];
    [button setTitle:@"断开所有链接" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(closeAllConnect) forControlEvents:UIControlEventTouchUpInside];
    [button sizeToFit];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:button];
    [self.navigationItem setRightBarButtonItem:item];
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];
}


// 监听键盘的frame即将改变的时候调用
- (void)keyboardWillChange:(NSNotification *)note{
    
    // 获得键盘的frame
    CGRect frame = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    // 修改底部约束
    if (frame.origin.y == self.view.frame.size.height) {
        self.bottomConstraint.constant = 180;
        
    }else{
        
        self.bottomConstraint.constant = self.view.frame.size.height - frame.origin.y + 10;
    }
    // 执行动画
    CGFloat duration = [note.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    [UIView animateWithDuration:duration animations:^{
        // 如果有需要,重新排版
        [self.view layoutIfNeeded];
    }];
}

@end
