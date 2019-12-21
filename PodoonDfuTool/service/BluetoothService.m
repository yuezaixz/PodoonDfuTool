//
//  BluetoothService.m
//  PodoonDfuTool
//
//  Created by 吴迪玮 on 2019/1/2.
//  Copyright © 2019年 podoon. All rights reserved.
//

#import "BluetoothService.h"

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

- (void)search {
    LOG_FUNC
    self.peripheral = nil;
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
    
    self.connectingPeripheral = nil;
    
    if (searchTimer_) {
        [searchTimer_ invalidate];
        searchTimer_ = nil;
    }
    
    [self.centermanager stopScan];
    
}

- (void)disconnect {
    if (self.peripheral) {
        self.peripheral.delegate = nil;
        [self.centermanager cancelPeripheralConnection:self.peripheral];
        self.peripheral = nil;
    }
}

- (void)sendData:(NSString *)cmd {
    if (self.peripheral) {
        [self writeCommand:cmd];
    }
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
    NSLog(@"RSSI:%@,%ld",peripheral.identifier.UUIDString, RSSI.integerValue);
    if ([peripheral.name rangeOfString:@"ZT"].location != NSNotFound && RSSI.integerValue > -50 && RSSI.integerValue != 127 ) {
        [self.delegate notifyDiscover];
        self.connectingPeripheral = peripheral;
        [self.centermanager connectPeripheral:peripheral options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
                                                                                             forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
        self.peripheral = peripheral;
    }
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
    
    //断开连接后清空状态
    self.peripheral = nil;
    self.connectingPeripheral = nil;
    [self.delegate notifyDisConnect];
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
            [self.delegate notifyReady];
        } else {
            [peripheral setNotifyValue:YES forCharacteristic:c];
        }
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)c error:(NSError *)error{
    if ([c.UUID isEqual:BT_Characteristic_PODOON_NOTIFY] && self.peripheral.identifier == peripheral.identifier) {
        NSData *tempData = c.value;
        if (tempData.length == 0 ) {
            return;
        }
        uint8_t *footData = [tempData bytes];
        NSString *offlineStr = [[NSString stringWithFormat:@"%s",footData] substringWithRange:NSMakeRange(0, tempData.length)];
        if ([offlineStr rangeOfString:@"Batt"].location != NSNotFound) {
            [self.delegate notifyghvLog:offlineStr];
            [self writeCommand:@"GVN"];
        } else if ([offlineStr rangeOfString:@"FW"].location != NSNotFound) {
            [self.delegate notifygvnLog:offlineStr];
            [self writeCommand:@"GMAC"];
        } else if ([offlineStr rangeOfString:@"DownCnt:"].location != NSNotFound) {
           [self.delegate notifyRemainDayLog:[offlineStr substringFromIndex:8]];
        } else if ([offlineStr rangeOfString:@"MC:"].location != NSNotFound) {
            [self.delegate notifymacLog:offlineStr];
        } else if ([offlineStr rangeOfString:@"Slp:"].location != NSNotFound) {
            [self.delegate notifySlpLog:offlineStr];
        }
        
        [self.delegate notifyLog:offlineStr];
        
    }
}

- (void)initAtFoundWrite {
    LOG_FUNC
    
    [self writeCommand:@"GHV"];
    [self performSelector:@selector(writeCommand:) withObject:@"GDC" afterDelay:0.02];
    [self performSelector:@selector(writeCommand:) withObject:@"GMAC" afterDelay:0.04];
    [self performSelector:@selector(SDL11) withObject:nil afterDelay:0.06];
    [self performSelector:@selector(SDI2) withObject:nil afterDelay:0.08];
}
- (void)SDL11 {
    [self writeCommand:@"SDL:11"];
}

- (void)SDI2 {
    [self writeCommand:@"SDI:2"];
}

- (void)writeCommand:(NSString *)command {
    LOG_FUNC
    
    if (_writeCharacteristic) {
//        [self debug:[NSString stringWithFormat:@"写入命令：%@",command]];
        NSData *data =[command dataUsingEncoding:NSUTF8StringEncoding];
        [self.peripheral writeValue:data forCharacteristic:_writeCharacteristic type:CBCharacteristicWriteWithoutResponse];
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

@end
