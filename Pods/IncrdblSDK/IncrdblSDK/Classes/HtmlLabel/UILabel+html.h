//
//  UILabel.h
//  wordByWord2
//
//  Created by Антон Красильников on 20/05/16.
//  Copyright © 2016 Incrdbl Mobile Entertainment LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString* const kNotificationHtmlLabelURLTapped;
extern NSString* const kNotificationHtmlLabelURLTapped_label;
extern NSString* const kNotificationHtmlLabelURLTapped_url;

@interface UILabel (html)

- (void) setHtml: (NSString*) html;
- (void) setHtml:(NSString *)html withCompletionHandler:(void (^)(BOOL success))handler;
- (void) setColorTextByHtmlTags:(NSString*)txt;
- (void) setTextByHtmlTags:(NSString*)txt;
+ (NSAttributedString*)convertColorStringByHtmlTags:(NSString*)txt defaultTextColor:(UIColor*)textColor font:(UIFont*)font;

- (NSArray<NSURL*>*)urls;
- (void)addHyperlinkLinkTapListening:(BOOL)listen;

@end
