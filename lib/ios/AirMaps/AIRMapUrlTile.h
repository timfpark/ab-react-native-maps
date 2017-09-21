//
//  AIRUrlTileOverlay.h
//  AirMaps
//
//  Created by cascadian on 3/19/16.
//  Copyright © 2016. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <UIKit/UIKit.h>

#import <React/RCTComponent.h>
#import <React/RCTView.h>
#import "AIRMapCoordinate.h"
#import "AIRMap.h"
#import "RCTConvert+AirMap.h"

//RHOM START
#import "AirMapCachedTileOverlay.h"
//RHOM STOP

@interface AIRMapUrlTile : MKAnnotationView <MKOverlay>

@property (nonatomic, weak) AIRMap *map;

//RHOM START
@property (nonatomic, strong) AIRMapCachedTileOverlay *tileOverlay;
//RHOM STOP

@property (nonatomic, strong) MKTileOverlayRenderer *renderer;
@property (nonatomic, copy) NSString *urlTemplate;
@property NSInteger maximumZ;
@property NSInteger minimumZ;
@property BOOL shouldReplaceMapContent;

#pragma mark MKOverlay protocol

@property(nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property(nonatomic, readonly) MKMapRect boundingMapRect;
//- (BOOL)intersectsMapRect:(MKMapRect)mapRect;
- (BOOL)canReplaceMapContent;

@end
