//
//  ValueLabel.h
//
//  Created by Антон Красильников on 20/05/16.
//  Copyright © 2016 Incrdbl Mobile Entertainment LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 label that support pseudo markup to format text
 
 # Usage:
 
 The text, that should be formatted, should be into angle brackets <> and key text=\"\". All angle brackets, that used just like symbols, should have slash preffix: "\<" "\>".
 
 There are available the following *format keys*:
 * color: HEX string
 * font: string name of the font
 * fontScale: float relative to base font size value
 * image: string name from Assets
 * url: string link to image, load asynchronously
 
 <image=%@,url=%@,color=%@,font=%@,fontScale=%f,text=%@,color=%@>
 
 # Example:
 
 "Шла <text=\"Саша\",color=ff0000,font=Montserrat-Italic> по <url=https://www.interfax.ru/ftproot/textphotos/2019/01/17/es700.jpg> и сосала <text=\"сушку\",fontScale=0.5>."
*/

@interface ValueLabel : UILabel

@property (nonatomic,assign) float linespacing;
@property (nonatomic,assign) BOOL markLinks;
@property (nonatomic,copy) void (^hyperlinkCallback)(NSURL*);


+(ValueLabel*)labelWithText:(NSString*)txt
                  textColor:(UIColor*)textColor
                       font:(UIFont *)font;

@end
