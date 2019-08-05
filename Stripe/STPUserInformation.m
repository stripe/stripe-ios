//
//  STPUserInformation.m
//  Stripe
//
//  Created by Jack Flintermann on 6/15/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPUserInformation.h"

#import "STPCardValidator.h"
#import "STPPaymentMethodBillingDetails.h"
#import "STPPaymentMethodAddress.h"

@implementation STPUserInformation

- (id)copyWithZone:(__unused NSZone *)zone {
    STPUserInformation *copy = [self.class new];
    copy.billingAddress = self.billingAddress;
    copy.shippingAddress = self.shippingAddress;
    return copy;
}

- (void)setBillingAddressWithBillingDetails:(STPPaymentMethodBillingDetails *)billingDetails {
    STPAddress *address = [STPAddress new];
    address.name = billingDetails.name;
    address.phone = billingDetails.phone;
    address.email = billingDetails.email;
    STPPaymentMethodAddress *pmAddress = billingDetails.address;
    address.line1 = pmAddress.line1;
    address.line2 = pmAddress.line2;
    address.city = pmAddress.city;
    address.state = pmAddress.state;
    address.postalCode = pmAddress.postalCode;
    address.country = pmAddress.country;
    self.billingAddress = address;
}

@end
