//
//  ValueLabelAttachment.h
//
//  Created by Антон Красильников on 17/10/2018.
//  Copyright © 2018 Incrdbl Mobile Entertainment LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ValueLabelItem.h"

@interface ValueLabelAttachment : ValueLabelItem

@property (nonatomic,assign) NSRange range;
@property (nonatomic,assign) BOOL innerLabel;
@property (nonatomic,retain) NSString* valueString;
@property (nonatomic,retain) UIFont* font;
@property (nonatomic,readonly) BOOL empty;

+(instancetype)scanForAttachment:(NSString*)string inRange:(NSRange)range font:(UIFont*)font;

@end

@interface NSString (ValueLabel)

-(NSString*)stringWithValueLabelPlaceholders;
-(NSString*)stringByRemovingValueLabelPlaceholders;

@end
