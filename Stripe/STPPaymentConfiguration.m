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
#import "STPTelemetryClient.h"
#import "STPRedirectContext.h"
#import "STPSource.h"
#import "STPSourcePoller.h"
#import "STPWeakStrongMacros.h"

#import <SafariServices/SafariServices.h>

@implementation STPPaymentConfiguration {
    NSURL *_returnURL;
}

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
        _availablePaymentMethodTypesSet = [NSOrderedSet orderedSetWithArray:@[[STPPaymentMethodType applePay],
                                                                              [STPPaymentMethodType card]]];
        _requiredBillingAddressFields = STPBillingAddressFieldsNone;
        _requiredShippingAddressFields = PKAddressFieldNone;
        _companyName = [NSBundle stp_applicationName];
        _shippingType = STPShippingTypeShipping;
        self.returnURLBlock = ^NSURL *() { return  nil; };
        self.threeDSecureSupportTypeBlock = ^STPThreeDSecureSupportType() { return STPThreeDSecureSupportTypeDisabled; };
        _pollingTimeout = 10;
    }
    return self;
}

- (id)copyWithZone:(__unused NSZone *)zone {
    STPPaymentConfiguration *copy = [self.class new];
    copy.availablePaymentMethodTypesSet = self.availablePaymentMethodTypesSet;
    copy.requiredBillingAddressFields = self.requiredBillingAddressFields;
    copy.requiredShippingAddressFields = self.requiredShippingAddressFields;
    copy.shippingType = self.shippingType;
    copy.companyName = self.companyName;
    copy.appleMerchantIdentifier = self.appleMerchantIdentifier;
    copy.useSourcesForCards = self.useSourcesForCards;
    copy.returnURLBlock = self.returnURLBlock;
    copy.threeDSecureSupportTypeBlock = self.threeDSecureSupportTypeBlock;
    copy.pollingTimeout = self.pollingTimeout;
    return copy;
}

- (BOOL)applePayEnabled {
    return (self.appleMerchantIdentifier
            && [self isPaymentMethodTypeAllowed:[STPPaymentMethodType applePay]]
            && [Stripe deviceSupportsApplePay]);
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

/**
 This gets around the fact that you can't reference UIApplication in app extension
 safe frameworks. This method is only available in non-extensions and sets up
 some blocks that do the non-extension-safe work. These blocks can then be
 safely referenced from other parts of the app (and will just be nil or do
 nothing if the user never called here).
 */
- (void)setReturnURL:(nullable NSURL *)returnURL {
    _returnURL = returnURL;
    self.returnURLBlock = ^() {
        return returnURL;
    };

    if (!self.sourceURLRedirectBlock) {
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
                                                timeout:self.pollingTimeout
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
}

- (void)setThreeDSecureSupportType:(STPThreeDSecureSupportType)threeDSecureSupportType {
    _threeDSecureSupportType = threeDSecureSupportType;
    self.threeDSecureSupportTypeBlock = ^() {
        return threeDSecureSupportType;
    };
}

@end

