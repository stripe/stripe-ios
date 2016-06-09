//
//  STPPaymentConfiguration+Private.m
//  Stripe
//
//  Created by Jack Flintermann on 6/9/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentConfiguration+Private.h"

@implementation STPPaymentConfiguration (Private)

- (BOOL)applePayEnabled {
    return self.appleMerchantIdentifier &&
    (self.supportedPaymentMethods & STPPaymentMethodTypeApplePay) &&
    [Stripe deviceSupportsApplePay];
}

@end
