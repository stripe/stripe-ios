//
//  STPApplePayPaymentMethod.m
//  Stripe
//
//  Created by Ben Guo on 4/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPApplePayPaymentMethod.h"
#import "UIImage+Stripe.h"

@implementation STPApplePayPaymentMethod

- (UIImage *)image {
    return [UIImage stp_applePayCardImage];
}

- (NSString *)label {
    return NSLocalizedString(@"Apple Pay", nil);
}

- (BOOL)isEqual:(id)object {
    return [object isKindOfClass:[STPApplePayPaymentMethod class]];
}

- (NSUInteger)hash {
    return [NSStringFromClass(self.class) hash];
}

@end
