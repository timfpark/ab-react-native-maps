#import "AirMapCachedTileOverlay.h"

#import <MapKit/MapKit.h>
#import <UIKit/UIKit.h>

@implementation AIRMapCachedTileOverlay

#define kMaxCacheItemAge -30 * 24 * 60 * 60

- (instancetype)init
{
    self.backgroundConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"io.rhom.mobile"];
    self.backgroundConfiguration.allowsCellularAccess = YES;

    return [super init];
}

// we clear old cache entries every time we start up.
- (void)clearCache
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSURL *tilePathUrl = [[NSURL alloc] initFileURLWithPath:self.tileCachePath];
        NSArray *keys = [NSArray arrayWithObject:NSURLIsDirectoryKey];

        NSDirectoryEnumerator *enumerator = [fileManager
                                             enumeratorAtURL:tilePathUrl
                                             includingPropertiesForKeys:keys
                                             options:0
                                             errorHandler:^(NSURL *url, NSError *error) {
                                                 NSLog(@"Error building enumerator.");
                                                 return YES;
                                             }];

        for (NSURL *url in enumerator) {
            NSError *error;
            NSNumber *isDirectory = nil;
            if (![url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error]) {
                NSLog(@"Error testing for directory.");
            }
            else if (![isDirectory boolValue]) {
                NSString *path = [url path];
                NSDictionary *attributes = [fileManager attributesOfItemAtPath:path error:nil];

                // NSLog(@"looking at cache path %@: %f", path, [[attributes fileModificationDate] timeIntervalSinceNow]);
                if ([[attributes fileModificationDate] timeIntervalSinceNow] < kMaxCacheItemAge) {
                    NSLog(@"deleting old cache item: %@", path);
                    [fileManager removeItemAtPath:path error:&error];
                }
            }
        }
    });
}

- (void) ensureInitialized {
    NSError *error;
    if (!self.tileCachePath) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        self.tileCachePath = [NSString stringWithFormat:@"%@/tileCache", documentsDirectory];

        if (![[NSFileManager defaultManager] fileExistsAtPath:self.tileCachePath])
            [[NSFileManager defaultManager] createDirectoryAtPath:self.tileCachePath withIntermediateDirectories:NO attributes:nil error:&error];

        [self clearCache];
    }
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    NSString* z = downloadTask.originalRequest.URL.pathComponents[2];
    NSString* x = downloadTask.originalRequest.URL.pathComponents[3];
    NSString* y = downloadTask.originalRequest.URL.pathComponents[4];

    NSString* tileCacheFilePath = [NSString stringWithFormat:@"file://%@/%@/%@/%@", self.tileCachePath, z, x, y];

    [[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL URLWithString:tileCacheFilePath] error:nil];
    NSLog(@"finished caching %@", downloadTask.originalRequest.URL.path);
}

- (BOOL)haveTileAtPath:(MKTileOverlayPath)path {
    NSError *error;

    [self ensureInitialized];

    NSString* tileCacheFileDirectory = [NSString stringWithFormat:@"%@/%d/%d", self.tileCachePath, path.z, path.x];
    if (![[NSFileManager defaultManager] fileExistsAtPath:tileCacheFileDirectory])
        [[NSFileManager defaultManager] createDirectoryAtPath:tileCacheFileDirectory withIntermediateDirectories:YES attributes:nil error:&error];

    NSString* tileCacheFilePath = [NSString stringWithFormat:@"%@/%d", tileCacheFileDirectory, path.y];

    return [[NSFileManager defaultManager] fileExistsAtPath:tileCacheFilePath];
}

typedef void (^tilecallback)(NSData *tileData, NSError *connectionError);

- (void)backgroundDownloadTileAtPath:(MKTileOverlayPath)path {
    [self ensureInitialized];

    NSLog([self URLForTilePath:path].absoluteString);
    NSURLRequest *request = [NSURLRequest requestWithURL:[self URLForTilePath:path]];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:self.backgroundConfiguration delegate:self delegateQueue:nil];
    NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request];

    [task resume];
}

- (void)downloadTileAtPath:(MKTileOverlayPath)path result:(tilecallback)result
{
    [self ensureInitialized];

    NSURLRequest *request = [NSURLRequest requestWithURL:[self URLForTilePath:path]];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:
                                  ^(NSData *data, NSURLResponse *response, NSError *error) {
                                      result(data, error);
                                  }];
    [task resume];
}

- (void)loadTileAtPath:(MKTileOverlayPath)path result:(tilecallback)result
{
    [self ensureInitialized];

    NSError *error;
    NSString* tileCacheFileDirectory = [NSString stringWithFormat:@"%@/%d/%d", self.tileCachePath, path.z, path.x];
    NSString* tileCacheFilePath = [NSString stringWithFormat:@"%@/%d", tileCacheFileDirectory, path.y];

    if (![self haveTileAtPath: path]) {
        NSLog(@"tile cache MISS for %d_%d_%d", path.z, path.x, path.y);
        [self downloadTileAtPath: path result: ^(NSData *data, NSError *error) {
            if (result) result(data, error);
            if (!error) [[NSFileManager defaultManager] createFileAtPath:tileCacheFilePath contents:data attributes:nil];
        }];
    } else {
        NSLog(@"tile cache HIT for %d_%d_%d", path.z, path.x, path.y);

        // If we use a tile, update its modified time so that our cache is purging only unused items.
        if (![[NSFileManager defaultManager] setAttributes:@{NSFileModificationDate:[NSDate date]}
                           ofItemAtPath:tileCacheFilePath
                                  error:&error]) {
            NSLog(@"Couldn't update modification date: %@", error);
        }

        NSData* tile = [NSData dataWithContentsOfFile:tileCacheFilePath];
        if (result) result(tile, nil);
    }
}

@end
