//
//  ImageUrlView.m
//  Created by Anton on 2/20/13.
//  Copyright (c) 2013 Incrdbl Mobile Entertainment LLC. All rights reserved.
//

#import "ImageUrlView.h"
#import "ImageLoader.h"

@interface ImageUrlView () <ImageLoaderListener>

@property (nonatomic,retain)UIActivityIndicatorView* activityIndicator;

@end

@implementation ImageUrlView
@synthesize urlStr;
@synthesize activityIndicator;

-(void)dealloc
{
    [ImageLoader removeListener:self];
    
    self.urlStr = nil;
    self.activityIndicator = nil;
    [super dealloc];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.contentMode = UIViewContentModeScaleAspectFill;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.contentMode = UIViewContentModeScaleAspectFill;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.contentMode = UIViewContentModeScaleAspectFill;
    }
    return self;
}

-(void)setUrlStr:(NSString *)urlStr_
{
    if ([urlStr_ isEqualToString:urlStr]) {
        return;
    }
    
    [urlStr release];
    urlStr = [urlStr_ retain];
    
    if (self.activityIndicator) {
        [self.activityIndicator removeFromSuperview];
    }
    
    if (urlStr.length == 0) {
        [self drawImage:nil];
        return;
    }
    
    if (_syncStorageLoad) {
        UIImage* loadedImage = [ImageLoader loadedImage:urlStr];
        if (loadedImage != nil) {
            [self drawImage:loadedImage];
        }else{
            [ImageLoader loadImageUrl:urlStr forListener:self];
        }
    }else{
        [ImageLoader loadImageUrl:urlStr forListener:self];
    }
    
}

-(void)setSyncStorageLoad:(BOOL)syncStorageLoad {
    _syncStorageLoad = syncStorageLoad;
    self.syncRender = _syncStorageLoad;
}

-(void)imageStartLoadingFor:(NSString*)imageUrl
{
    if ([imageUrl isEqualToString:urlStr]) {
        
        [self drawImage:self.coverImage];
        
        if (self.activityIndicator == nil) {
            self.activityIndicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
            activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
        }
        
        activityIndicator.center = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
        [activityIndicator startAnimating];
        [self addSubview:self.activityIndicator];
    }
}

-(void)imageLoadedFor:(NSString*)imageUrl image:(UIImage*)image
{
    if ([imageUrl isEqualToString:urlStr]) {
        
        [ImageLoader removeListener:self];
        
        if (self.activityIndicator) {
            [self.activityIndicator removeFromSuperview];
            self.activityIndicator = nil;
        }
        
        [self drawImage:image];
    }
}

@end
