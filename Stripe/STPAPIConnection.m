//
//  STPAPIConnection.m
//  Stripe
//
//  Created by Phil Cohen on 4/9/14.
//

#import <CommonCrypto/CommonDigest.h>
#import "STPAPIConnection.h"
#import "StripeError.h"

@interface STPAPIConnection () <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (nonatomic) BOOL started;
@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableData *receivedData;
@property (nonatomic, strong) NSURLResponse *receivedResponse;
@property (nonatomic, strong) NSError *overrideError; // Replaces the request's error
@property (nonatomic, copy) APIConnectionCompletionBlock completionBlock;

@end

@implementation STPAPIConnection

- (instancetype)initWithRequest:(NSURLRequest *)request {
    if (self = [super init]) {
        _request = request;
        _connection = [[NSURLConnection alloc] initWithRequest:_request delegate:self startImmediately:NO];
        _receivedData = [[NSMutableData alloc] init]; ///[NSMutableData data];
    }
    return self;
}

- (void)runOnOperationQueue:(NSOperationQueue *)queue completion:(APIConnectionCompletionBlock)handler {
    NSCAssert(!self.started, @"This API connection has already started.");
    NSCAssert(queue, @"'queue' is required");
    NSCAssert(handler, @"'handler' is required");

    self.started = YES;
    self.completionBlock = handler;
    [self.connection setDelegateQueue:queue];
    [self.connection start];
}

#pragma mark NSURLConnectionDataDelegate

- (void)connection:(__unused NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    self.receivedResponse = response;
}

- (void)connection:(__unused NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.receivedData appendData:data];
}

- (void)connectionDidFinishLoading:(__unused NSURLConnection *)connection {
    self.connection = nil;
    self.completionBlock(self.receivedResponse, self.receivedData, nil);
    self.receivedData = nil;
    self.receivedResponse = nil;
}

#pragma mark NSURLConnectionDelegate

- (void)connection:(__unused NSURLConnection *)connection didFailWithError:(NSError *)error {
    self.connection = nil;
    self.receivedData = nil;
    self.receivedResponse = nil;
    self.completionBlock(self.receivedResponse, self.receivedData, self.overrideError ?: error);
}

- (void)connection:(__unused NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        SecTrustRef serverTrust = [[challenge protectionSpace] serverTrust];
        SecTrustResultType resultType;
        SecTrustEvaluate(serverTrust, &resultType);

        // Check for revocation manually since CFNetworking doesn't. (see https://revoked.stripe.com for more)
        for (CFIndex i = 0, count = SecTrustGetCertificateCount(serverTrust); i < count; i++) {
            if ([self.class isCertificateBlacklisted:SecTrustGetCertificateAtIndex(serverTrust, i)]) {
                self.overrideError = [self.class blacklistedCertificateError];
                [challenge.sender cancelAuthenticationChallenge:challenge];
                return;
            }
        }

        [challenge.sender performDefaultHandlingForAuthenticationChallenge:challenge];
    } else if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodDefault]) {
        // If this is an HTTP Authorization request, just continue. We want to bubble this back through the
        // request's error handler.
        [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
    } else {
        [challenge.sender performDefaultHandlingForAuthenticationChallenge:challenge];
    }
}

#pragma mark Certificate verification

+ (NSArray *)certificateBlacklist {
    return @[
        @"05c0b3643694470a888c6e7feb5c9e24e823dc53", // api.stripe.com
        @"5b7dc7fbc98d78bf76d4d4fa6f597a0c901fad5c"  // revoked.stripe.com:444
    ];
}

+ (BOOL)isCertificateBlacklisted:(SecCertificateRef)certificate {
    return [[self certificateBlacklist] containsObject:[self SHA1FingerprintOfCertificateData:certificate]];
}

+ (NSString *)SHA1FingerprintOfCertificateData:(SecCertificateRef)certificate {
    CFDataRef data = SecCertificateCopyData(certificate);
    NSString *fingerprint = [self SHA1FingerprintOfData:(__bridge NSData *)data];
    CFRelease(data);

    return fingerprint;
}

+ (NSString *)SHA1FingerprintOfData:(NSData *)data {
    unsigned int outputLength = CC_SHA1_DIGEST_LENGTH;
    unsigned char output[outputLength];

    CC_SHA1(data.bytes, (unsigned int)data.length, output);
    NSMutableString *hash = [NSMutableString stringWithCapacity:outputLength * 2];
    for (unsigned int i = 0; i < outputLength; i++) {
        [hash appendFormat:@"%02x", output[i]];
    }
    return [hash copy];
}

+ (NSError *)blacklistedCertificateError {
    return [[NSError alloc] initWithDomain:StripeDomain
                                      code:STPConnectionError
                                  userInfo:@{
                                      NSLocalizedDescriptionKey: STPUnexpectedError,
                                      STPErrorMessageKey: @"Invalid server certificate. You tried to connect to a server "
                                                           "that has a revoked SSL certificate, which means we cannot securely send data to that server. "
                                                           "Please email support@stripe.com if you need help connecting to the correct API server."
                                  }];
}

@end
