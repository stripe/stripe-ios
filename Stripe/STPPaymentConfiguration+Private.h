//
//  STPPaymentConfiguration+Private.h
//  Stripe
//
//  Created by Jack Flintermann on 6/9/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Stripe/Stripe.h>

NS_ASSUME_NONNULL_BEGIN

@interface STPPaymentConfiguration ()

@property(nonatomic, readonly)BOOL applePayEnabled;
@property(nonatomic, readwrite) BOOL ineligibleForSmsAutofill;
@property (nonatomic, copy) NSOrderedSet<STPPaymentMethodType *> *availablePaymentMethodTypesSet;

/**
 Optional block to get around app extension restrictions
 It is set by returnURL setter so should exist for anyone using redirect sources with payment context
 
 It handles opening the redirect url, subscribes for foreground notifications, 
 does some polling when the customer comes back, and then returns you the completed source object
 */
@property (nonatomic, copy, nullable) void (^sourceURLRedirectBlock)(STPAPIClient *apiClient, STPSource *source, STPVoidBlock onRedirectReturn, STPSourceCompletionBlock completion);

@end

NS_ASSUME_NONNULL_END
