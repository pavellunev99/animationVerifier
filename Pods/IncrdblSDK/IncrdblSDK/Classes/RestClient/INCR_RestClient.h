//
//  INCR_RestClient.h
//
//  Created by Antone on 03/02/16.
//

#import <Foundation/Foundation.h>

typedef void (^RestClientJsonHandler) (NSError * _Nullable error, id _Nullable jsonObj);
typedef void (^RestClientHandler) (NSError * _Nullable error, id _Nullable data);

@interface INCR_RestClient : NSObject
+(NSURLSessionDataTask* _Nonnull)taskForRequestUrl:( NSString* _Nonnull )urlStr withHandler:(RestClientHandler _Nullable)handler;
+(void)requestUrl:( NSString* _Nonnull )urlStr withHandler:(RestClientHandler _Nullable)handler;
+(void)requestUrl:( NSString* _Nonnull )urlStr timeout:(NSTimeInterval)timeout withHandler:(RestClientHandler _Nullable)handler;
+(void)requestForJson:( NSString* _Nonnull )urlStr withHandler:(RestClientJsonHandler _Nonnull)handler;
+(NSData* _Nullable)syncLoad:(NSString* _Nonnull)urlStr;
+(void)postRequestUrl:( NSString* _Nonnull )urlStr body:(NSData* _Nullable)body withHandler:(RestClientHandler _Nullable)handler;

@end
