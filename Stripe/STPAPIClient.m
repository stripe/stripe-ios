//
//  STPAPIClient.m
//  StripeExample
//
//  Created by Jack Flintermann on 12/18/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <sys/utsname.h>

#import <Stripe/Stripe3DS2.h>

#import "STPAPIClient.h"
#import "STPAPIClient+ApplePay.h"
#import "STPAPIClient+Private.h"

#import "NSBundle+Stripe_AppName.h"
#import "NSError+Stripe.h"
#import "NSMutableURLRequest+Stripe.h"
#import "STP3DS2AuthenticateResponse.h"
#import "STPAnalyticsClient.h"
#import "STPAPIRequest.h"
#import "STPBankAccount.h"
#import "STPCard.h"
#import "STPDispatchFunctions.h"
#import "STPEmptyStripeResponse.h"
#import "STPEphemeralKey.h"
#import "STPFormEncoder.h"
#import "STPFPXBankStatusResponse.h"
#import "STPGenericStripeObject.h"
#import "STPAppInfo.h"
#import "STPMultipartFormDataEncoder.h"
#import "STPMultipartFormDataPart.h"
#import "STPPaymentConfiguration.h"
#import "STPPaymentMethodListDeserializer.h"
#import "STPPaymentMethodParams.h"
#import "STPPaymentMethod+Private.h"
#import "STPPaymentIntent+Private.h"
#import "STPPaymentIntentParams.h"
#import "STPSetupIntent+Private.h"
#import "STPSetupIntentConfirmParams.h"
#import "STPSource+Private.h"
#import "STPSourceParams.h"
#import "STPSourceParams+Private.h"
#import "STPSourcePoller.h"
#import "STPTelemetryClient.h"
#import "STPToken.h"
#import "UIImage+Stripe.h"

#ifdef STP_STATIC_LIBRARY_BUILD
#import "STPCategoryLoader.h"
#endif

static NSString * const APIVersion = @"2019-05-16";
static NSString * const APIBaseURL = @"https://api.stripe.com/v1";
static NSString * const APIEndpointToken = @"tokens";
static NSString * const APIEndpointSources = @"sources";
static NSString * const APIEndpointCustomers = @"customers";
static NSString * const FileUploadURL = @"https://uploads.stripe.com/v1/files";
static NSString * const APIEndpointPaymentIntents = @"payment_intents";
static NSString * const APIEndpointSetupIntents = @"setup_intents";
static NSString * const APIEndpointPaymentMethods = @"payment_methods";
static NSString * const APIEndpoint3DS2 = @"3ds2";
static NSString * const APIEndpointFPXStatus = @"fpx/bank_statuses";

#pragma mark - Stripe

@implementation Stripe

static NSArray<PKPaymentNetwork> *_additionalEnabledApplePayNetworks;

+ (void)setDefaultPublishableKey:(NSString *)publishableKey {
    [STPAPIClient validateKey:publishableKey];
    [STPPaymentConfiguration sharedConfiguration].publishableKey = publishableKey;
}

+ (NSString *)defaultPublishableKey {
    return [STPPaymentConfiguration sharedConfiguration].publishableKey;
}

@end

#pragma mark - STPAPIClient

@interface STPAPIClient()

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
        _urlSession = [NSURLSession sessionWithConfiguration:[self.class sharedUrlSessionConfiguration]];
    }
    return self;
}

+ (NSURLSessionConfiguration *)sharedUrlSessionConfiguration {
    static NSURLSessionConfiguration  *STPSharedURLSessionConfiguration;
    static dispatch_once_t configToken;
    dispatch_once(&configToken, ^{
        STPSharedURLSessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    });
    return STPSharedURLSessionConfiguration;
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
    additionalHeaders[@"X-Stripe-User-Agent"] = [self.class stripeUserAgentDetailsWithAppInfo:self.appInfo];
    additionalHeaders[@"Stripe-Version"] = APIVersion;
    additionalHeaders[@"Authorization"] = [@"Bearer " stringByAppendingString:self.apiKey ?: @""];
    additionalHeaders[@"Stripe-Account"] = self.stripeAccount;
    return [additionalHeaders copy];
}

- (void)setPublishableKey:(NSString *)publishableKey {
    [self.class validateKey:publishableKey];
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
              @"You must use a valid publishable key. For more info, see https://stripe.com/docs/keys");
    BOOL secretKey = [publishableKey hasPrefix:@"sk_"];
    NSCAssert(!secretKey,
              @"You are using a secret key. Use a publishable key instead. For more info, see https://stripe.com/docs/keys");
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

+ (NSString *)stripeUserAgentDetailsWithAppInfo:(nullable STPAppInfo *)appInfo {
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
    if (appInfo) {
        details[@"name"] = appInfo.name;
        details[@"partner_id"] = appInfo.partnerId;
        if (appInfo.version) {
            details[@"version"] = appInfo.version;
        }
        if (appInfo.url) {
            details[@"url"] = appInfo.url;
        }
    }
    return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:[details copy] options:(NSJSONWritingOptions)kNilOptions error:NULL] encoding:NSUTF8StringEncoding];
}

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
    [[STPTelemetryClient sharedInstance] sendTelemetryData];}

- (void)createTokenWithSSNLast4:(NSString *)ssnLast4 completion:(STPTokenCompletionBlock)completion {
    NSMutableDictionary *params = [@{@"pii": @{ @"ssn_last_4": ssnLast4 }} mutableCopy];
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

- (void)createTokenForCVCUpdate:(NSString *)cvc completion:(nullable STPTokenCompletionBlock)completion {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:@{@"cvc": cvc} forKey:@"cvc_update"];
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
    
    return [supportedNetworks arrayByAddingObjectsFromArray:self.additionalEnabledApplePayNetworks];
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

+ (void)setJCBPaymentNetworkSupported:(BOOL)JCBPaymentNetworkSupported {
    if (@available(iOS 10.1, *)) {
        if (JCBPaymentNetworkSupported && ![self.additionalEnabledApplePayNetworks containsObject:PKPaymentNetworkJCB]) {
            self.additionalEnabledApplePayNetworks = [self.additionalEnabledApplePayNetworks arrayByAddingObject:PKPaymentNetworkJCB];
        } else if (!JCBPaymentNetworkSupported) {
            NSMutableArray<PKPaymentNetwork> *updatedNetworks = [self.additionalEnabledApplePayNetworks mutableCopy];
            [updatedNetworks removeObject:PKPaymentNetworkJCB];
            self.additionalEnabledApplePayNetworks = updatedNetworks;
        }
    }
}

+ (BOOL)isJCBPaymentNetworkSupported {
    if (@available(iOS 10.1, *)) {
        return [self.additionalEnabledApplePayNetworks containsObject:PKPaymentNetworkJCB];
    } else {
        return NO;
    }
}

+ (NSArray<PKPaymentNetwork> *)additionalEnabledApplePayNetworks {
    return _additionalEnabledApplePayNetworks ?: @[];
}

+ (void)setAdditionalEnabledApplePayNetworks:(NSArray<PKPaymentNetwork> *)additionalEnabledApplePayNetworks {
    _additionalEnabledApplePayNetworks = [additionalEnabledApplePayNetworks copy];
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
       completion:(STPSourceProtocolCompletionBlock)completion { FAUXPAS_IGNORED(UnusedMethod)
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

+ (void)deleteSource:(NSString *)sourceID fromCustomerUsingKey:(STPEphemeralKey *)ephemeralKey completion:(STPErrorBlock)completion { FAUXPAS_IGNORED_ON_LINE(UnusedMethod)
    STPAPIClient *client = [self apiClientWithEphemeralKey:ephemeralKey];
    NSString *endpoint = [NSString stringWithFormat:@"%@/%@/%@/%@", APIEndpointCustomers, ephemeralKey.customerID, APIEndpointSources, sourceID];
    [STPAPIRequest<STPSourceProtocol> deleteWithAPIClient:client
                                                 endpoint:endpoint
                                               parameters:nil
                                            deserializers:@[[STPGenericStripeObject new]]
                                               completion:^(__unused STPGenericStripeObject *object, __unused NSHTTPURLResponse *response, NSError *error) {
                                                   completion(error);
                                               }];
}

+ (void)attachPaymentMethod:(NSString *)paymentMethodID toCustomerUsingKey:(STPEphemeralKey *)ephemeralKey completion:(STPErrorBlock)completion {
    STPAPIClient *client = [self apiClientWithEphemeralKey:ephemeralKey];
    NSString *endpoint = [NSString stringWithFormat:@"%@/%@/attach", APIEndpointPaymentMethods, paymentMethodID];
    [STPAPIRequest<STPPaymentMethod *> postWithAPIClient:client
                                                endpoint:endpoint
                                              parameters:@{@"customer": ephemeralKey.customerID}
                                            deserializer:[STPPaymentMethod new]
                                              completion:^(__unused STPPaymentMethod *paymentMethod, __unused NSHTTPURLResponse *response, NSError *error) {
                                                  completion(error);
                                              }];
}

+ (void)detachPaymentMethod:(NSString *)paymentMethodID fromCustomerUsingKey:(STPEphemeralKey *)ephemeralKey completion:(STPErrorBlock)completion {
    STPAPIClient *client = [self apiClientWithEphemeralKey:ephemeralKey];
    NSString *endpoint = [NSString stringWithFormat:@"%@/%@/detach", APIEndpointPaymentMethods, paymentMethodID];
    [STPAPIRequest<STPPaymentMethod *> postWithAPIClient:client
                                                endpoint:endpoint
                                              parameters:nil
                                            deserializer:[STPPaymentMethod new]
                                              completion:^(__unused STPPaymentMethod *paymentMethod, __unused NSHTTPURLResponse *response, NSError *error) {
                                                  completion(error);
                                              }];
}

+ (void)listPaymentMethodsForCustomerUsingKey:(STPEphemeralKey *)ephemeralKey completion:(STPPaymentMethodsCompletionBlock)completion {
    STPAPIClient *client = [self apiClientWithEphemeralKey:ephemeralKey];
    NSDictionary *params = @{
                             @"customer": ephemeralKey.customerID,
                             @"type": [STPPaymentMethod stringFromType:STPPaymentMethodTypeCard],
                             };
    [STPAPIRequest<STPPaymentMethodListDeserializer *> getWithAPIClient:client
                                                          endpoint:APIEndpointPaymentMethods
                                                        parameters:params
                                                      deserializer:[STPPaymentMethodListDeserializer new]
                                                        completion:^(STPPaymentMethodListDeserializer *deserializer, __unused NSHTTPURLResponse *response, NSError *error) {
                                                            completion(deserializer.paymentMethods, error);
                                                        }];
}

@end

#pragma mark - ThreeDS2

@implementation STPAPIClient (ThreeDS2)

- (void)authenticate3DS2:(STDSAuthenticationRequestParameters *)authRequestParams
        sourceIdentifier:(NSString *)sourceID
               returnURL:(nullable NSString *)returnURLString
              maxTimeout:(NSInteger)maxTimeout
              completion:(STP3DS2AuthenticateCompletionBlock)completion {
    NSString *endpoint = [NSString stringWithFormat:@"%@/authenticate", APIEndpoint3DS2];

    NSMutableDictionary *appParams = [[STDSJSONEncoder dictionaryForObject:authRequestParams] mutableCopy];
    appParams[@"deviceRenderOptions"] = @{@"sdkInterface": @"03",
                                          @"sdkUiType": @[@"01", @"02", @"03", @"04", @"05"],
                                          };
    appParams[@"sdkMaxTimeout"] = [NSString stringWithFormat:@"%02ld", (long)maxTimeout];
    NSData *appData = [NSJSONSerialization dataWithJSONObject:appParams options:NSJSONWritingPrettyPrinted error:NULL];

    NSMutableDictionary *params = [@{@"app": [[NSString alloc] initWithData:appData encoding:NSUTF8StringEncoding],
                                    @"source": sourceID,
                                     } mutableCopy];
    if (returnURLString != nil) {
        params[@"fallback_return_url"] = returnURLString;
    }

     [STPAPIRequest<STP3DS2AuthenticateResponse *> postWithAPIClient:self
                                                            endpoint:endpoint
                                                          parameters:[params copy]
                                                        deserializer:[STP3DS2AuthenticateResponse new]
                                                          completion:^(STP3DS2AuthenticateResponse *authenticateResponse, __unused NSHTTPURLResponse *response, NSError *error) {
                                                              completion(authenticateResponse, error);
                                                          }];
}

- (void)complete3DS2AuthenticationForSource:(NSString *)sourceID completion:(STPBooleanSuccessBlock)completion {

    [STPAPIRequest<STPEmptyStripeResponse *> postWithAPIClient:self
                                                      endpoint:[NSString stringWithFormat:@"%@/challenge_complete", APIEndpoint3DS2]
                                                    parameters:@{ @"source": sourceID }
                                                  deserializer:[STPEmptyStripeResponse new]
                                                    completion:^(__unused STPEmptyStripeResponse *emptyResponse, NSHTTPURLResponse *response, NSError *responseError) {
                                                        completion(response.statusCode == 200, responseError);
                                                    }];
}

@end

#pragma mark - Payment Intents

@implementation STPAPIClient (PaymentIntents)

- (void)retrievePaymentIntentWithClientSecret:(NSString *)secret
                                   completion:(STPPaymentIntentCompletionBlock)completion {
    [self retrievePaymentIntentWithClientSecret:secret
                                         expand:nil
                                     completion:completion];
}

- (void)retrievePaymentIntentWithClientSecret:(NSString *)secret
                                       expand:(nullable NSArray<NSString *> *)expand
                                   completion:(STPPaymentIntentCompletionBlock)completion {
    NSCAssert(secret != nil, @"'secret' is required to retrieve a PaymentIntent");
    NSCAssert(completion != nil, @"'completion' is required to use the PaymentIntent that is retrieved");
    NSString *identifier = [STPPaymentIntent idFromClientSecret:secret];

    NSString *endpoint = [NSString stringWithFormat:@"%@/%@", APIEndpointPaymentIntents, identifier];

    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    parameters[@"client_secret"] = secret;
    if (expand.count > 0) {
        parameters[@"expand"] = expand;
    }

    [STPAPIRequest<STPPaymentIntent *> getWithAPIClient:self
                                               endpoint:endpoint
                                             parameters:[parameters copy]
                                           deserializer:[STPPaymentIntent new]
                                             completion:^(STPPaymentIntent *paymentIntent, __unused NSHTTPURLResponse *response, NSError *error) {
                                                 completion(paymentIntent, error);
                                             }];
}

- (void)confirmPaymentIntentWithParams:(STPPaymentIntentParams *)paymentIntentParams
                            completion:(STPPaymentIntentCompletionBlock)completion {
    [self confirmPaymentIntentWithParams:paymentIntentParams
                                  expand:nil
                              completion:completion];
}

- (void)confirmPaymentIntentWithParams:(STPPaymentIntentParams *)paymentIntentParams
                                expand:(nullable NSArray<NSString *> *)expand
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
    if (expand.count > 0) {
        params[@"expand"] = expand;
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

#pragma mark - Setup Intents

@implementation STPAPIClient (SetupIntents)

- (void)retrieveSetupIntentWithClientSecret:(NSString *)secret
                                   completion:(STPSetupIntentCompletionBlock)completion {
    NSCAssert(secret != nil, @"'secret' is required to retrieve a SetupIntent");
    NSCAssert(completion != nil, @"'completion' is required to use the SetupIntent that is retrieved");
    NSString *identifier = [STPSetupIntent idFromClientSecret:secret];
    
    NSString *endpoint = [NSString stringWithFormat:@"%@/%@", APIEndpointSetupIntents, identifier];
    
    [STPAPIRequest<STPSetupIntent *> getWithAPIClient:self
                                               endpoint:endpoint
                                             parameters:@{ @"client_secret": secret }
                                           deserializer:[STPSetupIntent new]
                                             completion:^(STPSetupIntent *setupIntent, __unused NSHTTPURLResponse *response, NSError *error) {
                                                 completion(setupIntent, error);
                                             }];
}

- (void)confirmSetupIntentWithParams:(STPSetupIntentConfirmParams *)setupIntentParams
                            completion:(STPSetupIntentCompletionBlock)completion {
    NSCAssert(setupIntentParams.clientSecret != nil, @"'clientSecret' is required to confirm a SetupIntent");

    NSString *paymentMethodType = [STPPaymentMethod stringFromType:setupIntentParams.paymentMethodParams.type];
    [[STPAnalyticsClient sharedClient] logSetupIntentConfirmationAttemptWithConfiguration:self.configuration
                                                                        paymentMethodType:paymentMethodType];

    NSString *identifier = [STPSetupIntent idFromClientSecret:setupIntentParams.clientSecret];
    NSString *endpoint = [NSString stringWithFormat:@"%@/%@/confirm", APIEndpointSetupIntents, identifier];
    NSDictionary *params = [STPFormEncoder dictionaryForObject:setupIntentParams];
    [STPAPIRequest<STPSetupIntent *> postWithAPIClient:self
                                                endpoint:endpoint
                                              parameters:params
                                            deserializer:[STPSetupIntent new]
                                              completion:^(STPSetupIntent *setupIntent, __unused NSHTTPURLResponse *response, NSError *error) {
                                                  completion(setupIntent, error);
                                              }];
}

@end

#pragma mark - Payment Methods

@implementation STPAPIClient (PaymentMethods)

- (void)createPaymentMethodWithParams:(STPPaymentMethodParams *)paymentMethodParams
                                 completion:(STPPaymentMethodCompletionBlock)completion {
    NSCAssert(paymentMethodParams != nil, @"'paymentMethodParams' is required to create a PaymentMethod");
    NSCAssert(paymentMethodParams.rawTypeString != nil, @"Set the `type` or `rawTypeString` property on paymentMethodParams.");
    [STPAPIRequest<STPPaymentMethod *> postWithAPIClient:self
                                               endpoint:APIEndpointPaymentMethods
                                             parameters:[STPFormEncoder dictionaryForObject:paymentMethodParams]
                                           deserializer:[STPPaymentMethod new]
                                             completion:^(STPPaymentMethod *paymentMethod, __unused NSHTTPURLResponse *response, NSError *error) {
                                                 if (error == nil && paymentMethod != nil) {
                                                     [[STPAnalyticsClient sharedClient] logPaymentMethodCreationSucceededWithConfiguration:self.configuration paymentMethodID:paymentMethod.stripeId];
                                                 }
                                                 completion(paymentMethod, error);
                                             }];

}

#pragma mark - FPX

- (void)retrieveFPXBankStatusWithCompletion:(STPFPXBankStatusCompletionBlock)completion {
    [STPAPIRequest<STPFPXBankStatusResponse *> getWithAPIClient:self
                                               endpoint:APIEndpointFPXStatus
                                             parameters:@{ @"account_holder_type": @"individual" }
                                           deserializer:[STPFPXBankStatusResponse new]
                                             completion:^(STPFPXBankStatusResponse *statusResponse, __unused NSHTTPURLResponse *response, NSError *error) {
                                                 completion(statusResponse, error);
                                             }];
}

@end
