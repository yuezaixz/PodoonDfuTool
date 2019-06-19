//
//  RMHTTPSessionManager.m
//  Runmove
//
//  Created by 吴迪玮 on 2016/9/28.
//  Copyright © 2016年 Paodong. All rights reserved.
//

#import "RMHTTPSessionManager.h"

@implementation RMHTTPSessionManager

+ (instancetype)sharedManager {
    static RMHTTPSessionManager *afnManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        afnManager = [RMHTTPSessionManager manager];
    });
    return afnManager;
}

@end
