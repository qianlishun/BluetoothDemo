//
//  BLEDevice.h
//  BLETest03
//
//  Created by mrq on 16/9/13.
//  Copyright © 2016年 MrQ. All rights reserved.
//

#import <Foundation/Foundation.h>
@class BLEDevice;

@protocol BLEDeviceDelegate <NSObject>


- (void)getInfo:(NSString*)info withDevice:(BLEDevice *)device;


@end

@interface BLEDevice : NSObject

- (void)connect;

- (void)disconncet;

- (void)setDelegate:(id)delegate;

/// 设备名称
@property (nonatomic,copy) NSString *name;
/// 设备 mac 地址
@property (nonatomic,copy) NSString *mac;

/// 设备信号强度
@property (nonatomic,copy) NSString *RSSI;

/// 设备服务数量
@property (nonatomic,copy) NSString *serviceCount;


- (instancetype)initWithPeriphral:(id)thePeripheal;
@end
