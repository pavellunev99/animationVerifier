//
//  ImageLoader.m
//  Created by Anton on 20/03/15.
//  Copyright (c) 2015 Incrdbl Mobile Entertainment LLC. All rights reserved.
//

#import "ImageLoader.h"
#import <INCR_RestClient.h>
#import <UIKit/UIKit.h>

#define IMAGE_CASH_DICTIONARY @"CASHEDIMAGES"

#define MAX_LOADING_COUNT 5
#define MAX_IMAGE_CASH_COUNT 50
#define MAX_CASH_WEIGHT 2097152

typedef enum
{
    IMAGE_START_LOADING_NOTIFY = 0,
    IMAGE_LOADED_NOTIFY
}NotifyTaskType;

static ImageLoader* loader = nil;

BOOL AddSkipBackupAttributeToItemAtURL(NSString* URLstr)
{
    NSURL* URL = [NSURL fileURLWithPath:URLstr];
    BOOL success = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath: [URL path]]) {
        NSError *error = nil;
        
        success = [URL setResourceValue: [NSNumber numberWithBool: YES]
                   
                                 forKey: NSURLIsExcludedFromBackupKey error: &error];
        
        if(!success){
            
            NSLog(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
        }
    }
    
    return success;
}


@implementation CachedImage
@synthesize data;

- (void)dealloc
{
    self.url = nil;
    self.data = nil;
    self.image = nil;
    
    [super dealloc];
}

-(void)setData:(NSData *)data_
{
    @synchronized (self) {
        [data release];
        data = [data_ retain];
        if (data) {
            self.length = data.length;
        }
    }
}

-(NSData *)data
{
    @synchronized (self) {
        return data;
    }
}

-(void)readStoredData
{
    if (self.url.length == 0) {
        return;
    }
    
    NSString* urlStr = [NSString stringWithString:_url];
    
    NSData* _data = [CachedImage storedDataFor:urlStr];
    
    self.data = _data;
    
}

+(NSData*)storedDataFor:(NSString*)urlStr
{
    NSString *pdataPath = [CachedImage imagesDirectoryPath];
    if (![[NSFileManager defaultManager] fileExistsAtPath:pdataPath]) {
        return nil;
    }
    
    pdataPath = [pdataPath stringByAppendingFormat:@"/%lu",(unsigned long)[urlStr hash]];
    NSData* data = [NSData dataWithContentsOfFile:pdataPath];
    return data;
}

-(void)storeImageDataWithCompletionHandler:(void (^)(BOOL))handler
{
    if (self.url.length == 0 || self.data.length == 0) {
        if (handler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(NO);
            });
        }
        return;
    }
    
    if ([CachedImage isImageStoredFor:self.url]) {
        if (handler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(YES);
            });
        }
        return;
    }
    
    NSString* urlStr = [NSString stringWithString:_url];
    NSData* imageData = [NSData dataWithData:self.data];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        @autoreleasepool {
            
            if (![UIImage imageWithData:imageData]) {
                if (handler) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        handler(NO);
                    });
                }
                return;
            }
            
            NSString *pdataPath = [CachedImage imagesDirectoryPath];
            if (![[NSFileManager defaultManager] fileExistsAtPath:pdataPath]) {
                [[NSFileManager defaultManager] createDirectoryAtPath:pdataPath withIntermediateDirectories:NO attributes:nil error:nil];
            }
            pdataPath = [pdataPath stringByAppendingFormat:@"/%lu",(unsigned long)[urlStr hash]];
            [imageData writeToFile:pdataPath atomically:YES];
            
            AddSkipBackupAttributeToItemAtURL(pdataPath);
            
            if (handler) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(YES);
                });
            }
        }
    });
}

+(BOOL)isImageStoredFor:(NSString*)urlStr
{
    NSString *pdataPath = [CachedImage imagesDirectoryPath];
    pdataPath = [pdataPath stringByAppendingFormat:@"/%lu",(unsigned long)[urlStr hash]];
    
    return [[NSFileManager defaultManager] fileExistsAtPath:pdataPath];
}

+(NSString*)imagesDirectoryPath
{
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    return [rootPath stringByAppendingPathComponent:IMAGE_CASH_DICTIONARY];
}

@end

@interface ImageLoader ()
{
    NSUInteger _cashSize;
}
@property (nonatomic,retain) NSMutableDictionary* listeners;
@property (nonatomic,retain) NSMutableArray* imageCashArray;
@property (nonatomic,retain) NSMutableArray* imageToLoadArray;
@property (nonatomic,retain) NSMutableArray* imageInLoadingArray;
@property (nonatomic,retain) NSOperationQueue* loaderQueue;

@end

@implementation ImageLoader


+(void)loadImageUrl:(NSString*)imageUrl forListener:(id<ImageLoaderListener>)listener
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        loader = [[ImageLoader alloc] init];
    });

    [loader loadImageUrl:imageUrl forListener:listener];
}

+(void)removeListener:(id<ImageLoaderListener>)listener
{
    if (loader && listener) {
        [loader removeListener:listener];
    }
}

+(void)removeListener:(id<ImageLoaderListener>)listener forImageUrl:(NSString*)imageUrl
{
    if (loader && listener) {
        [loader removeListener:listener forImageUrl:imageUrl];
    }
}

+(UIImage*)cachedImage:(NSString*)imageUrl {
    return [loader cachedImageDataForUrl:imageUrl].image;
}

+(UIImage*)loadedImage:(NSString*)imageUrl {
    CachedImage* cachedImage = [loader cachedImageDataForUrl:imageUrl];
    if (cachedImage.image == nil) {
        cachedImage = [[CachedImage new] autorelease];
        cachedImage.url = imageUrl;
        [cachedImage readStoredData];
        if (cachedImage.data != nil) {
            cachedImage.image = [UIImage imageWithData:cachedImage.data];
        }
        [loader renewCacheWith:cachedImage];
    }
    return cachedImage.image;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(memoryWarningAction) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        self.listeners = [NSMutableDictionary dictionary];
        self.imageCashArray = [NSMutableArray array];
        self.imageToLoadArray = [NSMutableArray array];
        self.imageInLoadingArray = [NSMutableArray array];
        self.loaderQueue = [[[NSOperationQueue alloc] init] autorelease];
        _loaderQueue.maxConcurrentOperationCount = MAX_LOADING_COUNT;
    }
    return self;
}

- (void)dealloc
{
    self.listeners = nil;
    self.imageCashArray = nil;
    self.imageInLoadingArray = nil;
    self.imageToLoadArray = nil;
    
    [self.loaderQueue cancelAllOperations];
    self.loaderQueue = nil;
    [super dealloc];
}

-(void)memoryWarningAction
{
    [self.imageCashArray removeAllObjects];
    _cashSize = 0;
}

-(void)loadImageUrl:(NSString*)imageUrl forListener:(id<ImageLoaderListener>)listener
{
    if (listener) {
        
        [self addListener:listener forUrl:imageUrl];
        
        CachedImage* cachedImage = [self cachedImageDataForUrl:imageUrl];
        if (cachedImage.image != nil) {
            [self notifyListenerFor:cachedImage forTsk:IMAGE_LOADED_NOTIFY];
        }else
        {
            CachedImage* imageToLoad = [[[CachedImage alloc] init] autorelease];
            imageToLoad.url = imageUrl;
            
            BOOL imageAlreadyInLoad = NO;
            
            for (CachedImage* _image in self.imageToLoadArray) {
                if ([_image.url isEqualToString:imageUrl]) {
                    imageAlreadyInLoad = YES;
                    break;
                }
            }
            
            if (!imageAlreadyInLoad) {
                [self.imageToLoadArray addObject:imageToLoad];
                [self notifyListenerFor:imageToLoad forTsk:IMAGE_START_LOADING_NOTIFY];
                
                [self taskUpdate];
            }else
            {
                if ([listener respondsToSelector:@selector(imageStartLoadingFor:)]) {
                    [listener imageStartLoadingFor:cachedImage.url];
                }
            }
        }
    }
}

-(void)addListener:(id<ImageLoaderListener>)listener forUrl:(NSString*)urlStr
{
    if (urlStr.length > 0 && listener != nil) {
        NSArray* urlListeners = [_listeners objectForKey:urlStr];
        if (urlListeners.count > 0) {
            if (![urlListeners containsObject:listener]) {
                NSMutableArray* _newUrlListeners = [NSMutableArray arrayWithArray:urlListeners];
                [_newUrlListeners addObject:listener];
                [_listeners setObject:[NSArray arrayWithArray:_newUrlListeners] forKey:urlStr];
            }
        }else
        {
            [_listeners setObject:[NSArray arrayWithObject:listener] forKey:urlStr];
        }
    }
    
}

-(void)removeListener:(id<ImageLoaderListener>)listener
{
    NSArray* keys = [NSArray arrayWithArray:[_listeners allKeys]];
    for (id key in keys) {
        NSArray* listenersArray = [_listeners objectForKey:key];
        
        if ([listenersArray isKindOfClass:[NSArray class]]) {

            if ([listenersArray containsObject:listener]) {
                NSMutableArray* _newListenersArray = [NSMutableArray arrayWithArray:listenersArray];
                [_newListenersArray removeObject:listener];
                if (_newListenersArray.count > 0) {
                    [_listeners setObject:[NSArray arrayWithArray:_newListenersArray] forKey:key];
                }else
                {
                    [_listeners removeObjectForKey:key];
                }
            }
        }
    }
}

-(void)removeListener:(id<ImageLoaderListener>)listener forImageUrl:(NSString*)imageUrl
{
    if (imageUrl.length > 0) {
        NSArray* listenersArray = [_listeners objectForKey:imageUrl];
        
        if ([listenersArray isKindOfClass:[NSArray class]]) {
            
            if ([listenersArray containsObject:listener]) {
                NSMutableArray* _newListenersArray = [NSMutableArray arrayWithArray:listenersArray];
                [_newListenersArray removeObject:listener];
                if (_newListenersArray.count > 0) {
                    [_listeners setObject:[NSArray arrayWithArray:_newListenersArray] forKey:imageUrl];
                }else
                {
                    [_listeners removeObjectForKey:imageUrl];
                }
            }
        }
    }

}

-(NSArray*)listenersFor:(CachedImage*)cachedImage
{
    if (cachedImage.url.length > 0) {
        NSArray* imgListeners = [_listeners objectForKey:cachedImage.url];
        return imgListeners.count > 0 ? [NSArray arrayWithArray:imgListeners] : nil;
    }
    return nil;
}

-(void)notifyListenerFor:(CachedImage*)cachedImage forTsk:(NotifyTaskType)taskType
{
    if (cachedImage.url.length > 0) {
        NSArray* imageListeners = [self listenersFor:cachedImage];
        for (id<ImageLoaderListener> listener in imageListeners) {
            switch (taskType) {
                case IMAGE_START_LOADING_NOTIFY:
                {
                    if ([listener respondsToSelector:@selector(imageStartLoadingFor:)]) {
                        [listener imageStartLoadingFor:cachedImage.url];
                    }
                }
                    break;
                case IMAGE_LOADED_NOTIFY:
                {
                    if ([listener respondsToSelector:@selector(imageLoadedFor:image:)]) {
                        [listener imageLoadedFor:cachedImage.url image:cachedImage.image];
                    }
                }
                    break;
                default:
                    break;
            }
            
        }
    }
}

-(void)taskUpdate
{
    if (self.imageInLoadingArray.count < MAX_LOADING_COUNT && self.imageToLoadArray.count > 0) {
        
        CachedImage* nextOneImage = [self.imageToLoadArray lastObject];
        [self.imageInLoadingArray addObject:nextOneImage];
        [self.imageToLoadArray removeObject:nextOneImage];
        
        NSOperation* loadingOperation = nil;
        
        if ([CachedImage isImageStoredFor:nextOneImage.url]) {
            loadingOperation = [[[NSInvocationOperation alloc] initWithTarget:nextOneImage selector:@selector(readStoredData) object:nil] autorelease];
            
        }else
        {
            loadingOperation = [[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(syncLoad:) object:nextOneImage] autorelease];
        }
        
        loadingOperation.completionBlock = ^(){
            
            if (nextOneImage.data != nil) {
                nextOneImage.image = [UIImage imageWithData:nextOneImage.data];
            }
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [self handleLoadedImage:nextOneImage];
            }];
            
        };
        [self.loaderQueue addOperation:loadingOperation];
        
    }
}

-(void)syncLoad:(CachedImage*)nextOneImage
{
    nextOneImage.data = [INCR_RestClient syncLoad:nextOneImage.url];
}

-(CachedImage*)cachedImageDataForUrl:(NSString*)imageUrl
{
    CachedImage* foundImage = nil;
    for (CachedImage* cachedImage in _imageCashArray) {
        if ([cachedImage.url isEqualToString:imageUrl]) {
            foundImage = cachedImage;
            break;
        }
    }
    if (foundImage != nil) {
        [foundImage retain];
        [_imageCashArray removeObject:foundImage];
        [_imageCashArray insertObject:foundImage atIndex:0];
        [foundImage release];
    }
    return foundImage;
}

-(void)handleLoadedImage:(CachedImage*)cachedImage
{
    [self renewCacheWith:cachedImage];
    
    [self notifyListenerFor:cachedImage forTsk:IMAGE_LOADED_NOTIFY];
    
    [cachedImage storeImageDataWithCompletionHandler:^(BOOL success) {
        cachedImage.data = nil;
        [self.imageInLoadingArray removeObject:cachedImage];
        [self taskUpdate];
    }];
}

-(void)renewCacheWith:(CachedImage*)cachedImage {
    if (cachedImage.url.length > 0 && cachedImage.data.length > 0) {
        if (![self.imageCashArray containsObject:cachedImage]) {
            if (self.imageCashArray.count > MAX_IMAGE_CASH_COUNT || _cashSize > MAX_CASH_WEIGHT) {
                CachedImage* imageToRemove = [self.imageCashArray lastObject];
                _cashSize -= imageToRemove.length;
                [self.imageCashArray removeLastObject];
            }
        }else
        {
            _cashSize -= cachedImage.length;
            [self.imageCashArray removeObject:cachedImage];
        }
        
        [self.imageCashArray insertObject:cachedImage atIndex:0];
        _cashSize += cachedImage.length;
    }
}



@end
