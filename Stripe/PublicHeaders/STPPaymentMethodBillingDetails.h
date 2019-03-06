//
//  STPPaymentMethodBillingDetails.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/5/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"

@class STPPaymentMethodBillingDetailsAddress;

NS_ASSUME_NONNULL_BEGIN

/**
 Billing information associated with a `STPPaymentMethod` that may be used or required by particular types of payment methods.
 
 @see https://site-admin.stripe.com/docs/api/payment_methods/object#payment_method_object-billing_details
 */
@interface STPPaymentMethodBillingDetails : NSObject <STPAPIResponseDecodable>

/**
 You cannot directly instantiate an `STPPaymentMethodBillingDetails`. You should only use one that is part of an existing `STPPaymentMethod` object.
 */
- (instancetype)init __attribute__((unavailable("You cannot directly instantiate an STPPaymentMethodBillingDetails. You should only use one that is part of an existing STPPaymentMethod object.")));

/**
 Billing address.
 */
@property (nonatomic, nullable, readonly) STPPaymentMethodBillingDetailsAddress *address;

/**
 Email address.
 */
@property (nonatomic, nullable, readonly) NSString *email;

/**
 Full name.
 */
@property (nonatomic, nullable, readonly) NSString *name;

/**
 Billing phone number (including extension).
 */
@property (nonatomic, nullable, readonly) NSString *phone;

@end

NS_ASSUME_NONNULL_END
