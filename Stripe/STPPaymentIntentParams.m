//
//  STPPaymentIntentParams.m
//  Stripe
//
//  Created by Daniel Jackson on 7/3/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import "STPPaymentIntentParams.h"
#import "STPPaymentIntentParams+Utilities.h"

#import "STPConfirmPaymentMethodOptions.h"
#import "STPMandateCustomerAcceptanceParams.h"
#import "STPMandateOnlineParams+Private.h"
#import "STPMandateDataParams.h"
#import "STPPaymentIntentShippingDetailsParams.h"
#import "STPPaymentIntent+Private.h"
#import "STPPaymentMethod.h"
#import "STPPaymentMethodParams.h"
#import "STPPaymentResult.h"

@interface STPPaymentIntentParams ()

@end

@implementation STPPaymentIntentParams

@synthesize additionalAPIParameters = _additionalAPIParameters;

- (instancetype)init {
    // Not a valid clientSecret, but at least it'll be non-null
    return [self initWithClientSecret:@""];
}

- (instancetype)initWithClientSecret:(NSString *)clientSecret {
    self = [super init];
    if (self) {
        _clientSecret = [clientSecret copy];
        _additionalAPIParameters = @{};
    }
    return self;
}

- (NSString *)stripeId {
    return [STPPaymentIntent idFromClientSecret:self.clientSecret];
}

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],

                       // Identifier
                       [NSString stringWithFormat:@"stripeId = %@", self.stripeId],

                       // PaymentIntentParams details (alphabetical)
                       [NSString stringWithFormat:@"clientSecret = %@", (self.clientSecret.length > 0) ? @"<redacted>" : @""],
                       [NSString stringWithFormat:@"receiptEmail = %@", self.receiptEmail],
                       [NSString stringWithFormat:@"returnURL = %@", self.returnURL],
                       [NSString stringWithFormat:@"savePaymentMethod = %@", (self.savePaymentMethod.boolValue) ? @"YES" : @"NO"],
                       [NSString stringWithFormat:@"setupFutureUsage = %@", self.setupFutureUsage],
                       [NSString stringWithFormat:@"shipping = %@", self.shipping],
                       [NSString stringWithFormat:@"useStripeSDK = %@", (self.useStripeSDK.boolValue) ? @"YES" : @"NO"],
                       
                       // Source
                       [NSString stringWithFormat:@"sourceId = %@", self.sourceId],
                       [NSString stringWithFormat:@"sourceParams = %@", self.sourceParams],

                       // PaymentMethod
                       [NSString stringWithFormat:@"paymentMethodId = %@", self.paymentMethodId],
                       [NSString stringWithFormat:@"paymentMethodParams = %@", self.paymentMethodParams],

                       // Mandate
                       [NSString stringWithFormat:@"mandateData = %@", self.mandateData],

                       // PaymentMethodOptions
                       [NSString stringWithFormat:@"paymentMethodOptions = @%@", self.paymentMethodOptions],

                       // Additional params set by app
                       [NSString stringWithFormat:@"additionalAPIParameters = %@", self.additionalAPIParameters],
                       ];

    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

- (nullable NSString *)setupFutureUsageRawString {
    if (self.setupFutureUsage == nil) {
        return nil;
    }
    STPPaymentIntentSetupFutureUsage setupFutureUsage = [self.setupFutureUsage integerValue];
    switch (setupFutureUsage) {
        case STPPaymentIntentSetupFutureUsageOnSession:
            return @"on_session";
        case STPPaymentIntentSetupFutureUsageOffSession:
            return @"off_session";
        case STPPaymentIntentSetupFutureUsageNone:
        case STPPaymentIntentSetupFutureUsageUnknown:
            return nil;
    }
}

- (void)configureWithPaymentResult:(STPPaymentResult *)paymentResult {
    if (paymentResult.paymentMethod) {
        _paymentMethodId = [paymentResult.paymentMethod.stripeId copy];
    } else if (paymentResult.paymentMethodParams) {
        _paymentMethodParams = paymentResult.paymentMethodParams;
    }
}

- (STPMandateDataParams *)mandateData {
    BOOL paymentMethodRequiresMandate = self.paymentMethodParams.type == STPPaymentMethodTypeSEPADebit || self.paymentMethodParams.type == STPPaymentMethodTypeBacsDebit || self.paymentMethodParams.type == STPPaymentMethodTypeAUBECSDebit;
    
    if (_mandateData != nil) {
        return _mandateData;
    } else if (paymentMethodRequiresMandate) {
        // Create default infer from client mandate_data
        STPMandateDataParams *mandateData = [[STPMandateDataParams alloc] init];
        STPMandateCustomerAcceptanceParams *customerAcceptance = [[STPMandateCustomerAcceptanceParams alloc] init];
        STPMandateOnlineParams *onlineParams = [[STPMandateOnlineParams alloc] init];
        onlineParams.inferFromClient = @YES;
        customerAcceptance.type = STPMandateCustomerAcceptanceTypeOnline;
        customerAcceptance.onlineParams = onlineParams;
        mandateData.customerAcceptance = customerAcceptance;

        return mandateData;
    } else {
        return nil;
    }
}

#pragma mark - Deprecated Properties

- (NSString *)returnUrl {
    return self.returnURL;
}

- (void)setReturnUrl:(NSString *)returnUrl {
    self.returnURL = returnUrl;
}

- (NSNumber *)saveSourceToCustomer {
    return self.savePaymentMethod;
}

- (void)setSaveSourceToCustomer:(NSNumber *)saveSourceToCustomer {
    self.savePaymentMethod = saveSourceToCustomer;
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    __typeof(self) copy = [[[self class] allocWithZone:zone] init];

    copy.clientSecret = self.clientSecret;
    copy.paymentMethodParams = self.paymentMethodParams;
    copy.paymentMethodId = self.paymentMethodId;
    copy.sourceParams = self.sourceParams;
    copy.sourceId = self.sourceId;
    copy.receiptEmail = self.receiptEmail;
    copy.savePaymentMethod = self.savePaymentMethod;
    copy.returnURL = self.returnURL;
    copy.setupFutureUsage = self.setupFutureUsage;
    copy.useStripeSDK = self.useStripeSDK;
    copy.mandateData = self.mandateData;
    copy.paymentMethodOptions = self.paymentMethodOptions;
    copy.shipping = self.shipping;
    copy.additionalAPIParameters = self.additionalAPIParameters;

    return copy;
}

#pragma mark - STPFormEncodable

+ (nullable NSString *)rootObjectName {
    return nil;
}

+ (nonnull NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
             NSStringFromSelector(@selector(clientSecret)): @"client_secret",
             NSStringFromSelector(@selector(paymentMethodParams)): @"payment_method_data",
             NSStringFromSelector(@selector(paymentMethodId)): @"payment_method",
             NSStringFromSelector(@selector(setupFutureUsageRawString)): @"setup_future_usage",
             NSStringFromSelector(@selector(sourceParams)): @"source_data",
             NSStringFromSelector(@selector(sourceId)): @"source",
             NSStringFromSelector(@selector(receiptEmail)): @"receipt_email",
             NSStringFromSelector(@selector(savePaymentMethod)): @"save_payment_method",
             NSStringFromSelector(@selector(returnURL)): @"return_url",
             NSStringFromSelector(@selector(useStripeSDK)) : @"use_stripe_sdk",
             NSStringFromSelector(@selector(mandateData)) : @"mandate_data",
             NSStringFromSelector(@selector(paymentMethodOptions)) : @"payment_method_options",
             NSStringFromSelector(@selector(shipping)) : @"shipping",
             };
}

#pragma mark - Utilities

+ (BOOL)isClientSecretValid:(NSString *)clientSecret {
    static dispatch_once_t onceToken;
    static NSRegularExpression *regex = nil;
    dispatch_once(&onceToken, ^{
        regex = [[NSRegularExpression alloc] initWithPattern:@"^pi_[^_]+_secret_[^_]+$"
                                                     options:0
                                                       error:NULL];
    });

    return ([regex numberOfMatchesInString:clientSecret
                                  options:NSMatchingAnchored
                                    range:NSMakeRange(0, clientSecret.length)]) == 1;
}

@end
