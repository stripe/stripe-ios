//
//  STPCustomer+Stripe_PaymentMethods.h
//  Stripe
//
//  Created by Brian Dorfman on 3/17/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Stripe/Stripe.h>
#import "STPPaymentMethodTuple.h"

@interface STPCustomer (Stripe_PaymentMethods)
- (STPPaymentMethodTuple *)stp_paymentMethodTupleWithConfiguration:(STPPaymentConfiguration *)configuration;
+ (NSArray *)stp_sortedPaymentMethodsFromArray:(NSArray<id<STPPaymentMethod>> *)savedPaymentMethods
                                     sortOrder:(NSOrderedSet<STPPaymentMethodType *> *)orderedMethodTypes;
@end
