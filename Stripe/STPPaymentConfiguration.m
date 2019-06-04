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

+ (void)initialize {
    [STPAnalyticsClient initializeIfNeeded];
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
        _additionalPaymentOptions = STPPaymentOptionTypeAll;
        _requiredBillingAddressFields = STPBillingAddressFieldsNone;
        _requiredShippingAddressFields = nil;
        _verifyPrefilledShippingAddress = YES;
        _shippingType = STPShippingTypeShipping;
        _companyName = [NSBundle stp_applicationName];
        _canDeletePaymentOptions = YES;
    }
    return self;
}

- (BOOL)applePayEnabled {
    return self.appleMerchantIdentifier &&
    (self.additionalPaymentOptions & STPPaymentOptionTypeApplePay) &&
    [Stripe deviceSupportsApplePay];
}

#pragma mark - Description

- (NSString *)description {
    NSString *additionalPaymentOptionsDescription;

    if (self.additionalPaymentOptions == STPPaymentOptionTypeAll) {
        additionalPaymentOptionsDescription = @"STPPaymentOptionTypeAll";
    }
    else if (self.additionalPaymentOptions == STPPaymentOptionTypeNone) {
        additionalPaymentOptionsDescription = @"STPPaymentOptionTypeNone";
    }
    else {
        NSMutableArray *paymentOptions = [[NSMutableArray alloc] init];

        if (self.additionalPaymentOptions & STPPaymentOptionTypeApplePay) {
            [paymentOptions addObject:@"STPPaymentOptionTypeApplePay"];
        }

        additionalPaymentOptionsDescription = [paymentOptions componentsJoinedByString:@"|"];
    }

    NSString *requiredBillingAddressFieldsDescription;

    switch (self.requiredBillingAddressFields) {
        case STPBillingAddressFieldsNone:
            requiredBillingAddressFieldsDescription = @"STPBillingAddressFieldsNone";
            break;
        case STPBillingAddressFieldsZip:
            requiredBillingAddressFieldsDescription = @"STPBillingAddressFieldsZip";
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
                       [NSString stringWithFormat:@"publishableKey = %@", (self.publishableKey) ? @"<redacted>" : nil],
                       [NSString stringWithFormat:@"additionalPaymentOptions = %@", additionalPaymentOptionsDescription],

                       // Billing and shipping
                       [NSString stringWithFormat:@"requiredBillingAddressFields = %@", requiredBillingAddressFieldsDescription],
                       [NSString stringWithFormat:@"requiredShippingAddressFields = %@", requiredShippingAddressFieldsDescription],
                       [NSString stringWithFormat:@"verifyPrefilledShippingAddress = %@", (self.verifyPrefilledShippingAddress) ? @"YES" : @"NO"],
                       [NSString stringWithFormat:@"shippingType = %@", shippingTypeDescription],

                       // Additional configuration
                       [NSString stringWithFormat:@"companyName = %@", self.companyName],
                       [NSString stringWithFormat:@"appleMerchantIdentifier = %@", self.appleMerchantIdentifier],
                       [NSString stringWithFormat:@"canDeletePaymentOptions = %@", (self.canDeletePaymentOptions) ? @"YES" : @"NO"],
                       ];
    
    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

#pragma mark - NSCopying

- (id)copyWithZone:(__unused NSZone *)zone {
    STPPaymentConfiguration *copy = [self.class new];
    copy.publishableKey = self.publishableKey;
    copy.additionalPaymentOptions = self.additionalPaymentOptions;
    copy.requiredBillingAddressFields = self.requiredBillingAddressFields;
    copy.requiredShippingAddressFields = self.requiredShippingAddressFields;
    copy.verifyPrefilledShippingAddress = self.verifyPrefilledShippingAddress;
    copy.shippingType = self.shippingType;
    copy.companyName = self.companyName;
    copy.appleMerchantIdentifier = self.appleMerchantIdentifier;
    copy.canDeletePaymentOptions = self.canDeletePaymentOptions;
    return copy;
}

@end
