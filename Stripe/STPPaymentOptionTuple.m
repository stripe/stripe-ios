//
//  STPPaymentOptionTuple.m
//  Stripe
//
//  Created by Jack Flintermann on 5/17/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentOptionTuple.h"
#import "STPApplePayPaymentOption.h"
#import "STPCard.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPPaymentOptionTuple()

@property (nonatomic, nullable) id<STPPaymentOption> selectedPaymentOption;
@property (nonatomic) NSArray<id<STPPaymentOption>> *paymentOptions;

@end

@implementation STPPaymentOptionTuple

+ (instancetype)tupleWithPaymentOptions:(NSArray<id<STPPaymentOption>> *)paymentOptions
                  selectedPaymentOption:(nullable id<STPPaymentOption>)selectedPaymentOption {
    STPPaymentOptionTuple *tuple = [self new];
    tuple.paymentOptions = paymentOptions ?: @[];
    tuple.selectedPaymentOption = selectedPaymentOption;
    return tuple;
}

+ (instancetype)tupleWithPaymentOptions:(NSArray<id<STPPaymentOption>> *)paymentOptions
                  selectedPaymentOption:(nullable id<STPPaymentOption>)selectedPaymentOption
                      addApplePayOption:(BOOL)applePayEnabled {
    NSMutableArray *mutablePaymentOptions = paymentOptions.mutableCopy;
     id<STPPaymentOption> _Nullable selected = selectedPaymentOption;

    if (applePayEnabled) {
        STPApplePayPaymentOption *applePay = [STPApplePayPaymentOption new];
        [mutablePaymentOptions addObject:applePay];

        if (!selected) {
            selected = applePay;
        }
    }

    return [self tupleWithPaymentOptions:mutablePaymentOptions.copy
                   selectedPaymentOption:selected];
}

@end

NS_ASSUME_NONNULL_END
