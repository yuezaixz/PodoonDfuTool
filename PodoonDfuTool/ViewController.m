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

@property (strong, nonatomic) NSString *sstpVal;

@property (nonatomic) NSInteger valSSAS;
@property (nonatomic) NSInteger valSSTS;
@property (nonatomic) NSInteger valSSMS;
@property (nonatomic) NSInteger valSSAA;
@property (nonatomic) NSInteger valSSTA;
@property (nonatomic) NSInteger valSSMA;
@property (nonatomic) NSInteger valSSAF;
@property (nonatomic) NSInteger valSSTF;
@property (nonatomic) NSInteger valSSMF;
@property (nonatomic) NSInteger valSSAB;
@property (nonatomic) NSInteger valSSTB;
@property (nonatomic) NSInteger valSSMB;
@property (nonatomic) NSInteger valSSSC;

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
        [SVProgressHUD showSuccessWithStatus:@"发送成功" duration:1];
    } else if ([btn.titleLabel.text isEqualToString:@"设SSTP"]) {
        UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"提示" message:nil preferredStyle:
                                      UIAlertControllerStyleAlert];
        // 添加输入框 (注意:在UIAlertControllerStyleActionSheet样式下是不能添加下面这行代码的)
        [alertVc addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = @"请输入相似度";
            textField.keyboardType = UIKeyboardTypeNumberPad;
        }];
        UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            self.sstpVal = [NSString stringWithFormat:@"SSTP:%@",[[alertVc textFields] objectAtIndex:0].text];
        }];
        UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
        // 添加行为
        [alertVc addAction:action2];
        [alertVc addAction:action1];
        [self presentViewController:alertVc animated:YES completion:nil];
    } else if ([btn.titleLabel.text isEqualToString:@"写SSTP"]) {
        if (self.sstpVal) {
            [SVProgressHUD showSuccessWithStatus:self.sstpVal duration:1];
            [self performSelector:@selector(writeCmd:) withObject:self.sstpVal afterDelay:0.02];
        }
    } else if ([btn.titleLabel.text isEqualToString:@"设阈值"]) {
        UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"提示" message:nil preferredStyle:
                                      UIAlertControllerStyleAlert];
        // 添加输入框 (注意:在UIAlertControllerStyleActionSheet样式下是不能添加下面这行代码的)
        [alertVc addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = @"SSAS均方差综合侧卧门限";
            textField.keyboardType = UIKeyboardTypeNumberPad;
        }];
        [alertVc addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = @"SSTSTOP2综合侧卧门限";
            textField.keyboardType = UIKeyboardTypeNumberPad;
        }];
        [alertVc addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = @"SSMSMAX综合侧卧门限";
            textField.keyboardType = UIKeyboardTypeNumberPad;
        }];
        [alertVc addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = @"SSAA均方差强条件侧卧门限";
            textField.keyboardType = UIKeyboardTypeNumberPad;
        }];
        [alertVc addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = @"SSTATOP2强条件侧卧门限";
            textField.keyboardType = UIKeyboardTypeNumberPad;
        }];
        [alertVc addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = @"SSMAMAX强条件侧卧门限";
            textField.keyboardType = UIKeyboardTypeNumberPad;
        }];
        [alertVc addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = @"SSAF均方差综合仰卧门限";
            textField.keyboardType = UIKeyboardTypeNumberPad;
        }];
        [alertVc addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = @"SSTFTOP2综合仰卧门限";
            textField.keyboardType = UIKeyboardTypeNumberPad;
        }];
        [alertVc addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = @"SSMFMAX综合仰卧门限";
            textField.keyboardType = UIKeyboardTypeNumberPad;
        }];
        [alertVc addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = @"SSAB均方差强条件仰卧门限";
            textField.keyboardType = UIKeyboardTypeNumberPad;
        }];
        [alertVc addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = @"SSTBTOP2强条件仰卧门限";
            textField.keyboardType = UIKeyboardTypeNumberPad;
        }];
        [alertVc addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = @"SSMBMAX强条件仰卧门限";
            textField.keyboardType = UIKeyboardTypeNumberPad;
        }];
        [alertVc addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = @"SSSC灵敏度系数";
            textField.keyboardType = UIKeyboardTypeNumberPad;
        }];
        UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            self.valSSAS = [[alertVc textFields] objectAtIndex:0].text?[[alertVc textFields] objectAtIndex:0].text.integerValue:0;
            self.valSSTS = [[alertVc textFields] objectAtIndex:1].text?[[alertVc textFields] objectAtIndex:1].text.integerValue:0;
            self.valSSMS = [[alertVc textFields] objectAtIndex:2].text?[[alertVc textFields] objectAtIndex:2].text.integerValue:0;
            self.valSSAA = [[alertVc textFields] objectAtIndex:3].text?[[alertVc textFields] objectAtIndex:3].text.integerValue:0;
            self.valSSTA = [[alertVc textFields] objectAtIndex:4].text?[[alertVc textFields] objectAtIndex:4].text.integerValue:0;
            self.valSSMA = [[alertVc textFields] objectAtIndex:5].text?[[alertVc textFields] objectAtIndex:5].text.integerValue:0;
            self.valSSAF = [[alertVc textFields] objectAtIndex:6].text?[[alertVc textFields] objectAtIndex:6].text.integerValue:0;
            self.valSSTF = [[alertVc textFields] objectAtIndex:7].text?[[alertVc textFields] objectAtIndex:7].text.integerValue:0;
            self.valSSMF = [[alertVc textFields] objectAtIndex:8].text?[[alertVc textFields] objectAtIndex:8].text.integerValue:0;
            self.valSSAB = [[alertVc textFields] objectAtIndex:9].text?[[alertVc textFields] objectAtIndex:9].text.integerValue:0;
            self.valSSTB = [[alertVc textFields] objectAtIndex:10].text?[[alertVc textFields] objectAtIndex:10].text.integerValue:0;
            self.valSSMB = [[alertVc textFields] objectAtIndex:11].text?[[alertVc textFields] objectAtIndex:11].text.integerValue:0;
            self.valSSSC = [[alertVc textFields] objectAtIndex:12].text?[[alertVc textFields] objectAtIndex:12].text.integerValue:0;
        }];
        UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
        // 添加行为
        [alertVc addAction:action2];
        [alertVc addAction:action1];
        [self presentViewController:alertVc animated:YES completion:nil];
    } else if ([btn.titleLabel.text isEqualToString:@"写阈值"]) {
        NSMutableArray *cmdList = [NSMutableArray array];
        if (self.valSSAA && self.valSSAA != 0) {
            [cmdList addObject:[NSString stringWithFormat:@"SSAS:%ld",self.valSSAS]];
        }
        if (self.valSSTS && self.valSSTS != 0) {
            [cmdList addObject:[NSString stringWithFormat:@"SSTS:%ld",self.valSSTS]];
        }
        if (self.valSSMS && self.valSSMS != 0) {
            [cmdList addObject:[NSString stringWithFormat:@"SSMS:%ld",self.valSSMS]];
        }
        if (self.valSSAA && self.valSSAA != 0) {
            [cmdList addObject:[NSString stringWithFormat:@"SSAA:%ld",self.valSSAA]];
        }
        if (self.valSSTA && self.valSSTA != 0) {
            [cmdList addObject:[NSString stringWithFormat:@"SSTA:%ld",self.valSSTA]];
        }
        if (self.valSSMA && self.valSSMA != 0) {
            [cmdList addObject:[NSString stringWithFormat:@"SSMA:%ld",self.valSSMA]];
        }
        if (self.valSSAF && self.valSSAF != 0) {
            [cmdList addObject:[NSString stringWithFormat:@"SSAF:%ld",self.valSSAF]];
        }
        if (self.valSSTF && self.valSSTF != 0) {
            [cmdList addObject:[NSString stringWithFormat:@"SSTF:%ld",self.valSSTF]];
        }
        if (self.valSSMF && self.valSSMF != 0) {
            [cmdList addObject:[NSString stringWithFormat:@"SSMF:%ld",self.valSSMF]];
        }
        if (self.valSSAB && self.valSSAB != 0) {
            [cmdList addObject:[NSString stringWithFormat:@"SSAB:%ld",self.valSSAB]];
        }
        if (self.valSSTB && self.valSSTB != 0) {
            [cmdList addObject:[NSString stringWithFormat:@"SSTB:%ld",self.valSSTB]];
        }
        if (self.valSSMB && self.valSSMB != 0) {
            [cmdList addObject:[NSString stringWithFormat:@"SSMB:%ld",self.valSSMB]];
        }
        if (self.valSSSC && self.valSSSC != 0) {
            [cmdList addObject:[NSString stringWithFormat:@"SSSC:%ld",self.valSSSC]];
        }
        double delayTime = 0.02;
        for (NSString *cmd in cmdList) {
            [self performSelector:@selector(writeCmd:) withObject:cmd afterDelay:delayTime];
            delayTime += 0.02;
        }
    } else {
        [[BluetoothService sharedInstance] sendData:btn.titleLabel.text];
    }
}

- (void)writeCmd:(NSString *)cmd {
    NSLog(@"write cmd : %@", cmd);
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
