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
#import "STPPaymentOptionTuple.h"
#import "STPSource+Private.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STPCustomer (SourceTuple)

- (STPPaymentOptionTuple *)filteredSourceTupleForUIWithConfiguration:(STPPaymentConfiguration *)configuration {
    id<STPPaymentOption> _Nullable selectedMethod = nil;
    NSMutableArray<id<STPPaymentOption>> *methods = [NSMutableArray array];
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

    return [STPPaymentOptionTuple tupleWithPaymentOptions:methods
                                    selectedPaymentOption:selectedMethod
                                        addApplePayOption:configuration.applePayEnabled];
}

@end

NS_ASSUME_NONNULL_END

void linkSTPCustomerSourceTupleCategory(void){}
