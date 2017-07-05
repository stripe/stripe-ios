//
//  STPAPIRequest.m
//  Stripe
//
//  Created by Jack Flintermann on 10/14/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

#import "STPAPIRequest.h"

#import "NSMutableURLRequest+Stripe.h"
#import "STPAPIClient.h"
#import "STPAPIClient+Private.h"
#import "STPDispatchFunctions.h"
#import "STPInternalAPIResponseDecodable.h"
#import "StripeError.h"

@implementation STPAPIRequest

#pragma mark - POST

+ (NSURLSessionDataTask *)postWithAPIClient:(STPAPIClient *)apiClient
                                   endpoint:(NSString *)endpoint
                                 parameters:(NSDictionary *)parameters
                               deserializer:(id<STPAPIResponseDecodable>)deserializer
                                 completion:(STPAPIResponseBlock)completion {
    return [self postWithAPIClient:apiClient endpoint:endpoint parameters:parameters deserializers:@[deserializer] completion:completion];
}

+ (NSURLSessionDataTask *)postWithAPIClient:(STPAPIClient *)apiClient
                                   endpoint:(NSString *)endpoint
                                 parameters:(NSDictionary *)parameters
                              deserializers:(NSArray<id<STPAPIResponseDecodable>>*)deserializers
                                 completion:(STPAPIResponseBlock)completion {
    // Build url
    NSURL *url = [apiClient.apiURL URLByAppendingPathComponent:endpoint];

    // Setup request
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    [request stp_setFormPayload:parameters];

    // Perform request
    NSURLSessionDataTask *task = [apiClient.urlSession dataTaskWithRequest:request completionHandler:^(NSData *body, NSURLResponse *response, NSError *error) {
        [[self class] parseResponse:response body:body error:error deserializers:deserializers completion:completion];
    }];
    [task resume];

    return task;
}

#pragma mark - GET

+ (NSURLSessionDataTask *)getWithAPIClient:(STPAPIClient *)apiClient
                                  endpoint:(NSString *)endpoint
                                parameters:(NSDictionary *)parameters
                              deserializer:(id<STPAPIResponseDecodable>)deserializer
                                completion:(STPAPIResponseBlock)completion {
    // Build url
    NSURL *url = [apiClient.apiURL URLByAppendingPathComponent:endpoint];

    // Setup request
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request stp_addParametersToURL:parameters];
    request.HTTPMethod = @"GET";

    // Perform request
    NSURLSessionDataTask *task = [apiClient.urlSession dataTaskWithRequest:request completionHandler:^(NSData *body, NSURLResponse *response, NSError *error) {
        [[self class] parseResponse:response body:body error:error deserializers:@[deserializer] completion:completion];
    }];
    [task resume];

    return task;
}

#pragma mark - DELETE

+ (NSURLSessionDataTask *)deleteWithAPIClient:(STPAPIClient *)apiClient
                                     endpoint:(NSString *)endpoint
                                   parameters:(NSDictionary *)parameters
                                 deserializer:(id<STPAPIResponseDecodable>)deserializer
                                   completion:(STPAPIResponseBlock)completion {
    return [self deleteWithAPIClient:apiClient endpoint:endpoint parameters:parameters deserializers:@[deserializer] completion:completion];
}

+ (NSURLSessionDataTask *)deleteWithAPIClient:(STPAPIClient *)apiClient
                                     endpoint:(NSString *)endpoint
                                   parameters:(NSDictionary *)parameters
                                deserializers:(NSArray<id<STPAPIResponseDecodable>> *)deserializers
                                   completion:(STPAPIResponseBlock)completion {
    // Build url
    NSURL *url = [apiClient.apiURL URLByAppendingPathComponent:endpoint];

    // Setup request
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request stp_addParametersToURL:parameters];
    request.HTTPMethod = @"DELETE";

    // Perform request
    NSURLSessionDataTask *task = [apiClient.urlSession dataTaskWithRequest:request completionHandler:^(NSData *body, NSURLResponse *response, NSError *error) {
        [[self class] parseResponse:response body:body error:error deserializers:deserializers completion:completion];
    }];
    [task resume];

    return task;
}

#pragma mark -

+ (void)parseResponse:(NSURLResponse *)response
                 body:(NSData *)body
                error:(NSError *)error
        deserializers:(NSArray<id<STPAPIResponseDecodable>>*)deserializers
           completion:(STPAPIResponseBlock)completion {
    id<STPAPIResponseDecodable> responseObject;
    NSError *returnedError;
    NSHTTPURLResponse *httpResponse;
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        httpResponse = (NSHTTPURLResponse *)response;
    }

    if (deserializers.count == 0) {
        returnedError = [NSError stp_genericFailedToParseResponseError];
    } else {
        NSDictionary *jsonDictionary = body ? [NSJSONSerialization JSONObjectWithData:body options:(NSJSONReadingOptions)kNilOptions error:NULL] : nil;
        NSString *object = jsonDictionary[@"object"];
        Class deserializerClass;
        if (deserializers.count == 1) {
            deserializerClass = [deserializers.firstObject class];
        } else {
            for (id<STPAPIResponseDecodable> deserializer in deserializers) {
                if ([deserializer respondsToSelector:@selector(stripeObject)]
                    && [[(id<STPInternalAPIResponseDecodable>)deserializer stripeObject] isEqualToString:object]) {
                    deserializerClass = [deserializer class];
                }
            }
        }
        if (!deserializerClass) {
            returnedError = [NSError stp_genericFailedToParseResponseError];
        } else {
            responseObject = [deserializerClass decodedObjectFromAPIResponse:jsonDictionary];
            returnedError = [NSError stp_errorFromStripeResponse:jsonDictionary] ?: error;
        }
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
