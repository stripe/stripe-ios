//
//  PKAddPaymentPassRequest+Stripe_Error.m
//  Stripe
//
//  Created by Jack Flintermann on 9/29/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "PKAddPaymentPassRequest+Stripe_Error.h"
#import <objc/runtime.h>

@implementation PKAddPaymentPassRequest (Stripe_Error)
- (NSError *)stp_error {
    return objc_getAssociatedObject(self, @selector(stp_error));
}

- (void)setStp_error:(NSError *)stp_error {
    objc_setAssociatedObject(self, @selector(stp_error), stp_error, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end

void linkPKAddPaymentPassRequestCategory(void){}
