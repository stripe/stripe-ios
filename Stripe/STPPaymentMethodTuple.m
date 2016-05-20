//
//  STPPaymentMethodTuple.m
//  Stripe
//
//  Created by Jack Flintermann on 5/17/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodTuple.h"
#import "STPCardPaymentMethod.h"
#import "STPApplePayPaymentMethod.h"

@interface STPPaymentMethodTuple()

@property(nonatomic)id<STPPaymentMethod> selectedPaymentMethod;
@property(nonatomic)NSArray<id<STPPaymentMethod>> *paymentMethods;

@end

@implementation STPPaymentMethodTuple

+ (instancetype)tupleWithPaymentMethods:(NSArray<id<STPPaymentMethod>> *)paymentMethods
                  selectedPaymentMethod:(id<STPPaymentMethod>)selectedPaymentMethod {
    STPPaymentMethodTuple *tuple = [STPPaymentMethodTuple new];
    tuple.paymentMethods = paymentMethods ?: @[];
    tuple.selectedPaymentMethod = selectedPaymentMethod;
    return tuple;
}

+ (instancetype)tupleWithCardTuple:(STPCardTuple *)cardTuple
                   applePayEnabled:(BOOL)applePayEnabled {
    NSMutableArray *paymentMethods = [NSMutableArray array];
    for (STPCard *card in cardTuple.cards) {
        [paymentMethods addObject:[[STPCardPaymentMethod alloc] initWithCard:card]];
    }
    if (applePayEnabled) {
        [paymentMethods addObject:[STPApplePayPaymentMethod new]];
    }
    id<STPPaymentMethod> paymentMethod;
    if (cardTuple.selectedCard) {
        paymentMethod = [[STPCardPaymentMethod alloc] initWithCard:cardTuple.selectedCard];
    } else if (applePayEnabled) {
        paymentMethod = [STPApplePayPaymentMethod new];
    }
    return [self tupleWithPaymentMethods:paymentMethods selectedPaymentMethod:paymentMethod];
}

@end
