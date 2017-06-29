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

/**
 An `STPPaymentConfiguration` represents all the options you can set or change
 around a payment. 
 
 You provide an `STPPaymentConfiguration` object to your `STPPaymentContext` 
 when making a charge. The configuration generally has settings that
 will not change from payment to payment and thus is reusable, while the context 
 is specific to a single particular payment instance.
 */
@interface STPPaymentConfiguration : NSObject<NSCopying>

/**
 This is a convenience singleton configuration that uses the default values
 for every property
 */
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
 *  The shipping address fields the user must fill out when prompted for their shipping info.
 */
@property(nonatomic)PKAddressField requiredShippingAddressFields;

/**
 *  Whether the user should be prompted to verify prefilled shipping information.
 *  The default value is YES.
 */
@property(nonatomic)BOOL verifyPrefilledShippingAddress;

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
@end

NS_ASSUME_NONNULL_END
