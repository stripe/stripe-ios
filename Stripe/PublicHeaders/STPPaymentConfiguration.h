//
//  STPPaymentConfiguration.h
//  Stripe
//
//  Created by Jack Flintermann on 5/18/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPBackendAPIAdapter.h"
#import "STPPaymentMethod.h"
#import "STPTheme.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPPaymentConfiguration : NSObject<NSCopying>

/**
 *  The publishable key that will be used by the payment context.
 */
@property(nonatomic, copy)NSString *publishableKey;

/**
 *  This theme will inform the visual appearance of any UI created by the payment context. @see STPTheme
 */
@property(nonatomic, copy)STPTheme *theme;

/**
 *  An enum value representing which payment methods you will accept from your user. Unless you have a very specific reason not to, you should leave this at the default, STPPaymentMethodTypeAll.
 */
@property(nonatomic)STPPaymentMethodType supportedPaymentMethods;

/**
 *  The billing address fields the user must fill out in order for the form to validate. These fields will all be present on the returned token from Stripe. See https://stripe.com/docs/api#create_card_token for more information.
 */
@property(nonatomic)STPBillingAddressFields requiredBillingAddressFields;

/**
 *  The name of your company, for displaying to the user during the payment flow. For example, when using Apple Pay, the payment sheet's final line item will read "PAY {companyName}". This defaults to the name of your iOS application.
 */
@property(nonatomic, copy)NSString *companyName;

/**
 *  The Apple Merchant Identifier to use during Apple Pay transactions. To create one of these, see our guide at https://stripe.com/docs/mobile/applepay . You must set this to a valid identifier in order to automatically enable Apple Pay.
 */
@property(nonatomic, nullable, copy)NSString *appleMerchantIdentifier;

@property(nonatomic)BOOL smsAutofillDisabled;

@property(nonatomic, nullable, copy)NSString *prefilledUserEmail;

@end

NS_ASSUME_NONNULL_END
