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

- (instancetype)initWithCardTuple:(STPCardTuple *)cardTuple
                  applePayEnabled:(BOOL)applePayEnabled {
    NSMutableArray *paymentMethods = [NSMutableArray array];
    for (STPCard *card in cardTuple.cards) {
        [paymentMethods addObject:[[STPCardPaymentMethod alloc] initWithCard:card]];
    }
    if (applePayEnabled) {
        [paymentMethods addObject:[STPApplePayPaymentMethod new]];
    }
    STPPaymentMethodTuple *tuple = [STPPaymentMethodTuple new];
    tuple.paymentMethods = paymentMethods;
    if (cardTuple.selectedCard) {
        tuple.selectedPaymentMethod = [[STPCardPaymentMethod alloc] initWithCard:cardTuple.selectedCard];
    } else if (applePayEnabled) {
        tuple.selectedPaymentMethod = [STPApplePayPaymentMethod new];
    }
    return tuple;
}

@end
