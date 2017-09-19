//
//  TXUserLocationAnnotationView.h
//  BaiChuan
//
//  Created by 童煊 on 2017/9/8.
//  Copyright © 2017年 Samu33. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "TXUserLocationAnnotation.h"

@interface TXUserLocationAnnotationView : MKAnnotationView

@property (nonatomic, strong) UIImageView *arrowImageView;
@property (nonatomic, strong) TXUserLocationAnnotation *userAnnotation;

- (instancetype)initWithAnnotation:(id<MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier;
@end

