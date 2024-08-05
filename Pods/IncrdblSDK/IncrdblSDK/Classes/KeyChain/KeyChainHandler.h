//
//  KeyChainHandler.h
//  Created by Anton on 23/12/14.
//  Copyright (c) 2014 Incrdbl Mobile Entertainment LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KeyChainHandler : NSObject

+ (void)save:(NSString *)service account:(NSString *)account data:(id)data;
+ (id)load:(NSString *)service account:(NSString *)account;
+ (void)delete:(NSString *)service account:(NSString *)account;

@end
