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

@interface ViewController ()<RMBluetoothServiceDelegate,UITableViewDelegate,UITableViewDataSource>

@property (strong, nonatomic) NSMutableArray *logList;
@property (weak, nonatomic) IBOutlet UITableView *logTableView;

@property (weak, nonatomic) IBOutlet UIButton *startButton;

@property (weak, nonatomic) IBOutlet UIButton *noAirbagAdjustButton;
@property (weak, nonatomic) IBOutlet UIButton *airbagAdjustButton;
@property (weak, nonatomic) IBOutlet UIButton *saveDefaultButton;
@property (weak, nonatomic) IBOutlet UIButton *getDefaultButton;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet UILabel *presureLabel;
@property (weak, nonatomic) IBOutlet UILabel *defaultValLabel;
@property (weak, nonatomic) IBOutlet UILabel *currValLabel;
@property (weak, nonatomic) IBOutlet UILabel *resultLabel;

@property (nonatomic) NSInteger airPresulre;
@property (nonatomic) NSInteger defaultVal;
@property (nonatomic) NSInteger currVal;
@property (strong, nonatomic) NSString *logSS;
@property (strong, nonatomic) NSString *logResult;
@property (strong, nonatomic) NSString *logOther;

@end

@implementation ViewController {
    BOOL isStart_;
    BOOL isPause_;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    isStart_ = NO;
    [self clean];
    [BluetoothService sharedInstance].delegate = self;
    [self.logTableView setBackgroundColor:[UIColor whiteColor]];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
}

- (void)reload {
    [self.logTableView reloadData];
}

- (void)cleanVal {
    _airPresulre = 0;
    _defaultVal = 0;
    _currVal = 0;
}

- (void)clean {
    [self cleanVal];
    
    self.logList = nil;
    self.titleLabel.text = @"设备未连接";
//    [self reload];
}

- (IBAction)actionStart:(id)sender {
    if (!isStart_) {
        isStart_ = YES;
        [[BluetoothService sharedInstance] search];
        self.startButton.enabled = NO;
        [SVProgressHUD showWithStatus:@"连接中"];
        [self.startButton setTitle:@"断开" forState:UIControlStateNormal];
        [self cleanVal];
    } else {
        [self cleanVal];
        [[BluetoothService sharedInstance] disconnect];
        [SVProgressHUD showWithStatus:@"断开中"];
    }
}

- (IBAction)actionPause:(id)sender {
//    __weak AFHTTPSessionManager *session = [RMHTTPSessionManager sharedManager];
//
//
//    NSParameterAssert(session); // prevent infinite loop
//    NSMutableDictionary *postData = [@{
//                                      @"version": self.gvnLog,
//                                      @"mac_address": self.macLog,
//                                      @"voltage": self.ghvLog
//                                      } mutableCopy];
//    if (self.model && [self.model length] >= 1) {
//        [postData setObject:self.model forKey:@"model"];
//    }
//
//    [session POST: self.modelSwitch.isOn ?  @"https://service.runmaf.com/services/mobile/user/upload_product_record_new" : @"https://service.runmaf.com/services/mobile/user/upload_product_record"
//       parameters:[postData copy] progress:^(NSProgress * _Nonnull uploadProgress) {
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

- (IBAction)actionNoAirbagPresure:(id)sender {
    [self writeCmd:@"SCB:167"];
    [SVProgressHUD showSuccessWithStatus:@"执行无气囊校准" duration:10];
}

- (IBAction)actionAirbagPresure:(id)sender {
    [self writeCmd:@"SCD:167"];
    [SVProgressHUD showSuccessWithStatus:@"执行带气囊校准" duration:10];
}

- (IBAction)actionSaveDefault:(id)sender {
    [self writeCmd:@"SCS"];
    [SVProgressHUD showSuccessWithStatus:@"保存气压校准值" duration:10];
}

- (IBAction)actionGetDefault:(id)sender {
    [self writeCmd:@"GCD"];
    [SVProgressHUD showSuccessWithStatus:@"读取气压校准值" duration:10];
}

- (void)writeCmd:(NSString *)cmd {
    NSLog(@"write cmd : %@", cmd);
    [[BluetoothService sharedInstance] sendData:cmd];
}

- (void)writeCmd:(NSString *)cmd withDelay:(NSTimeInterval)delay {
    NSLog(@"write cmd : %@ %f", cmd, delay);
    [self performSelector:@selector(writeCmd:) withObject:cmd afterDelay:delay];
}

- (void)notifyLog:(NSString *)log{
    if ([log rangeOfString:@"RecvACK:SCB"].location != NSNotFound || [log rangeOfString:@"RecvACK:SCS"].location != NSNotFound || [log rangeOfString:@"RecvACK:SCD"].location != NSNotFound) {
        self.logOther = log;
    } else if ([log rangeOfString:@"Slp:"].location != NSNotFound) {
        self.logResult = log;
    } else if ([log rangeOfString:@"SS:"].location != NSNotFound) {
        self.logSS = log;
    }
    self.resultLabel.text = [NSString stringWithFormat:@"命令返回：%@\n校准：%@\n气压：%@", _logOther?:@"--", _logResult?:@"--", _logSS?:@"--" ];
//    if (![self hadConnected]) {
//        [SVProgressHUD showErrorWithStatus:@"设备未连接" duration:1];
//        return;
//    }
//    if (!isPause_) {
//        [self.logList insertObject:log atIndex:0];
//        [self.logTableView reloadData];
//    }
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

- (void)notifyReady{
    self.titleLabel.text = @"设备已连接";
    [SVProgressHUD dismiss];
    [SVProgressHUD showSuccessWithStatus:@"连接成功" duration:1];
    self.startButton.enabled = YES;
    [self.startButton setTitle:@"断开" forState:UIControlStateNormal];
}

- (void)notifyDisConnect{
    [SVProgressHUD showErrorWithStatus:@"设备已断开" duration:1];
    
    isStart_ = NO;
    self.titleLabel.text = @"设备未连接";
    [[BluetoothService sharedInstance] stop];
    [self clean];
    [self.startButton setTitle:@"开始" forState:UIControlStateNormal];
}

- (BOOL)hadConnected {
    return [BluetoothService sharedInstance].peripheral != nil;
}

-(void)notifyMacAddress:(NSString *)macAddress {
    self.titleLabel.text = macAddress;
}

- (void)notifyNoAirbagSucc {
    
    [SVProgressHUD dismiss];
    [SVProgressHUD showSuccessWithStatus:@"执行无气囊校准成功" duration:1.0];
}
- (void)notifyAirbagSucc {
    
    [SVProgressHUD dismiss];
    [SVProgressHUD showSuccessWithStatus:@"执行带气囊校准成功" duration:1.0];
}
- (void)notifySaveDefaultSucc {
    
    [SVProgressHUD dismiss];
    [SVProgressHUD showSuccessWithStatus:@"保存气压校准值成功" duration:1.0];
}
- (void)notifyGetDefault:(NSInteger)slp currCST:(NSInteger)currCST defaultCST:(NSInteger)defaultCST {
    _currVal = currCST;
    _defaultVal = defaultCST;
    
    self.defaultValLabel.text = [NSString stringWithFormat:@"%ld", defaultCST];
    self.currValLabel.text = [NSString stringWithFormat:@"%ld", currCST];
    [SVProgressHUD dismiss];
    [SVProgressHUD showSuccessWithStatus:@"读取气压校准值成功" duration:1.0];
}

- (void)notifyAirPresure: (NSInteger)airPresure {
    _airPresulre = airPresure;
    self.presureLabel.text = [NSString stringWithFormat:@"%ld", airPresure];
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
    return [[UITableViewCell alloc] init];
}

@end
