//
//  STPAPIRequest.m
//  Stripe
//
//  Created by Jack Flintermann on 10/14/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

#import "STPAPIRequest.h"

#import "NSMutableURLRequest+Stripe.h"
#import "STPInternalAPIResponseDecodable.h"
#import "STPAPIClient+Private.h"
#import "STPAPIClient.h"
#import "STPCard+Private.h"
#import "STPDispatchFunctions.h"
#import "STPFormEncoder.h"
#import "STPSource+Private.h"
#import "StripeError.h"

@implementation STPAPIRequest

+ (NSURLSessionDataTask *)postWithAPIClient:(STPAPIClient *)apiClient
                                   endpoint:(NSString *)endpoint
                                 parameters:(NSDictionary *)parameters
                                 serializer:(id<STPAPIResponseDecodable>)serializer
                                 completion:(STPAPIResponseBlock)completion {
    return [self postWithAPIClient:apiClient
                          endpoint:endpoint
                        parameters:parameters
                       serializers:@[serializer]
                        completion:completion];
}

+ (NSURLSessionDataTask *)postWithAPIClient:(STPAPIClient *)apiClient
                                   endpoint:(NSString *)endpoint
                                 parameters:(NSDictionary *)parameters
                                serializers:(NSArray<id<STPAPIResponseDecodable>>*)serializers
                                 completion:(STPAPIResponseBlock)completion {
    NSURL *url = [apiClient.apiURL URLByAppendingPathComponent:endpoint];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    NSString *query = [STPFormEncoder queryStringFromParameters:parameters];
    request.HTTPBody = [query dataUsingEncoding:NSUTF8StringEncoding];

    NSURLSessionDataTask *task = [apiClient.urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable body, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [[self class] parseResponse:response
                               body:body
                              error:error
                         serializers:serializers
                         completion:completion];
    }];
    [task resume];
    return task;
}

+ (NSURLSessionDataTask *)getWithAPIClient:(STPAPIClient *)apiClient
                                  endpoint:(NSString *)endpoint
                                parameters:(NSDictionary *)parameters
                                serializer:(id<STPAPIResponseDecodable>)serializer
                                completion:(STPAPIResponseBlock)completion {

    NSURL *url = [apiClient.apiURL URLByAppendingPathComponent:endpoint];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request stp_addParametersToURL:parameters];
    request.HTTPMethod = @"GET";

    NSURLSessionDataTask *task = [apiClient.urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable body, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [[self class] parseResponse:response
                               body:body
                              error:error
                        serializers:@[serializer]
                         completion:completion];
    }];
    [task resume];
    return task;
}

+ (void)parseResponse:(NSURLResponse *)response
                 body:(NSData *)body
                error:(NSError *)error
          serializers:(NSArray<id<STPAPIResponseDecodable>>*)serializers
           completion:(STPAPIResponseBlock)completion {
    id<STPAPIResponseDecodable> responseObject;
    NSError *returnedError;
    NSHTTPURLResponse *httpResponse;
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        httpResponse = (NSHTTPURLResponse *)response;
    }

    if (serializers.count == 0) {
        returnedError = [NSError stp_genericFailedToParseResponseError];
    } else {
        NSDictionary *jsonDictionary = body ? [NSJSONSerialization JSONObjectWithData:body options:(NSJSONReadingOptions)kNilOptions error:NULL] : nil;
        NSString *object = jsonDictionary[@"object"];
        Class serializerClass = [serializers.firstObject class];
        for (id<STPAPIResponseDecodable> serializer in serializers) {
            if ([serializer respondsToSelector:@selector(stripeObject)]
                && [[(id<STPInternalAPIResponseDecodable>)serializer stripeObject] isEqualToString:object]) {
                serializerClass = [serializer class];
            }
        }
        responseObject = [serializerClass decodedObjectFromAPIResponse:jsonDictionary];
        returnedError = [NSError stp_errorFromStripeResponse:jsonDictionary] ?: error;
        if ((!responseObject || ![response isKindOfClass:[NSHTTPURLResponse class]]) && !returnedError) {
            returnedError = [NSError stp_genericFailedToParseResponseError];
        }
    }

    stpDispatchToMainThreadIfNecessary(^{
        if (returnedError) {
            completion(nil, httpResponse, returnedError);
        } else {
            completion(responseObject, httpResponse, nil);
        }
    });

}

@end
