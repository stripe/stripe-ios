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

+ (instancetype)sharedConfiguration;

/**
 *  The publishable key that will be used by the payment context.
 */
@property(nonatomic, copy)NSString *publishableKey;

/**
 *  An enum value representing which payment methods you will accept from your user in addition to credit cards. Unless you have a very specific reason not to, you should leave this at the default, STPPaymentMethodTypeAll.
 */
@property(nonatomic)STPPaymentMethodType additionalPaymentMethods;

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

/**
 *  Set this to disable SMS autofill. The user won't receive an SMS code even if they have their payment information stored with Stripe, and won't be prompted to save it if they don't.
 */
@property(nonatomic)BOOL smsAutofillDisabled;

@end

NS_ASSUME_NONNULL_END
