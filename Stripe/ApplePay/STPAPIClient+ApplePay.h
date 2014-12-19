//
//  STPAPIClient+ApplePay.h
//  Stripe
//
//  Created by Jack Flintermann on 12/19/14.
//  Copyright (c) 2014 Stripe, Inc. All rights reserved.
//

#if defined(STRIPE_ENABLE_APPLEPAY)

#import "STPAPIClient.h"
#import <PassKit/PassKit.h>

@interface STPAPIClient (ApplePay)

- (void)createTokenWithPayment:(PKPayment *)payment completion:(STPCompletionBlock)completion;

+ (NSData *)formEncodedDataForPayment:(PKPayment *)payment;

@end

#endif
