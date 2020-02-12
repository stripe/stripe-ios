//
//  STPPaymentConfiguration.h
//  Stripe
//
//  Created by Jack Flintermann on 5/18/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPBackendAPIAdapter.h"
#import "STPPaymentOption.h"
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
 This is a convenience singleton configuration that uses the default values for
 every property
 */
+ (instancetype)sharedConfiguration;

/**
 An enum value representing which payment options you will accept from your user
 in addition to credit cards.
 
 The default value is `STPPaymentOptionTypeDefault`, which includes only Apple Pay.
 */
@property (nonatomic, assign, readwrite) STPPaymentOptionType additionalPaymentOptions;

/**
 The billing address fields the user must fill out when prompted for their 
 payment details. These fields will all be present on the returned PaymentMethod from
 Stripe.
 
 The default value is `STPBillingAddressFieldsPostalCode`.
 
 @see https://stripe.com/docs/api/payment_methods/create#create_payment_method-billing_details
 */
@property (nonatomic, assign, readwrite) STPBillingAddressFields requiredBillingAddressFields;

/**
 The shipping address fields the user must fill out when prompted for their
 shipping info. Set to nil if shipping address is not required.

 The default value is nil.
 */
@property (nonatomic, copy, nullable, readwrite) NSSet<STPContactField> *requiredShippingAddressFields;

/**
 Whether the user should be prompted to verify prefilled shipping information.
 
 The default value is YES.
 */
@property (nonatomic, assign, readwrite) BOOL verifyPrefilledShippingAddress;

/**
 The type of shipping for this purchase. This property sets the labels displayed
 when the user is prompted for shipping info, and whether they should also be
 asked to select a shipping method.
 
 The default value is STPShippingTypeShipping.
 */
@property (nonatomic, assign, readwrite) STPShippingType shippingType;

/**
 The set of countries supported when entering an address. This property accepts
 a set of ISO 2-character country codes.

 The default value is all known countries. Setting this property will limit
 the available countries to your selected set.
 */
@property (nonatomic, copy, null_resettable, readwrite) NSSet<NSString *> *availableCountries;

/**
 The name of your company, for displaying to the user during payment flows. For 
 example, when using Apple Pay, the payment sheet's final line item will read
 "PAY {companyName}". 
 
 The default value is the name of your iOS application which is derived from the
 `kCFBundleNameKey` of `[NSBundle mainBundle]`.
 */
@property (nonatomic, copy, readwrite) NSString *companyName;

/**
 The Apple Merchant Identifier to use during Apple Pay transactions. To create 
 one of these, see our guide at https://stripe.com/docs/mobile/apple-pay . You 
 must set this to a valid identifier in order to automatically enable Apple Pay.
 */
@property (nonatomic, copy, nullable, readwrite) NSString *appleMerchantIdentifier;

/**
 Determines whether or not the user is able to delete payment options
 
 This is only relevant to the `STPPaymentOptionsViewController` which, if 
 enabled, will allow the user to delete payment options by tapping the "Edit" 
 button in the navigation bar or by swiping left on a payment option and tapping
 "Delete". Currently, the user is not allowed to delete the selected payment 
 option but this may change in the future.

 Default value is YES but will only work if `STPPaymentOptionsViewController` is
 initialized with a `STPCustomerContext` either through the `STPPaymentContext` 
 or directly as an init parameter.
 */
@property (nonatomic, assign, readwrite) BOOL canDeletePaymentOptions;

#pragma mark - Deprecated

/**
 If you used [STPPaymentConfiguration sharedConfiguration].publishableKey, use [STPAPIClient sharedClient].publishableKey instead.  The SDK uses [STPAPIClient sharedClient] to make API requests by default.
 
 Your Stripe publishable key
 
 @see https://dashboard.stripe.com/account/apikeys
 */
@property (nonatomic, copy, readwrite) NSString *publishableKey DEPRECATED_MSG_ATTRIBUTE("If you used [STPPaymentConfiguration sharedConfiguration].publishableKey, use [STPAPIClient sharedClient].publishableKey instead. If you passed a STPPaymentConfiguration instance to an SDK component, create an STPAPIClient, set publishableKey on it, and set the SDK component's APIClient property.");

/**
 If you used [STPPaymentConfiguration sharedConfiguration].stripeAccount, use [STPAPIClient sharedClient].stripeAccount instead.  The SDK uses [STPAPIClient sharedClient] to make API requests by default.

 In order to perform API requests on behalf of a connected account, e.g. to
 create charges for a connected account, set this property to the ID of the
 account for which this request is being made.

 @see https://stripe.com/docs/payments/payment-intents/use-cases#connected-accounts
 */
@property (nonatomic, copy, nullable) NSString *stripeAccount DEPRECATED_MSG_ATTRIBUTE("If you used [STPPaymentConfiguration sharedConfiguration].stripeAccount, use [STPAPIClient sharedClient].stripeAccount instead. If you passed a STPPaymentConfiguration instance to an SDK component, create an STPAPIClient, set stripeAccount on it, and set the SDK component's APIClient property.");;

@end

NS_ASSUME_NONNULL_END
