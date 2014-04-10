//
//  STPAPIConnection.m
//  Stripe
//
//  Created by Phil Cohen on 4/9/14.
//

#import <CommonCrypto/CommonDigest.h>
#import "STPAPIConnection.h"

@interface STPAPIConnection () <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
@property (nonatomic) BOOL started;
@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableData *receivedData;
@property (nonatomic, strong) NSURLResponse *receivedResponse;
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
    _completionBlock(_receivedResponse, _receivedData, error); // Include what we received anyway.
}

#pragma mark NSURLConnectionDelegate

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    // Force NSURLAuthenticationMethodServerTrust.
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        if ([[self.class trustedHosts] containsObject:challenge.protectionSpace.host]) {
            NSURLCredential *urlCredential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
            [challenge.sender useCredential:urlCredential forAuthenticationChallenge:challenge];

            SecTrustRef serverTrust = [[challenge protectionSpace] serverTrust];
            for (CFIndex i = 0, count = SecTrustGetCertificateCount(serverTrust); i < count; i++) {
                [self.class verifyCertificate:SecTrustGetCertificateAtIndex(serverTrust, i) forChallenge:challenge];
            }
        }
    }
}

#pragma mark Certificate verification

+ (NSArray *)trustedHosts
{
    return @[@"api.stripe.com"];
}

+ (NSArray *)certificateBlacklist
{
    return @[@"86c0911d06a74fb66789119f1d732099"];
}

+ (void)verifyCertificate:(SecCertificateRef)certificate forChallenge:(NSURLAuthenticationChallenge *)challenge
{
    CFDataRef data = SecCertificateCopyData(certificate);
    NSString *fingerprint = [self.class MD5FingerprintOfData:(__bridge NSData *) data];
    CFRelease(data);

    if ([[self certificateBlacklist] containsObject:fingerprint]) {
        [[challenge sender] cancelAuthenticationChallenge:challenge];
        [NSException raise:@"InvalidCertificate" format:@"Invalid server certificate. You tried to connect to a server "
                "that has a revoked SSL certificate, which means we cannot securely send data to that server. "
                "Please email support@stripe.com if you need help connecting to the correct API server."];
    }
}

+ (NSString *)MD5FingerprintOfData:(NSData *)data
{
    unsigned char digest[CC_MD5_DIGEST_LENGTH];

    // Convert the NSData into a C buffer.
    void *cData = malloc([data length]);
    [data getBytes:cData length:[data length]];
    CC_MD5(cData, data.length, digest);

    // Convert to NSString.
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }

    free(cData);
    return [output lowercaseString];
}

@end