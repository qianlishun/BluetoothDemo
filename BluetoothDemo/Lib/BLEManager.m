//
//  BLEManager
//
//
//  Created by mrq on 16/9/13.
//  Copyright © 2016年 MrQ. All rights reserved.
//

#define BASIC_CHAR_REV_UUID     @"FF11"
#define BASIC_CHAR_FUNC_UUID    @"FF12"
#define BASIC_CHAR_SN_UUID      @"FF13"
#define BASIC_CHAR_SN_CONF_UUID @"FF14"


#import "BLEManager.h"

#import <CoreBluetooth/CoreBluetooth.h>

@interface BLEManager() <CBCentralManagerDelegate,CBPeripheralDelegate>
{
    
    /// 管理器
    CBCentralManager* theCntrMgr;
    
    NSMutableArray *allDevicesList;
    
    /// 可连接设备列表
    NSMutableArray *discoverDevices;
    
    /// 已连接设备
    NSMutableArray *connectedDevices;
    
    /// 过滤标识
    NSMutableArray *theFliter;
    
    //  Basic Profile
    unsigned char m_ucBasicRev;
    unsigned char m_ucBasicFunc;
    NSString*     m_BasicSN;

}

@property(strong,nonatomic) NSHashTable* observers;

@end

@implementation BLEManager

// 单例模式
+ (instancetype)sharedInstance{
    static BLEManager *share = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        share = [[BLEManager alloc]init];
    });
    return share;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
#if  __IPHONE_OS_VERSION_MIN_REQUIRED > __IPHONE_6_0
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                                 //蓝牙power没打开时alert提示框
                                 @YES,CBCentralManagerOptionShowPowerAlertKey,
                                 //重设centralManager恢复的IdentifierKey
                                 @"SmartBlueKit",CBCentralManagerOptionRestoreIdentifierKey,
                                 nil];
        
#else
        NSDictionary *options = nil;
#endif
        
        //        dispatch_queue_t queue = dispatch_get_main_queue();
        
        NSArray *backgroundModes = [[[NSBundle mainBundle] infoDictionary]objectForKey:@"UIBackgroundModes"];
        if ([backgroundModes containsObject:@"bluetooth-central"]) {
            //后台模式
            theCntrMgr =  [[CBCentralManager alloc] initWithDelegate:self queue:nil options:options];
        }
        else {
            //非后台模式
            theCntrMgr = [[CBCentralManager alloc]initWithDelegate:self queue:nil];
        }
        
        //        [self scanForDevice:0];
        
        _observers = [NSHashTable hashTableWithOptions:NSHashTableWeakMemory];
        
        discoverDevices = [NSMutableArray arrayWithCapacity:1];
        connectedDevices = [NSMutableArray arrayWithCapacity:1];
        theFliter = [NSMutableArray arrayWithCapacity:1];
        
        allDevicesList = [NSMutableArray arrayWithCapacity:1];
    }
    return self;
}
- (void)registeObserver: (id)observer{
    if (observer == nil)
        return;
    if([_observers containsObject:observer]){
        return;
    }
    if (self.BLEAvailable == BLE_STATE_ON) {
        if ([observer respondsToSelector:@selector(onManagerBLEAvailable:)]) {
            [observer onManagerBLEAvailable:self.BLEAvailable];
        }
    }
    [_observers addObject:observer];
}

- (void)deregisteObserver: (id)observer{
    if ([_observers containsObject:observer]) {
        [_observers removeObject:observer];
    }
}
- (void)scanForDevice: (unsigned short)filter{
    NSMutableString *str = [self filterStrWith:filter];
    NSLog(@"过滤:%@",str);
    theFliter =[NSMutableArray arrayWithArray:[str componentsSeparatedByString:@"//"]];
    [self scanForPeripherals];
}

- (void)cancelScan{
    id obs;
    for (obs in _observers) {
        if ([obs respondsToSelector:@selector(onManagerDevicesFound:)]) {
            [obs onManagerDevicesFound:discoverDevices.copy];
        }
    }
    [theCntrMgr stopScan];
}

- (void)connectDevice: (BLEDevice*)device{
    if (!device) {
        return;
    }
    CBPeripheral *peripheral = device.peripheral;
    if (!device.peripheral) {
        for (BLEDevice *d in discoverDevices) {
            if ([d.mac isEqualToString:device.mac]) {
                peripheral = d.peripheral;
                break;
            }
        }
        for (BLEDevice *d in allDevicesList) {
            if ([d.mac isEqualToString:device.mac]) {
                peripheral = d.peripheral;
                break;
            }
        }
    }
    if (theCntrMgr.state == CBCentralManagerStateUnsupported) {//设备不支持蓝牙
        
    }else {//设备支持蓝牙连接
        if (theCntrMgr.state == CBCentralManagerStatePoweredOn && peripheral != nil) {//蓝牙开启状态
            NSLog(@"连接设备:%@",peripheral.name);
            //连接设备
            [theCntrMgr connectPeripheral:peripheral options:@{CBConnectPeripheralOptionNotifyOnConnectionKey:@YES,CBConnectPeripheralOptionNotifyOnNotificationKey:@YES,CBConnectPeripheralOptionNotifyOnDisconnectionKey:@YES}];
        }
    }
}

- (void)disconnectDevice: (BLEDevice*)device{
    if (!device) {
        return;
    }
    CBPeripheral *per = device.peripheral;
    if (!device.peripheral) {
        for (BLEDevice *d in connectedDevices) {
            if ([d.mac isEqualToString:device.mac]) {
                per = d.peripheral;
                break;
            }
        }
    }
    [theCntrMgr cancelPeripheralConnection:per];
}

- (void)disconnectAllDevices{
    NSLog(@"关闭所有链接");
    for (BLEDevice *device in connectedDevices) {
        [self disconnectDevice:device];
    }
}


- (BLEAvailableState)BLEAvailable{
    switch (theCntrMgr.state) {
        case CBCentralManagerStatePoweredOn:
            return BLE_STATE_ON;
            break;
        case CBManagerStatePoweredOff:
            return BLE_STATE_OFF;
        default:
            return BLE_STATE_UNKNOWN;
            break;
    }
}


//
//  MARK: CBCenteralManagerDelegate
//
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSUInteger result = BLE_STATE_UNKNOWN;
    switch (central.state) {
        case CBCentralManagerStatePoweredOff:
            [theCntrMgr scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:[NSNumber numberWithBool:NO]}];
            
            NSLog(@"CBCentralManagerStatePoweredOff");
            result = BLE_STATE_OFF;
            break;
        case CBCentralManagerStatePoweredOn:
            NSLog(@"CBCentralManagerStatePoweredOn");
            result = BLE_STATE_ON;
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
    
    
    id obs;
    for (obs in _observers) {
        if ([obs respondsToSelector:@selector(onManagerBLEAvailable:)]) {
            [obs onManagerBLEAvailable:result];
        }
    }
    if(result != BLE_STATE_ON){
        [allDevicesList removeAllObjects];
        [connectedDevices removeAllObjects];
        [discoverDevices removeAllObjects];
    }
}

- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary *)dict {
    
}

//发现蓝牙设备
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI{
    
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
    
    [self addAllDeviceList:device];
    
}

//连接蓝牙设备失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"连接失败%s",__FUNCTION__);
    BLEDevice *device = [self getDeviceWithPeripheral:peripheral];
    id obs;
    for (obs in _observers) {
        if ([obs respondsToSelector:@selector(onManagerDeviceConnectFailed:)]) {
            [obs onManagerDeviceConnectFailed:device];
        }
    }
}

//连接蓝牙设备成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"连接成功%s",__FUNCTION__);
    
    BLEDevice *device = [self getDeviceWithPeripheral:peripheral];
    
    [self addConnectedDevice:device];
    [discoverDevices removeObject:device];
    
    [peripheral setDelegate:self];
    
    id obs;
    for (obs in _observers) {
        //        if ([obs respondsToSelector:@selector(onManagerDevicesFound:)]) {
        //            [obs onManagerDevicesFound:discoverDevices.copy];
        //        }
        if ([obs respondsToSelector:@selector(onManagerDeviceConnected:)]) {
            [obs onManagerDeviceConnected:device];
        }
    }
    [peripheral discoverServices:nil];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"断开连接%s",__FUNCTION__);
    
    if (error)
    {
        NSLog(@">>> didDisconnectPeripheral for %@ with error: %@", peripheral.name, [error localizedDescription]);
    }
    BLEDevice *device = [self getDeviceWithPeripheral:peripheral];
    
    [self removeConnectedDevice:device];
    
    id obs;
    for (obs in _observers) {
        if ([obs respondsToSelector:@selector(onManagerDeviceDisconnected:)]) {
            [obs onManagerDeviceDisconnected:device];
        }
    }
}

#pragma mark - CBPeripheralDelegate
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    for (CBService* service in peripheral.services)  {
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(nonnull CBService *)service error:(nullable NSError *)error{
    
    if (error) {
        return;
    }
    
    //
    //  Connection finished.
    //

    [self readBasicChars:peripheral];
    
     //  set Notify for UUID 
     // 这里是注册 character 的通知消息，要监听哪个服务的消息，就填这个服务的UUID
     // 对应的消息会在下面 didUpdateValueForCharacteristic 里得到
    CBCharacteristic* character = [self GetCharacteristic:UUID withPeripheral:peripheral];
    if (character) {
        [peripheral setNotifyValue:YES forCharacteristic: character];
    }
    
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    // Basic Profiles
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:BASIC_CHAR_REV_UUID ]]) {
        
        unsigned char* pvalue = (unsigned char*)[characteristic.value bytes];
        m_ucBasicRev = pvalue[0];
        [self didBLERead:BASIC_CHAR_REV_UUID withPeripheral:peripheral];
        
    } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:BASIC_CHAR_FUNC_UUID]]) {
        
        unsigned char* pvalue = (unsigned char*)[characteristic.value bytes];
        m_ucBasicFunc = pvalue[0];
        
        [self didBLERead:BASIC_CHAR_FUNC_UUID withPeripheral:peripheral];
        
    } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:BASIC_CHAR_SN_UUID]]) {
        
        NSLog(@"didUpdateValue for BASIC_CHAR_SN_UUID");
        
        char* psn = (char*)[characteristic.value bytes];
        
        m_BasicSN = [[NSString alloc] initWithFormat:@"%s",psn];
        
        [self didBLERead:BASIC_CHAR_SN_UUID withPeripheral:peripheral];
    }
}


#pragma mark - Function
/// 扫描设备
- (void)scanForPeripherals
{
    [discoverDevices removeAllObjects];
    
    NSUInteger bleEnble = BLE_STATE_UNKNOWN;
    
    if (theCntrMgr.state == CBCentralManagerStateUnsupported) {//设备不支持蓝牙
        
    }else {//设备支持蓝牙连接
        if (theCntrMgr.state == CBCentralManagerStatePoweredOn) {//蓝牙开启状态
            bleEnble = BLE_STATE_ON;
            [theCntrMgr scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:[NSNumber numberWithBool:NO]}];
        }else if(theCntrMgr.state == CBCentralManagerStatePoweredOff){
            bleEnble = BLE_STATE_OFF;
        }
    }
    
    if(!bleEnble){
        NSLog(@"蓝牙未打开或不支持");
        return;
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    /// ScanTimeInterval秒 后停止扫描
    [self performSelector:@selector(cancelScan) withObject:self afterDelay:ScanTimeInterval];
    
    //    [_scanTimer invalidate];
    //    _scanTimer = nil;
}

#pragma mark - 私有方法

#pragma mark - read UUID
/// 读取 UUID 抓取数据
- (void)didBLERead:(NSString *)uuid withPeripheral:(CBPeripheral*)periphearl{
    
    BLEDevice *device = [self getDeviceWithPeripheral:periphearl];
    
    // ---Basic---
    NSMutableString *info = [NSMutableString string];
    
    // serviceRevision
    if ([uuid isEqualToString:BASIC_CHAR_REV_UUID]) {
        unsigned char ucRev = [self basicRevision];
        NSString* rev = [[NSString alloc]initWithFormat:@"0x%x",ucRev];
        NSLog(@"serviceRevision:%@",rev);
        [self doRead:BASIC_CHAR_REV_UUID with:periphearl];
    }
    
    // function
    else if ([uuid isEqualToString:BASIC_CHAR_FUNC_UUID]) {
        
        unsigned char ucFunc = [self basicFunc];
        
        NSMutableString* func = [[NSMutableString alloc]init];
        if (ucFunc & 0x01) {    //  EarTag Reader Featured.
            
            [func appendFormat:@"FF17"];
            [self doRead:@"FF17" with:periphearl];
            
        }
        if (ucFunc & 0x10) {
            
            if ([func length]>0) {
                [func appendFormat:@"//"];
            }
            [func appendFormat:@"FF1C"];
            [self doRead:@"FF1C" with:periphearl];
            
        }
        
        [info appendString:func];
    }
    device.info = info.copy;
}

/// readValueForCharacteristic
-(void)doRead:(NSString *)uuid with:(CBPeripheral*)peripheral{
    
    CBCharacteristic* character = [self GetCharacteristic:uuid withPeripheral:peripheral];
    [peripheral readValueForCharacteristic:character];// 会去调用didUpdateValueForCharacteristic
}

-(void)readBasicChars:(CBPeripheral *)peripheral {
    // service revision
    CBCharacteristic* basicChar = [self GetCharacteristic:BASIC_CHAR_REV_UUID withPeripheral:peripheral];
    if (!basicChar) {
        return;
    }
    [peripheral readValueForCharacteristic:basicChar];
    
    // function provided
    basicChar = [self GetCharacteristic:BASIC_CHAR_FUNC_UUID withPeripheral:peripheral];
    [peripheral readValueForCharacteristic:basicChar];
    
    //  sn
    basicChar = [self GetCharacteristic:BASIC_CHAR_SN_UUID withPeripheral:peripheral];
    [peripheral readValueForCharacteristic:basicChar];
}


#pragma mark - Get Service && Characteristic
//----------------------------------------------------------------------------
//
-(CBService*)GetService:(NSString*)uuid withPeripheral:(CBPeripheral*)peripheral{
    if (peripheral == nil || peripheral.services == nil) {
        return nil;
    }
    CBUUID* servuuid = [CBUUID UUIDWithString:uuid];
    for (CBService* service in peripheral.services) {
        if ([service.UUID isEqual:servuuid]) {
            return service;
        }
    }
    return nil;
}

-(CBCharacteristic*)GetCharacteristic:(NSString*)uuid withPeripheral:(CBPeripheral*)peripheral{
    if (peripheral == nil || peripheral.services == nil) {
        return nil;
    }
    CBUUID* charuuid = [CBUUID UUIDWithString:uuid];
    for (CBService* service in peripheral.services) {
        for (CBCharacteristic* character in service.characteristics) {
            if ([character.UUID isEqual:charuuid]) {
                return character;
            }
        }
    }
    return nil;
}
- (CBCharacteristic*)Get1SCharacteristic:(NSString*)uuid withService:(CBService*)service{
    if (service == nil) {
        return nil;
    }
    CBUUID *charuuid = [CBUUID UUIDWithString:uuid];
    for (CBCharacteristic *charcter in service.characteristics) {
        if ([charcter.UUID isEqual:charuuid]) {
            return charcter;
        }
    }
    return nil;
}

-(unsigned char)basicRevision {
    return m_ucBasicRev;
}
-(unsigned char)basicFunc {
    return m_ucBasicFunc;
}

-(NSString*)basicSN {
    return m_BasicSN;
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


#pragma mark - 设备list管理
- (void)addDiscoverDevices:(BLEDevice *)device{
    if (!device) {
        return;
    }
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
    if (device && ![connectedDevices containsObject:device]) {
        device.isConnected = YES;
        
        [connectedDevices enumerateObjectsUsingBlock:^(BLEDevice*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.mac isEqualToString:device.mac]) {
                [connectedDevices removeObjectAtIndex:idx];
                *stop = YES;
            }
        }];
        [connectedDevices addObject:device];
    }
    
}

- (void)addAllDeviceList:(BLEDevice *)device{
    if (device && ![allDevicesList containsObject:device]) {
        [allDevicesList addObject:device];
    }
}

- (void)removeConnectedDevice:(BLEDevice *)device{
    if (device && [connectedDevices containsObject:device]) {
        device.isConnected = NO;
        [connectedDevices removeObject:device];
    }
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

- (NSArray *)connectedDeviceList{
    return connectedDevices.copy;
}

- (void)resetDeviceList{
    [allDevicesList removeAllObjects];
    [connectedDevices removeAllObjects];
    [discoverDevices removeAllObjects];
}

- (void)dealloc{
    
    NSLog(@"blueManager dealloc");
}


@end
