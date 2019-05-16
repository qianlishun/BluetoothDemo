//
//  BLEDevice.m
//  BLETest03
//
//  Created by mrq on 16/9/13.
//  Copyright © 2016年 MrQ. All rights reserved.
//

#import "BLEDevice.h"

#import <CoreBluetooth/CoreBluetooth.h>

@interface BLEDevice()

@property CBPeripheral* thePeripheral;

@end

@implementation BLEDevice
- (instancetype)initWithPeriphral:(id)thePeripheal{
    self = [super init];
    if (self) {
        self.thePeripheral = thePeripheal;
    }
    return self;
}

- (id)peripheral{
    return self.thePeripheral;
}

@end
