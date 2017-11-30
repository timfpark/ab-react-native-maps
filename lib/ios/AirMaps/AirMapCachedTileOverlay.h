#ifndef AIRMapCachedTileOverlay_h
#define AIRMapCachedTileOverlay_h

#import <MapKit/MapKit.h>

#import <React/RCTComponent.h>

@class AIRMapCachedTileOverlay;

@interface AIRMapCachedTileOverlay : MKTileOverlay <NSURLSessionDownloadDelegate, NSURLSessionTaskDelegate>

@property (strong, nonatomic) NSString *tileCachePath;
@property (strong, nonatomic) NSURLSessionConfiguration *backgroundConfiguration;

- (void)backgroundDownloadTileAtPath:(MKTileOverlayPath)path;
- (void)clearCache;
- (BOOL)haveTileAtPath:(MKTileOverlayPath)path;

@end

#endif /* AIRMapCachedTileOverlay */
