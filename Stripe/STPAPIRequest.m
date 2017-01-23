//
//  STPAPIRequest.m
//  Stripe
//
//  Created by Jack Flintermann on 10/14/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

#import "NSMutableURLRequest+Stripe.h"
#import "STPAPIClient+Private.h"
#import "STPAPIClient.h"
#import "STPDispatchFunctions.h"
#import "STPAPIRequest.h"
#import "StripeError.h"

@implementation STPAPIRequest

+ (void)postWithAPIClient:(STPAPIClient *)apiClient
                 endpoint:(NSString *)endpoint
                 postData:(NSData *)postData
               serializer:(id<STPAPIResponseDecodable>)serializer
               completion:(STPAPIResponseBlock)completion {

    NSURL *url = [apiClient.apiURL URLByAppendingPathComponent:endpoint];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    request.HTTPBody = postData;
    
    [[apiClient.urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable body, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [[self class] parseResponse:response
                               body:body
                              error:error
                         serializer:serializer
                         completion:completion];
    }] resume];

}

+ (void)getWithAPIClient:(STPAPIClient *)apiClient
                endpoint:(NSString *)endpoint
              parameters:(NSDictionary *)parameters
              serializer:(id<STPAPIResponseDecodable>)serializer
              completion:(STPAPIResponseBlock)completion {

    NSURL *url = [apiClient.apiURL URLByAppendingPathComponent:endpoint];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request stp_addParametersToURL:parameters];
    request.HTTPMethod = @"GET";

    [[apiClient.urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable body, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [[self class] parseResponse:response
                               body:body
                              error:error
                         serializer:serializer
                         completion:completion];
    }] resume];
    
}

+ (void)parseResponse:(NSURLResponse *)response
                 body:(NSData *)body
                error:(NSError *)error
           serializer:(id<STPAPIResponseDecodable>)serializer
           completion:(STPAPIResponseBlock)completion {

    NSDictionary *jsonDictionary = body ? [NSJSONSerialization JSONObjectWithData:body options:(NSJSONReadingOptions)kNilOptions error:NULL] : nil;
    id<STPAPIResponseDecodable> responseObject = [[serializer class] decodedObjectFromAPIResponse:jsonDictionary];
    NSError *returnedError = [NSError stp_errorFromStripeResponse:jsonDictionary] ?: error;
    if ((!responseObject || ![response isKindOfClass:[NSHTTPURLResponse class]]) && !returnedError) {
        returnedError = [NSError stp_genericFailedToParseResponseError];
    }

    NSHTTPURLResponse *httpResponse;
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        httpResponse = (NSHTTPURLResponse *)response;
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
