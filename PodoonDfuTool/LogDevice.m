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
    return [NSString stringWithFormat:@"%@,%@,%ld,%@,%@", self.macAddress, self.no?self.no:@"", self.connectCount, [LogDevice stringFromDateWithCommonFormat:self.lastDate], self.firmTime];
}

-(NSString *)stringDetailFormat {
    return [NSString stringWithFormat:@"MAC:%@,NO:%@,次数:%ld", self.macAddress, self.no?self.no:@"", self.connectCount];
}

+ (NSString *)stringFromDateWithCommonFormat:(NSDate *)date {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:[NSLocale currentLocale]];
    
    //    NSTimeZone *gmtZone = [NSTimeZone timeZoneWithName:@"Asia/Shanghai"];
    NSTimeZone* gmtZone = [NSTimeZone localTimeZone];
    [dateFormatter setTimeZone:gmtZone];
    [dateFormatter setDateFormat:@"MM-dd HH:mm"];
    return [dateFormatter stringFromDate:date];
}

@end
