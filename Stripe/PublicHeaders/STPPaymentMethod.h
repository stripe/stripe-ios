//
//  STPPaymentMethod.h
//  Stripe
//
//  Created by Ben Guo on 4/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  This represents all of the payment methods available to your user when configuring an STPPaymentContext.
 */
typedef NS_OPTIONS(NSUInteger, STPPaymentMethodType) {
    /**
     *  The user is allowed to pay with Apple Pay (if it's configured and available on their device).
     */
    STPPaymentMethodTypeApplePay = 1 << 0,
    /**
     *  The user is allowed to pay with a card.
     */
    STPPaymentMethodTypeCard = 1 << 1,
    /**
     *  The user can use any available payment method to pay.
     */
    STPPaymentMethodTypeAll = STPPaymentMethodTypeApplePay | STPPaymentMethodTypeCard
};

/**
 *  This protocol represents a payment method that a user can select and use to pay. Currently the only classes that conform to it are STPCard (which represents that the user wants to pay with a specific card) and STPApplePayPaymentMethod (which represents that the user wants to pay with Apple Pay).
 */
@protocol STPPaymentMethod <NSObject>

/**
 *  An image representing the payment method. For example, the Visa logo for a Visa card, or the Apple Pay logo.
 */
@property (nonatomic, readonly) UIImage *image;

/**
 *  A string describing the payment method, such as "Apple Pay" or "Visa 4242".
 */
@property (nonatomic, readonly) NSString *label;

@end
