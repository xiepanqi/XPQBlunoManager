//
//  DFBlunoManager.h
//
//  Created by Seifer on 15-5-14.
//  Copyright (c) 2015年 谢攀琪. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@protocol XPQBlunoDelegate <NSObject>

@optional
/**
 *	@brief	蓝牙开关状态更改后回调
 *	@param 	bleSwitch YES开，NO其他状态
 *	@return	void
 */
-(void)blunoDidUpdateState:(BOOL)bleSwitch;

/**
 *	@brief	发现从机
 *	@param 	peripheral 从机对象指针
 *  @param  RSSI 信号强度
 *	@return	void
 */
-(void)blunoDidDiscoverPeripheral:(CBPeripheral *)peripheral RSSI:(NSNumber *)RSSI;

/**
 *	@brief	设备连接成功
 *	@param 	peripheral 从机对象指针
 *	@return	void
 */
-(void)blunoDidConnectPeripheral:(CBPeripheral *)peripheral;

/**
 *	@brief	设备断开连接
 *	@param 	peripheral 断开的从机对象指针
 *	@return	void
 */
-(void)blunoDidDisconnectPeripheral:(CBPeripheral *)peripheral;

/**
 *	@brief	已经写入数据
 *	@return	void
 */
-(void)blunoDidWriteData;

/**
 *	@brief	收到数据
 *	@param 	data 接收到的数据
 *	@return	void
 */
-(void)blunoDidReceiveData:(NSData*)data;

/**
 *	@brief	监听状态改变
 *	@param 	isNotifying 改变后的状态
 *	@return	void
 */
-(void)blunoDidNotityUpdate:(BOOL)isNotifying;
@end

@interface XPQBlunoManager : NSObject<CBCentralManagerDelegate,CBPeripheralDelegate>

/// 主机指针
@property (strong, nonatomic, readonly) CBCentralManager* centralManager;
/// 从机指针字典 key为UUID，value为从机指针
@property (strong, nonatomic, readonly) NSMutableDictionary* dicPeripheral;
/// 当前连接的从机指针
@property (strong, nonatomic, readonly) CBPeripheral* currerPeripheral;
/// 代理
@property (nonatomic, weak) id<XPQBlunoDelegate> delegate;

/**
 *	@brief	单例
 *	@return	单例指针
 */
+ (id)sharedInstance;

/**
 *	@brief  设置读、写、监听的特性UUID
 *  @param  services 从机要选择的服务UUID,如果为nil将能扫描到所有从机
 *  @param  read 用来读的特性UUID
 *  @param  write 用来写的特性UUID
 *  @param  notify 用来监听的特性UUID
 *  @return void
 */
- (void)uuid:(CBUUID*)services read:(CBUUID*)read write:(CBUUID*)write notify:(CBUUID*)notify;

/**
 *	@brief	扫描包含services服务UUID从机设备
 *	@return	void
 */
- (void)scan;

/**
 *	@brief	停止扫描
 *	@return	void
 */
- (void)stopScan;

/**
 *	@brief	连接到设备
 *	@param 	UUID 需要连接的从机UUID
 *	@return	YES 连接成功
 *  @return NO UUID错误
 */
- (BOOL)connectToDevice:(NSString *)uuid;

/**
 *	@brief	断开设备连接
 *	@return	void
 */
- (void)disconnectToDevice;

/**
 *	@brief	向当前连接的从机写入数据
 *	@param 	data 需要写入的数据
 *	@return	YES 成功写入
 *  @return NO 蓝牙未连接或者蓝牙不可用
 */
- (BOOL)writeDataToDevice:(NSData*)data;

/**
 *	@brief	从当前连接的从机发送读操作
 *	@return	YES 读操作发送成功
 *  @return NO 蓝牙未连接或者蓝牙不可用
 */
- (BOOL)readDataFromDevice;

/**
 *	@brief	设置连接从机的监听开关
 *	@param 	enble YES打开监听，NO关闭监听
 *	@return	YES 操作成功
 *  @return NO 蓝牙未连接或者蓝牙不可用
 */
- (BOOL)setNotify:(BOOL)enble;

/**
 *	@brief	监听特性是否在监听当中
 *  @return YES 监听中
 *  @return NO  没有监听
 */
- (BOOL)isNotitying;
@end
