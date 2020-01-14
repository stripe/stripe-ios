//
//  STPAPIRequest.h
//  Stripe
//
//  Created by Jack Flintermann on 10/14/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPAPIResponseDecodable.h"

@class STPAPIClient;

NS_ASSUME_NONNULL_BEGIN

@interface STPAPIRequest<__covariant ResponseType:id<STPAPIResponseDecodable>> : NSObject

typedef void(^STPAPIResponseBlock)(ResponseType _Nullable object, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error);

+ (NSURLSessionDataTask *)postWithAPIClient:(STPAPIClient *)apiClient
                                   endpoint:(NSString *)endpoint
                                 parameters:(nullable NSDictionary *)parameters
                               deserializer:(ResponseType)deserializer
                                 completion:(STPAPIResponseBlock)completion;

+ (NSURLSessionDataTask *)postWithAPIClient:(STPAPIClient *)apiClient
                                   endpoint:(NSString *)endpoint
                          additionalHeaders:(nullable NSDictionary<NSString *, NSString *> *)additionalHeaders
                                 parameters:(nullable NSDictionary *)parameters
                               deserializer:(ResponseType)deserializer
                                 completion:(STPAPIResponseBlock)completion;

+ (NSURLSessionDataTask *)postWithAPIClient:(STPAPIClient *)apiClient
                                    endpoint:(NSString *)endpoint
                                  parameters:(nullable NSDictionary *)parameters
                               deserializers:(NSArray<ResponseType> *)deserializers
                                  completion:(STPAPIResponseBlock)completion;

+ (NSURLSessionDataTask *)postWithAPIClient:(STPAPIClient *)apiClient
                                   endpoint:(NSString *)endpoint
                          additionalHeaders:(nullable NSDictionary<NSString *, NSString *> *)additionalHeaders
                                 parameters:(nullable NSDictionary *)parameters
                              deserializers:(NSArray<ResponseType> *)deserializers
                                 completion:(STPAPIResponseBlock)completion;

+ (NSURLSessionDataTask *)getWithAPIClient:(STPAPIClient *)apiClient
                                  endpoint:(NSString *)endpoint
                                parameters:(nullable NSDictionary *)parameters
                              deserializer:(ResponseType)deserializer
                                completion:(STPAPIResponseBlock)completion;

+ (NSURLSessionDataTask *)getWithAPIClient:(STPAPIClient *)apiClient
                                  endpoint:(NSString *)endpoint
                         additionalHeaders:(nullable NSDictionary<NSString *, NSString *> *)additionalHeaders
                                parameters:(nullable NSDictionary *)parameters
                              deserializer:(ResponseType)deserializer
                                completion:(STPAPIResponseBlock)completion;

+ (NSURLSessionDataTask *)deleteWithAPIClient:(STPAPIClient *)apiClient
                                     endpoint:(NSString *)endpoint
                                   parameters:(nullable NSDictionary *)parameters
                                 deserializer:(ResponseType)deserializer
                                   completion:(STPAPIResponseBlock)completion;

+ (NSURLSessionDataTask *)deleteWithAPIClient:(STPAPIClient *)apiClient
                                     endpoint:(NSString *)endpoint
                            additionalHeaders:(nullable NSDictionary<NSString *, NSString *> *)additionalHeaders
                                   parameters:(nullable NSDictionary *)parameters
                                 deserializer:(ResponseType)deserializer
                                   completion:(STPAPIResponseBlock)completion;

+ (NSURLSessionDataTask *)deleteWithAPIClient:(STPAPIClient *)apiClient
                                     endpoint:(NSString *)endpoint
                                   parameters:(nullable NSDictionary *)parameters
                                deserializers:(NSArray<ResponseType> *)deserializer
                                   completion:(STPAPIResponseBlock)completion;

+ (NSURLSessionDataTask *)deleteWithAPIClient:(STPAPIClient *)apiClient
                                     endpoint:(NSString *)endpoint
                            additionalHeaders:(nullable NSDictionary<NSString *, NSString *> *)additionalHeaders
                                   parameters:(nullable NSDictionary *)parameters
                                deserializers:(NSArray<ResponseType> *)deserializer
                                   completion:(STPAPIResponseBlock)completion;

@end

NS_ASSUME_NONNULL_END
