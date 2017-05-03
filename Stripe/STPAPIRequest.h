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

@interface STPAPIRequest<__covariant ResponseType:id<STPAPIResponseDecodable>> : NSObject

typedef void(^STPAPIResponseBlock)(ResponseType object, NSHTTPURLResponse *response, NSError *error);

+ (NSURLSessionDataTask *)postWithAPIClient:(STPAPIClient *)apiClient
                                   endpoint:(NSString *)endpoint
                                 parameters:(NSDictionary *)parameters
                                 serializer:(ResponseType)serializer
                                 completion:(STPAPIResponseBlock)completion;

+ (NSURLSessionDataTask *)postWithAPIClient:(STPAPIClient *)apiClient
                                    endpoint:(NSString *)endpoint
                                  parameters:(NSDictionary *)parameters
                                 serializers:(NSArray<ResponseType>*)serializers
                                  completion:(STPAPIResponseBlock)completion;

+ (NSURLSessionDataTask *)getWithAPIClient:(STPAPIClient *)apiClient
                                  endpoint:(NSString *)endpoint
                                parameters:(NSDictionary *)parameters
                                serializer:(id<STPAPIResponseDecodable>)serializer
                                completion:(STPAPIResponseBlock)completion;

+ (void)parseResponse:(NSURLResponse *)response
                body:(NSData *)body
               error:(NSError *)error
         serializers:(NSArray<id<STPAPIResponseDecodable>>*)serializers
          completion:(STPAPIResponseBlock)completion;

@end
