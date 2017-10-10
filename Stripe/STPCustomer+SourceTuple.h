//
//  STPCustomer+SourceTuple.h
//  Stripe
//
//  Created by Brian Dorfman on 10/9/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Stripe/Stripe.h>

#import "STPPaymentMethodTuple.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPCustomer (SourceTuple)

/**
 Returns a tuple for this customer's sources array and defaultSource
 filtered to only include the source types supported 
 by STPPaymentContext/STPPaymentMethodsViewController and adding Apple Pay as a 
 method if appropriate.

 @return A new tuple ready to be used by the SDK's UI elements
 */
- (STPPaymentMethodTuple *)filteredSourceTupleForUIWithConfiguration:(STPPaymentConfiguration *)configuration;

@end

NS_ASSUME_NONNULL_END

void linkSTPCustomerSourceTupleCategory(void);
