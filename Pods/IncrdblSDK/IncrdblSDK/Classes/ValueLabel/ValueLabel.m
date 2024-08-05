//
//  ValueLabel.m
//
//  Created by Антон Красильников on 20/05/16.
//  Copyright © 2016 Incrdbl Mobile Entertainment LLC. All rights reserved.
//

#import "ValueLabel.h"
#import "ValueLabelAttachment.h"
#import "ValueLabelItem.h"
#import <UILabel+html.h>

#define defTextColor [UIColor whiteColor]

@interface ValueLabel ()
{
    UIColor* _baseTextColor;
}
@property (nonatomic,retain) UIFont* baseFont;
@property (nonatomic,retain) NSMutableArray<ValueLabelItem*>* items;
@property (nonatomic,retain) NSString* notParsedString;

@end

@implementation ValueLabel

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.notParsedString = nil;
    
    for (ValueLabelItem* item in _items) {
        if ([item isKindOfClass:[ValueLabelAttachment class]]) {
            [item removeObserver:self forKeyPath:@"text"];
        }
    }
    
    self.items = nil;
    self.baseFont = nil;
    [_baseTextColor release];
    self.hyperlinkCallback = nil;

    [super dealloc];
}

+(ValueLabel*)labelWithText:(NSString*)txt
                  textColor:(UIColor*)textColor
                       font:(UIFont *)font
{
    ValueLabel* label = [[[ValueLabel alloc] init] autorelease];
    
    label.textColor = textColor ? textColor : defTextColor;
    
    label.font = font ? font : [UIFont systemFontOfSize:17];
    
    label.text = txt;
    
    
    return label;
}

-(void)setFont:(UIFont *)font
{
    [super setFont:font];
    self.baseFont = font;
    if (_notParsedString.length > 0) {
        [self _update];
    }
}

-(void)setLinespacing:(float)linespacing {
    if (_linespacing != linespacing) {
        _linespacing = linespacing;
        [self _update];
    }
}

-(void)setMarkLinks:(BOOL)markLinks {
    if (_markLinks != markLinks) {
        _markLinks = markLinks;
        [self _update];
        [self addHyperlinkLinkTapListening:_markLinks];
    }
}

- (void)addHyperlinkLinkTapListening:(BOOL)listen {
    [super addHyperlinkLinkTapListening:listen];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationHtmlLabelURLTapped object:nil];
    
    if (listen) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hyperlinkTapAction:) name:kNotificationHtmlLabelURLTapped object:nil];
    }
}

-(void)hyperlinkTapAction:(NSNotification*)notification {
    
    if ([notification.object isKindOfClass:[NSDictionary class]]) {
        NSDictionary* dct = (NSDictionary*)notification.object;
        if ([dct objectForKey:kNotificationHtmlLabelURLTapped_label] == self) {
            NSURL* link = [dct objectForKey:kNotificationHtmlLabelURLTapped_url];
            if ([link isKindOfClass:[NSURL class]] && _hyperlinkCallback != nil) {
                _hyperlinkCallback(link);
            }
        }
    }
}

-(void)setTextColor:(UIColor *)textColor
{
    [super setTextColor:textColor];
    if (textColor != nil && ![_baseTextColor isEqual:textColor]) {
        [_baseTextColor release];
        _baseTextColor = [textColor retain];
        [self _update];
    }
}

-(void)setText:(NSString *)txt
{
    if ([_notParsedString isEqualToString:txt]) {
        return;
    }
    
    self.notParsedString = txt;
    [self _update];
}

-(void)_update
{
    if (_items == nil) {
        self.items = [NSMutableArray array];
    }
    for (ValueLabelItem* item in _items) {
        if ([item isKindOfClass:[ValueLabelAttachment class]]) {
            [item removeObserver:self forKeyPath:@"text"];
        }
    }
    [_items removeAllObjects];
    
    UIFont* font = self.baseFont ? self.baseFont : [UIFont systemFontOfSize:17];
    
    if (_baseTextColor == nil && self.textColor != nil) {
        _baseTextColor = [self.textColor retain];
    }
    
    UIColor* colorOfText = _baseTextColor ? _baseTextColor : defTextColor;
    
    NSString* txt = [_notParsedString stringWithValueLabelPlaceholders];
    
    NSDictionary *attrs = @{
                            NSFontAttributeName:font,
                            NSForegroundColorAttributeName:colorOfText
                            };
    
    NSRange range = NSMakeRange(0, txt.length);
    
    ValueLabelAttachment* attachment = [ValueLabelAttachment scanForAttachment:txt inRange:range font:font];
    
    while (attachment != nil) {
        
        [attachment addObserver:self forKeyPath:@"text" options:0 context:NULL];
        
        if (attachment.range.location - range.location > 0) {
            NSString* preString = [[txt substringWithRange:NSMakeRange(range.location, attachment.range.location - range.location)] stringByRemovingValueLabelPlaceholders];
            ValueLabelItem* item = [[ValueLabelItem new] autorelease];
            item.text = [[[NSAttributedString alloc] initWithString:preString attributes:attrs] autorelease];
            [_items addObject:item];
        }
        
        [_items addObject:attachment];
        
        range = NSMakeRange(attachment.range.location + attachment.range.length, txt.length - (attachment.range.location + attachment.range.length));
        
        attachment = [ValueLabelAttachment scanForAttachment:txt inRange:range font:font];
    }
    
    if (range.location < txt.length) {
        NSString* restString = [txt substringFromIndex:range.location];
        ValueLabelItem* item = [[ValueLabelItem new] autorelease];
        item.text = [[[NSAttributedString alloc] initWithString:restString attributes:attrs] autorelease];
        [_items addObject:item];
    }
    
    [self buildText];
}

-(void)buildText
{
    UIFont* font = self.baseFont ? self.baseFont : [UIFont systemFontOfSize:17];
    
    NSMutableAttributedString *string= [[[NSMutableAttributedString alloc] initWithString:@"" attributes:@{}] autorelease];
    
    for (ValueLabelItem* item in _items) {
        if (item.text.length > 0) {
            [string appendAttributedString:item.text];
        }
    }
    
    if (_linespacing != 0)
    {
        NSMutableParagraphStyle *style = [[[NSMutableParagraphStyle alloc] init] autorelease];
        style.alignment = self.textAlignment;
        [style setLineSpacing:_linespacing*font.pointSize/2];
        [style setParagraphSpacing:_linespacing*font.pointSize/2];
        [string addAttribute:NSParagraphStyleAttributeName value:style range:NSMakeRange(0, string.length)];
    }
    
    if (_markLinks) {
        NSDataDetector* detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
        
        NSString* labelText = string.string;
        
        NSArray *matches = [detector matchesInString:labelText
                                             options:0
                                               range:NSMakeRange(0, [labelText length])];
        
        if (matches.count > 0) {

            for (NSTextCheckingResult *match in matches) {
                NSRange matchRange = [match range];
                [string addAttributes:@{NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle)} range:matchRange];
            }
        }
    }
        
    self.attributedText = string;
    [self sizeToFit];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    [self buildText];
}

@end
