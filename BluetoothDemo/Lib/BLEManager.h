//
//  SonopTekBLEManager.h
//  BLETest03
//
//  Created by mrq on 16/9/13.
//  Copyright © 2016年 MrQ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BLEDevice.h"

/// 设备过滤选择
#define TEST_1       0x0001
#define TEST_2       0x0002
#define TEST_3       0x0004

///扫描时间
#define ScanTimeInterval 3.0

typedef enum : NSUInteger {
    BLE_STATE_UNKNOWN = -1,
    BLE_STATE_OFF = 0,
    BLE_STATE_ON = 1,
}BLEAvailableState;

@protocol BLEManagerDelegate <NSObject>

/// 蓝牙开启状态 (BLE_STATE_ON 为开启)
- (void)onManagerBLEAvailable: (BLEAvailableState)state;
/**
 * @brief 获取周边设备.
 * @param deviceArray 设备数组.(BlueDevice类型)
 */
- (void)onManagerDevicesFound:(NSArray*)deviceArray;
/**
 * @brief 连接设备成功.
 * @param device 对应设备
 */
- (void)onManagerDeviceConnected:(BLEDevice*)device;
/**
 * @brief 连接设备失败.
 * @param device 对应设备
 */
- (void)onManagerDeviceConnectFailed: (BLEDevice*)device;
/**
 * @brief 连接设备断开.
 * @param device 对应设备
 */
- (void)onManagerDeviceDisconnected: (BLEDevice*)device;


/**
 * @brief 接收蓝牙端数据.
 * @param msg 接收到的数据
 * @param device 对应设备
 */
- (void)onReceivedMsg:(NSString*)msg withDevice:(BLEDevice*)device;

@end

@interface BLEManager : NSObject

+ (instancetype)sharedInstance;
/// 注册观察者
- (void)registeObserver: (id)observer;
/// 注销观察者
- (void)deregisteObserver: (id)observer;
/// 开始扫描设备 并设置过滤(想扫描什么设备就填哪个,格式如 TEST1|TEST2 ，0代表不过滤)
- (void)scanForDevice: (unsigned short)filter;
/// 取消扫描
- (void)cancelScan;
/// 连接某设备
- (void)connectDevice: (BLEDevice*)device;
/// 断开某已连接设备的连接
- (void)disconnectDevice: (BLEDevice*)device;
/// 断开所有已连接的设备
- (void)disconnectAllDevices;

/// 已连接设备列表
- (NSArray *)connectedDeviceList;

/// 重置(清空所有设备列表)
- (void)resetDeviceList;

- (BLEAvailableState)BLEAvailable;


/// 发送消息到蓝牙端
- (void)sendMsg:(NSString*)msg device:(BLEDevice*)device response:(BOOL)response;


- (void)sendData:(NSData *)data device:(BLEDevice*)device UUID:(NSString*)UUID response:(BOOL)response;

@end
