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
#import "STPAPIClient.h"
#import "STPPaymentConfiguration+Private.h"
#import "STPRedirectContext.h"
#import "STPSource.h"
#import "STPSourcePoller.h"
#import "STPWeakStrongMacros.h"

#import <SafariServices/SafariServices.h>

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
    WEAK(self);
    self.sourceURLRedirectBlock = ^(STPAPIClient *apiClient, STPSource *source, UIViewController *presentingViewController, STPSourceCompletionBlock completion) {
        STRONG(self);
        STPRedirectContextCompletionBlock redirectCompletion = ^(NSString * _Nonnull sourceId, NSString * _Nonnull sourceClientSecret, NSError * _Nonnull redirectError) {
            STRONG(self);
            self.cancelSourceURLRedirectBlock = nil;

            if (redirectError) {
                completion(nil, redirectError);
            }
            else {
                [apiClient startPollingSourceWithId:sourceId
                                       clientSecret:sourceClientSecret
                                            timeout:10 //TODO: Add this timeout as a property on STPConfiguration?
                                         completion:^(STPSource * _Nullable polledSource, NSError * _Nullable pollerError) {
                                             completion(polledSource, pollerError);
                                         }];

            }
        };

        STPRedirectContext *context = [[STPRedirectContext alloc] initWithSource:source
                                                                      completion:redirectCompletion];

        self.cancelSourceURLRedirectBlock = ^ {
            STRONG(self);
            // Capturing context in this other block retains it until the block is cleared,
            // which is done in both here and redirect completion
            [context cancel];
            self.cancelSourceURLRedirectBlock = nil;
        };

        if ([SFSafariViewController class] != nil) {
            [context startSafariViewControllerRedirectFlowFromViewController:presentingViewController];
        }
        else {
            [context startSafariAppRedirectFlow];
        }
    };
}

@end

