//
//  STPCheckoutURLProtocol.m
//  Stripe
//
//  Created by Jack Flintermann on 11/14/14.
//
//

#import "STPCheckoutURLProtocol.h"
#import "StripeError.h"

static NSString *const STPCheckoutURLProtocolRequestKey = @"STPCheckoutURLProtocolRequestKey";

@interface STPCheckoutURLProtocol ()
@property (nonatomic, strong) NSURLConnection *connection;
@end

@implementation STPCheckoutURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    return [request.URL.host isEqualToString:@"checkout.stripe.com"] && ![NSURLProtocol propertyForKey:STPCheckoutURLProtocolRequestKey inRequest:request];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    NSMutableURLRequest *newRequest = [self.request mutableCopy];
    [NSURLProtocol setProperty:@YES forKey:STPCheckoutURLProtocolRequestKey inRequest:newRequest];
    self.connection = [NSURLConnection connectionWithRequest:newRequest delegate:self];
}

- (void)stopLoading {
    [self.connection cancel];
    self.connection = nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode / 100 != 2) {
            NSError *error = [[NSError alloc] initWithDomain:StripeDomain
                                                        code:STPConnectionError
                                                    userInfo:@{
                                                        NSLocalizedDescriptionKey: STPUnexpectedError,
                                                        STPErrorMessageKey: @"There was an unexpected error connecting to Stripe Checkout. Please contact "
                                                                            @"support@stripe.com if you're repeatedly seeing this error."
                                                    }];
            [self.client URLProtocol:self didFailWithError:error];
            [connection cancel];
            self.connection = nil;
            return;
        }
    }
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.client URLProtocol:self didLoadData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self.client URLProtocolDidFinishLoading:self];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self.client URLProtocol:self didFailWithError:error];
}

@end
