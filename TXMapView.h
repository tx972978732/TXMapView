//
//  TXMapView.h
//  BaiChuan
//
//  Created by 童煊 on 2017/9/7.
//  Copyright © 2017年 Samu33. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "TXUserLocationAnnotation.h"
#import "TXLocationModel.h"

typedef NS_ENUM(NSInteger,navMapType){
    navMapTypeAPL = 0,
    navMapTypeAMap = 1,
    navMapTypeBaiduMap = 2
};

@interface TXMapView : UIView<MKMapViewDelegate>

//***公共属性***//
@property (nonatomic, strong) MKMapView *mapView;//地图
//暂时不开放自定义mapType，该属性默认为0，需要选择地图类型，在导航方法中直接设定
@property (nonatomic, assign, readonly) navMapType mapType;//导航类型（目前只支持跳转外接导航app）默认系统原生导航
//***公共属性***//


//***地图初始化方法***//
- (instancetype)initWithFrame:(CGRect)frame;
//***地图初始化方法***//

//***添加大头针***//
/*
 说明:
 location:key值必须含有：latitude、longitude、name
 */
- (void)addAnnotationWithAddressLocation:(NSDictionary*)location;//添加单个位置大头针，地图显示区域受当前定位于大头针所在位置影响
- (void)addAnnotationsWithAddressLocations:(NSMutableArray*)locations;//添加大头针集合，地图显示区域由当前定位决定
//***添加大头针***//


//***导航方法***//
/*
 说明：
 1、可自定义起始位置或使用用户当前定位作为起始位置
 2、可自定义终点位置，当已经使用[addAnnotationWithAddressLocation:]方法时也可用Location作为默认终点，推荐自行定义终点位置
 3、navMapType:0-系统地图，1-高德地图，2-百度地图，设定其他值时默认为0采用系统地图。
 */

- (void)navigateFromCurrentLocationToAnnotationLocationWithMap:(navMapType)map withSuccessBlock:(void(^)(TXLocationModel*location))successBlock andFailureBlock:(void(^)(TXLocationModel *location, NSError *error))failureBlock;//直接使用添加的大头针位置作为终点进行导航返回终点位置，若未添加大头针则导航失败返回失败信息

- (void)navigateFromCurrentLocationToTerminalLocation:(TXLocationModel *)location withMap:(navMapType)map withSuccessBlock:(void(^)(TXLocationModel*location))successBlock andFailureBlock:(void(^)(TXLocationModel *location, NSError *error))failureBlock;//从当前定位地点导航至指定终点

- (void)navigateFromStartLocation:(TXLocationModel *)start toTerminalLocation:(TXLocationModel *)terminal withMap:(navMapType)map withSuccessBlock:(void(^)(TXLocationModel*location))successBlock andFailureBlock:(void(^)(TXLocationModel *location, NSError *error))failureBlock;//从指定起始位置导航至指定终点位置
//***导航方法***//

@end
