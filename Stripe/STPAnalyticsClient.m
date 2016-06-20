//
//  STPAnalyticsClient.m
//  Stripe
//
//  Created by Ben Guo on 4/22/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPAnalyticsClient.h"
#import "NSMutableURLRequest+Stripe.h"
#import "STPAPIClient.h"
#import "Stripe+ApplePay.h"
#import "STPSwitchTableViewCell.h"
#import <UIKit/UIKit.h>
#import <sys/utsname.h>

static BOOL STPShouldCollectAnalytics = YES;

@interface STPAddCardViewController (Internal)
@property(nonatomic)STPPaymentConfiguration *configuration;
@property(nonatomic)STPSwitchTableViewCell *rememberMeCell;
@end

@interface STPAnalyticsClient()
@property (nonatomic, readwrite) NSURLSession *urlSession;
@property (nonatomic, readwrite) BOOL logToConsole;
@property (nonatomic, readwrite) NSMutableDictionary *paymentContextPayload;
@property (nonatomic, readwrite) NSMutableDictionary *addCardPayload;
@end

@implementation STPAnalyticsClient

+ (void)disableAnalytics {
    STPShouldCollectAnalytics = NO;
}

+ (BOOL)shouldCollectAnalytics {
#if TARGET_OS_SIMULATOR
    return NO;
#endif
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunreachable-code"
    return NSClassFromString(@"XCTest") == nil && STPShouldCollectAnalytics;
#pragma clang diagnostic pop
}

+ (STPAnalyticsEventType)eventTypeForPaymentStatus:(STPPaymentStatus)status {
    switch (status) {
        case STPPaymentStatusSuccess: return STPAnalyticsEventTypeSuccess;
        case STPPaymentStatusError: return STPAnalyticsEventTypeError;
        case STPPaymentStatusUserCancellation: return STPAnalyticsEventTypeCancel;
    }
}

+ (NSNumber *)timestampWithDate:(NSDate *)date {
    return @((NSInteger)([date timeIntervalSince1970]*1000));
}

+ (NSString *)stringForBillingAddressFields:(STPBillingAddressFields)fields {
    switch (fields) {
        case STPBillingAddressFieldsFull: return @"full";
        case STPBillingAddressFieldsZip: return @"zip";
        case STPBillingAddressFieldsNone: return @"none";
    }
}

+ (NSString *)stringForPaymentMethod:(id<STPPaymentMethod>)paymentMethod {
    if ([paymentMethod isKindOfClass:[STPApplePayPaymentMethod class]]) {
        return @"apple_pay";
    }
    else if ([paymentMethod isKindOfClass:[STPCard class]]) {
        return @"card";
    }
    else if (paymentMethod == nil) {
        return @"none";
    }
    return @"unknown";
}

+ (NSString *)newSessionID {
    NSString *uuid = [NSUUID UUID].UUIDString;
    NSCharacterSet *nonAlphanumericSet = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
    return [[uuid componentsSeparatedByCharactersInSet:nonAlphanumericSet] componentsJoinedByString:@""];
}

+ (instancetype)sharedClient {
    static id sharedClient;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ sharedClient = [[self alloc] init]; });
    return sharedClient;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _urlSession = [NSURLSession sessionWithConfiguration:config];
        _logToConsole = NO;
        _paymentContextPayload = [@{} mutableCopy];
        _addCardPayload = [@{} mutableCopy];
    }
    return self;
}

- (void)resetPaymentContextPayload {
    [self.paymentContextPayload removeAllObjects];
    self.paymentContextPayload[@"session_id"] = [[self class] newSessionID];
}

- (void)resetAddCardPayload {
    [self.addCardPayload removeAllObjects];
    NSString *paymentContextSessionID = self.paymentContextPayload[@"session_id"];
    if (paymentContextSessionID != nil) {
        self.addCardPayload[@"session_id"] = paymentContextSessionID;
    }
    else {
        self.addCardPayload[@"session_id"] = [[self class] newSessionID];
    }
}

- (void)updatePayloadWithSharedFields:(NSMutableDictionary *)payload {
    NSMutableDictionary *fields = [@{
                                     @"analytics_ua": @"analytics.stripeios-1.0",
                                     @"bindings_version": STPSDKVersion,
                                     } mutableCopy];
    NSString *version = [UIDevice currentDevice].systemVersion;
    if (version) {
        fields[@"os_version"] = version;
    }
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceType = @(systemInfo.machine);
    if (deviceType) {
        fields[@"device_type"] = deviceType;
    }
    if (payload[@"publishable_key"] == nil) {
        fields[@"publishable_key"] = [STPAPIClient sharedClient].publishableKey;
    }
    fields[@"apple_pay_supported"] = @([Stripe deviceSupportsApplePay]);
    [payload addEntriesFromDictionary:fields];
}

- (void)updatePayload:(NSMutableDictionary *)payload withPaymentConfiguration:(STPPaymentConfiguration *)configuration {
    payload[@"publishable_key"] = configuration.publishableKey;
    payload[@"sms_autofill_disabled"] = @(configuration.smsAutofillDisabled);
    payload[@"required_billing_address_fields"] = [[self class] stringForBillingAddressFields:configuration.requiredBillingAddressFields];
}

- (void)logEvent:(STPAnalyticsEventType)event
forPaymentContext:(STPPaymentContext *)paymentContext {
    NSString *suffix;
    switch (event) {
        case STPAnalyticsEventTypeOpen:
            suffix = @"open";
            [self resetPaymentContextPayload];
            break;
        case STPAnalyticsEventTypeCancel:
            suffix = @"request_payment_cancel";
            break;
        case STPAnalyticsEventTypeError:
            suffix = @"request_payment_error";
            break;
        case STPAnalyticsEventTypeSuccess:
            suffix = @"request_payment_success";
            break;
    }
    NSMutableDictionary *payload = [NSMutableDictionary dictionaryWithDictionary:self.paymentContextPayload];
    NSString *eventName = [NSString stringWithFormat:@"payment_context.%@", suffix];
    payload[@"event"] = eventName;
    payload[@"selected_payment_method"] = [[self class] stringForPaymentMethod:paymentContext.selectedPaymentMethod];
    [self updatePayload:payload withPaymentConfiguration:paymentContext.configuration];
    [self updatePayloadWithSharedFields:payload];
    [self logPayload:payload];
}

- (void)logEvent:(STPAnalyticsEventType)event
forAddCardViewController:(STPAddCardViewController *)viewController {
    NSString *suffix;
    switch (event) {
        case STPAnalyticsEventTypeOpen:
            suffix = @"open";
            [self resetAddCardPayload];
            break;
        case STPAnalyticsEventTypeCancel:
            suffix = @"cancel";
            break;
        case STPAnalyticsEventTypeError:
            suffix = @"error";
            break;
        case STPAnalyticsEventTypeSuccess:
            suffix = @"success";
            break;
    }
    NSString *eventName = [NSString stringWithFormat:@"add_card.%@", suffix];
    NSMutableDictionary *payload = [NSMutableDictionary dictionaryWithDictionary:self.addCardPayload];
    payload[@"event"] = eventName;
    payload[@"remember_me_enabled"] = @(viewController.rememberMeCell.on);
    [self updatePayload:payload withPaymentConfiguration:viewController.configuration];
    [self updatePayloadWithSharedFields:payload];
    [self logPayload:payload];
}

- (void)logRUMWithTokenType:(STPTokenType)tokenType
             publishableKey:(NSString *)publishableKey
                   response:(NSHTTPURLResponse *)response
                      start:(NSDate *)startTime
                        end:(NSDate *)endTime {
    NSString *tokenTypeString;
    switch (tokenType) {
        case STPTokenTypeCard:
            tokenTypeString = @"card";
            break;
        case STPTokenTypeApplePay:
            tokenTypeString = @"apple_pay";
            break;
        case STPTokenTypeBankAccount:
            tokenTypeString = @"bank_account";
            break;
    }
    NSNumber *start = [[self class] timestampWithDate:startTime];
    NSNumber *end = [[self class] timestampWithDate:endTime];
    NSMutableDictionary *payload = [@{
                                     @"event": @"rum.stripeios",
                                     @"tokenType": tokenTypeString,
                                     @"url": response.URL.absoluteString ?: @"unknown",
                                     @"status": @(response.statusCode),
                                     @"publishable_key": publishableKey ?: @"unknown",
                                     @"start": start,
                                     @"end": end,
                                     } mutableCopy];
    if (self.paymentContextPayload[@"session_id"] != nil) {
        payload[@"session_id"] = self.paymentContextPayload[@"session_id"];
    }
    else if (self.addCardPayload[@"session_id"] != nil) {
        payload[@"session_id"] = self.addCardPayload[@"session_id"];
    }
    [self updatePayloadWithSharedFields:payload];
    [self logPayload:payload];
}

- (void)logPayload:(NSDictionary *)payload {
    if (self.logToConsole) {
        NSLog(@"%@", payload);
    }
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
