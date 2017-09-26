//
//  TXMapView.m
//  BaiChuan
//
//  Created by 童煊 on 2017/9/7.
//  Copyright © 2017年 Samu33. All rights reserved.
//

#import "TXMapView.h"
#import "TXUserLocationAnnotationView.h"

@interface TXMapView ()


//自定义大头针
@property (nonatomic, strong) TXUserLocationAnnotation *userLocationAnnotation;
//保存大头针位置信息
@property (nonatomic, strong) NSMutableDictionary *annoLocationDic;


//导航属性
@property (nonatomic, assign, readwrite) navMapType mapType;//导航类型（目前只支持跳转外接导航app）默认系统原生导航

@property (nonatomic, strong) CLGeocoder *geocoder;//地理编码解码
@property (nonatomic, strong) MKMapItem *startLocation;//起始位置
@property (nonatomic, strong) MKMapItem *terminalLoction;//终点位置

//***系统导航 导航功能模块
- (void)navByTerminal:(TXLocationModel*)terminal withCoordinate:(CLLocationCoordinate2D)coordinate withSuccessBlock:(void(^)(TXLocationModel*location))successBlock andFailureBlock:(void(^)(TXLocationModel *location, NSError *error))failureBlock;//系统导航：通过经纬度导航
- (void)navByTerminal:(TXLocationModel*)terminal withName:(NSString*)name withSuccessBlock:(void(^)(TXLocationModel*location))successBlock andFailureBlock:(void(^)(TXLocationModel *location, NSError *error))failureBlock;//系统导航：通过地理名称

@end

@implementation TXMapView

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self loadConfiguration];
        [self loadMapView];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateLocation) name:kUserLocationUpdateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateHeading) name:KUserHeadingUpdateNotification object:nil];
    }
    return self;
}

- (void)loadConfiguration{
    self.geocoder = [[CLGeocoder alloc]init];
    self.mapType = navMapTypeAPL;
    self.annoLocationDic = nil;
}

- (void)loadMapView{
    self.backgroundColor = [UIColor clearColor];
    
    self.mapView = [[MKMapView alloc]initWithFrame:self.frame];
    
    self.mapView.userTrackingMode = MKUserTrackingModeFollow;
    self.mapView.mapType = MKMapTypeStandard;
    self.mapView.delegate = self;
    
    self.mapView.showsUserLocation = YES;
    [self addSubview:self.mapView];
    
    
    NSDictionary *location = [[TXLocationManager sharedManager] getLocationSignal];
    [self.mapView setRegion:MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2DMake([[location valueForKey:@"latitude"] doubleValue], [[location valueForKey:@"longitude"] doubleValue]), 2000, 2000) animated:YES];
    
}

- (void)addAnnotationWithAddressLocation:(NSDictionary*)location{
    if (location!=nil) {
        self.annoLocationDic = [location mutableCopy];//保存大头针位置，用于导航终点

        MKPointAnnotation *annotation = [[MKPointAnnotation alloc]init];
        [annotation setCoordinate:CLLocationCoordinate2DMake([[location valueForKey:@"latitude"] doubleValue], [[location valueForKey:@"longitude"] doubleValue])];
        [annotation setTitle:[location valueForKey:@"name"]];
        [self.mapView addAnnotation:annotation];
        [self.mapView selectAnnotation:annotation animated:YES];//自动显示大头针title内容
        
        
        
        //计算用户与标记位置之间的经纬度中间值，以及距离，设定地图自动以其作为中心点显示
        NSDictionary *userlocation = [[TXLocationManager sharedManager] getLocationSignalOnce];
        NSLog(@"userlocation:%@",userlocation);
        double centerLati = 0;
        if ([[userlocation valueForKey:@"latitude"] doubleValue] > [[location valueForKey:@"latitude"] doubleValue]) {
            centerLati = ([[userlocation valueForKey:@"latitude"] doubleValue]-[[location valueForKey:@"latitude"] doubleValue])/2 + [[location valueForKey:@"latitude"] doubleValue];
        }else{
            centerLati = ([[location valueForKey:@"latitude"] doubleValue]-[[userlocation valueForKey:@"latitude"] doubleValue])/2 + [[userlocation valueForKey:@"latitude"] doubleValue];
        }

        double centerLong =0 ;
        if ([[userlocation valueForKey:@"longitude"] doubleValue] > [[location valueForKey:@"longitude"] doubleValue]) {
            centerLong = ([[userlocation valueForKey:@"longitude"] doubleValue]-[[location valueForKey:@"longitude"] doubleValue])/2 + [[location valueForKey:@"longitude"] doubleValue];
        }else{
            centerLong = ([[location valueForKey:@"longitude"] doubleValue]-[[userlocation valueForKey:@"longitude"] doubleValue])/2 + [[userlocation valueForKey:@"longitude"] doubleValue];
        }


//        CLLocation *orig= [[CLLocation alloc] initWithLatitude:[[userlocation valueForKey:@"latitude" ] doubleValue]  longitude:[[userlocation valueForKey:@"longitude" ] doubleValue]];
//        CLLocation* dist= [[CLLocation alloc] initWithLatitude:[[location valueForKey:@"latitude" ] doubleValue] longitude:[[userlocation valueForKey:@"longitude" ] doubleValue]];
//
//        CLLocationDistance kilometers = [orig distanceFromLocation:dist]/1000;
//        NSLog(@"距离%f:",kilometers);
        CLLocationDistance kilometers = [[TXLocationManager sharedManager] distanceFromLocation:nil toLocation:location];
        NSInteger distance = 5000;
        if (kilometers<1) {
            distance = 1500;
        }else{
            distance = (NSInteger)kilometers*1000*2;
        }
        [self.mapView setRegion:MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2DMake(centerLati, centerLong), distance, distance) animated:YES];
        
    }
}

- (void)addAnnotationsWithAddressLocations:(NSMutableArray*)locations{
    if (locations != nil) {
        for (NSDictionary *location in locations) {
            MKPointAnnotation *annotation = [[MKPointAnnotation alloc]init];
            [annotation setCoordinate:CLLocationCoordinate2DMake([[location valueForKey:@"latitude"] doubleValue], [[location valueForKey:@"longitude"] doubleValue])];
            [annotation setTitle:[location valueForKey:@"name"]];
            [self.mapView addAnnotation:annotation];
        }
    }
}

#pragma mark - navigate

- (void)navigateFromCurrentLocationToAnnotationLocationWithMap:(navMapType)map withSuccessBlock:(void(^)(TXLocationModel*location))successBlock andFailureBlock:(void(^)(TXLocationModel *location, NSError *error))failureBlock{
    [self navigateFromStartLocation:nil toTerminalLocation:nil withMap:map withSuccessBlock:successBlock andFailureBlock:failureBlock];
}
- (void)navigateFromCurrentLocationToTerminalLocation:(TXLocationModel *)location withMap:(navMapType)map withSuccessBlock:(void(^)(TXLocationModel*location))successBlock andFailureBlock:(void(^)(TXLocationModel *location, NSError *error))failureBlock{
    [self navigateFromStartLocation:nil toTerminalLocation:location withMap:map withSuccessBlock:successBlock andFailureBlock:failureBlock];
}


- (void)navigateFromStartLocation:(TXLocationModel *)start toTerminalLocation:(TXLocationModel *)terminal withMap:(navMapType)map withSuccessBlock:(void(^)(TXLocationModel*location))successBlock andFailureBlock:(void(^)(TXLocationModel *location, NSError *error))failureBlock{
    if (start) {
        self.startLocation = [[MKMapItem alloc]initWithPlacemark:[[MKPlacemark alloc] initWithCoordinate:start.coordinate]];
    }else{
        self.startLocation = [MKMapItem mapItemForCurrentLocation];
    }
    
    CLLocationCoordinate2D coordinate;
    if (terminal.latitude.length>0&&terminal.longitude.length>0) {
        coordinate = terminal.coordinate;
    }else {
        coordinate = CLLocationCoordinate2DMake([[self.annoLocationDic valueForKey:@"latitude"] doubleValue], [[self.annoLocationDic valueForKey:@"longitude"] doubleValue]);
    }
    NSLog(@"terminal coordinate:%.8f %.8f",coordinate.latitude,coordinate.longitude);
    if (map<navMapTypeAPL||map>navMapTypeBaiduMap) {
        map = self.mapType;
    }
    switch (map) {
            //使用系统地图导航
        case navMapTypeAPL:
            [self navByTerminal:terminal withCoordinate:coordinate withSuccessBlock:successBlock andFailureBlock:failureBlock];
            break;
        case navMapTypeAMap:
        {
            //判断是否安装了高德地图，如果安装了高德地图，则使用高德地图导航
            if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"iosamap://"]]) {
                NSString *urlsting =[[NSString stringWithFormat:@"iosamap://navi?sourceApplication=%@&backScheme= &lat=%f&lon=%f&dev=0&style=2",AppBundleName,coordinate.latitude,coordinate.longitude]stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                
                if ([[UIDevice currentDevice].systemVersion integerValue] >= 10) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlsting] options:@{} completionHandler:^(BOOL success) {
                        if (successBlock) {
                            successBlock(terminal);
                        }
                    }];
                }else{
                    [[UIApplication  sharedApplication]openURL:[NSURL URLWithString:urlsting]];
                    if (successBlock) {
                        successBlock(terminal);
                    }
                }
            }else{
                //未安装返回，执行failureBlock
                if (failureBlock) {
                    failureBlock(terminal,nil);
                }
            }
        }
            break;
        case navMapTypeBaiduMap:
        {
            //判断是否安装了百度地图，如果安装了百度地图，则使用百度地图导航
            if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"baidumap://"]]) {
                NSString *urlsting =[[NSString stringWithFormat:@"baidumap://map/direction?origin={{我的位置}}&destination=latlng:%f,%f|name=目的地&mode=driving&coord_type=gcj02",coordinate.latitude,coordinate.longitude] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                if ([[UIDevice currentDevice].systemVersion integerValue] >= 10) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlsting] options:@{} completionHandler:^(BOOL success) {
                        if (successBlock) {
                            successBlock(terminal);
                        }
                    }];
                }else{
                    [[UIApplication  sharedApplication]openURL:[NSURL URLWithString:urlsting]];
                    if (successBlock) {
                        successBlock(terminal);
                    }
                }
            }else{
                //未安装返回，执行failureBlock
                if (failureBlock) {
                    failureBlock(terminal,nil);
                }
            }
        }
            break;
        default:
            [self navByTerminal:terminal withCoordinate:coordinate withSuccessBlock:successBlock andFailureBlock:failureBlock];
            break;
    }
    
}

- (void)navByTerminal:(TXLocationModel*)terminal withCoordinate:(CLLocationCoordinate2D)coordinate withSuccessBlock:(void(^)(TXLocationModel*location))successBlock andFailureBlock:(void(^)(TXLocationModel *location, NSError *error))failureBlock{
    
/* 反编码地址定位不准确，暂未解决
 WEAKSELF
    [self.geocoder reverseGeocodeLocation:[[CLLocation alloc] initWithLatitude:coordinate.latitude  longitude:coordinate.longitude] completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        STRONGSELF
        if (error) {
            NSLog(@"geocoder coordinate error:%@\n try nav with location name ",error);
            NSString *name;
            if (terminal.name.length>0) {
                name = terminal.name;
            }else{
                name = [strongSelf.annoLocationDic valueForKey:@"name"];
            }
            [strongSelf navByTerminal:terminal withName:name withSuccessBlock:successBlock andFailureBlock:failureBlock];
        }else{
            strongSelf.terminalLoction = [[MKMapItem alloc]initWithPlacemark:[[MKPlacemark alloc]initWithPlacemark:[placemarks firstObject]]];
            NSLog(@"terminalLocation:%@",strongSelf.terminalLoction);
            [MKMapItem openMapsWithItems:@[strongSelf.startLocation,strongSelf.terminalLoction] launchOptions:@{MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving,MKLaunchOptionsShowsTrafficKey:[NSNumber numberWithBool:YES]}];
            if (successBlock) {
                successBlock(terminal);
            }
        }
        
    }];
*/
    NSString *name;
    if (terminal.name.length>0) {
        name = terminal.name;
    }else{
        name = [self.annoLocationDic valueForKey:@"name"];
    }

    self.terminalLoction = [[MKMapItem alloc]initWithPlacemark:[[MKPlacemark alloc]initWithCoordinate:coordinate]];
    self.terminalLoction.name = name;
    NSLog(@"terminalLocation:%@",self.terminalLoction);
    if (self.terminalLoction != nil) {
        [MKMapItem openMapsWithItems:@[self.startLocation,self.terminalLoction] launchOptions:@{MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving,MKLaunchOptionsShowsTrafficKey:[NSNumber numberWithBool:YES]}];
        if (successBlock) {
            successBlock(terminal);
        }
    }else{
        NSLog(@"geocoder coordinate failed try nav with location name ");
        [self navByTerminal:terminal withName:name withSuccessBlock:successBlock andFailureBlock:failureBlock];
    }

}

- (void)navByTerminal:(TXLocationModel*)terminal withName:(NSString*)name withSuccessBlock:(void(^)(TXLocationModel*location))successBlock andFailureBlock:(void(^)(TXLocationModel *location, NSError *error))failureBlock{
    //通过地理名称获取经纬度位置信息，进行导航
    WEAKSELF
    [self.geocoder geocodeAddressString:name completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        STRONGSELF
        if (error) {
            NSLog(@"geocoder name error:%@\n fail to nav",error);
            if (failureBlock) {
                failureBlock(terminal,error);
            }
        }else{
            strongSelf.terminalLoction = [[MKMapItem alloc]initWithPlacemark:[[MKPlacemark alloc]initWithPlacemark:[placemarks firstObject]]];
            NSLog(@"terminalLocation:%@",strongSelf.terminalLoction);
            [MKMapItem openMapsWithItems:@[strongSelf.startLocation,strongSelf.terminalLoction] launchOptions:@{MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving,MKLaunchOptionsShowsTrafficKey:[NSNumber numberWithBool:YES]}];
            if (successBlock) {
                successBlock(terminal);
            }
        }
    }];
    
}


#pragma mark - MKMapViewDelegate

- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView{
    self.mapView.showsCompass = YES;
    self.mapView.showsBuildings = YES;
    self.mapView.showsTraffic = YES;
    
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation NS_AVAILABLE(10_9, 4_0){
    //    NSLog(@"heading:%@ location:%@",userLocation.heading,userLocation.location);
    if(self.userLocationAnnotation == nil){
        self.userLocationAnnotation = [[TXUserLocationAnnotation alloc]initLocationAnnotationWithCoordinate:self.mapView.userLocation.location.coordinate andHeading:0.0];
        [self.userLocationAnnotation setTitle:@"我的位置"];
        [self.mapView addAnnotation:self.userLocationAnnotation];
    }
    self.userLocationAnnotation.coordinate = userLocation.location.coordinate;
}

- (nullable MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation{
    
    if ([annotation isKindOfClass:[TXUserLocationAnnotation class]]) {
        TXUserLocationAnnotationView *annotationView = nil;
        if (annotationView == nil) {
            annotationView = [[TXUserLocationAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:@"TXUserLocationAnnotationView"];
        }
        return annotationView;
    }
    else if([annotation isKindOfClass:[MKPointAnnotation class]])
    {
        MKPinAnnotationView *annotationView = nil;
        if (annotationView == nil)
        {
            annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:nil];
        }
        annotationView.pinColor = MKPinAnnotationColorRed;
        
        annotationView.canShowCallout= YES;       //设置气泡可以弹出，默认为NO
        annotationView.animatesDrop = NO;        //设置标注动画显示，默认为NO
        annotationView.draggable = YES;        //设置标注可以拖动，默认为NO
        
        return annotationView;
    }
    
    return nil;
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray<MKAnnotationView *> *)views{
    MKAnnotationView *userAV = [mapView viewForAnnotation:mapView.userLocation];
    userAV.hidden = YES;
}

//地图覆盖物的代理方法 绘制路径

-(MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay{
    
    MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
    
    
    
    renderer.strokeColor = AppBaseViewStyleColor;
    
    
    
    renderer.lineWidth = 8.0;
    
    
    
    return  renderer;
    
}


#pragma mark - KUserHeadingUpdateNotification
- (void)updateHeading{
    //    NSLog(@"get trueHeading:%f",[[[[TXLocationManager sharedManager] getHeadingSignal] valueForKey:@"trueHeading"] floatValue]);
    self.userLocationAnnotation.heading = [[[[TXLocationManager sharedManager] getHeadingSignal] valueForKey:@"trueHeading"] floatValue];
}

#pragma mark - kUserLocationUpdateNotification
- (void)updateLocation{
//    NSDictionary *location = [[TXLocationManager sharedManager] getLocationSignal];
    //    NSLog(@"get location:%@",location);
    //    self.userLocationAnnotation.coordinate = CLLocationCoordinate2DMake([[location valueForKey:@"latitude"] doubleValue], [[location valueForKey:@"longitude"] doubleValue]);
}



@end
