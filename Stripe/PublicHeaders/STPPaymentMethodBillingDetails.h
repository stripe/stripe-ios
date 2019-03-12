//
//  STPPaymentMethodBillingDetails.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/5/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"
#import "STPFormEncodable.h"

@class STPPaymentMethodBillingDetailsAddress;

NS_ASSUME_NONNULL_BEGIN

/**
 Billing information associated with a `STPPaymentMethod` that may be used or required by particular types of payment methods.
 
 @see https://stripe.com/docs/api/payment_methods/object#payment_method_object-billing_details
 */
@interface STPPaymentMethodBillingDetails : NSObject <STPAPIResponseDecodable, STPFormEncodable>

/**
 Billing address.
 */
@property (nonatomic, strong, nullable, readwrite) STPPaymentMethodBillingDetailsAddress *address;

/**
 Email address.
 */
@property (nonatomic, copy, nullable, readwrite) NSString *email;

/**
 Full name.
 */
@property (nonatomic, copy, nullable, readwrite) NSString *name;

/**
 Billing phone number (including extension).
 */
@property (nonatomic, copy, nullable, readwrite) NSString *phone;

@end

NS_ASSUME_NONNULL_END
