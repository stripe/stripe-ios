//
//  STPPaymentMethodParams.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/6/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPFormEncodable.h"

@class STPPaymentMethodBillingDetails, STPPaymentMethodCardParams;

NS_ASSUME_NONNULL_BEGIN

/**
 Types of a PaymentMethod
 */
typedef NS_ENUM(NSUInteger, STPPaymentMethodParamsType) {
    STPPaymentMethodParamsTypeCard,
};

@interface STPPaymentMethodParams : NSObject <STPFormEncodable>

/**
 The type of payment method.  The associated property will contain additional information (e.g. `type == STPPaymentMethodParamsTypeCard` means `card` should also be populated).
 */
@property (nonatomic, assign, readwrite) STPPaymentMethodParamsType type;

/**
 Billing information associated with the PaymentMethod that may be used or required by particular types of payment methods.
 */
@property (nonatomic, strong, nullable, readwrite) STPPaymentMethodBillingDetails *billingDetails;

/**
 If this is a card PaymentMethod, this contains the user’s card details.
 */
@property (nonatomic, strong, nullable, readwrite) STPPaymentMethodCardParams *card;

/**
 Set of key-value pairs that you can attach to the PaymentMethod. This can be useful for storing additional information about the PaymentMethod in a structured format.
 */
@property (nonatomic, copy, nullable, readwrite) NSDictionary<NSString *, NSString *> *metadata;

/**
 Creates params for a card PaymentMethod.
 
 @param card                An object containing the user's card details.
 @param billingDetails      An object containing the user's billing details.
 @param metadata            Additional information to attach to the PaymentMethod.
 */
+ (STPPaymentMethodParams *)paramsWithCard:(STPPaymentMethodCardParams *)card
                                billingDetails:(nullable STPPaymentMethodBillingDetails *)billingDetails
                                      metadata:(nullable NSDictionary<NSString *, NSString *> *)metadata;

@end

NS_ASSUME_NONNULL_END
