//
//  PKPayment+Stripe.h
//  Stripe
//
//  Created by Ben Guo on 7/2/15.
//

#import <PassKit/PassKit.h>

@interface PKPayment (Stripe)

/// Returns true if the instance is a payment from the simulator.
- (BOOL)isSimulated;

/// Sets the instance's transaction identifier to the expected ApplePayStubs format.
- (void)setFakeTransactionIdentifierWithRequest:(PKPaymentRequest *)request;

@end
