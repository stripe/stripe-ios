//
//  STPPaymentMethodTuple.m
//  Stripe
//
//  Created by Jack Flintermann on 5/17/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodTuple.h"
#import "STPApplePay.h"
#import "STPCard.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPPaymentMethodTuple()

@property (nonatomic, nullable) id<STPPaymentOption> selectedPaymentMethod;
@property (nonatomic) NSArray<id<STPPaymentOption>> *paymentMethods;

@end

@implementation STPPaymentMethodTuple

+ (instancetype)tupleWithPaymentMethods:(NSArray<id<STPPaymentOption>> *)paymentMethods
                  selectedPaymentMethod:(nullable id<STPPaymentOption>)selectedPaymentMethod {
    STPPaymentMethodTuple *tuple = [self new];
    tuple.paymentMethods = paymentMethods ?: @[];
    tuple.selectedPaymentMethod = selectedPaymentMethod;
    return tuple;
}

+ (instancetype)tupleWithPaymentMethods:(NSArray<id<STPPaymentOption>> *)paymentMethods
                  selectedPaymentMethod:(nullable id<STPPaymentOption>)selectedPaymentMethod
                      addApplePayMethod:(BOOL)applePayEnabled {
    NSMutableArray *mutablePaymentMethods = paymentMethods.mutableCopy;
     id<STPPaymentOption> _Nullable selected = selectedPaymentMethod;

    if (applePayEnabled) {
        STPApplePay *applePay = [STPApplePay new];
        [mutablePaymentMethods addObject:applePay];

        if (!selected) {
            selected = applePay;
        }
    }

    return [self tupleWithPaymentMethods:mutablePaymentMethods.copy
                   selectedPaymentMethod:selected];
}

@end

NS_ASSUME_NONNULL_END
