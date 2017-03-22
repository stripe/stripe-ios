//
//  STPPaymentMethod.h
//  Stripe
//
//  Created by Ben Guo on 4/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class STPPaymentMethodType;

NS_ASSUME_NONNULL_BEGIN

/**
 *  This protocol represents a payment method that a user can select and use to 
 *  pay. This may be a specific card, token, or source (eg. "Visa ending in 4242")
 *  or simply a generic type of payment (eg "Apple Pay", "Bancontact") that
 *  will be converted to an actual source later on at checkout time.
 *
 *  @see `STPCard`, `STPSource`, `STPPaymentMethodType`
 */
@protocol STPPaymentMethod <NSObject>

/**
 *  If this is a known, specific payment method, (eg an individual credit card
 *  represented by `STPCard` or `STPSource`) this will give you the generic 
 *  payment method type (eg `[STPPaymentMethodType creditCard]`).
 * 
 *  If this is already a generic type, it will simply return self.
 *
 *  If you want to learn the generic type of an `STPPaymentMethodType` object,
 *  you can compare to the class methods on `STPPaymentMethodType`
 *  e.g. to check if the method is a credit card do
 *  `if ([myPaymentMethod.type isEqual:[STPPaymentMethodType creditCard]])`
 *
 *  This may return nil for unknown source types, or source types that are not
 *  supported by the SDK's pre-built UI.
 *
 *  TODO: It's possibly not necessary to expose this information to the user
 */
@property (nonatomic, nullable, readonly) STPPaymentMethodType *paymentMethodType;

/**
 *  A small (32 x 20 points) logo image representing the payment method. 
 *  For example, the Visa logo for a Visa card, or the Apple Pay logo.
 */
@property (nonatomic, nullable, readonly) UIImage *paymentMethodImage;

/**
 *  A small (32 x 20 points) logo image representing the payment method that 
 *  can be used as template for tinted icons.
 */
@property (nonatomic, nullable,  readonly) UIImage *paymentMethodTemplateImage;

/**
 *  A string describing the payment method, such as "Apple Pay" or "Visa 4242".
 */
@property (nonatomic, nullable,  readonly) NSString *paymentMethodLabel;

@end

NS_ASSUME_NONNULL_END
