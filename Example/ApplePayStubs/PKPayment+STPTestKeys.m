//
//  PKPayment+STPTestKeys.m
//  StripeExample
//
//  Created by Jack Flintermann on 9/8/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000

#import "PKPayment+STPTestKeys.h"
#import <objc/runtime.h>

NSString *const STPSuccessfulChargeCardNumber = @"4242424242424242";
NSString *const STPFailingChargeCardNumber =    @"4000000000000002";

@implementation PKPayment (STPTestKeys)
@dynamic stp_testCardNumber;

- (void)setStp_testCardNumber:(NSString *)stp_testCardNumber {
    objc_setAssociatedObject(self, @selector(stp_testCardNumber), stp_testCardNumber, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)stp_testCardNumber {
    return objc_getAssociatedObject(self, @selector(stp_testCardNumber));
}

@end

#endif
