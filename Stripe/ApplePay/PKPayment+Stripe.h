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

/// Returns a fake transaction identifier with the expected ~-separated format.
+ (NSString *)testTransactionIdentifier;

@end
