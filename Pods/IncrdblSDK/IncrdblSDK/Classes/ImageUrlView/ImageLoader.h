//
//  ImageLoader.h
//  Created by Anton on 20/03/15.
//  Copyright (c) 2015 Incrdbl Mobile Entertainment LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class UIImage;

@interface CachedImage : NSObject

@property (retain) NSString*    url;
@property (retain) NSData*      data;
@property (retain) UIImage*     image;
@property (assign) NSUInteger   length;

+(NSString*)imagesDirectoryPath;
+(BOOL)isImageStoredFor:(NSString*)urlStr;
+(NSData*)storedDataFor:(NSString*)urlStr;
-(void)storeImageDataWithCompletionHandler:(void (^)(BOOL))handler;

@end

@protocol ImageLoaderListener <NSObject>
@optional
-(void)imageLoadedFor:(NSString*)imageUrl image:(UIImage*)image;
-(void)imageStartLoadingFor:(NSString*)imageUrl;

@end

@interface ImageLoader : NSObject

+(void)loadImageUrl:(NSString*)imageUrl forListener:(id<ImageLoaderListener>)listener;
+(void)removeListener:(id<ImageLoaderListener>)listener;
+(void)removeListener:(id<ImageLoaderListener>)listener forImageUrl:(NSString*)imageUrl;
+(UIImage*)cachedImage:(NSString*)imageUrl; // image from RAM cache
+(UIImage*)loadedImage:(NSString*)imageUrl; // image from RAM & disk cache

@end
