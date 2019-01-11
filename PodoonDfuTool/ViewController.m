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

@property (strong, nonatomic) NSMutableArray *logList;
@property (weak, nonatomic) IBOutlet UITableView *logTableView;

@property (weak, nonatomic) IBOutlet UILabel *fatLabel;
@property (weak, nonatomic) IBOutlet UILabel *ghvLabel;
@property (weak, nonatomic) IBOutlet UILabel *gvdLabel;
@property (weak, nonatomic) IBOutlet UILabel *gvd2Label;
@property (weak, nonatomic) IBOutlet UILabel *gvnLabel;
@property (weak, nonatomic) IBOutlet UILabel *gvhLabel;
@property (weak, nonatomic) IBOutlet UILabel *miniPcbLabel;

@property (strong, nonatomic) NSString *fatLog;
@property (strong, nonatomic) NSString *ghvLog;
@property (strong, nonatomic) NSString *gvdLog;
@property (strong, nonatomic) NSString *gvd2Log;
@property (strong, nonatomic) NSString *gvnLog;
@property (strong, nonatomic) NSString *gvhLog;
@property (nonatomic) BOOL miniError;

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
    self.fatLabel.text = self.fatLog ?: @"FAT";
    self.ghvLabel.text = self.ghvLog ?: @"GHV";
    self.gvdLabel.text = self.gvdLog ?: @"GVD";
    self.gvd2Label.text = self.gvd2Log ?: @"GVD2";
    self.gvnLabel.text = self.gvnLog ?: @"GVN";
    self.gvhLabel.text = self.gvhLog ?: @"GVH";
    self.miniPcbLabel.text = self.miniError?@"小板异常":@"小板正常";
}

- (void)clean {
    self.logList = nil;
    self.fatLog = self.ghvLog = self.gvdLog = self.gvd2Log = self.gvnLog = self.gvhLog = nil;
    self.miniError = NO;
    [self reload];
}

- (IBAction)actionStart:(id)sender {
    if (isStart_) {
        [[BluetoothService sharedInstance] stop];
        [[BluetoothService sharedInstance] disconnect];
        [self.startButton setTitle:@"开始" forState:UIControlStateNormal];
    } else {
        [[BluetoothService sharedInstance] search];
        [self.startButton setTitle:@"结束" forState:UIControlStateNormal];
        [self clean];
    }
    isStart_ = !isStart_;
}

- (IBAction)actionPause:(id)sender {
    isPause_ = !isPause_;
    [self.pauseBtn setTitle:(isPause_?@"继续":@"暂停") forState:UIControlStateNormal];
}

- (IBAction)actionClean:(id)sender {
    self.logList = nil;
    [self clean];
}

- (IBAction)actionCMD:(UIButton *)btn {
    [[BluetoothService sharedInstance] sendData:btn.titleLabel.text];
    [SVProgressHUD showWithStatus:@"发送中"];
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
    [SVProgressHUD showWithStatus:@"连接中"];
    [[BluetoothService sharedInstance] stop];
    [self actionStart:nil];
}

- (void)notifyDidConnect{
    [SVProgressHUD showWithStatus:@"准备中"];
    
}

- (void)notifyDisConnect {
    [SVProgressHUD showSuccessWithStatus:@"发送成功·" duration:2];
}

- (void)notifyReady{
    [SVProgressHUD showSuccessWithStatus:@"连接成功" duration:2];
}

- (BOOL)hadConnected {
    return [BluetoothService sharedInstance].peripheral != nil;
}


- (void)notifyfatLog:(NSString *)log{
    self.fatLog = log;
    [self reload];
}
- (void)notifyghvLog:(NSString *)log{
    self.ghvLog = log;
    [self reload];
}
- (void)notifygvdLog:(NSString *)log{
    self.gvdLog = log;
    [self reload];
}
- (void)notifygvd2Log:(NSString *)log{
    self.gvd2Log = log;
    [self reload];
}
- (void)notifygvnLog:(NSString *)log{
    self.gvnLog = log;
    [self reload];
}
- (void)notifygvhLog:(NSString *)log{
    self.gvhLog = log;
    [self reload];
}
- (void)notifyMiniError{
    self.miniError = YES;
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
