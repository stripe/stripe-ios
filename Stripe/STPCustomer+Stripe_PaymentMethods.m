//
//  STPCustomer+Stripe_PaymentMethods.m
//  Stripe
//
//  Created by Brian Dorfman on 3/17/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPCustomer+Stripe_PaymentMethods.h"
#import "STPPaymentConfiguration+Private.h"
#import "STPPaymentMethodTuple.h"

@implementation STPCustomer (Stripe_PaymentMethods)

- (STPPaymentMethodTuple *)stp_paymentMethodTupleWithConfiguration:(STPPaymentConfiguration *)configuration {


    NSOrderedSet<STPPaymentMethodType *> *availableTypes = configuration.availablePaymentMethodTypesSet;
    // TODO: store last payment method locally or on stripe meta data so
    // it can be a non-reusable source

    id<STPPaymentMethod> selectedPaymentMethod = nil;
    NSMutableArray<id<STPPaymentMethod>> *filteredSavedPaymentMethods = [NSMutableArray new];
    for (id<STPSourceProtocol> source in self.sources) {
        if ([source conformsToProtocol:@protocol(STPPaymentMethod)]) {
            id<STPPaymentMethod> paymentMethod = (id<STPPaymentMethod>)source;
            if ([availableTypes containsObject:paymentMethod.paymentMethodType]) {
                [filteredSavedPaymentMethods addObject:paymentMethod];
                if ([self.defaultSource.stripeID isEqualToString:source.stripeID]) {
                    selectedPaymentMethod = paymentMethod;
                }
            }
        }
    }

    NSArray<id<STPPaymentMethod>> *savedPaymentMethods = [self.class stp_sortedPaymentMethodsFromArray:filteredSavedPaymentMethods
                                                                                       sortOrder:availableTypes];

    NSMutableOrderedSet<STPPaymentMethodType *> *availablePaymentTypes = availableTypes.mutableCopy;
    // If apple pay is misconfigured, remove it from the list
    if (!configuration.applePayEnabled) {
        [availablePaymentTypes removeObject:[STPPaymentMethodType applePay]];
    }

    return [[STPPaymentMethodTuple alloc] initWithSavedPaymentMethods:savedPaymentMethods
                                                availablePaymentTypes:availablePaymentTypes.array
                                                selectedPaymentMethod:selectedPaymentMethod];
}


+ (NSArray *)stp_sortedPaymentMethodsFromArray:(NSArray<id<STPPaymentMethod>> *)savedPaymentMethods
                                     sortOrder:(NSOrderedSet<STPPaymentMethodType *> *)orderedMethodTypes {
    return [savedPaymentMethods sortedArrayUsingComparator:^NSComparisonResult(id<STPPaymentMethod>  _Nonnull obj1, id<STPPaymentMethod>  _Nonnull obj2) {
        STPPaymentMethodType *obj1Type = obj1.paymentMethodType;
        STPPaymentMethodType *obj2Type = obj2.paymentMethodType;
        if ([obj1Type isEqual:obj2Type]) {
            return [obj1.paymentMethodLabel compare:obj2.paymentMethodLabel];
        }
        else {
            NSUInteger obj1Index = [orderedMethodTypes indexOfObject:obj1Type];
            NSUInteger obj2Index = [orderedMethodTypes indexOfObject:obj2Type];
            if (obj1Index == NSNotFound
                && obj2Index != NSNotFound) {
                return NSOrderedDescending;
            }
            else if (obj1Index != NSNotFound
                     && obj2Index == NSNotFound) {
                return NSOrderedAscending;
            }
            else if (obj1Index < obj2Index) {
                return NSOrderedAscending;
            }
            else {
                return NSOrderedDescending;
            }
        }

    }];
}

@end
