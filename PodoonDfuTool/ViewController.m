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

typedef enum : NSUInteger {
    // 已进入应用，未连接
    AdjustTypeNoConnect,
    // 连接中
    AdjustTypeConnecting,
    // 连接成功，等待流程开始
    AdjustTypeReady,
    // 1、已进入透传
    AdjustTypeTunelEntered,
    // 2、已进入校准
    AdjustTypeAdjustEntered,
    // 3、开始校准中
    AdjustTypeAdjusting,
    // 3、校准成功
    AdjustTypeAdjustSuccess,
    // 3、校准失败
    AdjustTypeAdjustAdjustFail,
    // 3、校验失败
    AdjustTypeAdjustLimitFail,
    // 4、退出校准成功
    AdjustTypeExitAdjusted,
    // 5、开始数据成功
    AdjustTypeStartDataed,
    // 6、退出透传了，等待16通道检测
    AdjustTypeExitTunel,
    // 7、校验成功
    AdjustTypeCheckSuccess
} AdjustType;

@interface ViewController ()<RMBluetoothServiceDelegate,UITableViewDelegate,UITableViewDataSource>

@property (strong, nonatomic) NSMutableArray *logList;
@property (weak, nonatomic) IBOutlet UITableView *logTableView;

@property (weak, nonatomic) IBOutlet UIButton *limitButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *enterButton;
@property (weak, nonatomic) IBOutlet UIButton *adjustButton;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UILabel *promptLabel;
@property (weak, nonatomic) IBOutlet UILabel *successCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *adjustFailLabel;
@property (weak, nonatomic) IBOutlet UILabel *limitFailLabel;
@property (weak, nonatomic) IBOutlet UIButton *startOrResetButton;

@property (nonatomic) NSInteger successCount;
@property (nonatomic) NSInteger adjustFailCount;
@property (nonatomic) NSInteger limitFailCount;

@property (nonatomic) NSInteger limitVal;

@property (nonatomic) AdjustType adjustType;

@property (strong, nonatomic) NSMutableArray *forces;

@end

@implementation ViewController {
    BOOL isStart_;
    BOOL isPause_;
}

- (NSMutableArray *)forces {
    if (!_forces) {
        _forces = [[NSMutableArray alloc] initWithArray:@[@-1, @-1, @-1, @-1, @-1, @-1, @-1, @-1, @-1, @-1, @-1, @-1, @-1, @-1, @-1, @-1]];
    }
    return _forces;
}

- (void)setLimitVal:(NSInteger)limitVal {
    _limitVal = limitVal;
    [[NSUserDefaults standardUserDefaults] setInteger:_limitVal forKey:@"limitVal"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)resetForeces {
    _forces = [[NSMutableArray alloc] initWithArray:@[@-1, @-1, @-1, @-1, @-1, @-1, @-1, @-1, @-1, @-1, @-1, @-1, @-1, @-1, @-1, @-1]];
}

- (BOOL)forcesIsCompletly {
    for (NSNumber *force in _forces) {
        if (force.integerValue == -1) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)forcesIsCorrect {
    for (NSNumber *force in _forces) {
        if (force.integerValue < 100 - _limitVal || force.integerValue > 100 + _limitVal) {
            return NO;
        }
    }
    return YES;
}

- (void)setAdjustType:(AdjustType)adjustType {
    _adjustType = adjustType;
    
    switch (_adjustType) {
        case AdjustTypeNoConnect:
            [self handleAdjustTypeNoConnect];
            break;
        case AdjustTypeReady:
            [self handleAdjustTypeReady];
            break;
        case AdjustTypeTunelEntered:
            [self handleAdjustTypeTunelEntered];
            break;
        case AdjustTypeAdjustEntered:
            [self handleAdjustTypeAdjustEntered];
            break;
        case AdjustTypeAdjusting:
            [self handleAdjustTypeAdjusting];
            break;
        case AdjustTypeAdjustSuccess:
            [self handleAdjustTypeAdjustSuccess];
            break;
        case AdjustTypeAdjustAdjustFail:
            [self handleAdjustTypeAdjustAdjustFail];
            break;
        case AdjustTypeAdjustLimitFail:
            [self handleAdjustTypeAdjustLimitFail];
            break;
        case AdjustTypeConnecting:
            [self handleAdjustTypeConnecting];
        case AdjustTypeExitAdjusted:
            [self handleAdjustTypeExitAdjusting];
            break;
        case AdjustTypeStartDataed:
            [self handleAdjustTypeStartDataing];
            break;
        case AdjustTypeExitTunel:
            [self handleAdjustTypeExitTunel];
            break;
        case AdjustTypeCheckSuccess:
            [self handleAdjustTypeCheckSuccess];
            break;
            
        default:
            break;
    }
}

-(void)setSuccessCount:(NSInteger)successCount {
    _successCount = successCount;
    [self syncCount];
}

- (void)setLimitFailCount:(NSInteger)limitFailCount {
    _limitFailCount = limitFailCount;
    [self syncCount];
}

- (void)setAdjustFailCount:(NSInteger)adjustFailCount {
    _adjustFailCount = adjustFailCount;
    [self syncCount];
}

- (void)syncCount {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setInteger:self.successCount forKey:@"self.successCount"];
    [ud setInteger:self.adjustFailCount forKey:@"self.adjustFailCount"];
    [ud setInteger:self.limitFailCount forKey:@"self.limitFailCount"];
    [ud synchronize];
}

- (void)loadCount {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    _successCount = [ud integerForKey:@"self.successCount"];
    _adjustFailCount = [ud integerForKey:@"self.adjustFailCount"];
    _limitFailCount = [ud integerForKey:@"self.limitFailCount"];
    [self refreshCountLabel];
}

- (void)refreshCountLabel {
    self.successCountLabel.text = [NSString stringWithFormat:@"%ld", self.successCount];
    self.adjustFailLabel.text = [NSString stringWithFormat:@"%ld", self.adjustFailCount];
    self.limitFailLabel.text = [NSString stringWithFormat:@"%ld", self.limitFailCount];
}

- (void)handleAdjustTypeNoConnect{
    self.promptLabel.text = @"未连接";
    self.enterButton.enabled = NO;
    self.adjustButton.enabled = NO;
    self.doneButton.enabled = NO;
}
- (void)handleAdjustTypeReady{
    self.promptLabel.text = @"等待开始流程";
    self.enterButton.enabled = YES;
    self.adjustButton.enabled = NO;
    self.doneButton.enabled = NO;
}
- (void)handleAdjustTypeTunelEntered{
    self.promptLabel.text = @"进入透传成功";
    self.enterButton.enabled = NO;
    self.adjustButton.enabled = NO;
    self.doneButton.enabled = NO;
}
- (void)handleAdjustTypeAdjustEntered{
    self.promptLabel.text = @"进入透传及校准成功";
    self.enterButton.enabled = NO;
    self.adjustButton.enabled = YES;
    self.doneButton.enabled = NO;
}
- (void)handleAdjustTypeAdjusting{
    self.promptLabel.text = @"校准进行中";
    self.enterButton.enabled = NO;
    self.adjustButton.enabled = NO;
    self.doneButton.enabled = NO;
}
- (void)handleAdjustTypeAdjustSuccess{
    self.promptLabel.text = @"校准成功，等待退出校准";
    self.enterButton.enabled = NO;
    self.adjustButton.enabled = NO;
    self.doneButton.enabled = YES;
}
- (void)handleAdjustTypeAdjustAdjustFail{
    self.promptLabel.text = @"校准失败";
    self.enterButton.enabled = NO;
    self.adjustButton.enabled = YES;
    self.doneButton.enabled = YES;
    self.adjustFailCount += 1;
    [self syncCount];
}
- (void)handleAdjustTypeAdjustLimitFail{
    self.promptLabel.text = @"校验失败";
    self.enterButton.enabled = NO;
    self.adjustButton.enabled = NO;
    self.doneButton.enabled = YES;
    self.limitFailCount += 1;
    [self syncCount];
}
- (void)handleAdjustTypeConnecting {
    self.promptLabel.text = @"连接中";
    self.enterButton.enabled = NO;
    self.adjustButton.enabled = NO;
    self.doneButton.enabled = NO;
    
}
- (void)handleAdjustTypeExitAdjusting {
    self.promptLabel.text = @"退出校准中";
    self.enterButton.enabled = NO;
    self.adjustButton.enabled = NO;
    self.doneButton.enabled = NO;
    
}
- (void)handleAdjustTypeStartDataing {
    self.promptLabel.text = @"开始发送数据中";
    self.enterButton.enabled = NO;
    self.adjustButton.enabled = NO;
    self.doneButton.enabled = NO;
    
}
- (void)handleAdjustTypeExitTunel {
    self.promptLabel.text = @"退出透传中";
    self.enterButton.enabled = NO;
    self.adjustButton.enabled = NO;
    self.doneButton.enabled = NO;
}
- (void)handleAdjustTypeCheckSuccess {
    self.promptLabel.text = @"校准校验成功";
    self.enterButton.enabled = NO;
    self.adjustButton.enabled = NO;
    self.doneButton.enabled = YES;
    self.successCount += 1;
    [self syncCount];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.adjustType = AdjustTypeNoConnect;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"limitVal"]) {
        _limitVal = [[NSUserDefaults standardUserDefaults] integerForKey:@"limitVal"];
    } else {
        self.limitVal = 3;
    }
    
    [self.limitButton setTitle:[NSString stringWithFormat:@"%ld", self.limitVal] forState:UIControlStateNormal];
    [self loadCount];
    [BluetoothService sharedInstance].delegate = self;
    [self.logTableView setBackgroundColor:[UIColor whiteColor]];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
}

- (void)reload {
    [self.logTableView reloadData];
}

- (void)clean {
    self.logList = nil;
    self.titleLabel.text = @"设备未连接";
    [self reload];
}

- (IBAction)actionStart:(id)sender {
    if (self.adjustType == AdjustTypeNoConnect) {
        self.adjustType = AdjustTypeConnecting;
        [[BluetoothService sharedInstance] search];
        [self.startOrResetButton setTitle:@"连接中" forState:UIControlStateNormal];
        [self clean];
    } else if (self.adjustType != AdjustTypeConnecting) {
        [self resetForeces];
        self.successCount = 0;
        self.adjustFailCount = 0;
        self.limitFailCount = 0;
        [self syncCount];
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

- (IBAction)actionCopy:(id)sender {
    NSMutableString *result = [NSMutableString string];
    for (NSString *logItem in self.logList) {
        [result appendFormat:@"%@\n", logItem];
    }
    
    [[UIPasteboard generalPasteboard] setString:result];
    [SVProgressHUD showSuccessWithStatus:@"设置成功" duration:2];
}

- (IBAction)actionEnter:(id)sender {
    [[BluetoothService sharedInstance] enterTunel];
    [SVProgressHUD showWithStatus:@"进入透传中"];
}

- (IBAction)actionAdjust:(id)sender {
    [[BluetoothService sharedInstance] startAdjust];
    [SVProgressHUD showWithStatus:@"校准中"];
}

- (IBAction)actionDone:(id)sender {
    if (self.adjustType == AdjustTypeAdjustAdjustFail) {
        [[BluetoothService sharedInstance] exitAdjust];
        [SVProgressHUD showWithStatus:@"退出中"];
    } else if (self.adjustType == AdjustTypeAdjustLimitFail) {
        self.adjustType = AdjustTypeReady;
    } else {
        self.adjustType = AdjustTypeReady;
        [SVProgressHUD showWithStatus:@"完成中"];
    }
}

- (IBAction)actionLimitSetting:(id)sender {
    UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"提示" message:nil preferredStyle:
                                  UIAlertControllerStyleAlert];
    // 添加输入框 (注意:在UIAlertControllerStyleActionSheet样式下是不能添加下面这行代码的)
    [alertVc addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"请输入校验偏差范围";
        textField.keyboardType = UIKeyboardTypeNumberPad;
    }];
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        self.limitVal = [[[alertVc textFields] objectAtIndex:0].text integerValue];
        [self.limitButton setTitle:[NSString stringWithFormat:@"%ld", self.limitVal] forState:UIControlStateNormal];
    }];
    UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    // 添加行为
    [alertVc addAction:action2];
    [alertVc addAction:action1];
    [self presentViewController:alertVc animated:YES completion:nil];

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

- (void)notifyVals:(NSArray *)valArray rIndex:(NSInteger)rIndex {
    if (self.adjustType != AdjustTypeExitTunel) {
        return;
    }
    for (int i = 0; i < valArray.count; i++) {
        self.forces[(rIndex - 1) * 6 + i] = valArray[i];
    }
    if ([self forcesIsCompletly]) {
        if ([self forcesIsCorrect]) {
            self.adjustType = AdjustTypeCheckSuccess;
        } else {
            self.adjustType = AdjustTypeAdjustLimitFail;
        }
    }
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
    [self.startOrResetButton setTitle:@"复位" forState:UIControlStateNormal];
    self.adjustType = AdjustTypeReady;
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

// 进入或退出透传成功
- (void)notifyTunelSucc {
    if (self.adjustType == AdjustTypeReady) {
        self.adjustType = AdjustTypeTunelEntered;
        [[BluetoothService sharedInstance] enterAdjust];
    } else if (self.adjustType == AdjustTypeStartDataed) {
        self.adjustType = AdjustTypeExitTunel;
        [SVProgressHUD dismiss];
        // SDL:2 开始数据，并检测
        [[BluetoothService sharedInstance] sendData:@"SDL:2"];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.adjustType != AdjustTypeAdjustLimitFail || self.adjustType != AdjustTypeCheckSuccess) {
                self.adjustType = AdjustTypeAdjustLimitFail;
            }
        });
        
        [self resetForeces];
        [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"校验中，偏差%ld", self.limitVal]];
    }
}
// 进入退出校准成功或开始发送数据成功
- (void)notifyAdjustOrStartDataSucc {
    if (self.adjustType == AdjustTypeTunelEntered) {
        self.adjustType = AdjustTypeAdjustEntered;
        // 等待手动点击开始校准
        [SVProgressHUD dismiss];
        [SVProgressHUD showSuccessWithStatus:@"进入透传成功" duration:2];
    } else if (self.adjustType == AdjustTypeAdjustSuccess || self.adjustType == AdjustTypeAdjustAdjustFail) {
        self.adjustType = AdjustTypeExitAdjusted;
        [[BluetoothService sharedInstance] exitAdjust];
//        [SVProgressHUD dismiss];
//        [SVProgressHUD showSuccessWithStatus:@"校准完成" duration:2];
    } else if (self.adjustType == AdjustTypeExitAdjusted) {
        self.adjustType = AdjustTypeStartDataed;
        [[BluetoothService sharedInstance] exitTunel];
    }
}
// 校准成功
- (void)notifyAdjustSucc {
    self.adjustType = AdjustTypeAdjustSuccess;
}
// 校准失败
- (void)notifyAdjustFail {
    self.adjustType = AdjustTypeAdjustAdjustFail;
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
