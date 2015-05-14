//
//  DFBlunoManager.m
//
//  Created by Seifer on 15-5-14.
//  Copyright (c) 2015年 谢攀琪. All rights reserved.
//

#import "XPQBlunoManager.h"

/// 单例本身指针
static XPQBlunoManager* this = nil;

@interface XPQBlunoManager () {
    /// 服务UUID
    CBUUID *_servicesUUID;
    /// 读特性UUID
    CBUUID *_readUUID;
    /// 写特性UUID
    CBUUID *_writeUUID;
    /// 监听特性UUID
    CBUUID *_notifyUUID;
    
    /// 读特性
    CBCharacteristic *_readCharacteristic;
    /// 写特性
    CBCharacteristic *_writeCharacteristic;
    /// 监听特性
    CBCharacteristic *_notifyCharacteristic;
}

@end

@implementation XPQBlunoManager

#pragma mark - 单例实现需要函数
+ (id)sharedInstance {
    @synchronized(self) { //为了确保多线程情况下，仍然确保实体的唯一性
        if (!this) {
            this = [[XPQBlunoManager alloc] init];//该方法会调用 allocWithZone
            this->_centralManager = [[CBCentralManager alloc]initWithDelegate:this queue:nil];
            this->_dicPeripheral = [[NSMutableDictionary alloc] init];
            this->_currerPeripheral = nil;
            this->_servicesUUID = nil;
            this->_readUUID = nil;
            this->_writeUUID = nil;
            this->_notifyUUID = nil;
            
            this->_readCharacteristic = nil;
            this->_writeCharacteristic = nil;
            this->_notifyCharacteristic = nil;
        }
    }
	return this;
}

+(id)allocWithZone:(NSZone *)zone {
    @synchronized(self){
        if (!this) {
            this = [super allocWithZone:zone]; //确保使用同一块内存地址
            return this;
        }
    }
    return nil;
}

- (id)copyWithZone:(NSZone *)zone {
    return self; //确保copy对象也是唯一
}

#pragma mark - 主机操作
- (void)uuid:(CBUUID *)services read:(CBUUID *)read write:(CBUUID *)write notify:(CBUUID *)notify {
    _servicesUUID = services;
    _readUUID = read;
    _writeUUID = write;
    _notifyUUID = notify;
}

- (void)scan {
    [self.centralManager stopScan];         // 停止原来的扫描
    if (_centralManager.state == CBCentralManagerStatePoweredOn)
    {
        // 扫描有指定服务UUID的设备
        [self.centralManager scanForPeripheralsWithServices:@[_servicesUUID] options:nil];
        // 如果要扫描所有设备用下面的语句
        // [self.centralManager scanForPeripheralsWithServices:nil options:nil];
    }
}

- (void)stopScan {
    [self.centralManager stopScan];
}

- (BOOL)connectToDevice:(NSString *)uuid {
    BOOL result = YES;
    // 判断要连接的从机不是已经连接的从机
    if ( ! [[_currerPeripheral.identifier UUIDString] isEqualToString:uuid] ) {
        // 获取要连接的从机指针
        CBPeripheral *peripheral = [_dicPeripheral objectForKey:uuid];
        if (peripheral == nil) {    // 没有发现从机指针
            result = NO;
        }
        else {
            if (_currerPeripheral != nil) { // 判断原来是否连接了从机
                // 断开原来的连接
                [self disconnectToDevice];
            }
            // 连接从机
            [_centralManager connectPeripheral:peripheral options:nil];
            _currerPeripheral = peripheral;
            result = YES;
        }
    }
    return result;
}

- (void)disconnectToDevice {
    if (_currerPeripheral != nil) {
        // 断开从机连接
        [_centralManager cancelPeripheralConnection:_currerPeripheral];
        _currerPeripheral = nil;
    }
}

- (BOOL)writeDataToDevice:(NSData*)data {
    if ( _centralManager.state == CBCentralManagerStatePoweredOn
        && _currerPeripheral.state == CBPeripheralStateConnected
        && _writeCharacteristic != nil ) {
        if ( data != nil) {
            // 从指定服务端口指定特性写数据
            [_currerPeripheral writeValue:data forCharacteristic:_writeCharacteristic type:CBCharacteristicWriteWithResponse];
        }
        return YES;
    }
    else {
        return NO;
    }
}

-(BOOL)readDataFromDevice {
    if ( _centralManager.state == CBCentralManagerStatePoweredOn
        && _currerPeripheral.state == CBPeripheralStateConnected
        && _readCharacteristic != nil ) {
        [_currerPeripheral readValueForCharacteristic:_readCharacteristic];
        return YES;
    }
    else {
        return NO;
    }
}

-(BOOL)setNotify:(BOOL)enble {
    if ( _centralManager.state == CBCentralManagerStatePoweredOn
        && _currerPeripheral.state == CBPeripheralStateConnected
        && _notifyCharacteristic != nil ) {
        [_currerPeripheral setNotifyValue:enble forCharacteristic:_notifyCharacteristic];
        return YES;
    }
    else {
        return NO;
    }
}

-(BOOL)isNotitying {
    if (_notifyCharacteristic != nil) {
        return _notifyCharacteristic.isNotifying;
    }
    return NO;
}

#pragma mark - 主机控制器代理
// 中央管理器状态更新
-(void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state != CBCentralManagerStatePoweredOn)    // 蓝牙不可用
    {
        [self disconnectToDevice];
        // 把所有设备清空
        [_dicPeripheral removeAllObjects];
    }
    
    if ([((NSObject*)_delegate) respondsToSelector:@selector(blunoDidUpdateState:)])
    {
        [_delegate blunoDidUpdateState:(central.state == CBCentralManagerStatePoweredOn)];
    }    
}

// 扫描发现从机的时候回调
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    NSString* uuid = [peripheral.identifier UUIDString];
    [_dicPeripheral setObject:peripheral forKey:uuid];
    if ([((NSObject*)_delegate) respondsToSelector:@selector(blunoDidDiscoverPeripheral:RSSI:)]) {
        [_delegate blunoDidDiscoverPeripheral:peripheral RSSI:RSSI];
    }
}

// 连接从机后回调
-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    peripheral.delegate = self;
    // 开启搜索服务
    [peripheral discoverServices:nil];
    
    if ([_delegate respondsToSelector:@selector(blunoDidConnectPeripheral:)]) {
        [_delegate blunoDidConnectPeripheral:peripheral];
    }
}

// 从机断开后回调
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    // 从机断开后清空特性
    _readCharacteristic = nil;
    _writeCharacteristic = nil;
    _notifyCharacteristic = nil;
    if ([((NSObject*)_delegate) respondsToSelector:@selector(blunoDidDisconnectPeripheral:)]) {
        [_delegate blunoDidDisconnectPeripheral:peripheral];
    }
}

#pragma  mark - 从机代理
// 连接从机后回调,在CBCentralManager delegate的centralManager:didConnectPeripheral:回调之后
-(void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    // 遍历所有的服务
    for (CBService *services in peripheral.services) {
        // 启动搜寻特性
        if ([services.UUID isEqual:_servicesUUID]) {
            [peripheral discoverCharacteristics:nil forService:services];
        }
    }
}

// 搜寻到特性后回调
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if ([service.UUID isEqual:_servicesUUID]) {
        for (CBCharacteristic* characteristic in service.characteristics) {
            if ([characteristic.UUID isEqual:_readUUID]) {
                _readCharacteristic = characteristic;
            }
            if ([characteristic.UUID isEqual:_writeUUID]) {
                _writeCharacteristic = characteristic;
            }
            if ([characteristic.UUID isEqual:_notifyUUID]) {
                _notifyCharacteristic = characteristic;
            }
        }
    }
}

// 监听状态修改后回调
-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if ([_delegate respondsToSelector:@selector(blunoDidNotityUpdate:)]) {
        [_delegate blunoDidNotityUpdate:characteristic.isNotifying];
    }
}

// 接受到数据后回调
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if ([((NSObject*)_delegate) respondsToSelector:@selector(blunoDidReceiveData:)]) {
        [_delegate blunoDidReceiveData:characteristic.value];
    }
}

// 发送数据后回调
-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if ([((NSObject*)_delegate) respondsToSelector:@selector(blunoDidWriteData)]) {
        [_delegate blunoDidWriteData];
    }
}
@end