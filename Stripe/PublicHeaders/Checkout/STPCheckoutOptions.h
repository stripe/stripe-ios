//
//  STPCheckoutOptions.h
//  StripeExample
//
//  Created by Jack Flintermann on 10/6/14.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#define STP_IMAGE_CLASS UIImage
#else
#import <AppKit/AppKit.h>
#define STP_IMAGE_CLASS NSImage
#endif



/**
 *  This class represents a configurable set of options that you can pass to an STPCheckoutViewController to control the appearance of
 * Stripe Checkout. For more information on how these properties behave, see https://stripe.com/docs/checkout#integration-custom
 */
@interface STPCheckoutOptions : NSObject<NSCopying>;

-(nonnull instancetype)initWithPublishableKey:(nonnull NSString *)publishableKey;

#pragma mark - Required options

/**
 *  The Stripe publishable key to use for your Checkout requests. Defaults to [Stripe defaultPublishableKey]. Required.
 */
@property (nonatomic, copy, nonnull) NSString *publishableKey;

#pragma mark - Strongly recommended options

/**
 *  This can be an external image URL that will load in the header of Stripe Checkout. This takes precedent over the logoImage property. The recommended minimum
 * size for this image is 128x128px.
 */
@property (nonatomic, copy, nullable) NSURL *logoURL;

/**
 *  You can also specify a local UIImage to be used as the Checkout logo header (see logoURL).
 */
@property (nonatomic, nullable) STP_IMAGE_CLASS *logoImage;

/**
 *  This specifies the color of the header shown in Stripe Checkout. If you specify a logoURL (but not a logoImage) and leave this property nil, Checkout will
 * auto-detect the background color of the image you point to and use that as the header color.
 */
#if TARGET_OS_IPHONE
@property (nonatomic, copy, nullable) UIColor *logoColor;
#else
@property (nonatomic, copy, nullable) NSColor *logoColor;
#endif

/**
 *  The name of your company or website. Displayed in the header. Defaults to your app's name.
 */
@property (nonatomic, copy, nullable) NSString *companyName;

/**
 *  A description of the product or service being purchased. Appears in the header.
 */
@property (nonatomic, copy, nullable) NSString *purchaseDescription;

/**
 *  The amount (in cents) that's shown to the user. Note that this is for display purposes only; you will still have to explicitly specify the amount when you
 * create a charge using the Stripe API.
 *  @warning don't forget this is in cents! So for a $10 charge, specify 1000 here.
 */
@property (nonatomic) NSUInteger purchaseAmount;

/**
 *  If you already know the email address of your user, you can provide it to Checkout to be pre-filled.
 */
@property (nonatomic, copy, nullable) NSString *customerEmail;

#pragma mark - Additional options

/**
 *  The label of the payment button in the Checkout form (e.g. “Subscribe”, “Pay {{amount}}”, etc.). If you include {{amount}}, it will be replaced by the
 * provided amount. Otherwise, the amount will be appended to the end of your label. Defaults to "Pay {{amount}}".
 */
@property (nonatomic, copy, nullable) NSString *purchaseLabel;

/**
 *  The currency of the amount (3-letter ISO code). The default is "USD".
 */
@property (nonatomic, copy, nonnull) NSString *purchaseCurrency;

/**
 *  Specify whether to include the option to "Remember Me" for future purchases (true or false). The default is true.
 */
@property (nonatomic, copy, nullable) NSNumber *enableRememberMe;

/**
 *  Specify whether Checkout should validate your user's billing ZIP code (true or false). The default is false.
 */
@property (nonatomic, copy, nullable) NSNumber *enablePostalCode;

/**
 *  Specify whether Checkout should require the user to enter their billing address. The default is false.
 */
@property (nonatomic, copy, nullable) NSNumber *requireBillingAddress;

/**
 *  Used internally by Stripe Checkout.
 *
 *  @return a JSON string representing the options.
 */
- (nonnull NSString *)stringifiedJSONRepresentation;

@end
