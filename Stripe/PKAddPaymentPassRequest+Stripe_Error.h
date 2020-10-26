//
//  PKAddPaymentPassRequest+Stripe_Error.h
//  Stripe
//
//  Created by Jack Flintermann on 9/29/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <PassKit/PassKit.h>

// This is used to store an error on a PKAddPaymentPassRequest
// so that STPFakeAddPaymentPassViewController can inspect it for debugging.
@interface PKAddPaymentPassRequest (Stripe_Error)
@property (nonatomic) NSError *stp_error;
@end

void linkPKAddPaymentPassRequestCategory(void);
