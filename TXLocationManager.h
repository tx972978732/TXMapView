//
//  TXLocationManager.h
//  BaiChuan
//
//  Created by 童煊 on 2017/9/7.
//  Copyright © 2017年 Samu33. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#define kUserLocationUpdateNotification @"kUserLocationUpdateNotification"
#define KUserHeadingUpdateNotification @"KUserHeadingUpdateNotification"

@interface TXLocationManager : NSObject

//******說明******//
/* 1、初始化调用startLocating启动定位，调用pauseLocating暂停定位功能，调用restartLocation重启定位功能。
 2、getLocationSignal将获得一个包含经纬度信息的字典，该方法必须在isLocating==Yes时使用
 */
//******說明******//

//******建议*****//
/* 1、在AppDelegate中启动定位功能，获取当前位置信息，获取的信息缓存在locationDic当中
 2、在不需要位置信息时pause定位功能降低功耗和数据流量，建议在initVC中进行暂停，在有需要的地方再restart（根据isLocating标识判断）
 例子：成对调用 pause和restart 只在需要的时候获取位置信息
 if ([LIVLocationManager sharedManager].isLocating == NO) {
 [[LIVLocationManager sharedManager] restartLocating];
 NSDictionary *dic = [[LIVLocationManager sharedManager]getLocationSignal];
 [[LIVLocationManager sharedManager] pauseLocating];
 }else{
 NSDictionary *dic = [[LIVLocationManager sharedManager]getLocationSignal];
 [[LIVLocationManager sharedManager] pauseLocating];
 }
 
 
 */
//******建议*****//

@property (nonatomic, strong)CLLocationManager *manager;
@property (nonatomic, assign, readonly)BOOL isLocating;//default = NO;

+ (instancetype)sharedManager;
- (void)startLocating;//启动定位
- (void)pauseLocating;//暂停定位
- (void)restartLocating;//重启定位

//**下面4个方法都只能获取到最后一次定位的信息，如果要获取实时改变的定位信息 使用"kUserLocationUpdateNotification"和**"KUserHeadingUpdateNotification"//
- (NSDictionary *)getLocationSignal;//获取定位值，需要定位处于开启状态（isLocating = YES）
- (NSDictionary *)getHeadingSignal;//获取方向值，需要定位处于开启状态（isLocating = YES）

- (NSDictionary *)getLocationSignalOnce;//获取一次定位值（自动管理定位启动，获取一次后自动关闭定位）
- (NSDictionary *)getHeadingSignalOnce;//获取一次方向值（自动管理定位启动，获取一次后自动关闭定位）

//**helper methods 其他辅助方法
- (double)distanceFromLocation:(NSDictionary*)from toLocation:(NSDictionary*)to;//计算两个经纬度的距离,from传空时以当前定位经纬度为起始点,返回结果单位为公里(km)
@end
