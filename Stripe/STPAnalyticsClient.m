//
//  STPAnalyticsClient.m
//  Stripe
//
//  Created by Ben Guo on 4/22/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPAnalyticsClient.h"

#import "NSMutableURLRequest+Stripe.h"
#import "STPAPIClient+ApplePay.h"
#import "STPAPIClient.h"
#import "STPAddCardViewController+Private.h"
#import "STPAddCardViewController.h"
#import "STPAspects.h"
#import "STPCard.h"
#import "STPFormEncodable.h"
#import "STPPaymentCardTextField.h"
#import "STPPaymentConfiguration.h"
#import "STPPaymentContext.h"
#import "STPPaymentMethodType+Private.h"
#import "STPPaymentMethodsViewController+Private.h"
#import "STPPaymentMethodsViewController.h"
#import "STPToken.h"
#import <UIKit/UIKit.h>
#import <sys/utsname.h>

static BOOL STPAnalyticsCollectionDisabled = NO;

@interface STPAnalyticsClient()

@property (nonatomic) NSSet *apiUsage;
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

+ (void)initialize {
    [self initializeIfNeeded];
}

+ (void)initializeIfNeeded NS_EXTENSION_UNAVAILABLE("") {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [STPPaymentCardTextField stp_aspect_hookSelector:@selector(commonInit)
                                             withOptions:STPAspectPositionAfter
                                              usingBlock:^{
                                                  STPAnalyticsClient *client = [self sharedClient];
                                                  [client setApiUsage:[client.apiUsage setByAddingObject:NSStringFromClass([STPPaymentCardTextField class])]];
                                              } error:nil];
        
        [STPPaymentContext stp_aspect_hookSelector:@selector(initWithAPIAdapter:configuration:theme:)
                                       withOptions:STPAspectPositionAfter
                                        usingBlock:^{
                                            STPAnalyticsClient *client = [self sharedClient];
                                            [client setApiUsage:[client.apiUsage setByAddingObject:NSStringFromClass([STPPaymentContext class])]];
                                        } error:nil];
        
        
        [STPAddCardViewController stp_aspect_hookSelector:@selector(commonInitWithConfiguration:)
                                              withOptions:STPAspectPositionAfter
                                               usingBlock:^{
                                                   STPAnalyticsClient *client = [self sharedClient];
                                                   [client setApiUsage:[client.apiUsage setByAddingObject:NSStringFromClass([STPAddCardViewController class])]];
                                               } error:nil];
        
        [STPPaymentMethodsViewController stp_aspect_hookSelector:@selector(initWithConfiguration:apiAdapter:loadingPromise:theme:shippingAddress:delegate:)
                                                     withOptions:STPAspectPositionAfter
                                                      usingBlock:^{
                                                          STPAnalyticsClient *client = [self sharedClient];
                                                          [client setApiUsage:[client.apiUsage setByAddingObject:NSStringFromClass([STPPaymentMethodsViewController class])]];
                                                      } error:nil];

        [STPShippingAddressViewController stp_aspect_hookSelector:@selector(initWithConfiguration:theme:currency:shippingAddress:selectedShippingMethod:prefilledInformation:)
                                                      withOptions:STPAspectPositionAfter
                                                       usingBlock:^{
                                                           STPAnalyticsClient *client = [self sharedClient];
                                                           [client setApiUsage:[client.apiUsage setByAddingObject:NSStringFromClass([STPShippingAddressViewController class])]];
                                                       } error:nil];

    });
}

+ (void)disableAnalytics {
    STPAnalyticsCollectionDisabled = YES;
}

+ (BOOL)shouldCollectAnalytics {
#if TARGET_OS_SIMULATOR
    return NO;
#endif
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunreachable-code"
    return NSClassFromString(@"XCTest") == nil && !STPAnalyticsCollectionDisabled;
#pragma clang diagnostic pop
}

+ (NSNumber *)timestampWithDate:(NSDate *)date {
    return @((NSInteger)([date timeIntervalSince1970]*1000));
}

+ (NSString *)muid {
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _urlSession = [NSURLSession sessionWithConfiguration:config];
        _apiUsage = [NSSet set];
    }
    return self;
}

- (void)logRememberMeConversion:(STPAddCardRememberMeUsage)selected {
    NSMutableDictionary *payload = [self.class commonPayload];
    [payload addEntriesFromDictionary:@{
                                        @"event": @"stripeios.remember_me",
                                        @"selected": @(selected),
                                        }];
    [self logPayload:payload];
}

- (NSArray *)productUsage {
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(description)) ascending:YES];
    NSArray *productUsage = [self.apiUsage sortedArrayUsingDescriptors:@[sortDescriptor]];
    return productUsage ?: @[];
}

- (void)logTokenCreationAttemptWithConfiguration:(STPPaymentConfiguration *)configuration {
    NSDictionary *configurationDictionary = [self.class serializeConfiguration:configuration];
    NSMutableDictionary *payload = [self.class commonPayload];
    [payload addEntriesFromDictionary:@{
                                        @"event": @"stripeios.token_creation",
                                        @"apple_pay_enabled": @([Stripe deviceSupportsApplePay]),
                                        @"product_usage": [self productUsage],
                                        }];
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
                                        @"apple_pay_enabled": @([Stripe deviceSupportsApplePay]),
                                        @"product_usage": [self productUsage],
                                        }];
    [payload addEntriesFromDictionary:configurationDictionary];
    [self logPayload:payload];
}

- (void)logRUMWithToken:(STPToken *)token
          configuration:(STPPaymentConfiguration *)configuration
               response:(NSHTTPURLResponse *)response
                  start:(NSDate *)startTime
                    end:(NSDate *)endTime {
    NSString *tokenTypeString = @"unknown";
    if (token.bankAccount) {
        tokenTypeString = @"bank_account";
    } else if (token.card) {
        if (token.card.isApplePayCard) {
            tokenTypeString = @"apple_pay";
        } else {
            tokenTypeString = @"card";
        }
    }
    NSNumber *start = [[self class] timestampWithDate:startTime];
    NSNumber *end = [[self class] timestampWithDate:endTime];
    NSMutableDictionary *payload = [self.class commonPayload];
    [payload addEntriesFromDictionary:@{
                                        @"event": @"rum.stripeios",
                                        @"tokenType": tokenTypeString,
                                        @"url": response.URL.absoluteString ?: @"unknown",
                                        @"status": @(response.statusCode),
                                        @"publishable_key": configuration.publishableKey ?: @"unknown",
                                        @"start": start,
                                        @"end": end,
                                        }];
    [self logPayload:payload];
}

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
    return payload;
}

+ (NSString *)analyticsStringForPaymentMethodsTypes:(NSArray<STPPaymentMethodType *> *)types {

    NSMutableArray<NSString *> *analyticsStrings = [NSMutableArray new];
    for (STPPaymentMethodType *type in types) {
        [analyticsStrings addObject:[type analyticsString]];
    }

    return [analyticsStrings componentsJoinedByString:@","];
}

+ (NSDictionary *)serializeConfiguration:(STPPaymentConfiguration *)configuration {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    dictionary[@"publishable_key"] = configuration.publishableKey ?: @"unknown";
    dictionary[@"available_payment_methods"] = [self analyticsStringForPaymentMethodsTypes:configuration.availablePaymentMethodTypes];
    switch (configuration.requiredBillingAddressFields) {
        case STPBillingAddressFieldsNone:
            dictionary[@"required_billing_address_fields"] = @"none";
        case STPBillingAddressFieldsZip:
            dictionary[@"required_billing_address_fields"] = @"zip";
        case STPBillingAddressFieldsFull:
            dictionary[@"required_billing_address_fields"] = @"full";
    }
    NSMutableArray<NSString *> *shippingFields = [NSMutableArray new];
    if (configuration.requiredShippingAddressFields & PKAddressFieldName) {
        [shippingFields addObject:@"name"];
    }
    if (configuration.requiredShippingAddressFields & PKAddressFieldEmail) {
        [shippingFields addObject:@"email"];
    }
    if (configuration.requiredShippingAddressFields & PKAddressFieldPostalAddress) {
        [shippingFields addObject:@"address"];
    }
    if (configuration.requiredShippingAddressFields & PKAddressFieldPhone) {
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
    dictionary[@"sms_autofill_disabled"] = @(configuration.smsAutofillDisabled);
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
