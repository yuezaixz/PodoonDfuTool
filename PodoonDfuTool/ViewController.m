//
//  ViewController.m
//  PodoonDfuTool
//
//  Created by 吴迪玮 on 2019/1/2.
//  Copyright © 2019年 podoon. All rights reserved.
//

#import "ViewController.h"
#import "BluetoothService.h"

@interface ViewController ()<RMBluetoothServiceDelegate>

@property (weak, nonatomic) IBOutlet UILabel *topLabel;
@property (weak, nonatomic) IBOutlet UILabel *mainLabel;
@property (weak, nonatomic) IBOutlet UIButton *firmwareBtn;
@property (weak, nonatomic) IBOutlet UILabel *version;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [BluetoothService sharedInstance].delegate = self;
    [BluetoothService sharedInstance].otaUrl = @"ZT_H905A_20201016-V2.2.90";
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
}

- (IBAction)actionSelectFirmware:(id)sender {
    NSArray *firmwares = @[
        @"ZT_H905A_20201016-V2.2.90",
        @"ZT_H905A_20201007-V2.2.89",
    @"ZT_H905A_20200719-V2.2.86",
        @"ZT_H905A_20200524-V2.2.83",
    @"ZT_H905A_20200427-V2.0.83",
    @"ZT_H905A_20200425-V2.2.81",
                            @"ZT_H905A_20200319-V2.0.79",
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
