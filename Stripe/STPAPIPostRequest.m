//
//  STPAPIPostRequest.m
//  Stripe
//
//  Created by Jack Flintermann on 10/14/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

#import "STPAPIPostRequest.h"
#import "STPAPIClient.h"
#import "STPAPIClient+Private.h"
#import "StripeError.h"

@implementation STPAPIPostRequest

+ (void)startWithAPIClient:(STPAPIClient *)apiClient
                  endpoint:(NSString *)endpoint
                  postData:(NSData *)postData
                serializer:(id<STPAPIResponseDecodable>)serializer
                completion:(STPAPIPostResponseBlock)completion {

    NSURL *url = [apiClient.apiURL URLByAppendingPathComponent:endpoint];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    request.HTTPBody = postData;
    
    [[apiClient.urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable body, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            completion(nil, nil, [NSError stp_genericFailedToParseResponseError]);
            return;
        }
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSDictionary *jsonDictionary = body ? [NSJSONSerialization JSONObjectWithData:body options:0 error:NULL] : nil;
        id<STPAPIResponseDecodable> responseObject = [[serializer class] decodedObjectFromAPIResponse:jsonDictionary];
        NSError *returnedError = [NSError stp_errorFromStripeResponse:jsonDictionary] ?: error;
        if (!responseObject && !returnedError) {
            returnedError = [NSError stp_genericFailedToParseResponseError];
        }
        // We're using the api client's operation queue instead of relying on the url session's operation queue
        // because the api client's queue is mutable and may have changed after initialization (not ideal)
        if (returnedError) {
            [apiClient.operationQueue addOperationWithBlock:^{
                completion(nil, httpResponse, returnedError);
            }];
            return;
        }
        [apiClient.operationQueue addOperationWithBlock:^{
            completion(responseObject, httpResponse, nil);
        }];
    }] resume];
    
}

@end
