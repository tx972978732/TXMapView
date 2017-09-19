//
//  TXLocationModel.m
//  BaiChuan
//
//  Created by 童煊 on 2017/9/19.
//  Copyright © 2017年 Samu33. All rights reserved.
//

#import "TXLocationModel.h"

@interface TXLocationModel ()

@property (nonatomic, assign, readwrite) CLLocationCoordinate2D coordinate;//根据经纬度信息自动生成

@end

@implementation TXLocationModel

- (instancetype)initWithInfoDic:(NSMutableDictionary*)info{
    if (self = [super init]) {
        [self setValuesForKeysWithDictionary:info];
        [self loadCoordinate];
    }
    return self;
}

- (void)loadCoordinate{
    if (self.latitude&&self.longitude) {
        self.coordinate = CLLocationCoordinate2DMake([self.latitude doubleValue],[self.longitude doubleValue]);
    }
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key{
    NSLog(@"TXLocationModel undefindeKey:%@",key);
}

@end
