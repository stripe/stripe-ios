//
//  STPAPIClient.m
//  StripeExample
//
//  Created by Jack Flintermann on 12/18/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import <objc/runtime.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#import <sys/utsname.h>
#endif

#import "STPAPIClient.h"
#import "STPBankAccount.h"
#import "STPCard.h"
#import "STPToken.h"
#import "StripeError.h"

static NSString *const apiURLBase = @"api.stripe.com";
static NSString *const apiVersion = @"v1";
static NSString *const tokenEndpoint = @"tokens";
static NSString *STPDefaultPublishableKey;
static char kAssociatedClientKey;

@implementation Stripe

+ (void)setDefaultPublishableKey:(NSString *)publishableKey {
    STPDefaultPublishableKey = publishableKey;
}

+ (NSString *)defaultPublishableKey {
    return STPDefaultPublishableKey;
}

@end

typedef void (^STPAPIConnectionCompletionBlock)(NSURLResponse *response, NSData *body, NSError *requestError);

// Like NSURLConnection but verifies that the server isn't using a revoked certificate.
@interface STPAPIConnection : NSObject<NSURLConnectionDelegate, NSURLConnectionDataDelegate>

- (instancetype)initWithRequest:(NSURLRequest *)request;
- (void)runOnOperationQueue:(NSOperationQueue *)queue completion:(STPAPIConnectionCompletionBlock)handler;

@property (nonatomic) BOOL started;
@property (nonatomic, copy) NSURLRequest *request;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableData *receivedData;
@property (nonatomic, strong) NSURLResponse *receivedResponse;
@property (nonatomic, strong) NSError *overrideError; // Replaces the request's error
@property (nonatomic, copy) STPAPIConnectionCompletionBlock completionBlock;

@end

@interface STPAPIClient ()
@property (nonatomic, readwrite) NSURL *apiURL;
@end

@implementation STPAPIClient

+ (instancetype)sharedClient {
    static id sharedClient;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ sharedClient = [[self alloc] init]; });
    return sharedClient;
}

- (instancetype)init {
    return [self initWithPublishableKey:[Stripe defaultPublishableKey]];
}

- (instancetype)initWithPublishableKey:(NSString *)publishableKey {
    self = [super init];
    if (self) {
        [self.class validateKey:publishableKey];
        _apiURL = [[[NSURL URLWithString:[NSString stringWithFormat:@"https://%@", apiURLBase]] URLByAppendingPathComponent:apiVersion]
            URLByAppendingPathComponent:tokenEndpoint];
        _publishableKey = [publishableKey copy];
        _operationQueue = [NSOperationQueue mainQueue];
    }
    return self;
}

- (void)setOperationQueue:(NSOperationQueue *)operationQueue {
    NSCAssert(operationQueue, @"Operation queue cannot be nil.");
    _operationQueue = operationQueue;
}

#pragma mark - private helpers

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-variable"
+ (void)validateKey:(NSString *)publishableKey {
    NSCAssert(publishableKey != nil && ![publishableKey isEqualToString:@""],
              @"You must use a valid publishable key to create a token. For more info, see https://stripe.com/docs/stripe.js");
    BOOL secretKey = [publishableKey hasPrefix:@"sk_"];
    NSCAssert(!secretKey,
              @"You are using a secret key to create a token, instead of the publishable one. For more info, see https://stripe.com/docs/stripe.js");
#ifndef DEBUG
    if ([publishableKey.lowercaseString hasPrefix:@"pk_test"]) {
        NSLog(@"⚠️ Warning! You're building your app in a non-debug configuration, but appear to be using your Stripe test key. Make sure not to submit to "
              @"the App Store with your test keys!⚠️");
    }
#endif
}
#pragma clang diagnostic pop

+ (NSError *)errorFromStripeResponse:(NSDictionary *)jsonDictionary {
    NSDictionary *errorDictionary = jsonDictionary[@"error"];
    NSString *type = errorDictionary[@"type"];
    NSString *devMessage = errorDictionary[@"message"];
    NSString *parameter = errorDictionary[@"param"];
    NSInteger code = 0;

    // There should always be a message and type for the error
    if (devMessage == nil || type == nil) {
        NSDictionary *userInfo = @{
            NSLocalizedDescriptionKey: STPUnexpectedError,
            STPErrorMessageKey: @"Could not interpret the error response that was returned from Stripe."
        };
        return [[NSError alloc] initWithDomain:StripeDomain code:STPAPIError userInfo:userInfo];
    }

    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[STPErrorMessageKey] = devMessage;

    if (parameter) {
        userInfo[STPErrorParameterKey] = [self stringByReplacingSnakeCaseWithCamelCase:parameter];
    }

    if ([type isEqualToString:@"api_error"]) {
        code = STPAPIError;
        userInfo[NSLocalizedDescriptionKey] = STPUnexpectedError;
    } else if ([type isEqualToString:@"invalid_request_error"]) {
        code = STPInvalidRequestError;
        userInfo[NSLocalizedDescriptionKey] = devMessage;
    } else if ([type isEqualToString:@"card_error"]) {
        code = STPCardError;
        NSDictionary *errorCodes = @{
            @"incorrect_number": @{@"code": STPIncorrectNumber, @"message": STPCardErrorInvalidNumberUserMessage},
            @"invalid_number": @{@"code": STPInvalidNumber, @"message": STPCardErrorInvalidNumberUserMessage},
            @"invalid_expiry_month": @{@"code": STPInvalidExpMonth, @"message": STPCardErrorInvalidExpMonthUserMessage},
            @"invalid_expiry_year": @{@"code": STPInvalidExpYear, @"message": STPCardErrorInvalidExpYearUserMessage},
            @"invalid_cvc": @{@"code": STPInvalidCVC, @"message": STPCardErrorInvalidCVCUserMessage},
            @"expired_card": @{@"code": STPExpiredCard, @"message": STPCardErrorExpiredCardUserMessage},
            @"incorrect_cvc": @{@"code": STPIncorrectCVC, @"message": STPCardErrorInvalidCVCUserMessage},
            @"card_declined": @{@"code": STPCardDeclined, @"message": STPCardErrorDeclinedUserMessage},
            @"processing_error": @{@"code": STPProcessingError, @"message": STPCardErrorProcessingErrorUserMessage},
        };
        NSDictionary *codeMapEntry = errorCodes[errorDictionary[@"code"]];

        if (codeMapEntry) {
            userInfo[STPCardErrorCodeKey] = codeMapEntry[@"code"];
            userInfo[NSLocalizedDescriptionKey] = codeMapEntry[@"message"];
        } else {
            userInfo[STPCardErrorCodeKey] = errorDictionary[@"code"];
            userInfo[NSLocalizedDescriptionKey] = devMessage;
        }
    }

    return [[NSError alloc] initWithDomain:StripeDomain code:code userInfo:userInfo];
}

#pragma mark Utility methods -

+ (NSDictionary *)stripeUserAgentDetails {
    NSMutableDictionary *details = [@{
        @"lang": @"objective-c",
        @"bindings_version": STPSDKVersion,
    } mutableCopy];
#if TARGET_OS_IPHONE
    NSString *version = [UIDevice currentDevice].systemVersion;
    if (version) {
        details[@"os_version"] = version;
    }
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceType = @(systemInfo.machine);
    if (deviceType) {
        details[@"type"] = deviceType;
    }
    NSString *model = [UIDevice currentDevice].localizedModel;
    if (model) {
        details[@"model"] = model;
    }
    if ([[UIDevice currentDevice] respondsToSelector:@selector(identifierForVendor)]) {
        NSString *vendorIdentifier = [[[UIDevice currentDevice] performSelector:@selector(identifierForVendor)] performSelector:@selector(UUIDString)];
        if (vendorIdentifier) {
            details[@"vendor_identifier"] = vendorIdentifier;
        }
    }
#endif
    return [details copy];
}

+ (NSString *)JSONStringForObject:(id)object {
    return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:object options:0 error:NULL] encoding:NSUTF8StringEncoding];
}

@end

#pragma mark - Bank Accounts
@implementation STPAPIClient (BankAccounts)

- (void)createTokenWithBankAccount:(STPBankAccount *)bankAccount completion:(STPCompletionBlock)completion {
    [self createTokenWithData:[self.class formEncodedDataForBankAccount:bankAccount] completion:completion];
}

@end

#pragma mark - Credit Cards
@implementation STPAPIClient (CreditCards)

- (void)createTokenWithCard:(STPCard *)card completion:(STPCompletionBlock)completion {
    [self createTokenWithData:[self.class formEncodedDataForCard:card] completion:completion];
}

@end

@implementation STPAPIClient (PrivateMethods)

- (void)createTokenWithData:(NSData *)data completion:(STPCompletionBlock)completion {
    NSCAssert(data != nil, @"'data' is required to create a token");
    NSCAssert(completion != nil, @"'completion' is required to use the token that is created");

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.apiURL];
    request.HTTPMethod = @"POST";
    request.HTTPBody = data;
    [request setValue:[self.class JSONStringForObject:[self.class stripeUserAgentDetails]] forHTTPHeaderField:@"X-Stripe-User-Agent"];
    [request setValue:[@"Bearer " stringByAppendingString:self.publishableKey] forHTTPHeaderField:@"Authorization"];

    STPAPIConnection *connection = [[STPAPIConnection alloc] initWithRequest:request];

    // use the runtime to ensure we're not dealloc'ed before completion
    objc_setAssociatedObject(connection, &kAssociatedClientKey, self, OBJC_ASSOCIATION_RETAIN);

    [connection runOnOperationQueue:self.operationQueue
                         completion:^(NSURLResponse *response, NSData *body, NSError *requestError) {
                             if (requestError) {
                                 // If this is an error that Stripe returned, let's handle it as a StripeDomain error
                                 if (body) {
                                     NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:body options:0 error:NULL];
                                     if ([jsonDictionary valueForKey:@"error"] != nil) {
                                         completion(nil, [self.class errorFromStripeResponse:jsonDictionary]);
                                         return;
                                     }
                                 }
                                 completion(nil, requestError);
                                 return;
                             } else {
                                 NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:body options:0 error:NULL];
                                 if (!jsonDictionary) {
                                     NSDictionary *userInfo = @{
                                         NSLocalizedDescriptionKey: STPUnexpectedError,
                                         STPErrorMessageKey: @"The response from Stripe failed to get parsed into valid JSON."
                                     };
                                     NSError *error = [[NSError alloc] initWithDomain:StripeDomain code:STPAPIError userInfo:userInfo];
                                     completion(nil, error);
                                 } else if ([(NSHTTPURLResponse *)response statusCode] == 200) {
                                     completion([[STPToken alloc] initWithAttributeDictionary:jsonDictionary], nil);
                                 } else {
                                     completion(nil, [self.class errorFromStripeResponse:jsonDictionary]);
                                 }
                             }
                             // at this point it's safe to be dealloced
                             objc_setAssociatedObject(connection, &kAssociatedClientKey, nil, OBJC_ASSOCIATION_RETAIN);
                         }];
}

+ (NSData *)formEncodedDataForBankAccount:(STPBankAccount *)bankAccount {
    NSCAssert(bankAccount != nil, @"Cannot create a token with a nil bank account.");
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    NSMutableArray *parts = [NSMutableArray array];

    if (bankAccount.accountNumber) {
        params[@"account_number"] = bankAccount.accountNumber;
    }
    if (bankAccount.routingNumber) {
        params[@"routing_number"] = bankAccount.routingNumber;
    }
    if (bankAccount.country) {
        params[@"country"] = bankAccount.country;
    }

    [params enumerateKeysAndObjectsUsingBlock:^(id key, id val, __unused BOOL *stop) {
        [parts addObject:[NSString stringWithFormat:@"bank_account[%@]=%@", key, [self.class stringByURLEncoding:val]]];
    }];

    return [[parts componentsJoinedByString:@"&"] dataUsingEncoding:NSUTF8StringEncoding];
}

+ (NSData *)formEncodedDataForCard:(STPCard *)card {
    NSCAssert(card != nil, @"Cannot create a token with a nil card.");
    NSMutableDictionary *params = [NSMutableDictionary dictionary];

    if (card.number) {
        params[@"number"] = card.number;
    }
    if (card.cvc) {
        params[@"cvc"] = card.cvc;
    }
    if (card.name) {
        params[@"name"] = card.name;
    }
    if (card.addressLine1) {
        params[@"address_line1"] = card.addressLine1;
    }
    if (card.addressLine2) {
        params[@"address_line2"] = card.addressLine2;
    }
    if (card.addressCity) {
        params[@"address_city"] = card.addressCity;
    }
    if (card.addressState) {
        params[@"address_state"] = card.addressState;
    }
    if (card.addressZip) {
        params[@"address_zip"] = card.addressZip;
    }
    if (card.addressCountry) {
        params[@"address_country"] = card.addressCountry;
    }
    if (card.expMonth) {
        params[@"exp_month"] = @(card.expMonth).stringValue;
    }
    if (card.expYear) {
        params[@"exp_year"] = @(card.expYear).stringValue;
    }

    NSMutableArray *parts = [NSMutableArray array];

    [params enumerateKeysAndObjectsUsingBlock:^(id key, id val, __unused BOOL *stop) {
        [parts addObject:[NSString stringWithFormat:@"card[%@]=%@", key, [self.class stringByURLEncoding:val]]];

    }];

    return [[parts componentsJoinedByString:@"&"] dataUsingEncoding:NSUTF8StringEncoding];
}

/* This code is adapted from the code by David DeLong in this StackOverflow post:
 http://stackoverflow.com/questions/3423545/objective-c-iphone-percent-encode-a-string .  It is protected under the terms of a Creative Commons
 license: http://creativecommons.org/licenses/by-sa/3.0/
 */
+ (NSString *)stringByURLEncoding:(NSString *)string {
    NSMutableString *output = [NSMutableString string];
    const unsigned char *source = (const unsigned char *)[string UTF8String];
    NSInteger sourceLen = strlen((const char *)source);
    for (int i = 0; i < sourceLen; ++i) {
        const unsigned char thisChar = source[i];
        if (thisChar == ' ') {
            [output appendString:@"+"];
        } else if (thisChar == '.' || thisChar == '-' || thisChar == '_' || thisChar == '~' || (thisChar >= 'a' && thisChar <= 'z') ||
                   (thisChar >= 'A' && thisChar <= 'Z') || (thisChar >= '0' && thisChar <= '9')) {
            [output appendFormat:@"%c", thisChar];
        } else {
            [output appendFormat:@"%%%02X", thisChar];
        }
    }
    return output;
}

+ (NSString *)stringByReplacingSnakeCaseWithCamelCase:(NSString *)input {
    NSArray *parts = [input componentsSeparatedByString:@"_"];
    NSMutableString *camelCaseParam = [NSMutableString string];
    [parts enumerateObjectsUsingBlock:^(NSString *part, NSUInteger idx, __unused BOOL *stop) {
        [camelCaseParam appendString:(idx == 0 ? part : [part capitalizedString])];
    }];

    return [camelCaseParam copy];
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

@end

@implementation STPAPIConnection

- (instancetype)initWithRequest:(NSURLRequest *)request {
    if (self = [super init]) {
        _request = request;
        _connection = [[NSURLConnection alloc] initWithRequest:_request delegate:self startImmediately:NO];
        _receivedData = [[NSMutableData alloc] init];
    }
    return self;
}

- (void)runOnOperationQueue:(NSOperationQueue *)queue completion:(STPAPIConnectionCompletionBlock)handler {
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
    NSString *fingerprint = [STPAPIClient SHA1FingerprintOfData:(__bridge NSData *)data];
    CFRelease(data);

    return fingerprint;
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
