//
//  RenderImageView.h
//  Created by Anton on 3/5/14.
//  Copyright (c) 2014 Incrdbl Mobile Entertainment LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RenderImageView : UIImageView

@property (nonatomic,retain) UIImage *coverImage;
@property (nonatomic,assign) BOOL     needAppearanceAnimate;
@property (nonatomic,assign) NSTimeInterval appearanceDuration; // default 0.2
@property (nonatomic,assign) BOOL     syncRender;

-(void)drawImage:(UIImage*)image;

@end
