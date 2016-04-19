//
//  STPApplePayPaymentMethod.m
//  Stripe
//
//  Created by Ben Guo on 4/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPApplePayPaymentMethod.h"

@implementation STPApplePayPaymentMethod

- (STPPaymentMethodType)type {
    return STPPaymentMethodTypeApplePay;
}

- (UIImage *)image {
    // TODO
    return [UIImage new];
}

- (NSString *)label {
    return @"Apple Pay";
}


@end
