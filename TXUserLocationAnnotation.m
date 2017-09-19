//
//  TXUserLocationAnnotation.m
//  BaiChuan
//
//  Created by 童煊 on 2017/9/8.
//  Copyright © 2017年 Samu33. All rights reserved.
//

#import "TXUserLocationAnnotation.h"

@implementation TXUserLocationAnnotation

- (instancetype)initLocationAnnotationWithCoordinate:(CLLocationCoordinate2D)coordinate andHeading:(float)heading{
    self = [super init];
    if (self) {
        self.coordinate = coordinate;
        self.heading = heading;
    }
    return self;
}
@end
