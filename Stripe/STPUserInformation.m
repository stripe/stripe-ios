//
//  STPUserInformation.m
//  Stripe
//
//  Created by Jack Flintermann on 6/15/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPUserInformation.h"

#import "STPCardValidator.h"

@implementation STPUserInformation

- (id)copyWithZone:(__unused NSZone *)zone {
    STPUserInformation *copy = [self.class new];
    copy.billingAddress = self.billingAddress;
    copy.shippingAddress = self.shippingAddress;
    return copy;
}

- (void)setBillingAddressWithBillingDetails:(STPPaymentMethodBillingDetails *)billingDetails {
    self.billingAddress = [[STPAddress alloc] initWithPaymentMethodBillingDetails:billingDetails];
}

@end
