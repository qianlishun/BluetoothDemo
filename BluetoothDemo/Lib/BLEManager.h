//
//  SonopTekBLEManager.h
//  BLETest03
//
//  Created by mrq on 16/9/13.
//  Copyright © 2016年 MrQ. All rights reserved.
//

#import <Foundation/Foundation.h>


/// 设备过滤选择
#define TEST_1       0x0001
#define TEST_2       0x0002
#define TEST_3       0x0004

///扫描时间
#define ScanTimeInterval 4.0

@class  BLEDevice;
@protocol BLEManagerDelegate <NSObject>

// 获取周边设备
- (void)onDeviceFound:(NSArray *)deviceArray;

// @brief 连接设备的回调.
- (void)isConnected:(BOOL)isConnected withDevice:(BLEDevice *)device;

//brief 连接断开的回调.

- (void)disconnected:(BLEDevice *)device;

@end

@interface BLEManager : NSObject

/// 蓝牙开启状态 (YES 为开启)
@property (nonatomic,assign)   BOOL isBLEPoweredOn;

/// 已连接设备
@property (nonatomic,assign)  NSArray *connectedDevices;

+ (instancetype)sharedInstance;

- (void)setDelegate:(id)delegate;

/// 开始扫描设备 并设置过滤(想扫描什么设备就选择哪个,0代表不过滤)
- (void)scanForDevice:(unsigned short)filter;

- (void)stopScan;

- (void)closeAllDevice;

@end
