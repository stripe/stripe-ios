//
//  STPAnalyticsClient.m
//  Stripe
//
//  Created by Ben Guo on 4/22/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPAnalyticsClient.h"

#import "NSBundle+Stripe_AppName.h"
#import "NSMutableURLRequest+Stripe.h"
#import "STPAPIClient+ApplePay.h"
#import "STPAPIClient.h"
#import "STPAPIClient+Private.h"
#import "STPAddCardViewController+Private.h"
#import "STPAddCardViewController.h"
#import "STPCard.h"
#import "STPCardIOProxy.h"
#import "STPFormEncodable.h"
#import "STPPaymentCardTextField.h"
#import "STPPaymentCardTextField+Private.h"
#import "STPPaymentConfiguration.h"
#import "STPPaymentContext.h"
#import "STPPaymentOptionsViewController+Private.h"
#import "STPPaymentOptionsViewController.h"
#import "STPToken.h"
#import <UIKit/UIKit.h>
#import <sys/utsname.h>

@interface STPAnalyticsClient()

@property (nonatomic) NSMutableSet *productUsage;
@property (nonatomic) NSSet *additionalInfoSet;
@property (nonatomic, readwrite) NSURLSession *urlSession;

@end

@implementation STPAnalyticsClient

+ (instancetype)sharedClient {
    static id sharedClient;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedClient = [self new];
    });
    return sharedClient;
}

+ (BOOL)shouldCollectAnalytics {
#if TARGET_OS_SIMULATOR
    return NO;
#else
    return NSClassFromString(@"XCTest") == nil;
#endif
}

+ (NSString *)tokenTypeFromParameters:(NSDictionary *)parameters {
    NSArray *parameterKeys = parameters.allKeys;
    // these are currently mutually exclusive, so we can just run through and find the first match
    NSArray *tokenTypes = @[@"account", @"bank_account", @"card", @"pii", @"cvc_update"];
    for (NSString *type in tokenTypes) {
        if ([parameterKeys containsObject:type]) {
            return type;
        }
    }
    // We want to use a different value for pk_token, that's why it's not above
    if ([parameterKeys containsObject:@"pk_token"]) {
        return @"apple_pay";
    }
    return nil;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *config = [STPAPIClient sharedUrlSessionConfiguration];
        _urlSession = [NSURLSession sessionWithConfiguration:config];
        _productUsage = [NSMutableSet set];
        _additionalInfoSet = [NSSet set];
    }
    return self;
}

- (void)addClassToProductUsageIfNecessary:(Class)klass {
    @synchronized (self) {
        [self.productUsage addObject:NSStringFromClass(klass)];
    }
}

- (void)addAdditionalInfo:(NSString *)info {
    self.additionalInfoSet = [self.additionalInfoSet setByAddingObject:info];
}

- (void)clearAdditionalInfo {
    self.additionalInfoSet = [NSSet set];
}

- (NSArray *)additionalInfo {
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(description)) ascending:YES];
    NSArray *additionalInfo = [self.additionalInfoSet sortedArrayUsingDescriptors:@[sortDescriptor]];
    return additionalInfo ?: @[];
}

- (NSDictionary *)productUsageDictionary {
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(description)) ascending:YES];
    NSMutableDictionary *usage = [NSMutableDictionary new];
    NSArray *productUsage;
    @synchronized (self) {
        productUsage = [self.productUsage sortedArrayUsingDescriptors:@[sortDescriptor]] ?: @[];
    }

    NSString *uiUsageLevel = nil;
    if ([self.productUsage containsObject:NSStringFromClass([STPPaymentContext class])]) {
        uiUsageLevel = @"full";
    } else if (self.productUsage.count == 1
             && [self.productUsage containsObject:NSStringFromClass([STPPaymentCardTextField class])]) {
        uiUsageLevel = @"card_text_field";
    } else if (self.productUsage.count > 0) {
        uiUsageLevel = @"partial";
    } else {
        uiUsageLevel = @"none";
    }
    usage[@"ui_usage_level"] = uiUsageLevel;
    usage[@"product_usage"] = productUsage;

    return [usage copy];
}

- (void)logTokenCreationAttemptWithConfiguration:(STPPaymentConfiguration *)configuration
                                       tokenType:(NSString *)tokenType {
    NSDictionary *configurationDictionary = [self.class serializeConfiguration:configuration];
    NSMutableDictionary *payload = [self.class commonPayload];
    [payload addEntriesFromDictionary:@{
                                        @"event": @"stripeios.token_creation",
                                        @"token_type": tokenType ?: @"unknown",
                                        @"additional_info": [self additionalInfo],
                                        }];
    [payload addEntriesFromDictionary:[self productUsageDictionary]];
    [payload addEntriesFromDictionary:configurationDictionary];
    [self logPayload:payload];
}

- (void)logSourceCreationAttemptWithConfiguration:(STPPaymentConfiguration *)configuration
                                       sourceType:(NSString *)sourceType {
    NSDictionary *configurationDictionary = [self.class serializeConfiguration:configuration];
    NSMutableDictionary *payload = [self.class commonPayload];
    [payload addEntriesFromDictionary:@{
                                        @"event": @"stripeios.source_creation",
                                        @"source_type": sourceType ?: @"unknown",
                                        @"additional_info": [self additionalInfo],
                                        }];
    [payload addEntriesFromDictionary:[self productUsageDictionary]];
    [payload addEntriesFromDictionary:configurationDictionary];
    [self logPayload:payload];
}

- (void)logPaymentMethodCreationAttemptWithConfiguration:(STPPaymentConfiguration *)configuration
                                       paymentMethodType:(NSString *)paymentMethodType {
    NSDictionary *configurationDictionary = [self.class serializeConfiguration:configuration];
    NSMutableDictionary *payload = [self.class commonPayload];
    [payload addEntriesFromDictionary:@{
                                        @"event": @"stripeios.payment_method_creation",
                                        @"source_type": paymentMethodType ?: @"unknown",
                                        @"additional_info": [self additionalInfo],
                                        }];
    [payload addEntriesFromDictionary:[self productUsageDictionary]];
    [payload addEntriesFromDictionary:configurationDictionary];
    [self logPayload:payload];
}

- (void)logPaymentIntentConfirmationAttemptWithConfiguration:(STPPaymentConfiguration *)configuration
                                           paymentMethodType:(NSString *)paymentMethodType {
    NSDictionary *configurationDictionary = [self.class serializeConfiguration:configuration];
    NSMutableDictionary *payload = [self.class commonPayload];
    [payload addEntriesFromDictionary:@{
                                        @"event": @"stripeios.payment_intent_confirmation",
                                        @"source_type": paymentMethodType ?: @"unknown",
                                        @"additional_info": [self additionalInfo],
                                        }];
    [payload addEntriesFromDictionary:[self productUsageDictionary]];
    [payload addEntriesFromDictionary:configurationDictionary];
    [self logPayload:payload];
}

- (void)logSetupIntentConfirmationAttemptWithConfiguration:(STPPaymentConfiguration *)configuration
                                         paymentMethodType:(NSString *)paymentMethodType {
    NSDictionary *configurationDictionary = [self.class serializeConfiguration:configuration];
    NSMutableDictionary *payload = [self.class commonPayload];
    [payload addEntriesFromDictionary:@{
                                        @"event": @"stripeios.setup_intent_confirmation",
                                        @"source_type": paymentMethodType ?: @"unknown",
                                        @"additional_info": [self additionalInfo],
                                        }];
    [payload addEntriesFromDictionary:[self productUsageDictionary]];
    [payload addEntriesFromDictionary:configurationDictionary];
    [self logPayload:payload];
}

- (void)log3DS2AuthenticateAttemptWithConfiguration:(STPPaymentConfiguration *)configuration
                                           intentID:(NSString *)intentID {
    NSDictionary *configurationDictionary = [self.class serializeConfiguration:configuration];
    NSMutableDictionary *payload = [self.class commonPayload];
    [payload addEntriesFromDictionary:@{
                                        @"event": @"stripeios.3ds2_authenticate",
                                        @"intent_id": intentID,
                                        @"additional_info": [self additionalInfo],
                                        }];
    [payload addEntriesFromDictionary:[self productUsageDictionary]];
    [payload addEntriesFromDictionary:configurationDictionary];
    [self logPayload:payload];
}

- (void)log3DS2ChallengeFlowErroredWithConfiguration:(STPPaymentConfiguration *)configuration
                                            intentID:(NSString *)intentID
                                     errorDictionary:(NSDictionary *)errorDictionary {
    NSDictionary *configurationDictionary = [self.class serializeConfiguration:configuration];
    NSMutableDictionary *payload = [self.class commonPayload];
    [payload addEntriesFromDictionary:@{
                                        @"event": @"stripeios.3ds2_challenge_flow_errored",
                                        @"intent_id": intentID,
                                        @"additional_info": [self additionalInfo],
                                        @"error_dictionary": errorDictionary,
                                        }];
    [payload addEntriesFromDictionary:[self productUsageDictionary]];
    [payload addEntriesFromDictionary:configurationDictionary];
    [self logPayload:payload];
}

- (void)log3DS2FrictionlessFlowWithConfiguration:(STPPaymentConfiguration *)configuration
                                        intentID:(NSString *)intentID {
    NSDictionary *configurationDictionary = [self.class serializeConfiguration:configuration];
    NSMutableDictionary *payload = [self.class commonPayload];
    [payload addEntriesFromDictionary:@{
                                        @"event": @"stripeios.3ds2_frictionless_flow",
                                        @"intent_id": intentID,
                                        @"additional_info": [self additionalInfo],
                                        }];
    [payload addEntriesFromDictionary:[self productUsageDictionary]];
    [payload addEntriesFromDictionary:configurationDictionary];
    [self logPayload:payload];
}

- (void)logURLRedirectNextActionWithConfiguration:(STPPaymentConfiguration *)configuration
                                         intentID:(NSString *)intentID {
    NSDictionary *configurationDictionary = [self.class serializeConfiguration:configuration];
    NSMutableDictionary *payload = [self.class commonPayload];
    [payload addEntriesFromDictionary:@{
                                        @"event": @"stripeios.url_redirect_next_action",
                                        @"intent_id": intentID,
                                        @"additional_info": [self additionalInfo],
                                        }];
    [payload addEntriesFromDictionary:[self productUsageDictionary]];
    [payload addEntriesFromDictionary:configurationDictionary];
    [self logPayload:payload];
}


- (void)log3DS2ChallengeFlowPresentedWithConfiguration:(STPPaymentConfiguration *)configuration
                                              intentID:(NSString *)intentID
                                                uiType:(NSString *)uiType {
    NSDictionary *configurationDictionary = [self.class serializeConfiguration:configuration];
    NSMutableDictionary *payload = [self.class commonPayload];
    [payload addEntriesFromDictionary:@{
                                        @"event": @"stripeios.3ds2_challenge_flow_presented",
                                        @"intent_id": intentID,
                                        @"3ds2_ui_type": uiType,
                                        @"additional_info": [self additionalInfo],
                                        }];
    [payload addEntriesFromDictionary:[self productUsageDictionary]];
    [payload addEntriesFromDictionary:configurationDictionary];
    [self logPayload:payload];
}


- (void)log3DS2ChallengeFlowTimedOutWithConfiguration:(STPPaymentConfiguration *)configuration
                                             intentID:(NSString *)intentID
                                               uiType:(NSString *)uiType {
    NSDictionary *configurationDictionary = [self.class serializeConfiguration:configuration];
    NSMutableDictionary *payload = [self.class commonPayload];
    [payload addEntriesFromDictionary:@{
                                        @"event": @"stripeios.3ds2_challenge_flow_timed_out",
                                        @"intent_id": intentID,
                                        @"3ds2_ui_type": uiType,
                                        @"additional_info": [self additionalInfo],
                                        }];
    [payload addEntriesFromDictionary:[self productUsageDictionary]];
    [payload addEntriesFromDictionary:configurationDictionary];
    [self logPayload:payload];
}

- (void)log3DS2ChallengeFlowUserCanceledWithConfiguration:(STPPaymentConfiguration *)configuration
                                                 intentID:(NSString *)intentID
                                                   uiType:(NSString *)uiType {
    NSDictionary *configurationDictionary = [self.class serializeConfiguration:configuration];
    NSMutableDictionary *payload = [self.class commonPayload];
    [payload addEntriesFromDictionary:@{
                                        @"event": @"stripeios.3ds2_challenge_flow_canceled",
                                        @"intent_id": intentID,
                                        @"3ds2_ui_type": uiType,
                                        @"additional_info": [self additionalInfo],
                                        }];
    [payload addEntriesFromDictionary:[self productUsageDictionary]];
    [payload addEntriesFromDictionary:configurationDictionary];
    [self logPayload:payload];
}

- (void)log3DS2ChallengeFlowCompletedWithConfiguration:(STPPaymentConfiguration *)configuration
                                              intentID:(NSString *)intentID
                                                uiType:(NSString *)uiType {
    NSDictionary *configurationDictionary = [self.class serializeConfiguration:configuration];
    NSMutableDictionary *payload = [self.class commonPayload];
    [payload addEntriesFromDictionary:@{
                                        @"event": @"stripeios.3ds2_challenge_flow_completed",
                                        @"intent_id": intentID,
                                        @"3ds2_ui_type": uiType,
                                        @"additional_info": [self additionalInfo],
                                        }];
    [payload addEntriesFromDictionary:[self productUsageDictionary]];
    [payload addEntriesFromDictionary:configurationDictionary];
    [self logPayload:payload];
}

#pragma mark - Helpers

+ (NSMutableDictionary *)commonPayload {
    NSMutableDictionary *payload = [NSMutableDictionary dictionary];
    payload[@"bindings_version"] = STPSDKVersion;
    payload[@"analytics_ua"] = @"analytics.stripeios-1.0";
    NSString *version = [UIDevice currentDevice].systemVersion;
    if (version) {
        payload[@"os_version"] = version;
    }
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceType = @(systemInfo.machine);
    if (deviceType) {
        payload[@"device_type"] = deviceType;
    }
    payload[@"app_name"] = [NSBundle stp_applicationName];
    payload[@"app_version"] = [NSBundle stp_applicationVersion];
    payload[@"apple_pay_enabled"] = @([Stripe deviceSupportsApplePay]);
    payload[@"ocr_type"] = [STPCardIOProxy isCardIOAvailable] ? @"card_io" : @"none";
    
    return payload;
}

+ (NSDictionary *)serializeConfiguration:(STPPaymentConfiguration *)configuration {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    dictionary[@"publishable_key"] = [STPAPIClient sharedClient].publishableKey ?: @"unknown";
    
    if (configuration.additionalPaymentOptions == STPPaymentOptionTypeDefault) {
        dictionary[@"additional_payment_methods"] = @"default";
    }
    else if (configuration.additionalPaymentOptions == STPPaymentOptionTypeNone) {
        dictionary[@"additional_payment_methods"] = @"none";
    }
    else {
        NSMutableArray *methods = [[NSMutableArray alloc] init];
        if (configuration.additionalPaymentOptions & STPPaymentOptionTypeApplePay) {
            [methods addObject:@"applepay"];
        }
        if (configuration.additionalPaymentOptions & STPPaymentOptionTypeFPX) {
            [methods addObject:@"fpx"];
        }
        dictionary[@"additional_payment_methods"] = [methods componentsJoinedByString:@","];
    }
    switch (configuration.requiredBillingAddressFields) {
        case STPBillingAddressFieldsNone:
            dictionary[@"required_billing_address_fields"] = @"none";
        case STPBillingAddressFieldsPostalCode:
            dictionary[@"required_billing_address_fields"] = @"zip";
        case STPBillingAddressFieldsFull:
            dictionary[@"required_billing_address_fields"] = @"full";
        case STPBillingAddressFieldsName:
            dictionary[@"required_billing_address_fields"] = @"name";
    }
    NSMutableArray<NSString *> *shippingFields = [NSMutableArray new];
    if ([configuration.requiredShippingAddressFields containsObject:STPContactFieldName]) {
        [shippingFields addObject:@"name"];
    }
    if ([configuration.requiredShippingAddressFields containsObject:STPContactFieldEmailAddress]) {
        [shippingFields addObject:@"email"];
    }
    if ([configuration.requiredShippingAddressFields containsObject:STPContactFieldPostalAddress]) {
        [shippingFields addObject:@"address"];
    }
    if ([configuration.requiredShippingAddressFields containsObject:STPContactFieldPhoneNumber]) {
        [shippingFields addObject:@"phone"];
    }
    if ([shippingFields count] == 0) {
        [shippingFields addObject:@"none"];
    }
    dictionary[@"required_shipping_address_fields"] = [shippingFields componentsJoinedByString:@"_"];
    switch (configuration.shippingType) {
        case STPShippingTypeShipping:
            dictionary[@"shipping_type"] = @"shipping";
        case STPShippingTypeDelivery:
            dictionary[@"shipping_type"] = @"delivery";
    }
    dictionary[@"company_name"] = configuration.companyName ?: @"unknown";
    dictionary[@"apple_merchant_identifier"] = configuration.appleMerchantIdentifier ?: @"unknown";
    return [dictionary copy];
}

- (void)logPayload:(NSDictionary *)payload {
    if (![[self class] shouldCollectAnalytics]) {
        return;
    }
    NSURL *url = [NSURL URLWithString:@"https://q.stripe.com"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request stp_addParametersToURL:payload];
    NSURLSessionDataTask *task = [self.urlSession dataTaskWithRequest:request];
    [task resume];
}

@end
