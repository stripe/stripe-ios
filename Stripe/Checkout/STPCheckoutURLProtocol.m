//
//  STPCheckoutURLProtocol.m
//  Stripe
//
//  Created by Jack Flintermann on 11/14/14.
//
//

#import "STPCheckoutURLProtocol.h"
#import "StripeError.h"

NSString *const STPCheckoutURLProtocolRequestScheme = @"STPCheckoutURLProtocolRequestScheme";

@interface STPCheckoutURLProtocol () <NSURLConnectionDataDelegate>
@property (nonatomic, strong) NSURLConnection *connection;
@end

@implementation STPCheckoutURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    return [request.URL.scheme.lowercaseString isEqualToString:STPCheckoutURLProtocolRequestScheme.lowercaseString];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    NSMutableURLRequest *newRequest = [self.request mutableCopy];
    NSString *oldURLString = [[newRequest.URL absoluteString] lowercaseString];
    newRequest.URL =
        [NSURL URLWithString:[oldURLString stringByReplacingOccurrencesOfString:STPCheckoutURLProtocolRequestScheme.lowercaseString withString:@"http"]];
    self.connection = [NSURLConnection connectionWithRequest:newRequest delegate:self];
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
                                                        STPErrorMessageKey: @"Stripe Checkout couldn't open. Please check your internet connection and try again. If the problem persists, please contact support@stripe.com."
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
