//
//  ValueLabelAttachment.m
//
//  Created by Антон Красильников on 17/10/2018.
//  Copyright © 2018 Incrdbl Mobile Entertainment LLC. All rights reserved.
//

#import "ValueLabelAttachment.h"
#import <ImageLoader.h>
#define ValueLabelLeftAngleBracket @"|langbr|"
#define ValueLabelRightAngleBracket @"|rangbr|"

@interface UIColor (ValueLabel)

+ (UIColor*)valueLabel_colorFromHex:(unsigned)hex;
+ (UIColor *)valueLabel_colorFromHexString:(NSString *)hexString;
- (NSString *)valueLabel_hex;

@end

@implementation UIColor (ValueLabel)

+(UIColor*)valueLabel_colorFromHex:(unsigned)hex
{
    return [UIColor colorWithRed:((float)((hex & 0xFF0000) >> 16))/255.0 \
                           green:((float)((hex & 0x00FF00) >>  8))/255.0 \
                            blue:((float)((hex & 0x0000FF) >>  0))/255.0 \
                           alpha:1.0];
}

+ (UIColor *)valueLabel_colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    
    [scanner setCharactersToBeSkipped:[NSCharacterSet alphanumericCharacterSet].invertedSet];
    
    [scanner scanHexInt:&rgbValue];
    return [self valueLabel_colorFromHex:rgbValue];
}

- (NSString *)valueLabel_hex {
    
    CGFloat r = 0;
    CGFloat g = 0;
    CGFloat b = 0;
    
    [self getRed:&r green:&g blue:&b alpha:NULL];
    
    return [NSString stringWithFormat:@"#%02lX%02lX%02lX",
            lroundf(r * 255),
            lroundf(g * 255),
            lroundf(b * 255)];
}

@end


@interface UIView (ValueLabel)

- (UIImage*)valueLabel_getScreenshot;

@end

@implementation UIView (ValueLabel)

- (UIImage*)valueLabel_getScreenshot
{
    BOOL retina35 = ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] &&
                     ([UIScreen mainScreen].scale >= 2.0));
    CGSize imageSize;
    imageSize.width = self.frame.size.width;
    imageSize.height = self.frame.size.height;
    float delta = 0;
    
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, retina35 ? 0.0 : [UIScreen mainScreen].scale);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect frame = self.frame;
    CGRect oldframe = self.frame;
    frame.origin = CGPointMake(0, 0);
    self.frame = frame;
    
    CGContextSaveGState(context);
    
    CGContextTranslateCTM(context, self.center.x, [self center].y+delta);
    
    CGContextConcatCTM(context, [self transform]);
    
    CGContextTranslateCTM(context,
                          -[self bounds].size.width * [[self layer] anchorPoint].x,
                          -[self bounds].size.height * [[self layer] anchorPoint].y);
    
    [[self layer] renderInContext:context];
    
    CGContextRestoreGState(context);
    UIImage *screenshot = UIGraphicsGetImageFromCurrentImageContext();
    self.frame = oldframe;
    
    UIGraphicsEndImageContext();
    
    return screenshot;
}

@end

@interface ValueLabelAttachment () <ImageLoaderListener>
{
    CGFloat _fontSize;
}
@property (nonatomic,retain) NSString* countTxt;
@property (nonatomic,retain) NSString* additioanalText;
@property (nonatomic,assign) CGFloat fontScale;
@property (nonatomic,assign) CGFloat imageScale;
@property (nonatomic,retain) UIImage* image;
@property (nonatomic,assign) BOOL inner;
@property (nonatomic,retain) NSString* imageUrl;
@property (nonatomic,retain) UIColor* color;

@end

@implementation ValueLabelAttachment

- (void)dealloc
{
    self.valueString = nil;
    self.countTxt = nil;
    self.image = nil;
    self.imageUrl = nil;
    self.color = nil;
    self.font = nil;
    self.additioanalText = nil;
    
    [super dealloc];
}

+(instancetype)scanForAttachment:(NSString*)string inRange:(NSRange)range font:(UIFont *)font
{
    if (string.length == 0) {
        return  nil;
    }
    __block ValueLabelAttachment* attachment = nil;
    
    NSRegularExpression* regex = [[[NSRegularExpression alloc] initWithPattern:@"<.*?>" options:NSRegularExpressionCaseInsensitive error:nil] autorelease];
    
    if (regex != nil) {
        [regex enumerateMatchesInString:string options:NSMatchingReportProgress range:range usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) {
            if (result != nil && result.range.location != NSNotFound) {
                NSRange attrRange = NSMakeRange(result.range.location+1, result.range.length - 2);
                @try {
                    attachment = [self attachmentFromValueString:[string substringWithRange:attrRange] font:font];
                    attachment.range = result.range;
                } @catch (NSException *exception) {
                    attachment = nil;
                } @finally {
                    
                }
                
                *stop = YES;
            }
        }];
    }
    
    return attachment;
}

+(instancetype)attachmentFromValueString:(NSString*)valuStr font:(UIFont*)font
{
    ValueLabelAttachment* attachment = [[self new] autorelease];
    attachment.font = font;
    attachment->_fontSize = font.pointSize;
    
    attachment.valueString =  valuStr;    
    
    return attachment;
}

-(BOOL)empty {
    return
    self.countTxt.length == 0 &&
    self.additioanalText.length == 0 &&
    self.image == nil &&
    self.imageUrl.length == 0;
}

-(void)setValueString:(NSString *)valuStr
{
    if (valuStr == nil || ![_valueString isEqualToString:valuStr]) {
        [_valueString release];
        _valueString = [valuStr retain];
    }
    
    if (_valueString == nil) {
        self.text = nil;
        return;
    }
    /*{
     
    }*/
    // <count=%d,image=%@,url=%@,color=%@,inner=%d,font=%@,fontScale=%f,imageScale=%f,text=%@,color=%@>
    NSRange countRange = [valuStr rangeOfString:@"count="];
    if (countRange.length > 0 && countRange.location + countRange.length < valuStr.length)
    {
        NSString* _txt = [valuStr substringFromIndex:countRange.location + countRange.length];
        NSRange spaceRange = [_txt rangeOfString:@","];
        if (spaceRange.location < valuStr.length) {
            _txt = [_txt substringToIndex:spaceRange.location];
        }
        
        NSScanner* scaner = [NSScanner scannerWithString:_txt];
        
        int value = 0;
        
        if ([scaner scanInt:&value]) {
            self.countTxt = [NSString stringWithFormat:@"%d",value];
        }
    }
    
    NSRange innerRange = [valuStr rangeOfString:@"inner="];
    if (innerRange.length > 0 && innerRange.location + innerRange.length < valuStr.length)
    {
        NSString* _txt = [valuStr substringFromIndex:innerRange.location + innerRange.length];
        NSRange spaceRange = [_txt rangeOfString:@","];
        if (spaceRange.location < valuStr.length) {
            _txt = [_txt substringToIndex:spaceRange.location];
        }
        
        NSScanner* scaner = [NSScanner scannerWithString:_txt];
        
        int value = 0;
        
        if ([scaner scanInt:&value]) {
            _inner = value == 1;
        }
    }
    
    NSRange fontSizeRange = [valuStr rangeOfString:@"fontScale="];
    if (fontSizeRange.length > 0 && fontSizeRange.location + fontSizeRange.length < valuStr.length)
    {
        NSString* _txt = [valuStr substringFromIndex:fontSizeRange.location + fontSizeRange.length];
        NSRange spaceRange = [_txt rangeOfString:@","];
        if (spaceRange.location < valuStr.length) {
            _txt = [_txt substringToIndex:spaceRange.location];
        }
        
        NSScanner* scaner = [NSScanner scannerWithString:_txt];
        
        float value = 0;
        
        if ([scaner scanFloat:&value]) {
            _fontScale = value;
        }
    }
    
    NSRange fontNameRange = [valuStr rangeOfString:@"font="];
    if (fontNameRange.length > 0 && fontNameRange.location + fontNameRange.length < valuStr.length)
    {
        NSString* _txt = [valuStr substringFromIndex:fontNameRange.location + fontNameRange.length];
        NSRange spaceRange = [_txt rangeOfString:@","];
        if (spaceRange.location < valuStr.length) {
            _txt = [_txt substringToIndex:spaceRange.location];
        }
        
        _txt = [_txt stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (_txt.length > 0) {
            UIFont* font = [UIFont fontWithName:_txt size:_fontSize > 0 ? _fontSize : self.font.pointSize];
            if (font != nil) {
                self.font = font;
            }
        }
    }
    
    NSRange imageSizeRange = [valuStr rangeOfString:@"imageScale="];
    if (imageSizeRange.length > 0 && imageSizeRange.location + imageSizeRange.length < valuStr.length)
    {
        NSString* _txt = [valuStr substringFromIndex:imageSizeRange.location + imageSizeRange.length];
        NSRange spaceRange = [_txt rangeOfString:@","];
        if (spaceRange.location < valuStr.length) {
            _txt = [_txt substringToIndex:spaceRange.location];
        }
        
        NSScanner* scaner = [NSScanner scannerWithString:_txt];
        
        float value = 0;
        
        if ([scaner scanFloat:&value]) {
            _imageScale = value;
        }
    }
    
    NSRange imageRange = [valuStr rangeOfString:@"image="];
    if (imageRange.length > 0 && imageRange.location + imageRange.length < valuStr.length)
    {
        NSString* _txt = [valuStr substringFromIndex:imageRange.location + imageRange.length];
        NSRange spaceRange = [_txt rangeOfString:@","];
        if (spaceRange.location < valuStr.length) {
            _txt = [_txt substringToIndex:spaceRange.location];
        }
        self.image = [UIImage imageNamed:[_txt stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    }
    
    NSRange urlRange = [valuStr rangeOfString:@"url="];
    if (urlRange.length > 0 && urlRange.location + urlRange.length < valuStr.length)
    {
        NSString* _txt = [valuStr substringFromIndex:urlRange.location + urlRange.length];
        NSRange spaceRange = [_txt rangeOfString:@","];
        if (spaceRange.location < valuStr.length) {
            _txt = [_txt substringToIndex:spaceRange.location];
        }
        self.imageUrl = [_txt stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    
    NSRange textRange = [valuStr rangeOfString:@"text="];
    if (textRange.length > 0 && textRange.location + textRange.length < valuStr.length)
    {
        NSString* _txt = [valuStr substringFromIndex:textRange.location + textRange.length];
        NSString* endSymbol = @",";
        BOOL quotedString = NO;
        if ([_txt characterAtIndex:0] == '"') {
            endSymbol = @"\",";
            _txt = [valuStr substringFromIndex:textRange.location + textRange.length + 1];
            quotedString = YES;
        }
        NSRange spaceRange = [_txt rangeOfString:endSymbol];
        if (spaceRange.location < valuStr.length) {
            _txt = [_txt substringToIndex:spaceRange.location];
        }else if (quotedString)
        {
            _txt = [_txt substringToIndex:_txt.length - 1];
        }
        self.additioanalText = _txt;
    }
    
    NSRange colorRange = [valuStr rangeOfString:@"color="];
    if (colorRange.length > 0 && colorRange.location + colorRange.length < valuStr.length)
    {
        NSString* _txt = [valuStr substringFromIndex:colorRange.location + colorRange.length];
        NSRange spaceRange = [_txt rangeOfString:@","];
        if (spaceRange.location < valuStr.length) {
            _txt = [_txt substringToIndex:spaceRange.location];
        }
        self.color = [UIColor valueLabel_colorFromHexString:[_txt stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    }
    
    [self draw];
}

-(void)draw
{
    if (_color == nil) {
        //self.color = [UIColor whiteColor];
    }
    
    UIImage* image = nil;
    
    if (_image) {
        image = _image;
    }else if (_imageUrl.length > 0)
    {
        [ImageLoader loadImageUrl:_imageUrl forListener:self];
        return;
    }
    
    if (_font && _fontScale > 0) {
        self.font = [UIFont fontWithName:_font.fontName size:_fontScale*_fontSize];
    }
    
    NSMutableAttributedString* string = [[NSMutableAttributedString new] autorelease];
    
    if (_additioanalText.length > 0) {
        NSMutableDictionary* valueAttrs = [NSMutableDictionary dictionary];
        
        if (_font) {
            [valueAttrs setObject:_font forKey:NSFontAttributeName];
        }
        if (_color) {
            [valueAttrs setObject:_color forKey:NSForegroundColorAttributeName];
        }
        
        NSAttributedString *addString = [[[NSMutableAttributedString alloc] initWithString:[_additioanalText stringByRemovingValueLabelPlaceholders] attributes:valueAttrs] autorelease];
        [string appendAttributedString:addString];
    }
    
    if (!_inner) {
        
        if (_countTxt.length > 0) {
            NSMutableDictionary* valueAttrs = [NSMutableDictionary dictionary];
            
            if (_font) {
                [valueAttrs setObject:_font forKey:NSFontAttributeName];
            }
            if (_color) {
                [valueAttrs setObject:_color forKey:NSForegroundColorAttributeName];
            }
            
            NSAttributedString *valueString = [[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ ",[_countTxt stringByRemovingValueLabelPlaceholders]] attributes:valueAttrs] autorelease];
            [string appendAttributedString:valueString];
        }
        
        if (image) {
            NSTextAttachment *attachment = [[[NSTextAttachment alloc] init] autorelease];
            
            attachment.image = image;
            
            CGSize attachSize = attachment.image.size;
            
            {
                attachSize.height = _font.lineHeight;
                attachSize.width = attachment.image.size.width*_font.lineHeight/attachment.image.size.height;
            }
            
            attachment.bounds = CGRectMake(0, (_font.capHeight - attachSize.height)/2, attachSize.width, attachSize.height);
            
            NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
            
            [string appendAttributedString:attachmentString];
        }
        
    }else if (_image)
    {
        UIImageView* imageView = [[[UIImageView alloc] initWithImage:_image] autorelease];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        CGRect frame = imageView.bounds;
        frame.size.width *= _imageScale > 0 ? 1./_imageScale : 0.7;
        UILabel* valueLabel = [[[UILabel alloc] initWithFrame:frame] autorelease];
        valueLabel.center = CGPointMake(imageView.frame.size.width/2, imageView.frame.size.height/2);
        valueLabel.textAlignment = NSTextAlignmentCenter;
        valueLabel.textColor = _color;
        valueLabel.text = [_countTxt stringByRemovingValueLabelPlaceholders];
        valueLabel.font = _font;
        valueLabel.adjustsFontSizeToFitWidth = YES;
        valueLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        valueLabel.backgroundColor = [UIColor clearColor];
        [imageView addSubview:valueLabel];
        
        UIImage* att_image = [imageView valueLabel_getScreenshot];
        
        NSTextAttachment *attachment = [[[NSTextAttachment alloc] init] autorelease];
        
        attachment.image = att_image;
        
        CGSize attachmentSize = att_image.size;
        
        if (attachmentSize.height > _font.lineHeight) {
            attachmentSize.height = _font.lineHeight;
            attachmentSize.width = att_image.size.width * _font.lineHeight/att_image.size.height;
        }
        
        attachment.bounds = CGRectMake(0, (_font.capHeight - attachmentSize.height)/2, attachmentSize.width, attachmentSize.height);
        
        NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
        
        [string appendAttributedString:attachmentString];
    }
    
    self.text = string;
}

-(void)imageLoadedFor:(NSString*)imageUrl image:(UIImage*)image
{
    if (image != nil) {
        self.image = image;
        [self draw];
    }
    [ImageLoader removeListener:self forImageUrl:imageUrl];
}

@end

@implementation NSString (ValueLabel)

-(NSString*)stringByRemovingValueLabelPlaceholders {
    return [[self stringByReplacingOccurrencesOfString:ValueLabelLeftAngleBracket withString:@"<"] stringByReplacingOccurrencesOfString:ValueLabelRightAngleBracket withString:@">"];
}

-(NSString*)stringWithValueLabelPlaceholders {
    return [[self stringByReplacingOccurrencesOfString:@"\\<" withString:ValueLabelLeftAngleBracket] stringByReplacingOccurrencesOfString:@"\\>" withString:ValueLabelRightAngleBracket];
}

@end
