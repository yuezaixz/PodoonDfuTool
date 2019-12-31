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
@property (strong, nonatomic) NSString *logStr;
@property (weak, nonatomic) IBOutlet UITableView *logTableView;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@end

@implementation ViewController {
    BOOL isStart_;
    NSTimer *stopAnimationtimer;
    BOOL _hadConnect;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [BluetoothService sharedInstance].delegate = self;
    _hadConnect = true;
    
    NSUserDefaults *udf = [NSUserDefaults standardUserDefaults];
    self.logStr = [udf objectForKey:@"log_list"]?:@"";
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)reload {
    [self.logTableView reloadData];
}

- (IBAction)actionStop:(id)sender {
    if (stopAnimationtimer) {
        [stopAnimationtimer invalidate];
        stopAnimationtimer = nil;
    }
    [[BluetoothService sharedInstance] stop];
    [[BluetoothService sharedInstance] disconnect];
    isStart_ = false;
    self.titleLabel.text = @"";
    [self reload];
    
}

- (IBAction)actionClean:(id)sender {
    self.logList = [NSMutableArray array];
    self.logStr = @"";
    
    NSUserDefaults *udf = [NSUserDefaults standardUserDefaults];
    [udf setObject:self.logStr forKey:@"log_list"];
    [udf synchronize];
    [self reload];
}

- (IBAction)actionStart:(id)sender {
    [[BluetoothService sharedInstance] search];
    isStart_ = true;
    
    // 创建
    stopAnimationtimer = [NSTimer scheduledTimerWithTimeInterval:30
                                                          target:self
                                                        selector:@selector(check)
                                                        userInfo:nil
                                                         repeats:YES];
    [stopAnimationtimer fire];
}

- (void)check {
    if (!_hadConnect) {
        NSLog(@"开始重启");
        [[BluetoothService sharedInstance] search];
    }
    _hadConnect = false;
}

- (IBAction)actionCMD:(UIButton *)btn {
    if ([btn.titleLabel.text isEqualToString:@"开始"]) {
        
    } else if ([btn.titleLabel.text isEqualToString:@"复制"]) {
        if (self.logList && [self.logList count] > 0) {
            NSString *copyStr = self.logStr?:[self getLogSt];
            [[UIPasteboard generalPasteboard] setString:copyStr];
            [SVProgressHUD showSuccessWithStatus:@"复制成功" duration:1];
        }
    }
}

- (NSString *)getLogSt {
    NSMutableString *copyResult = [NSMutableString string];
    for (LogDevice *device in self.logList) {
        [copyResult appendString:@"\n"];
        [copyResult appendString:[device stringDetailFormat]];
    }
    return copyResult;
}

- (void)writeCmd:(NSString *)cmd {
    NSLog(@"write cmd : %@", cmd);
    [[BluetoothService sharedInstance] sendData:cmd];
}

- (void)notifyLog:(NSString *)log{
    
}

- (void)notifyDiscover:(NSString *)uuidString{
    self.titleLabel.text = @"设备连接中";
    [SVProgressHUD showSuccessWithStatus:@"连接中" duration:1];
    [[BluetoothService sharedInstance] performSelector:@selector(clear:) withObject:uuidString afterDelay:5];
//    [[BluetoothService sharedInstance] stop];
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


- (void)notifyTimeLog:(NSString *)mac atPeripheral:(CBPeripheral *)peripheral{
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
    }
    findDevice.firmTime = mac;
}

- (void)notifymacLog:(NSString *)mac atPeripheral:(CBPeripheral *)peripheral{
    _hadConnect = true;
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
                NSUserDefaults *udf = [NSUserDefaults standardUserDefaults];
                self.logStr = [self getLogSt];
                [udf setObject:self.logStr forKey:@"log_list"];
                [udf synchronize];
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
    
    
    NSUserDefaults *udf = [NSUserDefaults standardUserDefaults];
    self.logStr = [self getLogSt];
    [udf setObject:self.logStr forKey:@"log_list"];
    [udf synchronize];
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
        if (abs((int)[findDevice.lastDate timeIntervalSinceNow]) > 25) {
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
