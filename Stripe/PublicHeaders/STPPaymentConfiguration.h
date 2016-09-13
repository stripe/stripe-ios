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
#import "STPShippingMethod.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPPaymentConfiguration : NSObject<NSCopying>

+ (instancetype)sharedConfiguration;

/**
 *  Your Stripe publishable key. You can get this from https://dashboard.stripe.com/account/apikeys .
 */
@property(nonatomic, copy)NSString *publishableKey;

/**
 *  An enum value representing which payment methods you will accept from your user in addition to credit cards. Unless you have a very specific reason not to, you should leave this at the default, `STPPaymentMethodTypeAll`.
 */
@property(nonatomic)STPPaymentMethodType additionalPaymentMethods;

/**
 *  The billing address fields the user must fill out when prompted for their payment details. These fields will all be present on the returned token from Stripe. See https://stripe.com/docs/api#create_card_token for more information.
 */
@property(nonatomic)STPBillingAddressFields requiredBillingAddressFields;

/**
 *  The billing address fields the user must fill out when prompted for their shipping info.
 */
@property(nonatomic)STPBillingAddressFields requiredShippingAddressFields;

/**
 *  The type of shipping for this purchase. This property sets the labels displayed when the user is prompted for shipping info, and whether they should also be asked to select a shipping method. The default value is STPShippingTypeShipping.
 */
@property(nonatomic)STPShippingType shippingType;

/**
 *  The name of your company, for displaying to the user during payment flows. For example, when using Apple Pay, the payment sheet's final line item will read "PAY {companyName}". This defaults to the name of your iOS application.
 */
@property(nonatomic, copy)NSString *companyName;

/**
 *  The Apple Merchant Identifier to use during Apple Pay transactions. To create one of these, see our guide at https://stripe.com/docs/mobile/apple-pay . You must set this to a valid identifier in order to automatically enable Apple Pay.
 */
@property(nonatomic, nullable, copy)NSString *appleMerchantIdentifier;

/**
 *  When entering their payment information, users who have a saved card with Stripe will be prompted to autofill it by entering an SMS code. Set this property to `YES` to disable this feature. The user won't receive an SMS code even if they have their payment information stored with Stripe, and won't be prompted to save it if they don't.
 */
@property(nonatomic)BOOL smsAutofillDisabled;

@end

NS_ASSUME_NONNULL_END
