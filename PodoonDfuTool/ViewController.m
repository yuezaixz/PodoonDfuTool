//
//  ViewController.m
//  PodoonDfuTool
//
//  Created by 吴迪玮 on 2019/1/2.
//  Copyright © 2019年 podoon. All rights reserved.
//

#import "ViewController.h"
#import "BluetoothService.h"
#import "SVProgressHUD/SVProgressHUD.h"
#import "RMHTTPSessionManager.h"
#import <AFNetworking.h>
#import "LogDevice.h"

@interface LogTableViewCell:UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *logLabel;

@end

@implementation LogTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
}

@end

@interface ViewController ()<RMBluetoothServiceDelegate,UITableViewDelegate,UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UIButton *startButton;

@property (strong, nonatomic) NSMutableArray *logList;
@property (weak, nonatomic) IBOutlet UITableView *logTableView;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@end

@implementation ViewController {
    BOOL isStart_;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [BluetoothService sharedInstance].delegate = self;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
}

- (void)reload {
    [self.logTableView reloadData];
}

- (IBAction)actionClean:(id)sender {
    self.logList = nil;
    self.titleLabel.text = @"";
    [self reload];
}

- (IBAction)actionStart:(id)sender {
    if (isStart_) {
        [[BluetoothService sharedInstance] stop];
        [[BluetoothService sharedInstance] disconnect];
        [self actionClean:sender];
        [self.startButton setTitle:@"开始" forState:UIControlStateNormal];
    } else {
        [[BluetoothService sharedInstance] search];
        [self.startButton setTitle:@"结束" forState:UIControlStateNormal];
        [self actionClean:sender];
    }
    isStart_ = !isStart_;
}

- (IBAction)actionCMD:(UIButton *)btn {
    if ([btn.titleLabel.text isEqualToString:@"开始"]) {
        
    } else if ([btn.titleLabel.text isEqualToString:@"复制"]) {
        if (self.logList && [self.logList count] > 0) {
            NSMutableString *copyResult = [NSMutableString string];
            for (LogDevice *device in self.logList) {
                [copyResult appendString:@"\n"];
                [copyResult appendString:[device stringFormat]];
            }
            [[UIPasteboard generalPasteboard] setString:copyResult];
            [SVProgressHUD showSuccessWithStatus:@"复制成功" duration:1];
        }
    }
}

- (void)writeCmd:(NSString *)cmd {
    NSLog(@"write cmd : %@", cmd);
    [[BluetoothService sharedInstance] sendData:cmd];
}

- (void)notifyLog:(NSString *)log{
    
}

- (void)notifyDiscover{
    self.titleLabel.text = @"设备连接中";
    [SVProgressHUD showSuccessWithStatus:@"连接中" duration:1];
    [[BluetoothService sharedInstance] stop];
}

- (void)notifyDidConnect:(CBPeripheral *)peripheral{
    self.titleLabel.text = @"设备已连接";
}

- (void)notifyDisConnect{
    if (isStart_) {
        [SVProgressHUD showErrorWithStatus:@"设备已断开" duration:1];
        self.titleLabel.text = @"搜索中";
        [[BluetoothService sharedInstance] search];
        
    } else {
        self.titleLabel.text = @"已停止";
        [[BluetoothService sharedInstance] stop];
    }
    
    
}

- (void)notifyReady{
    self.titleLabel.text = @"设备已连接";
    [SVProgressHUD showSuccessWithStatus:@"连接成功" duration:2];
}

- (void)disconnectAndStop {
    [[BluetoothService sharedInstance] stop];
    [[BluetoothService sharedInstance] disconnect];
}

- (void)notifymacLog:(NSString *)mac atPeripheral:(CBPeripheral *)peripheral;{
    LogDevice *findDevice;
    for (LogDevice *device in self.logList) {
        if ([device.uuid isEqualToString:peripheral.identifier.UUIDString]) {
            findDevice = device;
        }
    }
    
    if (!findDevice) {
        findDevice = [[LogDevice alloc] init];
        findDevice.peripheral = peripheral;
        findDevice.uuid = peripheral.identifier.UUIDString;
        findDevice.macAddress = mac;
        findDevice.connectCount = 0;
        [self.logList addObject:findDevice];
        
        __weak AFHTTPSessionManager *session = [RMHTTPSessionManager sharedManager];
        
        
        NSParameterAssert(session); // prevent infinite loop
        NSMutableDictionary *postData = [@{
                                          @"mac_address": mac,
                                          } mutableCopy];
        [session POST:@"https://service.runmaf.com/services/mobile/user/query_product_record"
           parameters:[postData copy] progress:^(NSProgress * _Nonnull uploadProgress) {
            
        } success:^(NSURLSessionDataTask * _Nonnull task, NSDictionary * _Nullable msg) {
            
            if (msg && [[msg objectForKey:@"success"] boolValue] && [msg objectForKey:@"data"]) {
                findDevice.no = [NSString stringWithFormat:@"%@", [[msg objectForKey:@"data"] objectForKey:@"id"]];
                [self reload];
            }else{
//                [SVProgressHUD showErrorWithStatus:@"编号获取失败" duration:2];
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
//            [SVProgressHUD showErrorWithStatus:@"编号获取失败" duration:2];
        }];
    }

    findDevice.connectCount += 1;
    findDevice.lastDate = [NSDate date];
    [self performSelector:@selector(disconnectAndStop) withObject:nil afterDelay:2];
    [self reload];
}

-(NSMutableArray *)logList {
    if (!_logList) {
        _logList = [NSMutableArray array];
    }
    return _logList;
}

-(BOOL)canconnect:(NSString *)uuidString {
    LogDevice *findDevice;
    for (LogDevice *device in self.logList) {
        if ([device.uuid isEqualToString:uuidString]) {
            findDevice = device;
        }
    }
    if (!findDevice) {
        return true;
    } else {
        
        NSLog(@"1111aaaaa:%ld", abs((int)[findDevice.lastDate timeIntervalSinceNow]));
        if (abs((int)[findDevice.lastDate timeIntervalSinceNow]) > 120) {
            return true;
        }
    }
    return false;
}

#pragma mark - uitableview deleagate

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 30;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.logList count];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LogTableViewCell *cell = [self.logTableView dequeueReusableCellWithIdentifier:@"LogTableViewCell" forIndexPath:indexPath];
    LogDevice *log = [self.logList objectAtIndex:indexPath.row];
    cell.logLabel.text = [log stringFormat];
    return cell;
}

@end
