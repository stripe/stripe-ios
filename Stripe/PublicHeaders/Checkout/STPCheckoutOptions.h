//
//  STPCheckoutOptions.h
//  StripeExample
//
//  Created by Jack Flintermann on 10/6/14.
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif

/**
 *  This class represents a configurable set of options that you can pass to an STPCheckoutViewController or an STPPaymentPresenter to control the appearance of
 * Stripe Checkout. For more information on how these properties behave, see https://stripe.com/docs/checkout#integration-custom
 */
@interface STPCheckoutOptions : NSObject<NSCopying>

#pragma mark - Required options

/**
 *  The Stripe publishable key to use for your Checkout requests. Defaults to [Stripe defaultPublishableKey]. Required.
 */
@property (nonatomic, copy) NSString *publishableKey;

#pragma mark - Strongly recommended options

/**
 *  The merchant ID that you've obtained from Apple while creating your Apple Pay certificate. If you haven't done this, you can learn how at
 * https://stripe.com/docs/mobile/apple-pay . This property needs to be set in order to use Apple Pay with STPPaymentPresenter.
 */
@property (nonatomic, copy) NSString *appleMerchantId;

/**
 *  This can be an external image URL that will load in the header of Stripe Checkout. This takes precedent over the logoImage property. The recommended minimum
 * size for this image is 128x128px.
 */
@property (nonatomic, copy) NSURL *logoURL;

/**
 *  You can also specify a local UIImage to be used as the Checkout logo header (see logoURL).
 */
#if TARGET_OS_IPHONE
@property (nonatomic) UIImage *logoImage;
#else
@property (nonatomic) NSImage *logoImage;
#endif

/**
 *  This specifies the color of the header shown in Stripe Checkout. If you specify a logoURL (but not a logoImage) and leave this property nil, Checkout will
 * auto-detect the background color of the image you point to and use that as the header color.
 */
#if TARGET_OS_IPHONE
@property (nonatomic, copy) UIColor *logoColor;
#else
@property (nonatomic, copy) NSColor *logoColor;
#endif

/**
 *  The name of your company or website. Displayed in the header. Defaults to your app's name. This property needs to be set in order to use Apple Pay with
 * STPPaymentPresenter.
 */
@property (nonatomic, copy) NSString *companyName;

/**
 *  A description of the product or service being purchased. Appears in the header.
 */
@property (nonatomic, copy) NSString *purchaseDescription;

/**
 *  The amount (in cents) that's shown to the user. Note that this is for display purposes only; you will still have to explicitly specify the amount when you
 * create a charge using the Stripe API. This property needs to be set in order to use Apple Pay with STPPaymentPresenter.
 *  @warning don't forget this is in cents! So for a $10 charge, specify 1000 here.
 */
@property (nonatomic) NSUInteger purchaseAmount;

/**
 *  If you already know the email address of your user, you can provide it to Checkout to be pre-filled.
 */
@property (nonatomic, copy) NSString *customerEmail;

#pragma mark - Additional options

/**
 *  The label of the payment button in the Checkout form (e.g. “Subscribe”, “Pay {{amount}}”, etc.). If you include {{amount}}, it will be replaced by the
 * provided amount. Otherwise, the amount will be appended to the end of your label. Defaults to "Pay {{amount}}".
 */
@property (nonatomic, copy) NSString *purchaseLabel;

/**
 *  The currency of the amount (3-letter ISO code). The default is "USD".
 */
@property (nonatomic, copy) NSString *purchaseCurrency;

/**
 *  Specify whether to include the option to "Remember Me" for future purchases (true or false). The default is true.
 */
@property (nonatomic, copy) NSNumber *enableRememberMe;

/**
 *  Specify whether Checkout should validate your user's billing ZIP code (true or false). The default is false.
 */
@property (nonatomic, copy) NSNumber *enablePostalCode;

/**
 *  Specify whether Checkout should require the user to enter their billing address. The default is false.
 */
@property (nonatomic, copy) NSNumber *requireBillingAddress;

/**
 *  Used internally by Stripe Checkout.
 *
 *  @return a JSON string representing the options.
 */
- (NSString *)stringifiedJSONRepresentation;

@end
