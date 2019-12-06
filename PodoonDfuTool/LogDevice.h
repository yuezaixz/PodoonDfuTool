//
//  LogDevice.h
//  PodoonDfuTool
//
//  Created by 吴迪玮 on 2019/12/6.
//  Copyright © 2019 podoon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface LogDevice : NSObject

@property (strong, nonatomic) NSString *macAddress;
@property (strong, nonatomic) NSString *uuid;
@property (strong, nonatomic) NSString *no;
@property (nonatomic) NSInteger connectCount;
@property (strong, nonatomic) NSDate *lastDate;
@property (strong, nonatomic) CBPeripheral *peripheral;

-(NSString *)stringFormat;

@end
