//
//  BluetoothService.m
//  PodoonDfuTool
//
//  Created by 吴迪玮 on 2019/1/2.
//  Copyright © 2019年 podoon. All rights reserved.
//

#import "BluetoothService.h"
#import "DFUHelper.h"
#include "DFUHelper.h"
#import <AFNetworking/AFNetworking.h>
#import "SVProgressHUD.h"

#define BT_Service_FOOT [CBUUID UUIDWithString:@"6E400001-B5A3-F393-E0A9-E50E24DCCA9E"]
#define BT_Service_FOOT_S130 [CBUUID UUIDWithString:@"1801"]

#define BT_DFU_SERVICE_UUIDS [CBUUID UUIDWithString:@"00001530-1212-EFDE-1523-785FEABCD123"]

#define BT_SERVICE_PODOON [CBUUID UUIDWithString:@"6E400001-B5A3-F393-E0A9-E50E24DCCA9E"]

//设备NOTIFICATION服务
#define PODOON_DEVICE_UUID_NOTIFICATION_SERVICE @"6E400003-B5A3-F393-E0A9-E50E24DCCA9E"

#define BT_Characteristic_PODOON_NOTIFY [CBUUID UUIDWithString:PODOON_DEVICE_UUID_NOTIFICATION_SERVICE]

#define PODOON_DEVICE_UUID_WRITE_SERVICE @"6E400002-B5A3-F393-E0A9-E50E24DCCA9E"

#define BT_Characteristic_PODOON_WRITE [CBUUID UUIDWithString:PODOON_DEVICE_UUID_WRITE_SERVICE]

#define FIRMWARE_FOLDER_NAME @"s130_ota_zt"

#define LOG_FUNC NSLog(@"log func：%s",__FUNCTION__);

@interface BluetoothService()

@property (strong, nonatomic) CBPeripheral *connectingPeripheral;
@property (strong, nonatomic) CBPeripheral *peripheral;
@property (strong, nonatomic) CBPeripheral *dfuPeripheral;


@property(strong, nonatomic) DFUOperations *dfuOperations;
@property(strong, nonatomic) DFUHelper *dfuHelper;

@property (strong, nonatomic) NSURL *filePath;

@end

@implementation BluetoothService {
    NSTimer *searchTimer_;
    CBCharacteristic *_writeCharacteristic;
    BOOL isStartOTA_;
    BOOL isDFU_;
}

#pragma mark - init

+ (instancetype)sharedInstance
{
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];

//        NSURL *URL = [NSURL URLWithString:@"http://res-10048881.cossh.myqcloud.com/ZT_H904A.zip"];
//        NSURLRequest *request = [NSURLRequest requestWithURL:URL];
//
//        NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
//            NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
//            return [documentsDirectoryURL URLByAppendingPathComponent:[response suggestedFilename]];
//        } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [SVProgressHUD showSuccessWithStatus:@"固件更新成功" duration:2];
//            });
//            NSLog(@"File downloaded to: %@", filePath);
//            self.filePath = filePath;
//        }];
//        [downloadTask resume];
    }
    return self;
}

- (void)search {
    LOG_FUNC
    self.peripheral = nil;
    self.dfuPeripheral = nil;
    self.connectingPeripheral = nil;
    
    if (searchTimer_) {
        [searchTimer_ invalidate];
        searchTimer_ = nil;
    }
    searchTimer_ = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(searchPeripherals) userInfo:nil repeats:YES];
    [searchTimer_ fire];
}

- (void)stop {
    LOG_FUNC
    
    self.peripheral = nil;
    self.dfuPeripheral = nil;
    self.connectingPeripheral = nil;
    
    if (searchTimer_) {
        [searchTimer_ invalidate];
        searchTimer_ = nil;
    }
    
    [self.centermanager stopScan];
    
}

//根据tag值搜索设备
- (void)searchPeripherals{
    LOG_FUNC
    
    if (self.centermanager.state == CBCentralManagerStatePoweredOn) {
        NSMutableArray *searchServices = [NSMutableArray array];
        [searchServices addObjectsFromArray:[self foundServiceUUIDArray]];
        if ([searchServices count]) {
            [self startScanWithServices:[searchServices copy]];
        }
    }else{
        if(self.centermanager.state == CBCentralManagerStateUnknown){
            [self performSelector:@selector(searchPeripherals) withObject:nil afterDelay:.5];
            return;
        }
    }
}

//根据设备的UUID数组开始查找设备
- (void)startScanWithServices:(NSArray *)serviceArray{
    LOG_FUNC
    
    // 不弹出提示打开蓝牙
    NSDictionary *options = @{CBCentralManagerOptionShowPowerAlertKey : @NO};
    
    // 开始扫描
    [self.centermanager scanForPeripheralsWithServices:serviceArray options:options];
    
}

#pragma mark CBCentralManagerDelegate
//发现设备
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    LOG_FUNC
    
    if ([peripheral.name rangeOfString:@"ZT"].location != NSNotFound && RSSI.integerValue > -60 && RSSI.integerValue != 127 ) {
        [self.delegate notifyDiscover];
        self.connectingPeripheral = peripheral;
        [self.centermanager connectPeripheral:peripheral options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
                                                                                             forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
        self.peripheral = peripheral;
    }
}

- (void)startDFU {
    LOG_FUNC
    
    [self.dfuOperations setCentralManager:self.centermanager];
    [self.dfuOperations connectDevice:self.dfuPeripheral];
}

- (void)clean {
    LOG_FUNC
    
    isStartOTA_ = NO;
    isDFU_ = NO;
    
    [self.dfuOperations cleanCentralManager];
    self.centermanager = nil;
}

//连接成功
-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    LOG_FUNC
    [self.delegate notifyDidConnect];
    self.connectingPeripheral = nil;
    
    peripheral.delegate = self;
    
    [peripheral discoverServices:nil];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    LOG_FUNC
    
    [self.delegate notifyDisConnect];
    //断开连接后清空状态
    self.peripheral = nil;
    self.connectingPeripheral = nil;
}

- (void)centralManagerDidUpdateState:(nonnull CBCentralManager *)central {
    NSLog(@"%@", [NSString stringWithFormat:@"蓝牙状态改变:%ld",(long)central.state]);
}


#pragma mark - CBPeripheralDelegate
//发现设备提供的服务
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    LOG_FUNC
    
    for (CBService *s in peripheral.services){
        if ([s.UUID isEqual:BT_SERVICE_PODOON]) {
            [peripheral discoverCharacteristics:@[BT_Characteristic_PODOON_NOTIFY, BT_Characteristic_PODOON_WRITE] forService:s];
        }
        
        
    }
}

//发现服务的特性
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    LOG_FUNC
    
    for (CBCharacteristic *c in service.characteristics) {
        if ([c.UUID isEqual:BT_Characteristic_PODOON_WRITE]) {
            _writeCharacteristic = c;
            [self performSelector:@selector(initAtFoundWrite) withObject:nil afterDelay:0.2];
        } else {
            [peripheral setNotifyValue:YES forCharacteristic:c];
        }
    }
}

- (void)initAtFoundWrite {
    LOG_FUNC
    [self writeCommand:@"dfu"];
    [self.delegate notifyWriteDfu];
}

- (void)writeCommand:(NSString *)command {
    LOG_FUNC
    
    if (_writeCharacteristic) {
//        [self debug:[NSString stringWithFormat:@"写入命令：%@",command]];
        NSData *data =[command dataUsingEncoding:NSUTF8StringEncoding];
        [self.peripheral writeValue:data forCharacteristic:_writeCharacteristic type:CBCharacteristicWriteWithoutResponse];
    }
}

#pragma mark DFUOperations delegate methods
- (void)onDeviceConnected:(CBPeripheral *)peripheral {
    NSLog(@"onDeviceConnected %@", peripheral.name);
    self.dfuHelper.isDfuVersionExist = NO;
    
}

- (void)onDeviceConnectedWithVersion:(CBPeripheral *)peripheral {
    NSLog(@"onDeviceConnectedWithVersion %@", peripheral.name);
    self.dfuHelper.isDfuVersionExist = YES;
}

- (void)onDeviceDisconnected:(CBPeripheral *)peripheral {
    NSLog(@"device disconnected %@", peripheral.name);
}

- (void)onReadDFUVersion:(int)version {
    NSLog(@"onReadDFUVersion %d", version);
    self.dfuHelper.dfuVersion = version;
    NSLog(@"DFU Version: %d", self.dfuHelper.dfuVersion);
    if (self.dfuHelper.dfuVersion == 1) {
        [self.dfuOperations setAppToBootloaderMode];
    }
    //这里已经可以OTA了？
    if (!isStartOTA_) {
        [self startOTA];
        isStartOTA_ = YES;
    }
}

- (void)onDFUStarted {
    NSLog(@"onDFUStarted");
}

- (void)onDFUCancelled {
    NSLog(@"onDFUCancelled");
}

- (void)onSoftDeviceUploadStarted {
    NSLog(@"onSoftDeviceUploadStarted");
}

- (void)onSoftDeviceUploadCompleted {
    NSLog(@"onSoftDeviceUploadCompleted");
}

- (void)onBootloaderUploadStarted {
    NSLog(@"onBootloaderUploadStarted");
    
}

- (void)onBootloaderUploadCompleted {
    NSLog(@"onBootloaderUploadCompleted");
}

- (void)onTransferPercentage:(int)percentage {
//    [self notifyDfuPercentage:percentage];
    [self.delegate notifyPercent:percentage];
    NSLog(@"onTransferPercentage %d", percentage);
}

- (void)onSuccessfulFileTranferred {
    [self performSelector:@selector(successAction) withObject:nil afterDelay:0.2];
}

- (void)successAction {
//    [self notifyDfuSuccess];
    [self clean];
    [self.delegate notifySuccessDfu];
    NSLog(@"OnSuccessfulFileTransferred");
}

- (void)onError:(NSString *)errorMessage {
    NSLog(@"OnError %@", errorMessage);
    [self.delegate notifyFailDfu];
//    [self notifyDfuFailed:errorMessage];
}

- (void)startOTA {
    LOG_FUNC
    
    if (self.dfuPeripheral) {
        NSURL *url = nil;
        if (self.filePath) {
            url = self.filePath;
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showSuccessWithStatus:@"通过网络固件升级" duration:2];
            });
        } else {
            url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:FIRMWARE_FOLDER_NAME ofType:@"zip"]];
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showSuccessWithStatus:@"通过本地固件升级" duration:2];
            });
        }
        NSData *fileData = [NSData dataWithContentsOfURL:url];
        self.dfuHelper.selectedFileSize = fileData.length;
        self.dfuHelper.selectedFileURL = url;
        self.dfuHelper.isSelectedFileZipped = YES;
        self.dfuHelper.isManifestExist = NO;
        [self.dfuHelper unzipFiles:self.dfuHelper.selectedFileURL];
        
        [self.dfuHelper checkAndPerformDFU];
    }
}

#pragma mark - 蓝牙状态

- (CBManagerState)bluetoothState {
    return self.centermanager.state;
}

- (NSArray *)foundServiceUUIDArray{
    
    return @[BT_Service_FOOT, BT_Service_FOOT_S130, BT_DFU_SERVICE_UUIDS];
}

- (CBCentralManager *)centermanager{
    if(!_centermanager)
    {
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], CBCentralManagerOptionShowPowerAlertKey, nil];
        
        _centermanager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue() options:options];
    }
    
    return _centermanager;
}

-(DFUOperations *)dfuOperations {
    if (!_dfuOperations) {
        _dfuOperations = [[DFUOperations alloc] initWithDelegate:self];
    }
    return _dfuOperations;
}

-(DFUHelper *)dfuHelper {
    if (!_dfuHelper) {
        _dfuHelper = [[DFUHelper alloc] initWithData:self.dfuOperations];
        [_dfuHelper setFirmwareType:FIRMWARE_TYPE_APPLICATION];
    }
    return _dfuHelper;
}

@end
