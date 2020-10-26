//
//  STPPaymentOption.h
//  Stripe
//
//  Created by Ben Guo on 4/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 This represents all of the payment methods available to your user when
 configuring an `STPPaymentContext`. This is in addition to card payments, which
 are always enabled.
 */
typedef NS_OPTIONS(NSUInteger, STPPaymentOptionType) {
    /**
     Don't allow any payment methods except for cards.
     */
    STPPaymentOptionTypeNone = 0,

    /**
     The user is allowed to pay with Apple Pay if it's configured and available
     on their device.
     */
    STPPaymentOptionTypeApplePay = 1 << 0,

    /**
     The user is allowed to pay with FPX.
     */
    STPPaymentOptionTypeFPX = 1 << 1,
    
    /**
     The user is allowed to use the default payment methods to pay.
     */
    STPPaymentOptionTypeAll __attribute__((deprecated("use STPPaymentOptionTypeDefault instead"))) = STPPaymentOptionTypeApplePay,
    STPPaymentOptionTypeDefault = STPPaymentOptionTypeApplePay
};

/**
 This protocol represents a payment method that a user can select and use to 
 pay.
 
 The classes that conform to it and are supported by the UI:
 
 - `STPApplePay`, which represents that the user wants to pay with
 Apple Pay
 - `STPPaymentMethod`.  Only `STPPaymentMethod.type == STPPaymentMethodTypeCard` and
`STPPaymentMethod.type == STPPaymentMethodTypeFPX` are supported by `STPPaymentContext`
 and `STPPaymentOptionsViewController`
 - `STPPaymentMethodParams`. This should be used with non-reusable payment method, such
 as FPX and iDEAL. Instead of reaching out to Stripe to create a PaymentMethod, you can
 pass an STPPaymentMethodParams directly to Stripe when confirming a PaymentIntent.

 @note card-based Sources, Cards, and FPX support this protocol for use
 in a custom integration.
 */
@protocol STPPaymentOption <NSObject>

/**
 A small (32 x 20 points) logo image representing the payment method. For
 example, the Visa logo for a Visa card, or the Apple Pay logo.
 */
@property (nonatomic, strong, readonly) UIImage *image;

/**
 A small (32 x 20 points) logo image representing the payment method that can be
 used as template for tinted icons.
 */
@property (nonatomic, strong, readonly) UIImage *templateImage;

/**
 A string describing the payment method, such as "Apple Pay" or "Visa 4242".
 */
@property (nonatomic, strong, readonly) NSString *label;

/**
 Describes whether this payment option may be used multiple times. If it is not reusable,
 the payment method must be discarded after use.
 */
@property (nonatomic, readonly, getter=isReusable) BOOL reusable;

@end

NS_ASSUME_NONNULL_END
