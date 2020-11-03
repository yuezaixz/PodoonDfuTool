//
//  BluetoothService.h
//  PodoonDfuTool
//
//  Created by 吴迪玮 on 2019/1/2.
//  Copyright © 2019年 podoon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "DFUOperations.h"

NS_ASSUME_NONNULL_BEGIN


@protocol RMBluetoothServiceDelegate <NSObject>

@required

- (void)notifyDiscover;
- (void)notifyDidConnect;
- (void)notifyWriteDfu;
- (void)notifyStartDfu;
- (void)notifyPercent:(NSInteger)percent;
- (void)notifySuccessDfu;
- (void)notifyFailDfu;
- (void)notifyVersion:(NSString *)version;
- (void)notifymacLog:(NSString *)version;

@end

@interface BluetoothService : NSObject <CBCentralManagerDelegate,CBPeripheralDelegate,DFUOperationsDelegate>

// 搜索蓝牙Server对象
@property (strong, nonatomic) CBCentralManager *centermanager;
@property (weak, nonatomic) id<RMBluetoothServiceDelegate> delegate;

@property (strong, nonatomic) NSString *otaUrl;
@property (nonatomic) BOOL isVersion;
@property (strong, nonatomic)  NSString  * _Nullable uuidStr;

+ (instancetype)sharedInstance;

- (void)search;

- (void)stop;
- (void)disconnect;
- (void)removeDevice;

- (void)writeCommand:(NSString *)command;

@end

NS_ASSUME_NONNULL_END
