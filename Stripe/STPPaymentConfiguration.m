//
//  STPPaymentConfiguration.m
//  Stripe
//
//  Created by Jack Flintermann on 5/18/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentConfiguration.h"
#import "NSBundle+Stripe_AppName.h"
#import "Stripe.h"

@implementation STPPaymentConfiguration

- (instancetype)init {
    self = [super init];
    if (self) {
        _publishableKey = [Stripe defaultPublishableKey];
        _theme = [STPTheme new];
        _supportedPaymentMethods = STPPaymentMethodTypeAll;
        _requiredBillingAddressFields = STPBillingAddressFieldsNone;
        _companyName = [NSBundle stp_applicationName];
        _smsAutofillDisabled = NO;
    }
    return self;
}

- (id)copyWithZone:(__unused NSZone *)zone {
    STPPaymentConfiguration *copy = [STPPaymentConfiguration new];
    copy.publishableKey = self.publishableKey;
    copy.theme = self.theme;
    copy.supportedPaymentMethods = self.supportedPaymentMethods;
    copy.requiredBillingAddressFields = self.requiredBillingAddressFields;
    copy.companyName = self.companyName;
    copy.appleMerchantIdentifier = self.appleMerchantIdentifier;
    copy.smsAutofillDisabled = self.smsAutofillDisabled;
    return copy;
}

@end
