//
//  STPPaymentCardTextField+Private.h
//  Stripe
//
//  Created by Brian Dorfman on 5/3/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Stripe/Stripe.h>

@class STPFormTextField;

@interface STPPaymentCardTextField (Private)
@property (nonatomic, strong) NSArray<STPFormTextField *> *allFields;
- (void)commonInit;
@end
