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
#import "STPPaymentMethodType.h"
#import "STPTheme.h"

NS_ASSUME_NONNULL_BEGIN


/**
 Options for 3D Secure support.

 - STPThreeDSecureSupportTypeDisabled: Your customer will never be prompted for 
 3DS verification.

 - STPThreeDSecureSupportTypeStatic: Your customer will be prompted for 
 3DS verification if available.  If 3DS is not available, the original card 
 source will be passed to your app. Note that if you charge a card source, you 
 will not be protected from fraud by 3DS. If you want to reject all card payments
 that haven't passed 3DS verification, you should update your logic accordingly 
 in paymentContext:didCreatePaymentResult:completion: if the payment result is
 a card source, instead of passing the source to your backend to be charged, you
 should call the completion block with an error.
 */
typedef NS_ENUM(NSUInteger, STPThreeDSecureSupportType) {
    STPThreeDSecureSupportTypeDisabled,
    STPThreeDSecureSupportTypeStatic,
};

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
@property (nonatomic, copy) NSString *publishableKey;

/**
 *  If YES, STPPaymentContext will generate STPSource objects when creating
 *  new cards. Otherwise it will generate STPCard objects. Existing saved cards 
 *  on the customer will be processed regardless of whether they were created
 *  uses sources or tokens.
 *
 *  The default value is NO
 *
 *  @see https://stripe.com/docs/sources
 */
@property (nonatomic) BOOL useSourcesForCards;

/**
 *  An array of payment method type objects that represents the list of
 *  the available payment methods available to users of your app.
 * 
 *  The methods in this list will be shown to users in STPPaymentMethodsViewController
 *  for users to choose from in the order they are listed in this array.
 *  Any methods types not in either this array will not be available to users 
 *  of your app.
 *
 *  If a method appears in the array twice, all but the first will be removed.
 */
@property (nonatomic, copy) NSArray<STPPaymentMethodType *> *availablePaymentMethodTypes;

/**
 *  The billing address fields the user must fill out when prompted for their 
 *  payment details. These fields will all be present on the returned token from 
 *  Stripe. See https://stripe.com/docs/api#create_card_token for more information.
 */
@property (nonatomic) STPBillingAddressFields requiredBillingAddressFields;

/**
 *  The billing address fields the user must fill out when prompted for their 
 *  shipping info.
 */
@property (nonatomic) PKAddressField requiredShippingAddressFields;

/**
 *  The type of shipping for this purchase. This property sets the labels 
 *  displayed when the user is prompted for shipping info, and whether they 
 *  should also be asked to select a shipping method.
 *
 *  The default value is STPShippingTypeShipping.
 */
@property (nonatomic) STPShippingType shippingType;

/**
 *  The name of your company, for displaying to the user during payment flows.
 *  For example, when using Apple Pay, the payment sheet's final line item will 
 *  read "PAY {companyName}". This defaults to the name of your iOS application.
 */
@property (nonatomic, copy) NSString *companyName;

/**
 *  The Apple Merchant Identifier to use during Apple Pay transactions.
 *  To create one of these, see our guide at https://stripe.com/docs/mobile/apple-pay. 
 *  You must set this to a valid identifier in order to automatically enable Apple Pay.
 */
@property (nonatomic, nullable, copy) NSString *appleMerchantIdentifier;

/**
 *  If you use payment methods which require redirect flows, this returnURL
 *  must be set to a URL that will bring the user back into your app so they
 *  can continue your checkout flow. It can be either a universal link or a 
 *  native scheme.
 *
 *  To learn more about universal links, see https://developer.apple.com/library/content/documentation/General/Conceptual/AppSearch/UniversalLinks.html
 *  To learn more about native url schemes, see https://developer.apple.com/library/content/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/Inter-AppCommunication/Inter-AppCommunication.html#//apple_ref/doc/uid/TP40007072-CH6-SW10
 */
@property (nonatomic, nullable, copy) NSURL *returnURL NS_EXTENSION_UNAVAILABLE("Redirect based sources are not available in extensions");


/**
 *  This setting controls whether or not STPPaymentContext will attempt to create
 *  3D Secure source objects from card source objects when payment is requested.
 *
 *  See the enum for description of the possible values.
 *
 *  The default value is STPThreeDSecureSupportTypeDisabled.
 *
 *  A successful 3DS source creation will result in a redirect, if necessary, 
 *  so the user can authorize the charge. If a 3DS source is created, neither 
 *  the original card source nor the 3DS source will be passed back to your app. 
 *  Instead, your backend should listen for source status webhooks and charge 
 *  the 3DS source when it becomes chargeable.
 *  See:
 *  https://stripe.com/docs/sources/three-d-secure
 *  https://stripe.com/docs/sources#best-practices
 *
 *  @note To use a non-Disabled value here, your `useSourcesForCards` property 
 *  must be set to YES and `returnURL` must be set to a valid URL that your 
 *  app can receive callbacks from.
 */
@property (nonatomic, assign) STPThreeDSecureSupportType threeDSecureSupportType NS_EXTENSION_UNAVAILABLE("Redirect based sources are not available in extensions");


/**
 *  For payment methods that redirect a user to authorize a payment, the SDK
 *  will poll the source for up to this amount of time after the user returns to
 *  the app in order to determine the status of the payment. The default is 10
 *  seconds. Timeouts are capped at 5 minutes.
 */
@property (nonatomic) NSTimeInterval pollingTimeout;

@end

NS_ASSUME_NONNULL_END
