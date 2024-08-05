//
//  ServerTime.h
//  Created by Антон Красильников on 19/05/16.
//  Copyright © 2016 Incrdbl Mobile Entertainment LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 
 После сихронизации серверного времени методом +(void)syncTime:(NSTimeInterval)serverTime метод +(NSTimeInterval)currentTimestamp будет возвращать текущее серверное время
 
 **/

@interface ServerTime : NSObject

// system uptime
+(time_t)uptime;

// синхронизировать cо значением, полученным с сервера
+(void)syncTime:(NSTimeInterval)serverTime;

+(NSTimeInterval)currentTimestamp;
+(NSTimeInterval)timeIntervalSinceDate:(NSDate *)date;
+(NSDate*)date;

@end
