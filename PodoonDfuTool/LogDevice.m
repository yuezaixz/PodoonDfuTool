//
//  LogDevice.m
//  PodoonDfuTool
//
//  Created by 吴迪玮 on 2019/12/6.
//  Copyright © 2019 podoon. All rights reserved.
//

#import "LogDevice.h"

@implementation LogDevice

-(NSString *)stringFormat {
    return [NSString stringWithFormat:@"%@,%@,%ld,%@", self.macAddress, self.no?self.no:@"", self.connectCount, self.lastDate];
}

@end
