//
//  STPPaymentOptionTuple.m
//  Stripe
//
//  Created by Jack Flintermann on 5/17/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentOptionTuple.h"
#import "STPApplePayPaymentOption.h"
#import "STPPaymentConfiguration+Private.h"
#import "STPPaymentMethod.h"

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

+ (instancetype)tupleFilteredForUIWithPaymentMethods:(NSArray<STPPaymentMethod *> *)paymentMethods
                               selectedPaymentMethod:(nullable NSString *)selectedPaymentMethodID
                                       configuration:(STPPaymentConfiguration *)configuration {
    NSMutableArray *paymentOptions = [NSMutableArray new];
    STPPaymentMethod *selectedPaymentMethod = nil;
    for (STPPaymentMethod *paymentMethod in paymentMethods) {
        if (paymentMethod.type == STPPaymentMethodTypeCard) {
            [paymentOptions addObject:paymentMethod];
            if ([paymentMethod.stripeId isEqualToString:selectedPaymentMethodID]) {
                selectedPaymentMethod = paymentMethod;
            }
        }
    }

    return [[self class] tupleWithPaymentOptions:paymentOptions
                                    selectedPaymentOption:selectedPaymentMethod
                                        addApplePayOption:configuration.applePayEnabled];
}

@end

NS_ASSUME_NONNULL_END
