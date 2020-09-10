//
//  STPPaymentConfiguration.m
//  Stripe
//
//  Created by Jack Flintermann on 5/18/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentConfiguration.h"
#import "STPPaymentConfiguration+Private.h"

#import "NSBundle+Stripe_AppName.h"
#import "STPAnalyticsClient.h"
#import "STPTelemetryClient.h"
#import "Stripe.h"

@interface STPPaymentConfiguration ()

// See STPPaymentConfiguration+Private.h

@end

@implementation STPPaymentConfiguration

@synthesize publishableKey = _publishableKey;
@synthesize stripeAccount = _stripeAccount;

+ (void)initialize {
    [STPTelemetryClient sharedInstance];
}

+ (instancetype)sharedConfiguration {
    static STPPaymentConfiguration *sharedConfiguration;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedConfiguration = [self new];
    });
    return sharedConfiguration;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _additionalPaymentOptions = STPPaymentOptionTypeDefault;
        _requiredBillingAddressFields = STPBillingAddressFieldsPostalCode;
        _requiredShippingAddressFields = nil;
        _verifyPrefilledShippingAddress = YES;
        _shippingType = STPShippingTypeShipping;
        _companyName = [NSBundle stp_applicationName];
        _canDeletePaymentOptions = YES;
        _cardScanningEnabled = NO;
    }
    return self;
}

- (BOOL)applePayEnabled {
    return self.appleMerchantIdentifier &&
    (self.additionalPaymentOptions & STPPaymentOptionTypeApplePay) &&
    [Stripe deviceSupportsApplePay];
}

- (NSSet<NSString *> *)availableCountries {
    if (_availableCountries == nil) {
        return [NSSet setWithArray:[NSLocale ISOCountryCodes]];
    } else {
        return _availableCountries;
    }
}

- (NSSet<NSString *> *)_availableCountries {
    return _availableCountries;
}

#pragma mark - Description

- (NSString *)description {
    NSString *additionalPaymentOptionsDescription;

    if (self.additionalPaymentOptions == STPPaymentOptionTypeDefault) {
        additionalPaymentOptionsDescription = @"STPPaymentOptionTypeDefault";
    } else if (self.additionalPaymentOptions == STPPaymentOptionTypeNone) {
        additionalPaymentOptionsDescription = @"STPPaymentOptionTypeNone";
    } else {
        NSMutableArray *paymentOptions = [[NSMutableArray alloc] init];

        if (self.additionalPaymentOptions & STPPaymentOptionTypeApplePay) {
            [paymentOptions addObject:@"STPPaymentOptionTypeApplePay"];
        }

        if (self.additionalPaymentOptions & STPPaymentOptionTypeFPX) {
            [paymentOptions addObject:@"STPPaymentOptionTypeFPX"];
        }
        
        additionalPaymentOptionsDescription = [paymentOptions componentsJoinedByString:@"|"];
    }

    NSString *requiredBillingAddressFieldsDescription;

    switch (self.requiredBillingAddressFields) {
        case STPBillingAddressFieldsNone:
            requiredBillingAddressFieldsDescription = @"STPBillingAddressFieldsNone";
            break;
        case STPBillingAddressFieldsPostalCode:
            requiredBillingAddressFieldsDescription = @"STPBillingAddressFieldsPostalCode";
            break;
        case STPBillingAddressFieldsFull:
            requiredBillingAddressFieldsDescription = @"STPBillingAddressFieldsFull";
            break;
        case STPBillingAddressFieldsName:
            requiredBillingAddressFieldsDescription = @"STPBillingAddressFieldsName";
            break;
    }

    NSString *requiredShippingAddressFieldsDescription = [self.requiredShippingAddressFields.allObjects componentsJoinedByString:@"|"];

    NSString *shippingTypeDescription;

    switch (self.shippingType) {
        case STPShippingTypeShipping:
            shippingTypeDescription = @"STPShippingTypeShipping";
            break;
        case STPShippingTypeDelivery:
            shippingTypeDescription = @"STPShippingTypeDelivery";
            break;
    }

    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],

                       // Basic configuration
                       [NSString stringWithFormat:@"additionalPaymentOptions = %@", additionalPaymentOptionsDescription],

                       // Billing and shipping
                       [NSString stringWithFormat:@"requiredBillingAddressFields = %@", requiredBillingAddressFieldsDescription],
                       [NSString stringWithFormat:@"requiredShippingAddressFields = %@", requiredShippingAddressFieldsDescription],
                       [NSString stringWithFormat:@"verifyPrefilledShippingAddress = %@", (self.verifyPrefilledShippingAddress) ? @"YES" : @"NO"],
                       [NSString stringWithFormat:@"shippingType = %@", shippingTypeDescription],
                       [NSString stringWithFormat:@"availableCountries = %@", _availableCountries],

                       // Additional configuration
                       [NSString stringWithFormat:@"companyName = %@", self.companyName],
                       [NSString stringWithFormat:@"appleMerchantIdentifier = %@", self.appleMerchantIdentifier],
                       [NSString stringWithFormat:@"canDeletePaymentOptions = %@", (self.canDeletePaymentOptions) ? @"YES" : @"NO"],
                       [NSString stringWithFormat:@"cardScanningEnabled = %@", (self.cardScanningEnabled) ? @"YES" : @"NO"],
                       ];
    
    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

#pragma mark - NSCopying

- (id)copyWithZone:(__unused NSZone *)zone {
    STPPaymentConfiguration *copy = [self.class new];
    copy.additionalPaymentOptions = self.additionalPaymentOptions;
    copy.requiredBillingAddressFields = self.requiredBillingAddressFields;
    copy.requiredShippingAddressFields = self.requiredShippingAddressFields;
    copy.verifyPrefilledShippingAddress = self.verifyPrefilledShippingAddress;
    copy.shippingType = self.shippingType;
    copy.companyName = self.companyName;
    copy.appleMerchantIdentifier = self.appleMerchantIdentifier;
    copy.canDeletePaymentOptions = self.canDeletePaymentOptions;
    copy.cardScanningEnabled = self.cardScanningEnabled;
    copy.availableCountries = _availableCountries;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    copy.publishableKey = self.publishableKey;
    copy.stripeAccount = self.stripeAccount;
#pragma clang diagnostic pop
    
    return copy;
}

#pragma mark - Deprecated

// For legacy reasons, we'll try to keep the same behavior as before if setting these properties on the singleton.

- (void)setPublishableKey:(NSString *)publishableKey {
    if (self == [STPPaymentConfiguration sharedConfiguration]) {
        [STPAPIClient sharedClient].publishableKey = publishableKey;
    } else {
        _publishableKey = [publishableKey copy];
    }
}

- (NSString *)publishableKey {
    if (self == [STPPaymentConfiguration sharedConfiguration]) {
        return [STPAPIClient sharedClient].publishableKey;
    }
    return _publishableKey;
}

- (void)setStripeAccount:(NSString *)stripeAccount {
    if (self == [STPPaymentConfiguration sharedConfiguration]) {
        [STPAPIClient sharedClient].stripeAccount = stripeAccount;
    } else {
        _stripeAccount = [stripeAccount copy];
    }
}

- (NSString *)stripeAccount {
    if (self == [STPPaymentConfiguration sharedConfiguration]) {
        return [STPAPIClient sharedClient].stripeAccount;
    }
    return _stripeAccount;
}

@end
