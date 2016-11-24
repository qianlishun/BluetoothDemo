//
//  SonopTekBLEManager.m
//  BLETest03
//
//  Created by mrq on 16/9/13.
//  Copyright © 2016年 MrQ. All rights reserved.
//

#import "BLEManager.h"
#import "BLEDriver.h"
#import "BLEDevice.h"

#import <CoreBluetooth/CoreBluetooth.h>

@interface BLEManager() <BLEDriverDelegate>
{
    
    NSTimer* scanTimer;

    id __weak theDelegate;
    // 管理器
    BLEDriver*  ble;

}

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
        
        ble = [BLEDriver sharedInstance];
        [ble setDelegate:self];
    }
    return self;
}

#pragma mark - Public Method
/// 设置代理
- (void)setDelegate:(id)delegate{
    theDelegate = delegate;
}

- (BOOL)isBLEPoweredOn{
    return ble.isBLEPoweredOn;
}

- (NSArray *)connectedDevices{
    return ble->connectedDevices.copy;
}

- (void)scanForDevice:(unsigned short)filter{
    [ble scanForDevice:filter];
}

- (void)stopScan{
    [ble stopScan];
}

- (void)closeAllDevice{
    [ble closelAllDevice];
}

#pragma mark - BLEDriverDelegate
- (void)onDeviceFound:(NSArray *)deviceArray{
    
    if ([theDelegate respondsToSelector:@selector(onDeviceFound:)]) {
        [theDelegate onDeviceFound:deviceArray];
    }
}
- (void)isConnected:(BOOL)isConnected withDevice:(BLEDevice *)device{
    if ([theDelegate respondsToSelector:@selector(isConnected:withDevice:)]) {
        [theDelegate isConnected:isConnected withDevice:device];
    }
}
- (void)disconnected:(BLEDevice *)device{
    if ([theDelegate respondsToSelector:@selector(disconnected:)]) {
        [theDelegate disconnected:device];
    }
}
@end
