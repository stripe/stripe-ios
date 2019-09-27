//
//  STPPaymentResult.m
//  Stripe
//
//  Created by Jack Flintermann on 1/15/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentResult.h"

#import "STPPaymentMethod.h"
#import "STPPaymentMethodParams.h"

@interface STPPaymentResult()
@property (nonatomic) STPPaymentMethod *paymentMethod;
@property (nonatomic) STPPaymentMethodParams *paymentMethodParams;
@end

@implementation STPPaymentResult

- (instancetype)initWithPaymentOption:(id<STPPaymentOption>)paymentOption {
    self = [super init];
    if (self) {
        if ([paymentOption isKindOfClass:[STPPaymentMethod class]]) {
            _paymentMethod = (STPPaymentMethod *)paymentOption;
        } else if ([paymentOption isKindOfClass:[STPPaymentMethodParams class]]) {
            _paymentMethodParams = (STPPaymentMethodParams *)paymentOption;
        } else {
            return nil;
        }
    }
    return self;
}

- (id<STPPaymentOption>)paymentOption {
    if (_paymentMethod != nil) {
        return _paymentMethod;
    } else {
        return _paymentMethodParams;
    }
}

@end
