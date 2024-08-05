//
//  UILabel.m
//  wordByWord2
//
//  Created by Антон Красильников on 20/05/16.
//  Copyright © 2016 Incrdbl Mobile Entertainment LLC. All rights reserved.
//

#import "UILabel+html.h"

NSString* const kNotificationHtmlLabelURLTapped = @"NotificationHtmlLabelURLTapped";
NSString* const kNotificationHtmlLabelURLTapped_label = @"label";
NSString* const kNotificationHtmlLabelURLTapped_url = @"url";
NSString* const _htmlTapGestureSetKey = @"_htmlTapGestureSet";

@interface UIColor (INCRDBL_HEX)
+(UIColor*)incrdbl_colorFromHex:(unsigned)hex;
+(UIColor *)incrdbl_colorFromHexString:(NSString *)hexString;
-(NSString *)incrdbl_hex;
@end

@implementation UIColor (INCRDBL_HEX)

+(UIColor*)incrdbl_colorFromHex:(unsigned)hex
{
    return [UIColor colorWithRed:((float)((hex & 0xFF0000) >> 16))/255.0 \
                    green:((float)((hex & 0x00FF00) >>  8))/255.0 \
                     blue:((float)((hex & 0x0000FF) >>  0))/255.0 \
                           alpha:1.0];
}

+(UIColor *)incrdbl_colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    
    [scanner setCharactersToBeSkipped:[NSCharacterSet alphanumericCharacterSet].invertedSet];
    
    [scanner scanHexInt:&rgbValue];
    return [self incrdbl_colorFromHex:rgbValue];
}

- (NSString *)incrdbl_hex {
    
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

@interface UILabelHtmlTapGestureRecognizer: UITapGestureRecognizer

@end

@implementation UILabelHtmlTapGestureRecognizer

- (NSURL*)didTapUrlInLabel:(UILabel *)label {
    
    if (label.attributedText.length == 0) {
        return nil;
    }
    
    CGSize labelSize = label.bounds.size;
    // create instances of NSLayoutManager, NSTextContainer and NSTextStorage
    NSLayoutManager *layoutManager = [[[NSLayoutManager alloc] init] autorelease];
    NSTextContainer *textContainer = [[[NSTextContainer alloc] initWithSize:CGSizeZero] autorelease];
    NSTextStorage *textStorage = [[[NSTextStorage alloc] initWithAttributedString:label.attributedText] autorelease];
    
    // configure layoutManager and textStorage
    [layoutManager addTextContainer:textContainer];
    [textStorage addLayoutManager:layoutManager];
    
    // configure textContainer for the label
    textContainer.lineFragmentPadding = 0.0;
    textContainer.lineBreakMode = label.lineBreakMode;
    textContainer.maximumNumberOfLines = label.numberOfLines;
    textContainer.size = labelSize;
    
    // find the tapped character location and compare it to the specified range
    CGPoint locationOfTouchInLabel = [self locationInView:label];
    CGRect textBoundingBox = [layoutManager usedRectForTextContainer:textContainer];
    CGPoint textContainerOffset = CGPointMake((labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x,
                                              (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y);
    CGPoint locationOfTouchInTextContainer = CGPointMake(locationOfTouchInLabel.x - textContainerOffset.x,
                                                         locationOfTouchInLabel.y - textContainerOffset.y);
    NSInteger indexOfCharacter = [layoutManager characterIndexForPoint:locationOfTouchInTextContainer
                                                       inTextContainer:textContainer
                              fractionOfDistanceBetweenInsertionPoints:nil];
    
    NSRange attrPointer = NSMakeRange(0, 0);
    
    NSNumber* value = [label.attributedText attribute:NSUnderlineStyleAttributeName atIndex:indexOfCharacter effectiveRange:&attrPointer];
    
    if ([value isKindOfClass:[NSNumber class]] && [value isEqualToNumber:@(NSUnderlineStyleSingle)]) {
        NSString* linkStr = [label.attributedText.string substringWithRange:attrPointer];
        return [NSURL URLWithString:linkStr];
    }
    
    return nil;
}

@end

@implementation UILabel (html)

- (void) setHtml: (NSString*) html
{
    NSError *err = nil;
    
    if ([html rangeOfString:@"<style>"].length == 0) {
        html = [html stringByAppendingFormat:@"<style>body{font-family: '%@'; font-size:%fpx; text-align: %@; color: %@}</style>",self.font.fontName,self.font.pointSize,self.textAlignment == NSTextAlignmentLeft ? @"left" : (self.textAlignment == NSTextAlignmentRight ? @"right" : @"center"),[self.textColor incrdbl_hex]];
    }
    
    @try {
        self.attributedText =
        [[[NSAttributedString alloc]
          initWithData: [html dataUsingEncoding:NSUnicodeStringEncoding]
          options: @{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType }
          documentAttributes: nil
          error: &err] autorelease];
    } @catch (NSException *exception) {
        
    } @finally {
        
    }
    
    if(err)
        NSLog(@"Unable to parse label text: %@", err);
}

- (void) setHtml:(NSString *)html withCompletionHandler:(void (^)(BOOL success))handler
{
    dispatch_queue_t _queue = dispatch_queue_create("html label parse queue", DISPATCH_QUEUE_CONCURRENT);
    
    NSString* fontName = self.font.fontName;
    float pointSize = self.font.pointSize;
    NSTextAlignment textAlignment = self.textAlignment;
    NSString* hexColor = [self.textColor incrdbl_hex];
    
    dispatch_async(_queue, ^{
        @autoreleasepool {
            NSError *err = nil;
            
            NSString* _html = nil;
            
            if ([html rangeOfString:@"<style>"].length == 0) {
                _html = [html stringByAppendingFormat:@"<style>body{font-family: '%@'; font-size:%fpx; text-align: %@; color: %@}</style>",fontName,pointSize,textAlignment == NSTextAlignmentLeft ? @"left" : (textAlignment == NSTextAlignmentRight ? @"right" : @"center"),hexColor];
            }else
            {
                _html = html;
            }
            
            NSAttributedString* attributedText = nil;
            
            @try {
                attributedText =
                [[[NSAttributedString alloc]
                  initWithData: [_html dataUsingEncoding:NSUnicodeStringEncoding]
                  options: @{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType }
                  documentAttributes: nil
                  error: &err] autorelease];
            } @catch (NSException *exception) {
                
            } @finally {
                
            }
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                if (attributedText) {
                    self.attributedText = attributedText;
                }
                if (handler) {
                    handler(attributedText != nil && err == nil);
                }
            }];
            dispatch_release(_queue);
        }
    });
}

-(void)setColorTextByHtmlTags:(NSString*)txt
{
    self.attributedText = [UILabel convertColorStringByHtmlTags:txt defaultTextColor:self.textColor font:self.font];
}

+ (NSAttributedString*)convertColorStringByHtmlTags:(NSString*)txt defaultTextColor:(UIColor*)textColor font:(UIFont*)font
{
    NSMutableAttributedString* attributedText = [[[NSMutableAttributedString alloc] init] autorelease];
    
    if (textColor == nil) {
        textColor = [UIColor whiteColor];
    }
    
    txt = [txt stringByReplacingOccurrencesOfString:@"<br>" withString:@"\n"];
    
    NSRange searchRange = {0,txt.length};
    
    NSString* startFontAnchor = @"<font";
    NSString* endFontAnchor = @"</font>";
    
    @try {
        while (searchRange.length > 0) {
            NSRange range = [txt rangeOfString:startFontAnchor options:NSCaseInsensitiveSearch range:searchRange];
            if (range.length > 0 && txt.length > range.location) {
                
                NSString* defaultStr = [txt substringWithRange:NSMakeRange(searchRange.location, range.location - searchRange.location)];
                
                if (defaultStr.length > 0) {
                    [attributedText appendAttributedString:[[[NSAttributedString alloc] initWithString:defaultStr attributes:@{NSForegroundColorAttributeName : textColor}] autorelease]];
                }
                
                NSRange _preColorRange = NSMakeRange(range.location + range.length, txt.length - (range.location + range.length));
                
                NSRange colorRange = [txt rangeOfString:@"=" options:NSCaseInsensitiveSearch range:_preColorRange];
                
                if (colorRange.length > 0 && txt.length - (colorRange.location + 1) > 0) {
                    
                    NSRange endColorRange = [txt rangeOfString:@">" options:NSLiteralSearch range:NSMakeRange(colorRange.location + 1, txt.length - (colorRange.location + 1))];
                    
                    NSUInteger restLength = txt.length - (endColorRange.location + 1);
                    
                    if (endColorRange.length > 0 && restLength > 0) {
                        NSString* colorStr = [txt substringWithRange:NSMakeRange(colorRange.location + 1, endColorRange.location - (colorRange.location + 1))];
                        UIColor* color = [UIColor incrdbl_colorFromHexString:colorStr];
                        
                        NSRange endFontRange = [txt rangeOfString:endFontAnchor options:NSCaseInsensitiveSearch range:NSMakeRange(endColorRange.location + 1, restLength)];
                        
                        if (endFontRange.length > 0) {
                            NSString* coloredTxt = [txt substringWithRange:NSMakeRange(endColorRange.location + 1, endFontRange.location - (endColorRange.location + 1))];
                            
                            if (coloredTxt.length > 0) {
                                [attributedText appendAttributedString:[[[NSAttributedString alloc] initWithString:coloredTxt attributes:@{NSForegroundColorAttributeName : (color ? color : textColor)}] autorelease]];
                            }
                            
                            searchRange.location = endFontRange.location + endFontRange.length;
                            searchRange.length = txt.length - searchRange.location;
                            continue;
                        }else
                        {
                            break;
                        }
                        
                    }else
                    {
                        break;
                    }
                    
                    
                }else
                {
                    break;
                }
                
            }else
            {
                if (searchRange.length > 0) {
                    NSString* defaultStr = [txt substringWithRange:searchRange];
                    if (defaultStr.length > 0) {
                        [attributedText appendAttributedString:[[[NSAttributedString alloc] initWithString:defaultStr attributes:@{NSForegroundColorAttributeName : textColor}] autorelease]];
                    }
                }
                
                break;
            }
        }
        if (font != nil) {
            [attributedText addAttributes:@{NSFontAttributeName : font} range:NSMakeRange(0, attributedText.length)];
        }
        
    } @catch (NSException *exception) {
        
    } @finally {
        
    }
    return attributedText;
}

- (void) setTextByHtmlTags:(NSString*)txt
{
    self.attributedText = [UILabel convertStringByHtmlTags:txt defaultTextColor:self.textColor font:self.font];
    
    [self addHyperlinkLinkTapListening:YES];
}

-(void)addHyperlinkLinkTapListening:(BOOL)listen {
    if (listen) {
        UILabelHtmlTapGestureRecognizer* tapGesture = nil;
        
        for (UIGestureRecognizer* gesture in self.gestureRecognizers) {
            if ([gesture isKindOfClass:[UILabelHtmlTapGestureRecognizer class]]) {
                tapGesture = (UILabelHtmlTapGestureRecognizer*)gesture;
                break;
            }
        }
        
        if (tapGesture == nil) {
            UILabelHtmlTapGestureRecognizer* tapGesture = [[[UILabelHtmlTapGestureRecognizer alloc] initWithTarget:self action:@selector(tapgesureAction:)] autorelease];
            [self addGestureRecognizer:tapGesture];
        }
    }else{
        for (UIGestureRecognizer* gesture in self.gestureRecognizers) {
            if ([gesture isKindOfClass:[UILabelHtmlTapGestureRecognizer class]]) {
                [self removeGestureRecognizer:gesture];
                break;
            }
        }
    }
}

-(void)tapgesureAction:(UILabelHtmlTapGestureRecognizer*)gesture
{
    NSURL* url = [gesture didTapUrlInLabel:self];
    if (url) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationHtmlLabelURLTapped object:@{kNotificationHtmlLabelURLTapped_label:self,kNotificationHtmlLabelURLTapped_url:url}];
    }
}

+ (NSAttributedString*)convertStringByHtmlTags:(NSString*)txt defaultTextColor:(UIColor*)textColor font:(UIFont*)font
{
    NSMutableAttributedString* attributedText = [[[NSMutableAttributedString alloc] init] autorelease];
    
    if (textColor == nil) {
        textColor = [UIColor whiteColor];
    }
    
    if (font == nil) {
        font = [UIFont systemFontOfSize:17];
    }
    
    txt = [txt stringByReplacingOccurrencesOfString:@"<br>" withString:@"\n"];
    
    NSRange searchRange = {0,txt.length};
    
    NSString* startFontAnchor = @"<font";
    NSString* endFontAnchor = @"</font>";
    
    @try {
        while (searchRange.length > 0) {
            NSRange range = [txt rangeOfString:startFontAnchor options:NSCaseInsensitiveSearch range:searchRange];
            if (range.length > 0 && txt.length > range.location) {
                
                NSString* defaultStr = [txt substringWithRange:NSMakeRange(searchRange.location, range.location - searchRange.location)];
                
                if (defaultStr.length > 0) {
                    
                    NSMutableDictionary* attrDct = [NSMutableDictionary dictionaryWithDictionary:@{NSForegroundColorAttributeName : textColor}];
                    if (font != nil) {
                        [attrDct setObject:font forKey:NSFontAttributeName];
                    }
                    
                    [attributedText appendAttributedString:[[[NSAttributedString alloc] initWithString:defaultStr attributes:attrDct] autorelease]];
                }
                
                NSRange _fontStartRange = NSMakeRange(range.location + range.length, txt.length - (range.location + range.length));
                NSRange _fontFormatEndRange = [txt rangeOfString:@">" options:NSLiteralSearch range:searchRange];
                NSRange _fontFormatRange = NSMakeRange(_fontStartRange.location, _fontFormatEndRange.location - _fontStartRange.location);
                NSRange _fontEndRange = [txt rangeOfString:endFontAnchor options:NSCaseInsensitiveSearch range:searchRange];
                NSRange _formatedStringRange = NSMakeRange(_fontFormatEndRange.location + _fontFormatEndRange.length, _fontEndRange.location - (_fontFormatEndRange.location + _fontFormatEndRange.length));
                
                if ((NSInteger)(txt.length - _fontEndRange.location) - 1 < 0) {
                    break;
                }
                
                NSRange colorRange = [txt rangeOfString:@"color=" options:NSCaseInsensitiveSearch range:_fontFormatRange];
                NSRange sizeRange = [txt rangeOfString:@"size=" options:NSCaseInsensitiveSearch range:_fontFormatRange];
                
                UIColor* color = nil;
                float fontSize = 0;
                
                if (colorRange.length > 0 && txt.length - (colorRange.location + 1) > 0) {
                    
                    NSRange endColorRange = [txt rangeOfString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(colorRange.location + colorRange.length, _fontFormatEndRange.location - (colorRange.location + colorRange.length))];
                    
                    if (endColorRange.length == 0 || endColorRange.location > _fontFormatEndRange.location) {
                        endColorRange = _fontFormatEndRange;
                    }
                    
                    if (endColorRange.length > 0) {
                        NSString* colorStr = [txt substringWithRange:NSMakeRange(colorRange.location + colorRange.length, endColorRange.location - (colorRange.location + colorRange.length))];
                        color = [UIColor incrdbl_colorFromHexString:colorStr];
                    }
                }
                
                if (sizeRange.length > 0 && txt.length - (sizeRange.location + 1) > 0) {
                    
                    NSRange endSizeRange = [txt rangeOfString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(sizeRange.location + sizeRange.length, _fontFormatEndRange.location - (sizeRange.location + sizeRange.length))];

                    if (endSizeRange.length == 0 || endSizeRange.location > _fontFormatEndRange.location) {
                        endSizeRange = _fontFormatEndRange;
                    }
                    
                    if (endSizeRange.length > 0) {
                        NSString* sizeStr = [txt substringWithRange:NSMakeRange(sizeRange.location + sizeRange.length, endSizeRange.location - (sizeRange.location + sizeRange.length))];
                        
                        NSMutableString* numberedStr = [NSMutableString string];
                        
                        for (int i = 0; i < sizeStr.length; i++) {
                            char ch = [sizeStr characterAtIndex:i];
                            if ((ch >= '0' && ch <= '9') || ch == '.') {
                                [numberedStr appendString:[NSString stringWithFormat:@"%c",ch]];
                            }
                        }
                        
                        fontSize = [numberedStr floatValue];
                    }
                }
                
                NSString* formatedTxt = [txt substringWithRange:_formatedStringRange];
                
                if (formatedTxt.length > 0) {
                    
                    NSMutableDictionary* dct = [NSMutableDictionary dictionaryWithDictionary:@{NSForegroundColorAttributeName : (color ? color : textColor)}];
                    
                    if (fontSize > 0) {
                        [dct setObject:[UIFont fontWithName:font.fontName size:fontSize] forKey:NSFontAttributeName];
                    }
                    
                    [attributedText appendAttributedString:[[[NSAttributedString alloc] initWithString:formatedTxt attributes:dct] autorelease]];
                }
                
                searchRange.location = _fontEndRange.location + _fontEndRange.length;
                searchRange.length = txt.length - searchRange.location;
                
            }else
            {
                if (searchRange.length > 0) {
                    NSString* defaultStr = [txt substringWithRange:searchRange];
                    if (defaultStr.length > 0) {
                        [attributedText appendAttributedString:[[[NSAttributedString alloc] initWithString:defaultStr attributes:@{NSForegroundColorAttributeName : textColor}] autorelease]];
                    }
                }
                
                break;
            }
        }
        
        NSDataDetector* detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
        
        NSString* labelText = attributedText.string;
        
        NSArray *matches = [detector matchesInString:labelText
                                             options:0
                                               range:NSMakeRange(0, [labelText length])];
        
        if (matches.count > 0) {

            for (NSTextCheckingResult *match in matches) {
                NSRange matchRange = [match range];
                [attributedText addAttributes:@{NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle)} range:matchRange];
            }            
        }
        
    } @catch (NSException *exception) {
        
    } @finally {
        
    }
    return attributedText;
}

- (NSArray<NSURL*>*)urls
{
    NSMutableArray<NSURL*>* urls = [NSMutableArray array];
    [self.attributedText enumerateAttribute:NSUnderlineStyleAttributeName inRange:NSMakeRange(0, self.attributedText.length) options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
        if ([value isKindOfClass:[NSNumber class]] && [value isEqualToNumber:@(NSUnderlineStyleSingle)]) {
            NSString* linkStr = [self.attributedText.string substringWithRange:range];
            NSURL* url =  [NSURL URLWithString:linkStr];
            if (url) {
                [urls addObject:url];
            }
        }
    }];
    return urls;
}

@end
