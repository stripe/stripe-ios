//
//  STPStrictURLProtocol.m
//  Stripe
//
//  Created by Jack Flintermann on 1/7/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#import "STPStrictURLProtocol.h"
#import "StripeError.h"

@interface STPStrictURLProtocol()<NSURLConnectionDataDelegate>
@end

@implementation STPStrictURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    return [self propertyForKey:STPStrictURLProtocolRequestKey inRequest:request] != nil;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    NSMutableURLRequest *newRequest = [self.request mutableCopy];
    [self.class removePropertyForKey:STPStrictURLProtocolRequestKey inRequest:newRequest];
    self.connection = [NSURLConnection connectionWithRequest:[newRequest copy] delegate:self];
}

- (void)stopLoading {
    [self.connection cancel];
    self.connection = nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        // 30x redirects are automatically followed and will not reach here,
        // so we only need to check for successful 20x status codes.
        if (httpResponse.statusCode / 100 != 2 && httpResponse.statusCode != 301) {
            NSError *error = [[NSError alloc] initWithDomain:StripeDomain
                                                        code:STPConnectionError
                                                    userInfo:@{
                                                               NSLocalizedDescriptionKey: STPUnexpectedError,
                                                               STPErrorMessageKey: @"Stripe Checkout couldn't open. Please check your internet connection and try "
                                                               @"again. If the problem persists, please contact support@stripe.com."
                                                               }];
            [self.client URLProtocol:self didFailWithError:error];
            [connection cancel];
            self.connection = nil;
            return;
        }
    }
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
}

- (void)connection:(__unused NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.client URLProtocol:self didLoadData:data];
}

- (void)connectionDidFinishLoading:(__unused NSURLConnection *)connection {
    [self.client URLProtocolDidFinishLoading:self];
}

- (void)connection:(__unused NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self.client URLProtocol:self didFailWithError:error];
}


@end
