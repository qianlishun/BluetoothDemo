//
//  BLEDriver.m
//  BLETest03
//
//  Created by mrq on 16/9/13.
//  Copyright © 2016年 MrQ. All rights reserved.
//

#import "BLEDriver.h"
#import "BLEDevice.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "BLEManager.h"

@interface BLEDriver() <CBCentralManagerDelegate,CBPeripheralDelegate>

@property (nonatomic,strong)     NSTimer *scanTimer;


@end


@implementation BLEDriver

+ (BLEDriver*)sharedInstance
{
    static BLEDriver* singleInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleInstance = [[BLEDriver alloc]init];
    });
    return singleInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        dispatch_queue_t queue = dispatch_get_main_queue();
        centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:queue options:@{CBCentralManagerOptionShowPowerAlertKey:@YES}];
        [centralManager setDelegate:self];
        
        discoverDevices = [NSMutableArray arrayWithCapacity:1];
        discoverPers = [NSMutableArray arrayWithCapacity:1];
        connectedPeripherals = [NSMutableArray arrayWithCapacity:1];
        connectedDevices = [NSMutableArray arrayWithCapacity:1];
        theFliter = [NSMutableArray arrayWithCapacity:1];
        
    }
    return self;
}


/// 设置代理
- (void)setDelegate:(id)delegate{
    theDelegate = delegate;
}


- (BOOL)isBLEPoweredOn{
    return (centralManager.state == CBCentralManagerStatePoweredOn);
}


#pragma mark - Scan
/// 开始扫描
- (void)scanForDevice:(unsigned short)filter
{
    
    NSMutableString *str = [self filterStrWith:filter];
    
    NSLog(@"过滤:%@",str);
    
    //    if (!_scanTimer) {
    //        _scanTimer = [NSTimer timerWithTimeInterval:ScanTimeInterval target:self selector:@selector(scanForPeripherals) userInfo:nil repeats:NO];
    //        [[NSRunLoop mainRunLoop] addTimer:_scanTimer forMode:NSDefaultRunLoopMode];
    //    }
    //    if (_scanTimer) {
    //        [_scanTimer fire];
    //    }
    
    theFliter =[NSMutableArray arrayWithArray:[str componentsSeparatedByString:@"//"]];
    
    [self scanForPeripherals];
}


/// 停止扫描
- (void)stopScan
{
    [centralManager stopScan];
}


/// 扫描设备
- (void)scanForPeripherals
{
    [discoverDevices removeAllObjects];
    [discoverPers removeAllObjects];
    
    if ([theDelegate respondsToSelector:@selector(onDeviceFound:)]) {
        [theDelegate onDeviceFound:discoverDevices.copy];
    }
    
    if (centralManager.state == CBCentralManagerStateUnsupported) {//设备不支持蓝牙
        
    }else {//设备支持蓝牙连接
        if (centralManager.state == CBCentralManagerStatePoweredOn) {//蓝牙开启状态
            
            [centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:[NSNumber numberWithBool:NO]}];
        }
    }
    /// ScanTimeInterval秒 后停止扫描
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ScanTimeInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [centralManager stopScan];
    });
    //    [_scanTimer invalidate];
    //    _scanTimer = nil;
}

#pragma mark - connect
/// 链接某设备
- (void)connectDevice:(CBPeripheral *)peripheral{
    
    if (centralManager.state == CBCentralManagerStateUnsupported) {//设备不支持蓝牙
        
    }else {//设备支持蓝牙连接
        if (centralManager.state == CBCentralManagerStatePoweredOn && peripheral != nil) {//蓝牙开启状态
            
            NSLog(@"连接设备:%@",peripheral.name);
            //连接设备
            [centralManager connectPeripheral:peripheral options:@{CBConnectPeripheralOptionNotifyOnConnectionKey:@YES,CBConnectPeripheralOptionNotifyOnNotificationKey:@YES,CBConnectPeripheralOptionNotifyOnDisconnectionKey:@YES}];
        }
    }
}

/// 断开某设备连接
- (void)disConnectDevice:(CBPeripheral *)peripheral{
    
    if (!peripheral) {
        return;
    }
    
    [centralManager cancelPeripheralConnection:peripheral];
}

/// 断开所有连接
- (void)closelAllDevice{
    NSLog(@"关闭所有链接");
    for (CBPeripheral *per in connectedPeripherals) {
        [centralManager cancelPeripheralConnection:per];
    }
}


#pragma mark - CBCentralManager Delegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state) {
        case CBCentralManagerStatePoweredOff:
            NSLog(@"CBCentralManagerStatePoweredOff");
            break;
        case CBCentralManagerStatePoweredOn:
            NSLog(@"CBCentralManagerStatePoweredOn");
            break;
        case CBCentralManagerStateResetting:
            NSLog(@"CBCentralManagerStateResetting");
            break;
        case CBCentralManagerStateUnauthorized:
            NSLog(@"CBCentralManagerStateUnauthorized");
            break;
        case CBCentralManagerStateUnknown:
            NSLog(@"CBCentralManagerStateUnknown");
            break;
        case CBCentralManagerStateUnsupported:
            NSLog(@"CBCentralManagerStateUnsupported");
            break;
            
        default:
            break;
    }
}

//发现蓝牙设备
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    
    BOOL isWanted = NO;
    
    /// 如果数组不为空,说明设置了过滤. 去判断设备是不是想要的; (该数组count为1时代表数组为空)
    if (theFliter.count > 1) {
        
        for (NSString *fliter in theFliter) {
            if ([peripheral.name hasPrefix:fliter]) {
                isWanted = YES;
            }
        }
        
    }else{ // 数组为空, 那么未设置过滤, 则添加所有设备到设备发现列表
        isWanted = YES;
    }
    
    if (!isWanted) {
        return;
    }
    
    NSArray *serviceUUIDs = [advertisementData objectForKey:@"kCBAdvDataServiceUUIDs"];
    
    BLEDevice *device = [[BLEDevice alloc]initWithPeriphral:peripheral];
    
    device.name = peripheral.name;
    device.RSSI = RSSI.stringValue;
    device.serviceCount = [NSString stringWithFormat:@"%lu",(unsigned long)serviceUUIDs.count];
    device.mac = peripheral.identifier.UUIDString;
    
    [self addDiscoverDevices:device];
    
    [self addDiscoverPers:peripheral];
    
    if ([theDelegate respondsToSelector:@selector(onDeviceFound:)]) {
        [theDelegate onDeviceFound:discoverDevices.copy];
    }
}

//连接蓝牙设备成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"连接成功%s",__FUNCTION__);
    
    [self addPeripheral:peripheral];
    
    BLEDevice *device = [self getDeviceWithPeripheral:peripheral];
    
    [self addConnectedDevice:device];
    
    [peripheral setDelegate:device];
    
    [discoverPers removeObject:peripheral];
    
    [discoverDevices removeObject:device];
    
    if ([theDelegate respondsToSelector:@selector(onDeviceFound:)]) {
        [theDelegate onDeviceFound:discoverDevices.copy];
    }
    
    [peripheral discoverServices:nil];
    
    if ([theDelegate respondsToSelector:@selector(isConnected:withDevice:)]) {
        [theDelegate isConnected:YES withDevice:device];
    }
    
}
//连接蓝牙设备失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    
    NSLog(@"连接失败%s",__FUNCTION__);
    BLEDevice *device = [self getDeviceWithPeripheral:peripheral];
    
    if ([theDelegate respondsToSelector:@selector(isConnected:withDevice:)]) {
        [theDelegate isConnected:NO withDevice:device];
    }
}

// 连接断开
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"断开连接%s",__FUNCTION__);
    
    if (error)
    {
        NSLog(@">>> didDisconnectPeripheral for %@ with error: %@", peripheral.name, [error localizedDescription]);
    }
    BLEDevice *device = [self getDeviceWithPeripheral:peripheral];
    
    [connectedPeripherals removeObject:peripheral];
    [connectedDevices removeObject:device];
    
    if ([theDelegate respondsToSelector:@selector(disconnected:)]) {
        [theDelegate disconnected:device];
    }
}


#pragma mark - 设备list管理
///  存储 BLEDevice
- (void)addDiscoverDevices:(BLEDevice *)device{
    
    BOOL isExist = NO;
    
    if (discoverDevices.count == 0) {
        [discoverDevices addObject:device];
    }else {
        for (int i = 0;i < discoverDevices.count;i++) {
            BLEDevice *info = [discoverDevices objectAtIndex:i];
            if ([info.mac isEqualToString:device.mac]) {
                isExist = YES;
                [discoverDevices replaceObjectAtIndex:i withObject:info];
            }
        }
        if (!isExist) {
            [discoverDevices addObject:device];
        }
    }
}

- (void)addConnectedDevice:(BLEDevice *)device{
    if (![connectedDevices containsObject:device]) {
        [connectedDevices addObject:device];
    }
}

/// 存储CBPeripheral
- (void)addDiscoverPers:(CBPeripheral *)peripheral{
    if (![discoverPers containsObject:peripheral]) {
        [discoverPers addObject:peripheral];
    }
}

- (void)addPeripheral:(CBPeripheral *)peripheral {
    if (![connectedPeripherals containsObject:peripheral]) {
        [connectedPeripherals addObject:peripheral];
    }
}


// BLEDevice --> CBPeripheral
- (CBPeripheral *)getPeripheralWithDevice:(BLEDevice *)device{
    
    for (CBPeripheral *per in discoverPers) {
        
        if ([per.identifier.UUIDString isEqualToString:device.mac]) {
            return per;
        }
    }
    for (CBPeripheral *per in connectedPeripherals) {
        if ([per.identifier.UUIDString isEqualToString:device.mac]) {
            return per;
        }
    }
    return nil;
}

// CBPeripheral --> BLEDevice
- (BLEDevice *)getDeviceWithPeripheral:(CBPeripheral *)peripheral{
    for (BLEDevice *device in discoverDevices) {
        
        if ([device.mac isEqualToString:peripheral.identifier.UUIDString]) {
            return device;
        }
    }
    for (BLEDevice *device in connectedDevices) {
        if ([device.mac isEqualToString:peripheral.identifier.UUIDString]) {
            return device;
        }
    }
    return  nil;
}



/// filterCode --> filterStr
- (NSMutableString *)filterStrWith:(unsigned short)filter{
    
    NSMutableString *str = [NSMutableString new];
    
    if (filter == 0) {
        return str;
    }
    
    if (filter & TEST_1) {
        [str appendString:@"TEST-1//"];
    }
    if (filter & TEST_2) {
        [str appendString:@"TEST-2//"];
    }
    if (filter & TEST_3){
        [str appendString:@"TEST-3//"];
    }
    
    return str;
}


@end
