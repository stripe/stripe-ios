//
//  PKPayment+Stripe.h
//  Stripe
//
//  Created by Ben Guo on 7/2/15.
//

@import PassKit;

@interface PKPayment (Stripe)

/// Returns true if the instance is a payment from the simulator.
- (BOOL)isSimulated;

/// Sets the simulated instance's transaction identifier to the expected ~-separated format.
- (void)setFakeTransactionIdentifier;

@end
