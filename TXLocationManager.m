//
//  TXLocationManager.m
//  BaiChuan
//
//  Created by 童煊 on 2017/9/7.
//  Copyright © 2017年 Samu33. All rights reserved.
//

#import "TXLocationManager.h"

@interface TXLocationManager ()<CLLocationManagerDelegate>

@property (nonatomic, strong)NSMutableDictionary *locationDic;
@property (nonatomic, strong)NSMutableDictionary *headingDic;
@property (nonatomic, strong)RACSignal *latitude;
@property (nonatomic, strong)RACSignal *longitude;
@property (nonatomic, strong)RACSignal *location;
@property (nonatomic, strong)RACSignal *trueHeading;//真北
@property (nonatomic, strong)RACSignal *magHeading;//磁北
@property (nonatomic, strong)RACSignal *heading;
@property (nonatomic, strong)RACSubject *stopLocation;//停止订阅Location
@property (nonatomic, strong)RACSubject *stopHeading;//停止订阅Heading
@property (nonatomic, assign, readwrite)BOOL isLocating;

@end

static TXLocationManager *locationManager = nil;


@implementation TXLocationManager

+ (instancetype)sharedManager{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (locationManager==nil) {
            locationManager = [[self alloc]init];
            locationManager.isLocating = NO;
            //存儲位置信息的字典
            if (locationManager.locationDic == nil) {
                locationManager.locationDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"",@"latitude",@"",@"longitude", nil];
            }
            //存儲方向信息的字典
            if (locationManager.headingDic == nil) {
                locationManager.headingDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"",@"trueHeading",@"",@"magHeading", nil];
            }
        }
    });
    return locationManager;
}

- (void)startLocating{
    //定位管理
    self.manager = [[CLLocationManager alloc]init];
    self.manager.distanceFilter = 10;
    self.manager.desiredAccuracy = kCLLocationAccuracyBest;
    self.manager.headingFilter = 5.0f;
    self.manager.delegate = self;
    if ([self.manager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.manager requestWhenInUseAuthorization];
    }
    if ([CLLocationManager headingAvailable]) {
        [self.manager startUpdatingHeading];
    }
    [self.manager startUpdatingLocation];
    self.isLocating = YES;
    //信號流
    self.latitude = [[self.locationDic rac_valuesForKeyPath:@"latitude" observer:self] replayLazily];
    self.longitude =  [[self.locationDic rac_valuesForKeyPath:@"longitude" observer:self] replayLazily];
    self.trueHeading = [[self.headingDic rac_valuesForKeyPath:@"trueHeading" observer:self] replayLazily];
    self.magHeading = [[self.headingDic rac_valuesForKeyPath:@"magHeading" observer:self] replayLazily];
    
    self.location = [[RACSignal combineLatest:@[self.latitude,self.longitude] reduce:^id(NSString *latitude,NSString *longitude){
//        NSLog(@"latitude:%@,longitude:%@",latitude,longitude);
        if (latitude.length!=0&&longitude.length!=0) {
            NSDictionary *returnDic = @{@"latitude":latitude,@"longitude":longitude};
            return returnDic;
        }else if (latitude.length==0||longitude.length==0){
            NSDictionary *returnDic = @{@"latitude":@"0",@"longitude":@"0"};
            return returnDic;
        }
        else{
            return [RACSignal empty];
        }
    }] replayLast];
    self.heading = [[RACSignal combineLatest:@[self.trueHeading,self.magHeading] reduce:^id(NSString *trueHeading,NSString *magHeading){
//        NSLog(@"trueHeading:%@,magHeading:%@",trueHeading,magHeading);
        if (trueHeading.length!=0&&magHeading.length!=0) {
            NSDictionary *returnDic = @{@"trueHeading":trueHeading,@"magHeading":magHeading};
            return returnDic;
        }else if (trueHeading.length!=0){
            NSDictionary *returnDic = @{@"trueHeading":trueHeading,@"magHeading":@"0"};
            return returnDic;
        }else if (trueHeading.length==0||magHeading.length==0){
            NSDictionary *returnDic = @{@"trueHeading":@"0",@"magHeading":@"0"};
            return returnDic;
        }else{
            return [RACSignal empty];
        }
    }] replayLast];
    
}

- (void)pauseLocating{
    if (self.isLocating == YES) {
        NSLog(@"暂停获取地理位置信息");
        [self.stopLocation sendCompleted];
        [self.stopHeading sendCompleted];
        [self.manager stopUpdatingLocation];
        [self.manager stopUpdatingHeading];
        self.isLocating = NO;
    }
}
- (void)restartLocating{
    if (self.isLocating == NO) {
        NSLog(@"重新开始获取地理位置信息");
        [self.manager startUpdatingLocation];
        [self.manager startUpdatingHeading];
        self.isLocating = YES;
    }
}

- (NSDictionary *)getLocationSignal{
    __block NSDictionary *result;
    self.stopLocation = [[RACSubject alloc]init];
    @weakify(self);
    [[self.location takeUntil:self.stopLocation] subscribeNext:^(id x) {
        @strongify(self);
        if (![x isKindOfClass:[RACSignal class]]) {
//            NSLog(@"location signal:%@",x);
            [self.stopLocation sendCompleted];
            result = x;
        }else{
            result = self.locationDic;
            NSLog(@"empty signal");
        }
    }];
    return result;
}

- (NSDictionary *)getHeadingSignal{
    __block NSDictionary *result;
    self.stopHeading = [[RACSubject alloc]init];
    @weakify(self);
    [[self.heading takeUntil:self.stopHeading] subscribeNext:^(id x) {
        @strongify(self);
        if (![x isKindOfClass:[RACSignal class]]) {
//            NSLog(@"heading signal:%@",x);
            [self.stopHeading sendCompleted];
            result = x;
        }else{
            result = self.headingDic;
            NSLog(@"empty signal");
        }
    }];
    return result;
}

- (NSDictionary *)getLocationSignalOnce{
    if (self.isLocating == YES) {
        NSDictionary *result = [self getLocationSignal];
        [self pauseLocating];
        return result;
    }else{
        [self restartLocating];
        NSDictionary *result = [self getLocationSignal];
        [self pauseLocating];
        return result;
    }
}

- (NSDictionary *)getHeadingSignalOnce{
    if (self.isLocating == YES) {
        NSDictionary *result = [self getHeadingSignal];
        [self pauseLocating];
        return result;
    }else{
        [self restartLocating];
        NSDictionary *result = [self getHeadingSignal];
        [self pauseLocating];
        return result;
    }
}


#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations{
    CLLocation *location = locations.lastObject;
    [self.locationDic setObject:[NSString stringWithFormat:@"%f",location.coordinate.latitude] forKey:@"latitude"];
    [self.locationDic setObject:[NSString stringWithFormat:@"%f",location.coordinate.longitude] forKey:@"longitude"];
//    NSLog(@"location:latitude-%f,longitude-%f",location.coordinate.latitude,location.coordinate.longitude);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kUserLocationUpdateNotification object:nil];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading{
    [self.headingDic setObject:[NSString stringWithFormat:@"%f",newHeading.magneticHeading] forKey:@"magHeading"];
    [self.headingDic setObject:[NSString stringWithFormat:@"%f",newHeading.trueHeading] forKey:@"trueHeading"];
//    NSLog(@"magneticHeading:%f,trueHeading:%f",newHeading.magneticHeading,newHeading.trueHeading);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:KUserHeadingUpdateNotification object:nil];
}

- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager
{
    return YES;
}

@end
