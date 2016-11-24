//
//  BLEDriver.h
//  BLEDemo
//
//  Created by mrq on 16/9/13.
//  Copyright © 2016年 MrQ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#define BASIC_CHAR_REV_UUID     @"FF11"
#define BASIC_CHAR_FUNC_UUID    @"FF12"
#define BASIC_CHAR_SN_UUID      @"FF13"
#define BASIC_CHAR_SN_CONF_UUID @"FF14"

@class BLEDevice;
@protocol BLEDriverDelegate <NSObject>

@optional
/**
 * @brief 搜索周边设备.
 * @param deviceArray 设备数组.(SonopTekBLEDevice类型)
 */
- (void)onDeviceFound:(NSArray *)deviceArray;

/// 链接设备的回调
- (void)isConnected:(BOOL)isConnected withDevice:(BLEDevice *)device;

/// 连接断开的回调
- (void)disconnected:(BLEDevice *)device;


@end

@class BLEDevice;
@interface BLEDriver : NSObject{
    
    id __weak theDelegate;
    
    CBCentralManager*  centralManager;
    NSMutableArray *discoverDevices;
    
    NSMutableArray *discoverPers;
    
    NSMutableArray *connectedPeripherals;
    
    NSMutableArray *theFliter;
    
@public
    NSMutableArray *connectedDevices;
}

@property (nonatomic,assign)    BOOL isBLEPoweredOn;

+ (BLEDriver*)sharedInstance;

- (void)setDelegate:(id)delegate;

- (void)scanForDevice:(unsigned short)filter;

- (void)stopScan;

- (void)connectDevice: (CBPeripheral*)device;

- (void)disConnectDevice:(CBPeripheral*)device;

- (void)closelAllDevice;

- (void)addDiscoverPers:(CBPeripheral *)peripheral;

- (CBPeripheral *)getPeripheralWithDevice:(BLEDevice *)device;
- (BLEDevice *)getDeviceWithPeripheral:(CBPeripheral *)peripheral;

@end
