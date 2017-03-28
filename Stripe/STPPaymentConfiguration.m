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
#import "STPSource.h"
#import "STPSourcePoller.h"
#import "STPWeakStrongMacros.h"
#import "Stripe.h"

@implementation STPPaymentConfiguration {
    NSURL *_returnURL;
}

@synthesize ineligibleForSmsAutofill = _ineligibleForSmsAutofill;

+ (void)initialize {
    [STPAnalyticsClient initializeIfNeeded];
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
        _availablePaymentMethodTypesSet = [NSOrderedSet orderedSetWithArray:@[[STPPaymentMethodType applePay],
                                                                              [STPPaymentMethodType creditCard]]];
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
    copy.availablePaymentMethodTypesSet = self.availablePaymentMethodTypesSet;
    copy.requiredBillingAddressFields = self.requiredBillingAddressFields;
    copy.requiredShippingAddressFields = self.requiredShippingAddressFields;
    copy.shippingType = self.shippingType;
    copy.companyName = self.companyName;
    copy.appleMerchantIdentifier = self.appleMerchantIdentifier;
    copy.smsAutofillDisabled = self.smsAutofillDisabled;
    return copy;
}

- (BOOL)applePayEnabled {
    return (self.appleMerchantIdentifier
            && [self isPaymentMethodTypeAllowed:[STPPaymentMethodType applePay]]
            && [Stripe deviceSupportsApplePay]);
}

- (void)setIneligibleForSmsAutofill:(BOOL)ineligibleForSmsAutofill {
    _ineligibleForSmsAutofill = ineligibleForSmsAutofill;
    self.smsAutofillDisabled = (self.smsAutofillDisabled || ineligibleForSmsAutofill);
}

- (BOOL)isPaymentMethodTypeAllowed:(STPPaymentMethodType *)type {
    return ([self.availablePaymentMethodTypesSet containsObject:type]);
}

- (void)setAvailablePaymentMethodTypes:(NSArray<STPPaymentMethodType *> *)availablePaymentMethodTypes {
    self.availablePaymentMethodTypesSet = [NSOrderedSet orderedSetWithArray:availablePaymentMethodTypes];
}

- (NSArray<STPPaymentMethodType *> *)availablePaymentMethodTypes {
    return self.availablePaymentMethodTypesSet.array;
}

- (NSURL *)returnURL {
    return _returnURL;
}

- (void)setReturnURL:(nullable NSURL *)returnURL {
    _returnURL = returnURL;
    self.sourceURLRedirectBlock = ^(STPAPIClient *apiClient, STPSource *source, STPVoidBlock onRedirectReturn, STPSourceCompletionBlock completion) {
        if (completion) {
            __block id notificationObserver = nil;

            void (^notificationBlock)(NSNotification * _Nonnull note) = ^(NSNotification * __unused _Nonnull note) {
                [[NSNotificationCenter defaultCenter] removeObserver:notificationObserver];
                notificationObserver = nil;

                if (onRedirectReturn) {
                    onRedirectReturn();
                }

                __block STPSourcePoller *poller = [[STPSourcePoller alloc] initWithAPIClient:apiClient
                                                                                clientSecret:source.clientSecret
                                                                                    sourceID:source.stripeID
                                                                                     timeout:10 //TODO: Add this timeout as a property on STPConfiguration?
                                                                                  completion:^(STPSource * _Nullable polledSource, NSError * _Nullable error) {
                                                                                      // reference poller here so it's retained until its own timeout
                                                                                      poller = nil;
                                                                                      completion(polledSource, error);
                                                                                  }];
            };

            notificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification
                                                                                     object:nil
                                                                                      queue:[NSOperationQueue mainQueue]
                                                                                 usingBlock:notificationBlock];
        }

        [[UIApplication sharedApplication] openURL:source.redirect.url];
    };
}

@end

