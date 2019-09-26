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
@property (weak, nonatomic) IBOutlet UIButton *pauseBtn;
@property (weak, nonatomic) IBOutlet UIButton *noButton;

@property (strong, nonatomic) NSMutableArray *logList;
@property (weak, nonatomic) IBOutlet UITableView *logTableView;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet UILabel *gvnLabel;
@property (weak, nonatomic) IBOutlet UILabel *gvhLabel;
@property (weak, nonatomic) IBOutlet UILabel *macLabel;

@property (strong, nonatomic) NSString *ghvLog;
@property (strong, nonatomic) NSString *gvnLog;
@property (strong, nonatomic) NSString *macLog;
@property (strong, nonatomic) NSString *currentNO;

@end

@implementation ViewController {
    BOOL isStart_;
    BOOL isPause_;
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

    self.gvnLabel.text = self.gvnLog ?: @"版本";
    self.gvhLabel.text = self.ghvLog ?: @"电量";
    self.macLabel.text = self.macLog ?: @"物理地址";
}

- (void)clean {
    self.logList = nil;
    self.gvnLog = self.ghvLog = self.macLog = nil;
    [self.noButton setTitle:@"上报序号(点击复制)：--" forState:UIControlStateNormal];
    self.titleLabel.text = @"设备未连接";
    [self reload];
}

- (IBAction)actionStart:(id)sender {
    if (isStart_) {
        [[BluetoothService sharedInstance] stop];
        [[BluetoothService sharedInstance] disconnect];
        [self clean];
        [self.startButton setTitle:@"开始" forState:UIControlStateNormal];
    } else {
        [[BluetoothService sharedInstance] search];
        [self.startButton setTitle:@"结束" forState:UIControlStateNormal];
        [self clean];
    }
    isStart_ = !isStart_;
}

- (IBAction)actionPause:(id)sender {
    if (!self.gvnLog || !self.ghvLog || !self.macLog) {
         [SVProgressHUD showErrorWithStatus:@"未连接或无数据" duration:2];
        return;
    }
    
    __weak AFHTTPSessionManager *session = [RMHTTPSessionManager sharedManager];
    
    
    NSParameterAssert(session); // prevent infinite loop
    
    [session POST:@"https://service.runmaf.com/services/mobile/user/upload_product_record"
       parameters:@{
        @"version": self.gvnLog,
        @"mac_address": self.macLog,
        @"voltage": self.ghvLog
       } progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, NSDictionary * _Nullable msg) {
        if (msg && [[msg objectForKey:@"success"] boolValue] && [msg objectForKey:@"data"]) {
            self.currentNO = [msg objectForKey:@"data"];
            [self.noButton setTitle:[NSString stringWithFormat:@"上报序号(点击复制)：%@",self.currentNO] forState:UIControlStateNormal];
        }else{
            [SVProgressHUD showErrorWithStatus:@"上报失败" duration:2];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [SVProgressHUD showErrorWithStatus:@"上报失败" duration:2];
    }];
    
    
}

- (IBAction)actionCopy:(id)sender {
    if (self.currentNO) {
        [[UIPasteboard generalPasteboard] setString:self.currentNO];
        [SVProgressHUD showSuccessWithStatus:@"复制成功" duration:2];
    } else {
        [SVProgressHUD showErrorWithStatus:@"编号不存在" duration:2];
    }
}


- (IBAction)actionCMD:(UIButton *)btn {
    if ([btn.titleLabel.text isEqualToString:@"写入值"]) {
        [SVProgressHUD showWithStatus:@"写入中"];
        [self performSelector:@selector(writeCmd:) withObject:@"SSAS:120" afterDelay:0.02];
        [self performSelector:@selector(writeCmd:) withObject:@"SSMS:6" afterDelay:0.04];
        [self performSelector:@selector(writeCmd:) withObject:@"SSAF:90" afterDelay:0.06];
        [self performSelector:@selector(writeCmd:) withObject:@"SSAB:60" afterDelay:0.08];
        [self performSelector:@selector(writeCmd:) withObject:@"SSTB:20" afterDelay:0.1];
        [self performSelector:@selector(writeCmd:) withObject:@"SSMB:4" afterDelay:0.12];
        [SVProgressHUD performSelector:@selector(dismiss) withObject:nil afterDelay:0.2];
    } else if ([btn.titleLabel.text isEqualToString:@"SCB"]) {
        [self performSelector:@selector(writeCmd:) withObject:@"SCB:167" afterDelay:0.02];
    } else {
        [[BluetoothService sharedInstance] sendData:btn.titleLabel.text];
    }
}

- (void)writeCmd:(NSString *)cmd {
    [[BluetoothService sharedInstance] sendData:cmd];
}

- (void)notifyLog:(NSString *)log{
    if (![self hadConnected]) {
        [SVProgressHUD showErrorWithStatus:@"设备未连接" duration:2];
        return;
    }
    if (!isPause_) {
        [self.logList insertObject:log atIndex:0];
        [self.logTableView reloadData];
    }
}

-(NSMutableArray *)logList {
    if (!_logList) {
        _logList = [NSMutableArray array];
    }
    return _logList;
}

- (void)notifyDiscover{
    self.titleLabel.text = @"设备连接中";
    [SVProgressHUD showWithStatus:@"连接中"];
    [[BluetoothService sharedInstance] stop];
}

- (void)notifyDidConnect{
    [SVProgressHUD showWithStatus:@"准备中"];
    
    self.titleLabel.text = @"设备未连接";
}

- (void)notifyDisConnect{
    [SVProgressHUD showErrorWithStatus:@"设备已断开" duration:2];
    
    self.titleLabel.text = @"设备未连接";
    [[BluetoothService sharedInstance] stop];
    [self clean];
    [self.startButton setTitle:@"开始" forState:UIControlStateNormal];
    isStart_ = NO;
}

- (void)notifyReady{
    self.titleLabel.text = @"设备已连接";
    [SVProgressHUD showSuccessWithStatus:@"连接成功" duration:2];
}

- (void)notifySlpLog:(NSString *)log {
    self.titleLabel.text = log;
}

- (BOOL)hadConnected {
    return [BluetoothService sharedInstance].peripheral != nil;
}


- (void)notifyghvLog:(NSString *)log{
    self.ghvLog = log;
    [self reload];
}
- (void)notifygvnLog:(NSString *)log{
    self.gvnLog = log;
    [self reload];
}
- (void)notifymacLog:(NSString *)mac{
    self.macLog = mac;
    [self reload];
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
    NSString *log = [self.logList objectAtIndex:indexPath.row];
    cell.logLabel.text = log;
    return cell;
}

@end
