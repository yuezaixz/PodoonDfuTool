//
//  ViewController.m
//  PodoonDfuTool
//
//  Created by 吴迪玮 on 2019/1/2.
//  Copyright © 2019年 podoon. All rights reserved.
//

#import "ViewController.h"
#import "BluetoothService.h"
#import "RMHTTPSessionManager.h"

@interface ViewController ()<RMBluetoothServiceDelegate>

@property (weak, nonatomic) IBOutlet UILabel *topLabel;
@property (weak, nonatomic) IBOutlet UILabel *mainLabel;
@property (weak, nonatomic) IBOutlet UIButton *firmwareBtn;
@property (weak, nonatomic) IBOutlet UILabel *version;
@property (weak, nonatomic) IBOutlet UILabel *macAddressLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [BluetoothService sharedInstance].delegate = self;
    [BluetoothService sharedInstance].otaUrl = @"ZT_H905A_20211228-V2.3.5";
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
}

- (IBAction)actionSelectFirmware:(id)sender {
    NSArray *firmwares = @[
        @"ZT_H905A_20211228-V2.3.5",
        @"ZT_H905A_20211226-V2.3.4",
        @"ZT_H905A_20210827-V2.2.99",
        @"ZT_H905A_20210507-V2.2.98",
        @"ZT_H905A_20210121-V2.2.95",
        @"ZT_H905A_20210113-V2.2.94",
        @"ZT_H905A_20201102-V2.2.84",
        @"ZT_H905A_20201101-V2.2.83",
        @"ZT_H905A_20201101-V2.2.91",
        @"ZT_H905A_20201217-V2.2.92",
        @"Temp_Test_OTA"
                           ];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"选择固件"
                                                                             message:@""
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    __weak typeof(self) weakSelf = self;
    
    for (NSString *firmware in firmwares) {
        UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:firmware style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf.firmwareBtn setTitle:firmware forState:UIControlStateNormal];
            [BluetoothService sharedInstance].otaUrl = firmware;
        }];
        [alertController addAction:defaultAction];
    }
    
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消-Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alertController addAction:cancelAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)actionStart:(id)sender {
    [BluetoothService sharedInstance].isVersion = NO;
    [BluetoothService sharedInstance].uuidStr = nil;
    [[BluetoothService sharedInstance] search];
    self.topLabel.text = @"运行中";
    self.mainLabel.text = @"搜索中";
}
- (IBAction)actionStop:(id)sender {
    [BluetoothService sharedInstance].isVersion = NO;
    [BluetoothService sharedInstance].uuidStr = nil;
    [[BluetoothService sharedInstance] stop];
    self.topLabel.text = @"已停止";
    self.mainLabel.text = @"未运行";
}

- (void)notifyVersion:(NSString *)version {
    self.version.text = version;
//    [[BluetoothService sharedInstance] disconnect];
    [[BluetoothService sharedInstance] writeCommand:@"SRC"];
    [[BluetoothService sharedInstance] stop];
    [BluetoothService sharedInstance].isVersion = NO;
    [BluetoothService sharedInstance].uuidStr = nil;
    
    [self performSelector:@selector(removeDevice) withObject:nil afterDelay:1];
}


- (void)notifymacLog:(NSString *)mac {
    if (mac) {
        __weak AFHTTPSessionManager *session = [RMHTTPSessionManager sharedManager];
        self.macAddressLabel.text = mac;
        
        NSParameterAssert(session); // prevent infinite loop
        NSDictionary *postData = @{
                                          @"mac_address": [mac substringFromIndex:3],
                                          };
        
        [session POST:@"https://service.runmaf.com/services/mobile/user/query_product_record"
           parameters:[postData copy] progress:^(NSProgress * _Nonnull uploadProgress) {
            
        } success:^(NSURLSessionDataTask * _Nonnull task, NSDictionary * _Nullable msg) {
            if (msg && [[msg objectForKey:@"success"] boolValue] && [msg objectForKey:@"data"] && [[msg objectForKey:@"data"] objectForKey:@"no"]) {
                NSString *currentNO = [[msg objectForKey:@"data"] objectForKey:@"no"];
                dispatch_async(dispatch_get_main_queue(), ^{

                    self.macAddressLabel.text = currentNO;
                });
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        }];
    }
}

- (void)removeDevice{
    [[BluetoothService sharedInstance] removeDevice];
}

- (void)notifyDidConnect {
    self.mainLabel.text = @"已连接设备";
}

- (void)notifyDiscover { 
    
    self.mainLabel.text = @"已发现设备";
}

- (void)notifyFailDfu {
    [[BluetoothService sharedInstance] stop];
    self.mainLabel.text = @"OTA失败";
    self.topLabel.text = @"已停止";
}

- (void)notifyPercent:(NSInteger)percent { 
    self.mainLabel.text = [NSString stringWithFormat:@"%@:%ld%%",  @"升级中",(long)percent];
}

- (void)notifyStartDfu { 
    self.mainLabel.text = @"开始OTA";
}

- (void)notifySuccessDfu { 
    self.mainLabel.text = @"OTA成功";
    self.topLabel.text = @"已停止";
    [BluetoothService sharedInstance].isVersion = YES;
    [[BluetoothService sharedInstance] search];
}

- (void)notifyWriteDfu {
    self.mainLabel.text = @"写入DFU成功";
}

@end
