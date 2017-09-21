#ifndef AIRMapCachedTileOverlay_h
#define AIRMapCachedTileOverlay_h

#import <MapKit/MapKit.h>

#import <React/RCTComponent.h>

@class AIRMapCachedTileOverlay;

@interface AIRMapCachedTileOverlay : MKTileOverlay

@property (strong, nonatomic) NSString *tileCachePath;

- (void)clearCache;

@end

#endif /* AIRMapCachedTileOverlay */
