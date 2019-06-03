//
//  STPPaymentResult.m
//  Stripe
//
//  Created by Jack Flintermann on 1/15/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentResult.h"

#import "STPPaymentMethod.h"

@interface STPPaymentResult()
@property (nonatomic) STPPaymentMethod *paymentMethod;
@end

@implementation STPPaymentResult

- (nonnull instancetype)initWithPaymentMethod:(STPPaymentMethod *)paymentMethod {
    self = [super init];
    if (self) {
        _paymentMethod = paymentMethod;
    }
    return self;
}

@end
