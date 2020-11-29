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

- (void)notifyNoAirbagSucc;
- (void)notifyAirbagSucc;
- (void)notifySaveDefaultSucc;
- (void)notifyGetDefault:(NSInteger)slp currCST:(NSInteger)currCST defaultCST:(NSInteger)defaultCST;

- (void)notifyAirPresure: (NSInteger)airPresure;
- (void)notifyMacAddress: (NSString *)macAddress;

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
- (void)noairbagAdjust;
// 进入校准
- (void)airbagAdjust;
// 开始校准
- (void)saveDefault;
// 退出校准
- (void)getDefault;

@end

NS_ASSUME_NONNULL_END
