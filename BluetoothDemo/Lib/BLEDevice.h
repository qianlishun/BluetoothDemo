//
//  BLEDevice.h
//  BLETest03
//
//  Created by mrq on 16/9/13.
//  Copyright © 2016年 MrQ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BLEDevice : NSObject

/// 设备名称
@property (nonatomic,copy) NSString *name;
/// 设备 mac 地址
@property (nonatomic,copy) NSString *mac;

/// 设备信号强度
@property (nonatomic,copy) NSString *RSSI;

/// 设备服务数量
@property (nonatomic,copy) NSString *serviceCount;

@property (nonatomic,copy) NSString *info;

/// 连接状态
@property (nonatomic,assign) BOOL isConnected;

@property (nonatomic,strong,readonly) id peripheral;
- (instancetype)initWithPeriphral:(id)thePeripheal;
@end
