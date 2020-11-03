//
//  RMHTTPSessionManager.h
//  Runmove
//
//  Created by 吴迪玮 on 2016/9/28.
//  Copyright © 2016年 Paodong. All rights reserved.
//

#import <AFNetworking/AFHTTPSessionManager.h>

@interface RMHTTPSessionManager : AFHTTPSessionManager

+ (instancetype)sharedManager;

@end
