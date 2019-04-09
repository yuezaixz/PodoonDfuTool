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

@end

@interface BluetoothService : NSObject <CBCentralManagerDelegate,CBPeripheralDelegate,DFUOperationsDelegate>

// 搜索蓝牙Server对象
@property (strong, nonatomic) CBCentralManager *centermanager;
@property (weak, nonatomic) id<RMBluetoothServiceDelegate> delegate;

@property (strong, nonatomic) NSString *otaUrl;

+ (instancetype)sharedInstance;

- (void)search;

- (void)stop;

@end

NS_ASSUME_NONNULL_END
