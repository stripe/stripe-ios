//
//  STPPaymentConfiguration.m
//  Stripe
//
//  Created by Jack Flintermann on 5/18/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentConfiguration.h"

#import "NSBundle+Stripe_AppName.h"
#import "STPAnalyticsClient.h"
#import "STPPaymentConfiguration+Private.h"
#import "STPTelemetryClient.h"
#import "Stripe.h"

@implementation STPPaymentConfiguration

@synthesize ineligibleForSmsAutofill = _ineligibleForSmsAutofill;

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
        _additionalPaymentMethods = STPPaymentMethodTypeAll;
        _requiredBillingAddressFields = STPBillingAddressFieldsNone;
        _requiredShippingAddressFields = PKAddressFieldNone;
        _companyName = [NSBundle stp_applicationName];
        _smsAutofillDisabled = NO;
        _shippingType = STPShippingTypeShipping;
    }
    return self;
}

- (id)copyWithZone:(__unused NSZone *)zone {
    STPPaymentConfiguration *copy = [self.class new];
    copy.publishableKey = self.publishableKey;
    copy.additionalPaymentMethods = self.additionalPaymentMethods;
    copy.requiredBillingAddressFields = self.requiredBillingAddressFields;
    copy.requiredShippingAddressFields = self.requiredShippingAddressFields;
    copy.shippingType = self.shippingType;
    copy.companyName = self.companyName;
    copy.appleMerchantIdentifier = self.appleMerchantIdentifier;
    copy.smsAutofillDisabled = self.smsAutofillDisabled;
    return copy;
}

- (BOOL)applePayEnabled {
    return self.appleMerchantIdentifier &&
    (self.additionalPaymentMethods & STPPaymentMethodTypeApplePay) &&
    [Stripe deviceSupportsApplePay];
}

- (void)setIneligibleForSmsAutofill:(BOOL)ineligibleForSmsAutofill {
    _ineligibleForSmsAutofill = ineligibleForSmsAutofill;
    self.smsAutofillDisabled = (self.smsAutofillDisabled || ineligibleForSmsAutofill);
}


@end

