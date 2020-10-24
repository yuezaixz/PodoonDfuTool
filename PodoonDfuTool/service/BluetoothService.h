//
//  BluetoothService.h
//  PodoonDfuTool
//
//  Created by 吴迪玮 on 2019/1/2.
//  Copyright © 2019年 podoon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN


@protocol RMBluetoothServiceDelegate <NSObject>

@required

- (void)notifyDiscover;
- (void)notifyDidConnect;
- (void)notifyDisConnect;
- (void)notifyReady;
- (void)notifyLog:(NSString *)log;
- (void)notifyVals:(NSArray *)valArray rIndex: (NSInteger) rIndex;
// 进入或退出透传成功
- (void)notifyTunelSucc;
// 进入退出校准成功或开始发送数据成功
- (void)notifyAdjustOrStartDataSucc;
// 校准成功
- (void)notifyAdjustSucc;
// 校准失败
- (void)notifyAdjustFail;

@end

@interface BluetoothService : NSObject <CBCentralManagerDelegate,CBPeripheralDelegate>

// 搜索蓝牙Server对象
@property (strong, nonatomic) CBCentralManager *centermanager;
@property (weak, nonatomic) id<RMBluetoothServiceDelegate> delegate;
@property (strong, nonatomic) CBPeripheral *peripheral;

+ (instancetype)sharedInstance;

- (void)search;

- (void)stop;

- (void)disconnect;

- (void)sendData:(NSString *)cmd;

// 进入透传
- (void)enterTunel;
// 进入校准
- (void)enterAdjust;
// 开始校准
- (void)startAdjust;
// 退出校准
- (void)exitAdjust;
// 启动数据
- (void)startData;
// 退出透传
- (void)exitTunel;

@end

NS_ASSUME_NONNULL_END
