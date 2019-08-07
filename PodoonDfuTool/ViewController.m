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
@property (strong, nonatomic) NSString *gbpLog;
@property (strong, nonatomic) NSString *currentNO;

@property (strong, nonatomic) NSMutableArray *calArray;

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

    self.gvnLabel.text = self.gbpLog ?: @"版本";
    self.gvhLabel.text = self.ghvLog ?: @"电量";
    self.macLabel.text = self.macLog ?: @"物理地址";
}

- (void)clean {
    self.logList = nil;
    self.calArray = nil;
    self.gbpLog = self.ghvLog = self.macLog = nil;
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
//    [[BluetoothService sharedInstance] sendData:@"HCM0"];
    [self performSelector:@selector(actionStart:) withObject:nil afterDelay:0];
    
//    if (!self.gvnLog || !self.ghvLog || !self.macLog) {
//         [SVProgressHUD showErrorWithStatus:@"未连接或无数据" duration:2];
//        return;
//    }
//
//    __weak AFHTTPSessionManager *session = [RMHTTPSessionManager sharedManager];
//
//
//    NSParameterAssert(session); // prevent infinite loop
//
//    [session POST:@"https://service.runmaf.com/services/mobile/user/upload_product_record"
//       parameters:@{
//        @"version": self.gvnLog,
//        @"mac_address": self.macLog,
//        @"voltage": self.ghvLog
//       } progress:^(NSProgress * _Nonnull uploadProgress) {
//
//    } success:^(NSURLSessionDataTask * _Nonnull task, NSDictionary * _Nullable msg) {
//        if (msg && [[msg objectForKey:@"success"] boolValue] && [msg objectForKey:@"data"]) {
//            self.currentNO = [msg objectForKey:@"data"];
//            [self.noButton setTitle:[NSString stringWithFormat:@"上报序号(点击复制)：%@",self.currentNO] forState:UIControlStateNormal];
//        }else{
//            [SVProgressHUD showErrorWithStatus:@"上报失败" duration:2];
//        }
//    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
//        [SVProgressHUD showErrorWithStatus:@"上报失败" duration:2];
//    }];
    
    
}

- (IBAction)actionCopy:(id)sender {
    if (self.currentNO) {
        [[UIPasteboard generalPasteboard] setString:self.currentNO];
        [SVProgressHUD showSuccessWithStatus:@"复制成功" duration:2];
    } else {
        [SVProgressHUD showErrorWithStatus:@"编号不存在" duration:2];
    }
}

- (IBAction)actionGCD:(id)sender {
    if (self.calArray && [self.calArray count]) {
        self.calArray = nil;
    } else {
        [self.calArray addObject:@"GCD日志："];
        [self actionCMD:sender];
    }
}


- (IBAction)actionCMD:(UIButton *)btn {
    [[BluetoothService sharedInstance] sendData:btn.titleLabel.text];
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

- (NSMutableArray *)calArray {
    if (!_calArray) {
        _calArray = [NSMutableArray array];
    }
    return _calArray;
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

-(void)notifyGBP:(NSString *)log {
    self.gbpLog = log;
    [self reload];
}

-(void)notifyGCD:(NSString *)log {
    [self.calArray addObject:log];
    [self reload];
}

#pragma mark - uitableview deleagate

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 30;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.calArray && [self.calArray count]) {
        return [self.calArray count];
    }
    return [self.logList count];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LogTableViewCell *cell = [self.logTableView dequeueReusableCellWithIdentifier:@"LogTableViewCell" forIndexPath:indexPath];
    NSString *log;
    if (self.calArray && [self.calArray count]) {
        log = [self.calArray objectAtIndex:indexPath.row];
    } else {
        log = [self.logList objectAtIndex:indexPath.row];
    }
    
    cell.logLabel.text = log;
    return cell;
}

@end
