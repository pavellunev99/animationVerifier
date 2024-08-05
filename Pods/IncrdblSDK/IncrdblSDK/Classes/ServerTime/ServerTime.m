//
//  ServerTime.m
//  Created by Антон Красильников on 19/05/16.
//  Copyright © 2016 Incrdbl Mobile Entertainment LLC. All rights reserved.
//

#import "ServerTime.h"
#include <sys/sysctl.h>

static NSTimeInterval serverTimestamp = 0;
static NSTimeInterval startSystemUptime = 0;


@implementation ServerTime

+ (time_t)uptime
{
    struct timeval boottime;
    
    int mib[2] = {CTL_KERN, KERN_BOOTTIME};
    
    size_t size = sizeof(boottime);
    
    time_t now;
    
    time_t uptime = -1;
    
    (void)time(&now);
    
    if (sysctl(mib, 2, &boottime, &size, NULL, 0) != -1 && boottime.tv_sec != 0)
    {
        uptime = now - boottime.tv_sec;
    }
    
    return uptime;
}

+(void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        startSystemUptime = [self uptime];
        serverTimestamp = [[NSDate date] timeIntervalSince1970];
    });
}

+(void)syncTime:(NSTimeInterval)serverTime
{
    @synchronized (self) {
        if (serverTime > 0) {
            serverTimestamp = serverTime;
            startSystemUptime = [self uptime];
        }
    }
}

+(NSTimeInterval)currentTimestamp
{
    NSTimeInterval timestamp = 0;
    
    @synchronized (self) {
        NSTimeInterval systemUptime = [self uptime];
                
        timestamp = serverTimestamp + systemUptime - startSystemUptime;
    }
    return timestamp;
}

+(NSTimeInterval)timeIntervalSinceDate:(NSDate *)date
{
    return [self currentTimestamp] - [date timeIntervalSince1970];
}

+(NSDate*)date
{
    return [NSDate dateWithTimeIntervalSince1970:[self currentTimestamp]];
}

@end
