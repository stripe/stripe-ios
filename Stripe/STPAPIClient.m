//
//  STPAPIClient.m
//  StripeExample
//
//  Created by Jack Flintermann on 12/18/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#import "TargetConditionals.h"
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#import <sys/utsname.h>
#endif

#import "STPAPIClient.h"
#import "STPFormEncoder.h"
#import "STPBankAccount.h"
#import "STPCard.h"
#import "STPToken.h"
#import "StripeError.h"
#import "STPAPIResponseDecodable.h"
#import "STPAPIPostRequest.h"
#import "STPAnalyticsClient.h"

#if __has_include("Fabric.h")
#import "Fabric+FABKits.h"
#import "FABKitProtocol.h"
#endif

#ifdef STP_STATIC_LIBRARY_BUILD
#import "STPCategoryLoader.h"
#endif

#define FAUXPAS_IGNORED_IN_METHOD(...)

static NSString *const apiURLBase = @"api.stripe.com/v1";
static NSString *const tokenEndpoint = @"tokens";
static NSString *const stripeAPIVersion = @"2015-10-12";
static NSString *STPDefaultPublishableKey;

@implementation Stripe

+ (void)setDefaultPublishableKey:(NSString *)publishableKey {
    STPDefaultPublishableKey = publishableKey;
}

+ (NSString *)defaultPublishableKey {
    return STPDefaultPublishableKey;
}

+ (void)disableAnalytics {
    [STPAnalyticsClient disableAnalytics];
}

@end

#if __has_include("Fabric.h")
@interface STPAPIClient ()<NSURLSessionDelegate, FABKit>
#else
@interface STPAPIClient()<NSURLSessionDelegate>
#endif
@property (nonatomic, readwrite) NSURL *apiURL;
@property (nonatomic, readwrite) NSURLSession *urlSession;
@property (nonatomic, readwrite) STPAnalyticsClient *analyticsClient;
@end

@implementation STPAPIClient

#ifdef STP_STATIC_LIBRARY_BUILD
+ (void)initialize {
    [STPCategoryLoader loadCategories];
}
#endif

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
        _apiURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@", apiURLBase]];
        _publishableKey = [publishableKey copy];
        _operationQueue = [NSOperationQueue mainQueue];
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSString *auth = [@"Bearer " stringByAppendingString:self.publishableKey];
        config.HTTPAdditionalHeaders = @{
                                         @"X-Stripe-User-Agent": [self.class stripeUserAgentDetails],
                                         @"Stripe-Version": stripeAPIVersion,
                                         @"Authorization": auth,
                                         };
        _urlSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:_operationQueue];
        _analyticsClient = [[STPAnalyticsClient alloc] init];
    }
    return self;
}

- (void)setOperationQueue:(NSOperationQueue *)operationQueue {
    NSCAssert(operationQueue, @"Operation queue cannot be nil.");
    _operationQueue = operationQueue;
}

- (void)createTokenWithData:(NSData *)data
                  tokenType:(STPTokenType)tokenType
                 completion:(STPTokenCompletionBlock)completion {
    NSCAssert(data != nil, @"'data' is required to create a token");
    NSCAssert(completion != nil, @"'completion' is required to use the token that is created");
    NSDate *start = [NSDate date];
    NSString *publishableKey = self.publishableKey;
    [STPAPIPostRequest<STPToken *> startWithAPIClient:self
                                             endpoint:tokenEndpoint
                                             postData:data
                                           serializer:[STPToken new]
                                           completion:^(STPToken *object, NSHTTPURLResponse *response, NSError *error) {
                                               NSDate *end = [NSDate date];
                                               [self.analyticsClient logRUMWithTokenType:tokenType
                                                                          publishableKey:publishableKey
                                                                                response:response
                                                                                   start:start
                                                                                     end:end];
                                               completion(object, error);
                                           }];
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
        FAUXPAS_IGNORED_IN_METHOD(NSLogUsed);
        NSLog(@"ℹ️ You're using your Stripe testmode key. Make sure to use your livemode key when submitting to the App Store!");
    }
#endif
}
#pragma clang diagnostic pop

#pragma mark Utility methods -

+ (NSString *)stripeUserAgentDetails {
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
    return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:[details copy] options:0 error:NULL] encoding:NSUTF8StringEncoding];
}

#pragma mark Fabric
#if __has_include("Fabric.h")

+ (NSString *)bundleIdentifier {
    return @"com.stripe.stripe-ios";
}

+ (NSString *)kitDisplayVersion {
    return STPSDKVersion;
}

+ (void)initializeIfNeeded {
    Class fabric = NSClassFromString(@"Fabric");
    if (fabric) {
        // The app must be using Fabric, as it exists at runtime. We fetch our default publishable key from Fabric.
        NSDictionary *fabricConfiguration = [fabric configurationDictionaryForKitClass:[STPAPIClient class]];
        NSString *publishableKey = fabricConfiguration[@"publishable"];
        if (!publishableKey) {
            NSLog(@"Configuration dictionary returned by Fabric was nil, or doesn't have publishableKey. Can't initialize Stripe.");
            return;
        }
        [self validateKey:publishableKey];
        [Stripe setDefaultPublishableKey:publishableKey];
    } else {
        NSCAssert(fabric, @"initializeIfNeeded method called from a project that doesn't have Fabric.");
    }
}

#endif

@end

#pragma mark - Bank Accounts
@implementation STPAPIClient (BankAccounts)

- (void)createTokenWithBankAccount:(STPBankAccountParams *)bankAccount completion:(STPTokenCompletionBlock)completion {
    NSData *data = [STPFormEncoder formEncodedDataForObject:bankAccount];
    [self createTokenWithData:data tokenType:STPTokenTypeBankAccount completion:completion];
}

@end

#pragma mark - Credit Cards
@implementation STPAPIClient (CreditCards)

- (void)createTokenWithCard:(STPCard *)card completion:(STPTokenCompletionBlock)completion {
    NSData *data = [STPFormEncoder formEncodedDataForObject:card];
    [self createTokenWithData:data tokenType:STPTokenTypeCard completion:completion];
}

@end

@implementation Stripe (Deprecated)

+ (id)alloc {
    NSCAssert(NO, @"'Stripe' is a static class and cannot be instantiated.");
    return nil;
}

+ (void)createTokenWithCard:(STPCard *)card
             publishableKey:(NSString *)publishableKey
             operationQueue:(NSOperationQueue *)queue
                 completion:(STPCompletionBlock)handler {
    NSCAssert(card != nil, @"'card' is required to create a token");
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:publishableKey];
    client.operationQueue = queue;
    [client createTokenWithCard:card completion:handler];
}

+ (void)createTokenWithBankAccount:(STPBankAccount *)bankAccount
                    publishableKey:(NSString *)publishableKey
                    operationQueue:(NSOperationQueue *)queue
                        completion:(STPCompletionBlock)handler {
    NSCAssert(bankAccount != nil, @"'bankAccount' is required to create a token");
    NSCAssert(handler != nil, @"'handler' is required to use the token that is created");
    
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:publishableKey];
    client.operationQueue = queue;
    [client createTokenWithBankAccount:bankAccount completion:handler];
}

#pragma mark Shorthand methods -

+ (void)createTokenWithCard:(STPCard *)card completion:(STPCompletionBlock)handler {
    [self createTokenWithCard:card publishableKey:[self defaultPublishableKey] completion:handler];
}

+ (void)createTokenWithCard:(STPCard *)card publishableKey:(NSString *)publishableKey completion:(STPCompletionBlock)handler {
    [self createTokenWithCard:card publishableKey:publishableKey operationQueue:[NSOperationQueue mainQueue] completion:handler];
}

+ (void)createTokenWithCard:(STPCard *)card operationQueue:(NSOperationQueue *)queue completion:(STPCompletionBlock)handler {
    [self createTokenWithCard:card publishableKey:[self defaultPublishableKey] operationQueue:queue completion:handler];
}

+ (void)createTokenWithBankAccount:(STPBankAccount *)bankAccount completion:(STPCompletionBlock)handler {
    [self createTokenWithBankAccount:bankAccount publishableKey:[self defaultPublishableKey] completion:handler];
}

+ (void)createTokenWithBankAccount:(STPBankAccount *)bankAccount publishableKey:(NSString *)publishableKey completion:(STPCompletionBlock)handler {
    [self createTokenWithBankAccount:bankAccount publishableKey:publishableKey operationQueue:[NSOperationQueue mainQueue] completion:handler];
}

+ (void)createTokenWithBankAccount:(STPBankAccount *)bankAccount operationQueue:(NSOperationQueue *)queue completion:(STPCompletionBlock)handler {
    [self createTokenWithBankAccount:bankAccount publishableKey:[self defaultPublishableKey] operationQueue:queue completion:handler];
}

@end
