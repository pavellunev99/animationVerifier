//
//  ImageUrlView.h
//  Created by Anton on 2/20/13.
//  Copyright (c) 2013 Incrdbl Mobile Entertainment LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RenderImageView.h"

@interface ImageUrlView : RenderImageView

@property (nonatomic,retain) NSString* urlStr;
@property (nonatomic,assign) BOOL syncStorageLoad;

@end
