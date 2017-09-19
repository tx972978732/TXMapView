//
//  TXUserLocationAnnotationView.m
//  BaiChuan
//
//  Created by 童煊 on 2017/9/8.
//  Copyright © 2017年 Samu33. All rights reserved.
//

#import "TXUserLocationAnnotationView.h"

@interface TXUserLocationAnnotationView ()

@property (nonatomic, assign) uint8_t kvoContext;
@end

@implementation TXUserLocationAnnotationView

- (instancetype)initWithAnnotation:(id<MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self) {
        self.kvoContext = 13;
        self.userAnnotation = annotation;
        [self initArrowView];
        [self setupObserver];
    }
    return self;
}

//- (void)dealloc{
//    if ([self.annotation isMemberOfClass:[TXUserLocationAnnotation class]]) {
//        [(TXUserLocationAnnotation*)self.annotation removeObserver:self forKeyPath:@"heading"];
//    }
//}

- (void)initArrowView{
    self.arrowImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"dingweituceng"]];
    [self addSubview:self.arrowImageView];
}

- (void)setupObserver{
//    if ([self.annotation isMemberOfClass:[TXUserLocationAnnotation class]]) {
//        [(TXUserLocationAnnotation*)self.annotation addObserver:self forKeyPath:@"heading" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:&_kvoContext];
//    }
    [RACObserve(self.userAnnotation, heading) subscribeNext:^(id x) {
        WEAKSELF
        [UIView animateWithDuration:0.05 animations:^{
            weakSelf.arrowImageView.transform = CGAffineTransformMakeRotation([x floatValue]/180*M_PI);
        }];
    }];
}

//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
//    if (context == &_kvoContext) {
//        TXUserLocationAnnotation *annotation = self.annotation;
//        WEAKSELF
//        [UIView animateWithDuration:0.05 animations:^{
//            weakSelf.arrowImageView.transform = CGAffineTransformMakeRotation(annotation.heading/180*M_PI);
//        }];
//    }
//    
//}
@end
