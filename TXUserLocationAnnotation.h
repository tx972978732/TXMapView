//
//  TXUserLocationAnnotation.h
//  BaiChuan
//
//  Created by 童煊 on 2017/9/8.
//  Copyright © 2017年 Samu33. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface TXUserLocationAnnotation : MKPointAnnotation

@property (nonatomic, assign) CLLocationDirection heading;
- (instancetype)initLocationAnnotationWithCoordinate:(CLLocationCoordinate2D)coordinate andHeading:(float)heading;
@end
