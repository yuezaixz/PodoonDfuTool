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
- (void)notifyfatLog:(NSString *)log;
- (void)notifyghvLog:(NSString *)log;
- (void)notifygvdLog:(NSString *)log;
- (void)notifygvd2Log:(NSString *)log;
- (void)notifygvnLog:(NSString *)log;
- (void)notifygvhLog:(NSString *)log;
- (void)notifyMiniError;

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

@end

NS_ASSUME_NONNULL_END
