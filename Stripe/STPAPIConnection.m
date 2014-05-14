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

- (id)initWithRequest:(NSURLRequest *)request
{
    if (self = [super init]) {
        _request = request;
        _connection = [[NSURLConnection alloc] initWithRequest:_request delegate:self startImmediately:NO];
        _receivedData = [NSMutableData data];
    }
    return self;
}

- (void)runOnOperationQueue:(NSOperationQueue *)queue completion:(APIConnectionCompletionBlock)handler
{
    if (self.started) {
        [NSException raise:@"OperationNotPermitted" format:@"This API connection has already started."];
    }
    if (!queue) {
        [NSException raise:@"RequiredParameter" format:@"'queue' is required"];
    }
    if (!handler) {
        [NSException raise:@"RequiredParameter" format:@"'handler' is required"];
    }

    _started = YES;
    _completionBlock = [handler copy];
    [_connection setDelegateQueue:queue];
    [_connection start];
}

#pragma mark NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    _receivedResponse = response;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_receivedData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    _completionBlock(_receivedResponse, _receivedData, nil);
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (_overrideError) {
        error = _overrideError;
    }
    _completionBlock(_receivedResponse, _receivedData, error);
}

#pragma mark NSURLConnectionDelegate

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        SecTrustRef serverTrust = [[challenge protectionSpace] serverTrust];
        SecTrustResultType resultType;
        SecTrustEvaluate(serverTrust, &resultType);

        // Check for revocation manually since CFNetworking doesn't. (see https://revoked.stripe.com for more)
        for (CFIndex i = 0, count = SecTrustGetCertificateCount(serverTrust); i < count; i++) {
            if ([self.class isCertificateBlacklisted:SecTrustGetCertificateAtIndex(serverTrust, i)]) {
                _overrideError = [self.class blacklistedCertificateError];
                [challenge.sender cancelAuthenticationChallenge:challenge];
                return;
            }
        }

        [challenge.sender performDefaultHandlingForAuthenticationChallenge:challenge];
    }
}

#pragma mark Certificate verification

+ (NSArray *)certificateBlacklist
{
    return @[
            @"05c0b3643694470a888c6e7feb5c9e24e823dc53", // api.stripe.com
            @"5b7dc7fbc98d78bf76d4d4fa6f597a0c901fad5c" // revoked.stripe.com:444
    ];
}

+ (BOOL)isCertificateBlacklisted:(SecCertificateRef)certificate
{
    return [[self certificateBlacklist] containsObject:[self SHA1FingerprintOfCertificateData:certificate]];
}

+ (NSString *)SHA1FingerprintOfCertificateData:(SecCertificateRef)certificate
{
    CFDataRef data = SecCertificateCopyData(certificate);
    NSString *fingerprint = [self SHA1FingerprintOfData:(__bridge NSData *) data];
    CFRelease(data);

    return fingerprint;
}

+ (NSString *)SHA1FingerprintOfData:(NSData *)data
{
    unsigned char digest[CC_SHA1_DIGEST_LENGTH];

    // Convert the NSData into a C buffer.
    void *cData = malloc([data length]);
    [data getBytes:cData length:[data length]];
    CC_SHA1(cData, (CC_LONG) data.length, digest);

    // Convert to NSString.
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }

    free(cData);
    return [output lowercaseString];
}

+ (NSError *)blacklistedCertificateError
{
    return [[NSError alloc] initWithDomain:StripeDomain
                                      code:STPConnectionError
                                  userInfo:@{
                                          NSLocalizedDescriptionKey : STPUnexpectedError,
                                          STPErrorMessageKey : @"Invalid server certificate. You tried to connect to a server "
                                                  "that has a revoked SSL certificate, which means we cannot securely send data to that server. "
                                                  "Please email support@stripe.com if you need help connecting to the correct API server."
                                  }];
}

@end