//
//  STPAPIClient.m
//  StripeExample
//
//  Created by Jack Flintermann on 12/18/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <sys/utsname.h>

#import "STPAPIClient.h"
#import "STPAPIClient+ApplePay.h"
#import "STPAPIClient+Private.h"

#import "NSBundle+Stripe_AppName.h"
#import "NSError+Stripe.h"
#import "STPAPIRequest.h"
#import "STPAnalyticsClient.h"
#import "STPBankAccount.h"
#import "STPCard.h"
#import "STPDispatchFunctions.h"
#import "STPEphemeralKey.h"
#import "STPFormEncoder.h"
#import "STPMultipartFormDataEncoder.h"
#import "STPMultipartFormDataPart.h"
#import "NSMutableURLRequest+Stripe.h"
#import "STPPaymentConfiguration.h"
#import "STPPaymentIntent+Private.h"
#import "STPPaymentIntentParams.h"
#import "STPSource+Private.h"
#import "STPSourceParams.h"
#import "STPSourceParams+Private.h"
#import "STPSourcePoller.h"
#import "STPTelemetryClient.h"
#import "STPToken.h"
#import "UIImage+Stripe.h"

#if __has_include("Fabric.h")
#import "Fabric+FABKits.h"
#import "FABKitProtocol.h"
#endif

#ifdef STP_STATIC_LIBRARY_BUILD
#import "STPCategoryLoader.h"
#endif

static NSString * const APIVersion = @"2015-10-12";
static NSString * const APIBaseURL = @"https://api.stripe.com/v1";
static NSString * const APIEndpointToken = @"tokens";
static NSString * const APIEndpointSources = @"sources";
static NSString * const APIEndpointCustomers = @"customers";
static NSString * const FileUploadURL = @"https://uploads.stripe.com/v1/files";
static NSString * const APIEndpointPaymentIntents = @"payment_intents";

#pragma mark - Stripe

@implementation Stripe

+ (void)setDefaultPublishableKey:(NSString *)publishableKey {
    [STPPaymentConfiguration sharedConfiguration].publishableKey = publishableKey;
}

+ (NSString *)defaultPublishableKey {
    return [STPPaymentConfiguration sharedConfiguration].publishableKey;
}

@end

#pragma mark - STPAPIClient

#if __has_include("Fabric.h")
@interface STPAPIClient ()<FABKit>
#else
@interface STPAPIClient()
#endif

@property (nonatomic, strong, readwrite) NSMutableDictionary<NSString *,NSObject *> *sourcePollers;
@property (nonatomic, strong, readwrite) dispatch_queue_t sourcePollersQueue;
@property (nonatomic, strong, readwrite) NSString *apiKey;

// See STPAPIClient+Private.h

@end

@implementation STPAPIClient

+ (NSString *)apiVersion {
    return APIVersion;
}

+ (void)initialize {
    [STPAnalyticsClient initializeIfNeeded];
    [STPTelemetryClient sharedInstance];
#ifdef STP_STATIC_LIBRARY_BUILD
    [STPCategoryLoader loadCategories];
#endif
}

+ (instancetype)sharedClient {
    static id sharedClient;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ sharedClient = [[self alloc] init]; });
    return sharedClient;
}

- (instancetype)init {
    return [self initWithConfiguration:[STPPaymentConfiguration sharedConfiguration]];
}

- (instancetype)initWithPublishableKey:(NSString *)publishableKey {
    STPPaymentConfiguration *config = [[STPPaymentConfiguration alloc] init];
    config.publishableKey = [publishableKey copy];
    return [self initWithConfiguration:config];
}

- (instancetype)initWithConfiguration:(STPPaymentConfiguration *)configuration {
    NSString *publishableKey = [configuration.publishableKey copy];
    if (publishableKey) {
        [self.class validateKey:publishableKey];
    }
    self = [super init];
    if (self) {
        _apiKey = publishableKey;
        _apiURL = [NSURL URLWithString:APIBaseURL];
        _configuration = configuration;
        _stripeAccount = configuration.stripeAccount;
        _sourcePollers = [NSMutableDictionary dictionary];
        _sourcePollersQueue = dispatch_queue_create("com.stripe.sourcepollers", DISPATCH_QUEUE_SERIAL);
        _urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    }
    return self;
}

- (NSMutableURLRequest *)configuredRequestForURL:(NSURL *)url {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [[self defaultHeaders] enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull key, NSString *  _Nonnull obj, __unused BOOL * _Nonnull stop) {
        [request setValue:obj forHTTPHeaderField:key];
    }];
    return request;
}

- (NSDictionary<NSString *, NSString *> *)defaultHeaders {
    NSMutableDictionary *additionalHeaders = [NSMutableDictionary new];
    additionalHeaders[@"X-Stripe-User-Agent"] = [self.class stripeUserAgentDetails];
    additionalHeaders[@"Stripe-Version"] = APIVersion;
    additionalHeaders[@"Authorization"] = [@"Bearer " stringByAppendingString:self.apiKey ?: @""];
    additionalHeaders[@"Stripe-Account"] = self.stripeAccount;
    return [additionalHeaders copy];
}

- (void)setPublishableKey:(NSString *)publishableKey {
    self.configuration.publishableKey = [publishableKey copy];
    self.apiKey = [publishableKey copy];
}

- (NSString *)publishableKey {
    return self.configuration.publishableKey;
}

- (void)createTokenWithParameters:(NSDictionary *)parameters
                       completion:(STPTokenCompletionBlock)completion {
    NSCAssert(parameters != nil, @"'parameters' is required to create a token");
    NSCAssert(completion != nil, @"'completion' is required to use the token that is created");
    NSString *tokenType = [STPAnalyticsClient tokenTypeFromParameters:parameters];
    [[STPAnalyticsClient sharedClient] logTokenCreationAttemptWithConfiguration:self.configuration
                                                                      tokenType:tokenType];
    [STPAPIRequest<STPToken *> postWithAPIClient:self
                                        endpoint:APIEndpointToken
                                      parameters:parameters
                                    deserializer:[STPToken new]
                                      completion:^(STPToken *object, __unused NSHTTPURLResponse *response, NSError *error) {
                                          completion(object, error);
                                      }];
}

#pragma mark Helpers

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
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSLog(@"ℹ️ You're using your Stripe testmode key. Make sure to use your livemode key when submitting to the App Store!");
        });
    }
#endif
}
#pragma clang diagnostic pop

+ (NSString *)stripeUserAgentDetails {
    NSMutableDictionary *details = [@{
        @"lang": @"objective-c",
        @"bindings_version": STPSDKVersion,
    } mutableCopy];
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

    NSString *vendorIdentifier = [UIDevice currentDevice].identifierForVendor.UUIDString;
    if (vendorIdentifier) {
        details[@"vendor_identifier"] = vendorIdentifier;
    }
    return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:[details copy] options:(NSJSONWritingOptions)kNilOptions error:NULL] encoding:NSUTF8StringEncoding];
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

- (void)createTokenWithBankAccount:(STPBankAccountParams *)bankAccount
                        completion:(STPTokenCompletionBlock)completion {
    NSMutableDictionary *params = [[STPFormEncoder dictionaryForObject:bankAccount] mutableCopy];
    [[STPTelemetryClient sharedInstance] addTelemetryFieldsToParams:params];
    [self createTokenWithParameters:params completion:completion];
    [[STPTelemetryClient sharedInstance] sendTelemetryData];
}

@end

#pragma mark - Personally Identifiable Information

@implementation STPAPIClient (PII)

- (void)createTokenWithPersonalIDNumber:(NSString *)pii completion:(__nullable STPTokenCompletionBlock)completion {
    NSMutableDictionary *params = [@{@"pii": @{ @"personal_id_number": pii }} mutableCopy];
    [[STPTelemetryClient sharedInstance] addTelemetryFieldsToParams:params];
    [self createTokenWithParameters:params completion:completion];
    [[STPTelemetryClient sharedInstance] sendTelemetryData];
}

@end

#pragma mark - Connect Accounts

@implementation STPAPIClient (ConnectAccounts)

- (void)createTokenWithConnectAccount:(STPConnectAccountParams *)account completion:(__nullable STPTokenCompletionBlock)completion {
    NSMutableDictionary *params = [[STPFormEncoder dictionaryForObject:account] mutableCopy];
    [[STPTelemetryClient sharedInstance] addTelemetryFieldsToParams:params];
    [self createTokenWithParameters:params completion:completion];
    [[STPTelemetryClient sharedInstance] sendTelemetryData];
}

@end

#pragma mark - Upload

@implementation STPAPIClient (Upload)

- (NSData *)dataForUploadedImage:(UIImage *)image
                         purpose:(STPFilePurpose)purpose {

    NSUInteger maxBytes;
    switch (purpose) {
        case STPFilePurposeIdentityDocument:
            maxBytes = 4 * 1000000;
            break;
        case STPFilePurposeDisputeEvidence:
            maxBytes = 8 * 1000000;
            break;
        case STPFilePurposeUnknown:
            maxBytes = 0;
            break;
    }
    return [image stp_jpegDataWithMaxFileSize:maxBytes];
}

- (void)uploadImage:(UIImage *)image
            purpose:(STPFilePurpose)purpose
         completion:(nullable STPFileCompletionBlock)completion {

    STPMultipartFormDataPart *purposePart = [[STPMultipartFormDataPart alloc] init];
    purposePart.name = @"purpose";
    purposePart.data = [[STPFile stringFromPurpose:purpose] dataUsingEncoding:NSUTF8StringEncoding];

    STPMultipartFormDataPart *imagePart = [[STPMultipartFormDataPart alloc] init];
    imagePart.name = @"file";
    imagePart.filename = @"image.jpg";
    imagePart.contentType = @"image/jpeg";

    imagePart.data = [self dataForUploadedImage:image
                                        purpose:purpose];

    NSString *boundary = [STPMultipartFormDataEncoder generateBoundary];
    NSData *data = [STPMultipartFormDataEncoder multipartFormDataForParts:@[purposePart, imagePart] boundary:boundary];

    NSMutableURLRequest *request = [self configuredRequestForURL:[NSURL URLWithString:FileUploadURL]];
    [request setHTTPMethod:@"POST"];
    [request stp_setMultipartFormData:data boundary:boundary];

    [[_urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable body, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSDictionary *jsonDictionary = body ? [NSJSONSerialization JSONObjectWithData:body options:(NSJSONReadingOptions)kNilOptions error:NULL] : nil;
        STPFile *file = [STPFile decodedObjectFromAPIResponse:jsonDictionary];

        NSError *returnedError = [NSError stp_errorFromStripeResponse:jsonDictionary] ?: error;
        if ((!file || ![response isKindOfClass:[NSHTTPURLResponse class]]) && !returnedError) {
            returnedError = [NSError stp_genericFailedToParseResponseError];
        }

        if (!completion) {
            return;
        }

        stpDispatchToMainThreadIfNecessary(^{
            if (returnedError) {
                completion(nil, returnedError);
            } else {
                completion(file, nil);
            }
        });
    }] resume];
}

@end

#pragma mark - Credit Cards

@implementation STPAPIClient (CreditCards)

- (void)createTokenWithCard:(STPCardParams *)cardParams completion:(STPTokenCompletionBlock)completion {
    NSMutableDictionary *params = [[STPFormEncoder dictionaryForObject:cardParams] mutableCopy];
    [[STPTelemetryClient sharedInstance] addTelemetryFieldsToParams:params];
    [self createTokenWithParameters:params completion:completion];
    [[STPTelemetryClient sharedInstance] sendTelemetryData];
}

@end

#pragma mark - Apple Pay

@implementation Stripe (ApplePay)

+ (BOOL)canSubmitPaymentRequest:(PKPaymentRequest *)paymentRequest {
    if (![self deviceSupportsApplePay]) {
        return NO;
    }
    if (paymentRequest == nil) {
        return NO;
    }
    if (paymentRequest.merchantIdentifier == nil) {
        return NO;
    }
    return [[[paymentRequest.paymentSummaryItems lastObject] amount] floatValue] > 0;
}

+ (NSArray<NSString *> *)supportedPKPaymentNetworks {
    NSArray *supportedNetworks = @[PKPaymentNetworkAmex, PKPaymentNetworkMasterCard, PKPaymentNetworkVisa];
    if ((&PKPaymentNetworkDiscover) != NULL) {
        supportedNetworks = [supportedNetworks arrayByAddingObject:PKPaymentNetworkDiscover];
    }
    return supportedNetworks;
}

+ (BOOL)deviceSupportsApplePay {
    return [PKPaymentAuthorizationViewController class] && [PKPaymentAuthorizationViewController canMakePaymentsUsingNetworks:[self supportedPKPaymentNetworks]];
}

+ (PKPaymentRequest *)paymentRequestWithMerchantIdentifier:(NSString *)merchantIdentifier {
    return [self paymentRequestWithMerchantIdentifier:merchantIdentifier country:@"US" currency:@"USD"];
}

+ (PKPaymentRequest *)paymentRequestWithMerchantIdentifier:(NSString *)merchantIdentifier
                                                   country:(NSString *)countryCode
                                                  currency:(NSString *)currencyCode {
    PKPaymentRequest *paymentRequest = [PKPaymentRequest new];
    [paymentRequest setMerchantIdentifier:merchantIdentifier];
    [paymentRequest setSupportedNetworks:[self supportedPKPaymentNetworks]];
    [paymentRequest setMerchantCapabilities:PKMerchantCapability3DS];
    [paymentRequest setCountryCode:countryCode.uppercaseString];
    [paymentRequest setCurrencyCode:currencyCode.uppercaseString];
    return paymentRequest;
}

@end

#pragma mark - Sources

@implementation STPAPIClient (Sources)

- (void)createSourceWithParams:(STPSourceParams *)sourceParams completion:(STPSourceCompletionBlock)completion {
    NSCAssert(sourceParams != nil, @"'params' is required to create a source");
    NSCAssert(completion != nil, @"'completion' is required to use the source that is created");
    NSString *sourceType = [STPSource stringFromType:sourceParams.type];
    [[STPAnalyticsClient sharedClient] logSourceCreationAttemptWithConfiguration:self.configuration
                                                                      sourceType:sourceType];
    sourceParams.redirectMerchantName = self.configuration.companyName ?: [NSBundle stp_applicationName];
    NSMutableDictionary *params = [[STPFormEncoder dictionaryForObject:sourceParams] mutableCopy];
    [[STPTelemetryClient sharedInstance] addTelemetryFieldsToParams:params];
    [STPAPIRequest<STPSource *> postWithAPIClient:self
                                         endpoint:APIEndpointSources
                                       parameters:params
                                     deserializer:[STPSource new]
                                       completion:^(STPSource *object, __unused NSHTTPURLResponse *response, NSError *error) {
                                           completion(object, error);
                                       }];
    [[STPTelemetryClient sharedInstance] sendTelemetryData];
}

- (void)retrieveSourceWithId:(NSString *)identifier clientSecret:(NSString *)secret completion:(STPSourceCompletionBlock)completion {
    NSCAssert(identifier != nil, @"'identifier' is required to retrieve a source");
    NSCAssert(secret != nil, @"'secret' is required to retrieve a source");
    NSCAssert(completion != nil, @"'completion' is required to use the source that is retrieved");
    [self retrieveSourceWithId:identifier clientSecret:secret responseCompletion:^(STPSource * object, __unused NSHTTPURLResponse *response, NSError *error) {
        completion(object, error);
    }];
}

- (NSURLSessionDataTask *)retrieveSourceWithId:(NSString *)identifier clientSecret:(NSString *)secret responseCompletion:(STPAPIResponseBlock)completion {
    NSString *endpoint = [NSString stringWithFormat:@"%@/%@", APIEndpointSources, identifier];
    NSDictionary *parameters = @{@"client_secret": secret};
    return [STPAPIRequest<STPSource *> getWithAPIClient:self
                                               endpoint:endpoint
                                             parameters:parameters
                                           deserializer:[STPSource new]
                                             completion:completion];
}

- (void)startPollingSourceWithId:(NSString *)identifier clientSecret:(NSString *)secret timeout:(NSTimeInterval)timeout completion:(STPSourceCompletionBlock)completion {
    [self stopPollingSourceWithId:identifier];
    STPSourcePoller *poller = [[STPSourcePoller alloc] initWithAPIClient:self
                                                            clientSecret:secret
                                                                sourceID:identifier
                                                                 timeout:timeout
                                                              completion:completion];
    dispatch_async(self.sourcePollersQueue, ^{
        self.sourcePollers[identifier] = poller;
    });
}

- (void)stopPollingSourceWithId:(NSString *)identifier {
    dispatch_async(self.sourcePollersQueue, ^{
        STPSourcePoller *poller = (STPSourcePoller *)self.sourcePollers[identifier];
        if (poller) {
            [poller stopPolling];
            self.sourcePollers[identifier] = nil;
        }
    });
}

@end

#pragma mark - Customers

@implementation STPAPIClient (Customers)

+ (STPAPIClient *)apiClientWithEphemeralKey:(STPEphemeralKey *)key {
    STPAPIClient *client = [[self alloc] init];
    client.apiKey = key.secret;
    return client;
}

+ (void)retrieveCustomerUsingKey:(STPEphemeralKey *)ephemeralKey completion:(STPCustomerCompletionBlock)completion {
    STPAPIClient *client = [self apiClientWithEphemeralKey:ephemeralKey];
    NSString *endpoint = [NSString stringWithFormat:@"%@/%@", APIEndpointCustomers, ephemeralKey.customerID];
    [STPAPIRequest<STPCustomer *> getWithAPIClient:client
                                          endpoint:endpoint
                                        parameters:nil
                                      deserializer:[STPCustomer new]
                                        completion:^(STPCustomer *object, __unused NSHTTPURLResponse *response, NSError *error) {
                                            completion(object, error);
                                        }];
}

+ (void)updateCustomerWithParameters:(NSDictionary *)parameters
                            usingKey:(STPEphemeralKey *)ephemeralKey
                          completion:(STPCustomerCompletionBlock)completion {
    STPAPIClient *client = [self apiClientWithEphemeralKey:ephemeralKey];
    NSString *endpoint = [NSString stringWithFormat:@"%@/%@", APIEndpointCustomers, ephemeralKey.customerID];
    [STPAPIRequest<STPCustomer *> postWithAPIClient:client
                                           endpoint:endpoint
                                         parameters:parameters
                                       deserializer:[STPCustomer new]
                                         completion:^(STPCustomer *object, __unused NSHTTPURLResponse *response, NSError *error) {
                                             completion(object, error);
                                         }];
}

+ (void)addSource:(NSString *)sourceID
toCustomerUsingKey:(STPEphemeralKey *)ephemeralKey
       completion:(STPSourceProtocolCompletionBlock)completion {
    STPAPIClient *client = [self apiClientWithEphemeralKey:ephemeralKey];
    NSString *endpoint = [NSString stringWithFormat:@"%@/%@/%@", APIEndpointCustomers, ephemeralKey.customerID, APIEndpointSources];
    [STPAPIRequest<STPSourceProtocol> postWithAPIClient:client
                                               endpoint:endpoint
                                             parameters:@{@"source": sourceID}
                                          deserializers:@[[STPCard new], [STPSource new]]
                                             completion:^(id object, __unused NSHTTPURLResponse *response, NSError *error) {
                                                 completion(object, error);
                                             }];
}

+ (void)deleteSource:(NSString *)sourceID fromCustomerUsingKey:(STPEphemeralKey *)ephemeralKey completion:(STPSourceProtocolCompletionBlock)completion {
    STPAPIClient *client = [self apiClientWithEphemeralKey:ephemeralKey];
    NSString *endpoint = [NSString stringWithFormat:@"%@/%@/%@/%@", APIEndpointCustomers, ephemeralKey.customerID, APIEndpointSources, sourceID];
    [STPAPIRequest<STPSourceProtocol> deleteWithAPIClient:client
                                                 endpoint:endpoint
                                               parameters:nil
                                            deserializers:@[[STPCard new], [STPSource new]]
                                               completion:^(id object, __unused NSHTTPURLResponse *response, NSError *error) {
                                                   completion(object, error);
                                               }];
}

@end

#pragma mark - Payment Intents

@implementation STPAPIClient (PaymentIntents)

- (void)retrievePaymentIntentWithClientSecret:(NSString *)secret
                                   completion:(STPPaymentIntentCompletionBlock)completion {
    NSCAssert(secret != nil, @"'secret' is required to retrieve a PaymentIntent");
    NSCAssert(completion != nil, @"'completion' is required to use the PaymentIntent that is retrieved");
    NSString *identifier = [STPPaymentIntent idFromClientSecret:secret];

    NSString *endpoint = [NSString stringWithFormat:@"%@/%@", APIEndpointPaymentIntents, identifier];

    [STPAPIRequest<STPPaymentIntent *> getWithAPIClient:self
                                               endpoint:endpoint
                                             parameters:@{ @"client_secret": secret }
                                           deserializer:[STPPaymentIntent new]
                                             completion:^(STPPaymentIntent *paymentIntent, __unused NSHTTPURLResponse *response, NSError *error) {
                                                 completion(paymentIntent, error);
                                             }];
}

- (void)confirmPaymentIntentWithParams:(STPPaymentIntentParams *)paymentIntentParams
                            completion:(STPPaymentIntentCompletionBlock)completion {
    NSCAssert(paymentIntentParams.clientSecret != nil, @"'clientSecret' is required to confirm a PaymentIntent");
    NSString *identifier = paymentIntentParams.stripeId;
    NSString *sourceType = [STPSource stringFromType:paymentIntentParams.sourceParams.type];
    [[STPAnalyticsClient sharedClient] logPaymentIntentConfirmationAttemptWithConfiguration:self.configuration
                                                                                 sourceType:sourceType];

    NSString *endpoint = [NSString stringWithFormat:@"%@/%@/confirm", APIEndpointPaymentIntents, identifier];

    NSMutableDictionary *params = [[STPFormEncoder dictionaryForObject:paymentIntentParams] mutableCopy];
    if ([params[@"source_data"] isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *sourceParamsDict = [params[@"source_data"] mutableCopy];
        [[STPTelemetryClient sharedInstance] addTelemetryFieldsToParams:sourceParamsDict];
        params[@"source_data"] = [sourceParamsDict copy];
    }

    [STPAPIRequest<STPPaymentIntent *> postWithAPIClient:self
                                                endpoint:endpoint
                                              parameters:[params copy]
                                            deserializer:[STPPaymentIntent new]
                                              completion:^(STPPaymentIntent *paymentIntent, __unused NSHTTPURLResponse *response, NSError *error) {
                                                  completion(paymentIntent, error);
                                              }];
}

@end
