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

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [BluetoothService sharedInstance].delegate = self;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
}
- (IBAction)actionStart:(id)sender {
    [[BluetoothService sharedInstance] search];
    self.topLabel.text = @"运行中";
    self.mainLabel.text = @"搜索中";
}
- (IBAction)actionStop:(id)sender {
    [[BluetoothService sharedInstance] stop];
    self.topLabel.text = @"已停止";
    self.mainLabel.text = @"未运行";
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
    [[BluetoothService sharedInstance] stop];
}

- (void)notifyWriteDfu {
    self.mainLabel.text = @"写入DFU成功";
}

@end
