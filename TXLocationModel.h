//
//  TXLocationModel.h
//  BaiChuan
//
//  Created by 童煊 on 2017/9/19.
//  Copyright © 2017年 Samu33. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TXLocationModel : NSObject

@property (nonatomic, strong) NSString *latitude;
@property (nonatomic, strong) NSString *longitude;
@property (nonatomic, strong) NSString *name;

@property (nonatomic, assign, readonly) CLLocationCoordinate2D coordinate;//根据经纬度信息自动生成

- (instancetype)initWithInfoDic:(NSMutableDictionary*)info;

@end
