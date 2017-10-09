//
//  STPPaymentMethodTuple.m
//  Stripe
//
//  Created by Jack Flintermann on 5/17/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodTuple.h"
#import "STPApplePayPaymentMethod.h"
#import "STPCard.h"

@interface STPPaymentMethodTuple()

@property (nonatomic) id<STPPaymentMethod> selectedPaymentMethod;
@property (nonatomic) NSArray<id<STPPaymentMethod>> *paymentMethods;

@end

@implementation STPPaymentMethodTuple

+ (instancetype)tupleWithPaymentMethods:(NSArray<id<STPPaymentMethod>> *)paymentMethods
                  selectedPaymentMethod:(id<STPPaymentMethod>)selectedPaymentMethod {
    STPPaymentMethodTuple *tuple = [self new];
    tuple.paymentMethods = paymentMethods ?: @[];
    tuple.selectedPaymentMethod = selectedPaymentMethod;
    return tuple;
}

+ (instancetype)tupleWithPaymentMethods:(NSArray<id<STPPaymentMethod>> *)paymentMethods
                  selectedPaymentMethod:(id<STPPaymentMethod>)selectedPaymentMethod
                      addApplePayMethod:(BOOL)applePayEnabled {
    NSMutableArray *mutablePaymentMethods = paymentMethods.mutableCopy;
    id<STPPaymentMethod> selected = selectedPaymentMethod;

    if (applePayEnabled) {
        STPApplePayPaymentMethod *applePay = [STPApplePayPaymentMethod new];
        [mutablePaymentMethods addObject:applePay];

        if (!selected) {
            selected = applePay;
        }
    }

    return [self tupleWithPaymentMethods:mutablePaymentMethods.copy
                   selectedPaymentMethod:selected];
}

@end
