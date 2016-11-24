//
//  BLEDevice.m
//  BLETest03
//
//  Created by mrq on 16/9/13.
//  Copyright © 2016年 MrQ. All rights reserved.
//

#import "BLEDevice.h"
#import "BLEDriver.h"

#import <CoreBluetooth/CoreBluetooth.h>

@interface BLEDevice()<BLEDriverDelegate,CBPeripheralDelegate>{
    BLEDriver *theDriver;
    
    id __weak theDelegate;
    

    //  Basic Profile
    unsigned char m_ucBasicRev;
    unsigned char m_ucBasicFunc;
    NSString*     m_BasicSN;
    
}

@property CBPeripheral* thePeripheral;

@end

@implementation BLEDevice

/// 设置代理
- (void)setDelegate:(id)delegate{
    theDelegate = delegate;
}

- (void)connect
{
    [theDriver connectDevice:self.thePeripheral];
}

- (void)disconncet
{
    [theDriver disConnectDevice:self.thePeripheral];
}


- (instancetype)initWithPeriphral:(id)thePeripheal
{
    self = [super init];
    if (self) {
        _thePeripheral = thePeripheal;
        theDriver = [BLEDriver sharedInstance];
    
        }
    return self;
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
    BLEDevice *device = [theDriver getDeviceWithPeripheral:peripheral];
    [theDelegate isConnected:YES withDevice:device];
    
    [self readBasicChars:peripheral];
    
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


#pragma mark - 私有方法

#pragma mark - read UUID
/// 读取 UUID 抓取数据
- (void)didBLERead:(NSString *)uuid withPeripheral:(CBPeripheral*)periphearl{
    
   BLEDevice *device = [theDriver getDeviceWithPeripheral:periphearl];
    
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
        
        if ([theDelegate respondsToSelector:@selector(getInfo:withDevice:)]) {
            [theDelegate getInfo:info withDevice:device];
        }
    }
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
@end
