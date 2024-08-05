//
//  RenderImageView.m
//  Created by Anton on 3/5/14.
//  Copyright (c) 2014 Incrdbl Mobile Entertainment LLC. All rights reserved.
//

#import "RenderImageView.h"

static NSOperationQueue* renderQueue = nil;

@interface RenderImageView ()
{
    BOOL _needAnimate;
    BOOL _animating;
}

@property (nonatomic,retain) UIImage *drawnImage;

@end

@implementation RenderImageView
@synthesize needAppearanceAnimate = _needAnimate;

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self renderImage];
}

+(void)initialize
{
    renderQueue = [[NSOperationQueue alloc] init];
    [super initialize];
}

- (void)dealloc
{
    [_drawnImage release];
    _drawnImage = nil;
    [_coverImage release];
    _coverImage = nil;
    [super dealloc];
}

-(void)setCoverImage:(UIImage *)coverImage
{
    [_coverImage release];
    _coverImage = [coverImage retain];
    if (_coverImage != nil && _drawnImage == nil) {
        super.image = _coverImage;
    }
}

-(void)setImage:(UIImage *)image {
    self.drawnImage = image;
}

- (UIImage *)image {
    return super.image;
}

-(void)drawImage:(UIImage*)image
{
    self.drawnImage = image;
}

-(void)setDrawnImage:(UIImage *)image
{
    if (image == _drawnImage) {
        return;
    }
    
    [_drawnImage release];
    _drawnImage = [image retain];
    
    self.backgroundColor = [UIColor clearColor];
        
    [self renderImage];
}

-(void)renderImage
{
    if (_drawnImage) {
        
        UIImage* tmpImage = [UIImage imageWithCGImage:_drawnImage.CGImage];
        
        CGRect frame = self.frame;
        
        if (_syncRender) {
            [self drawRenderedImage:[self getRenderedImageForRect:frame image:tmpImage]];
        }else{
            [renderQueue addOperationWithBlock:^{
                UIImage* renderedImage = [self getRenderedImageForRect:frame image:tmpImage];
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self drawRenderedImage:renderedImage];
                }];
            }];
        }
    }else
    {
        super.image = _coverImage;
    }
}

-(void)drawRenderedImage:(UIImage*)renderedImage {
    if (_needAnimate && !_animating) {
        _animating = YES;
        _needAnimate = NO;
        
        [UIView transitionWithView:self
                          duration: _appearanceDuration > 0 ? _appearanceDuration : 0.2
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
            super.image = renderedImage;
        } completion:^(BOOL finished) {
            _animating = NO;
        }];
    }else{
        super.image = renderedImage;
    }
}

-(UIImage*)getRenderedImageForRect:(CGRect)rect image:(UIImage*)image
{
    
    UIImage* resizedImage = image;
    
    float side = MAX(rect.size.width, rect.size.height);
    float imageSide = MAX(image.size.height, image.size.width);
    
    if (side > 0 && imageSide > 4*side) {
        
        CGRect frame = CGRectZero;
        
        if (image.size.height > image.size.width) {
            frame.size.height = side;
            frame.size.width = side*image.size.width/image.size.height;
        }else
        {
            frame.size.width = side;
            frame.size.height = side*image.size.height/image.size.width;
        }
        
        UIGraphicsBeginImageContextWithOptions(frame.size, NO, 0);
        UIGraphicsGetCurrentContext();
        
        [image drawInRect:frame];
        
        resizedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        image = resizedImage;
    }
    
    return image;
}

@end
