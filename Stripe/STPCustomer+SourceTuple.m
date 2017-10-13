//
//  STPCustomer+SourceTuple.m
//  Stripe
//
//  Created by Brian Dorfman on 10/9/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPCustomer+SourceTuple.h"

#import "STPCard.h"
#import "STPPaymentConfiguration+Private.h"
#import "STPPaymentMethodTuple.h"
#import "STPSource+Private.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STPCustomer (SourceTuple)

- (STPPaymentMethodTuple *)filteredSourceTupleForUIWithConfiguration:(STPPaymentConfiguration *)configuration {
    id<STPPaymentMethod> _Nullable selectedMethod = nil;
    NSMutableArray<id<STPPaymentMethod>> *methods = [NSMutableArray array];
    for (id<STPSourceProtocol> customerSource in self.sources) {
        if ([customerSource isKindOfClass:[STPCard class]]) {
            STPCard *card = (STPCard *)customerSource;
            [methods addObject:card];
            if ([card.stripeID isEqualToString:self.defaultSource.stripeID]) {
                selectedMethod = card;
            }
        }
        else if ([customerSource isKindOfClass:[STPSource class]]) {
            STPSource *source = (STPSource *)customerSource;
            if (source.type == STPSourceTypeCard
                && source.cardDetails != nil) {
                [methods addObject:source];
                if ([source.stripeID isEqualToString:self.defaultSource.stripeID]) {
                    selectedMethod = source;
                }
            }
        }
    }

    return [STPPaymentMethodTuple tupleWithPaymentMethods:methods
                                    selectedPaymentMethod:selectedMethod
                                        addApplePayMethod:configuration.applePayEnabled];
}

@end

NS_ASSUME_NONNULL_END

void linkSTPCustomerSourceTupleCategory(void){}
