//
//  INCR_RestClient.m
//
//  Created by Antone on 03/02/16.
//

#import "INCR_RestClient.h"

static NSURLSession* _urlSession = nil;

@implementation NSThread (BlockThreadCategory)

+ (void)thread_runBlock:(void (^)(void))block{
    block();
}

- (void)thread_performBlock:(void (^)(void))block{
    
    if ([[NSThread currentThread] isEqual:self])
        block();
    else
        [self thread_performBlock:block waitUntilDone:NO];
}
- (void)thread_performBlock:(void (^)(void))block waitUntilDone:(BOOL)wait{
    
    [NSThread performSelector:@selector(thread_runBlock:)
                     onThread:self
                   withObject:[[block copy] autorelease]
                waitUntilDone:wait];
}

- (void)thread_performBlock:(void (^)(void))block afterDelay:(NSTimeInterval)delay{
    
    [self performSelector:@selector(thread_performBlock:)
               withObject:[[block copy] autorelease] 
               afterDelay:delay];
}

@end


@implementation INCR_RestClient

+(void)initialize
{
    [super initialize];
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.HTTPMaximumConnectionsPerHost = 5;
    _urlSession = [[NSURLSession sessionWithConfiguration:config] retain];
}

+ (NSString*)JSONString:(id)obj
{
    if (obj && [NSJSONSerialization isValidJSONObject:obj]) {
        NSError* error = nil;
        NSData* jsonData = [NSJSONSerialization dataWithJSONObject:obj options:NSJSONWritingPrettyPrinted error:&error];
        if (error) {
            NSLog(@"NSJSONSerialization write error:%@",error);
        }
        return jsonData ? [[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] autorelease] : nil;
    }else
    {
        return nil;
    }
}

+ (id)parseJSONData:(NSData*)data
{
    if (data == nil) {
        return nil;
    }
    NSError* error = nil;
    id parsedObj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    
    if (error) {
        NSLog(@"NSJSONSerialization read error:\n%@",error);
    }
    return parsedObj;
    
}

+(NSURLSessionDataTask*)taskForRequestUrl:( NSString* _Nonnull )urlStr withHandler:(RestClientHandler _Nullable)handler
{
    return [self taskForRequestUrl:urlStr timeout:60 withHandler:handler];
}

+(NSURLSessionDataTask*)taskForPostRequestUrl:( NSString* _Nonnull )urlStr body:(NSData*)body timeout:(NSTimeInterval)timeout withHandler:(RestClientHandler _Nullable)handler
{
    RestClientJsonHandler _handler = [[handler copy] autorelease];
    
    NSThread* thread = [NSThread currentThread];
    
    NSURL *url = [NSURL URLWithString:[urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:timeout > 0 ? timeout : 60.0] autorelease];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:body];
    
    NSURLSessionDataTask* task = [_urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (_handler) {
            if (thread && thread.isExecuting) {
                [thread thread_performBlock:^{
                    _handler(error,data);
                }];
            }else
            {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    _handler(error,data);
                }];
            }
            
        }
        
    }];
    return task;
}

+(NSURLSessionDataTask*)taskForRequestUrl:( NSString* _Nonnull )urlStr timeout:(NSTimeInterval)timeout withHandler:(RestClientHandler _Nullable)handler
{
    RestClientJsonHandler _handler = [[handler copy] autorelease];
    
    NSThread* thread = [NSThread currentThread];
    
    NSURL *url = [NSURL URLWithString:[urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:timeout > 0 ? timeout : 60.0] autorelease];
    [request setHTTPMethod:@"GET"];
    
    NSURLSessionDataTask* task = [_urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (_handler) {
            if (thread && thread.isExecuting) {
                [thread thread_performBlock:^{
                    _handler(error,data);
                }];
            }else
            {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    _handler(error,data);
                }];
            }
            
        }
        
    }];
    return task;
}

+(void)requestUrl:( NSString* _Nonnull )urlStr withHandler:(RestClientHandler _Nullable)handler
{
    [[self taskForRequestUrl:urlStr withHandler:handler] resume];
}

+(void)postRequestUrl:( NSString* _Nonnull )urlStr body:(NSData*)body withHandler:(RestClientHandler _Nullable)handler
{
    [[self taskForPostRequestUrl:urlStr body:body timeout:60 withHandler:handler] resume];
}

+(void)requestUrl:( NSString* _Nonnull )urlStr timeout:(NSTimeInterval)timeout withHandler:(RestClientHandler _Nullable)handler
{
    [[self taskForRequestUrl:urlStr timeout:timeout withHandler:handler] resume];
}

+(void)requestForJson:(NSString*)urlStr withHandler:(RestClientJsonHandler)handler
{
    RestClientJsonHandler _handler = [[handler copy] autorelease];
    
    NSThread* thread = [NSThread currentThread];
    
    NSURL *url = [NSURL URLWithString:[urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:60.0] autorelease];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    NSURLSessionDataTask* task = [_urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        id jObj = nil;
        
        if (error == nil && data != nil) {
            jObj = [self parseJSONData:data];
        }

        if (_handler) {
            if (thread && thread.isExecuting) {
                [thread thread_performBlock:^{
                    _handler(error,jObj);
                }];
            }else
            {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    _handler(error,jObj);
                }];
            }
            
        }
        
    }];
    [task resume];
}

+(NSData* _Nullable)syncLoad:(NSString* _Nonnull)urlStr
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    __block NSData* _data = nil;
    
    NSURLSession *session = [NSURLSession sharedSession];
    
    urlStr = [urlStr stringByReplacingOccurrencesOfString:@"http:" withString:@"https:"];
    NSURL *url = [NSURL URLWithString:[urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:60.0];
    [request setHTTPMethod:@"GET"];
    
    NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (data) {
            _data = [data retain];
        } else {
            NSLog(@"error = %@", error);
        }
        
        dispatch_semaphore_signal(semaphore);
    }];
    [task resume];
        
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    [request release];
    
    dispatch_release(semaphore);
    
    return _data ? [_data autorelease] : nil;
    
}

@end
