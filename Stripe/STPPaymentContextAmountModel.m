//
//  STPPaymentContextAmountModel.m
//  Stripe
//
//  Created by Brian Dorfman on 8/16/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentContextAmountModel.h"

#import "NSDecimalNumber+Stripe_Currency.h"

@implementation STPPaymentContextAmountModel {
    NSInteger _paymentAmount;
    NSArray<PKPaymentSummaryItem *> *_paymentSummaryItems;
}

FAUXPAS_IGNORED_IN_CLASS(APIAvailability)

- (instancetype)initWithAmount:(NSInteger)paymentAmount {
    self = [super init];
    if (self) {
        _paymentAmount = paymentAmount;
        _paymentSummaryItems = nil;
    }
    return self;
}

- (instancetype)initWithPaymentSummaryItems:(NSArray<PKPaymentSummaryItem *> *)paymentSummaryItems {
    self = [super init];
    if (self) {
        _paymentAmount = 0;
        _paymentSummaryItems = paymentSummaryItems;
    }
    return self;
}

- (NSInteger)paymentAmountWithCurrency:(NSString *)paymentCurrency shippingMethod:(STPShippingMethod *)shippingMethod {
    NSInteger shippingAmount = (shippingMethod != nil) ? shippingMethod.amount : 0;
    if (_paymentSummaryItems == nil) {
        return _paymentAmount + shippingAmount;
    }
    else {
        PKPaymentSummaryItem *lastItem = _paymentSummaryItems.lastObject;
        return [lastItem.amount stp_amountWithCurrency:paymentCurrency] + shippingAmount;
    }
}

- (NSArray<PKPaymentSummaryItem *> *)paymentSummaryItemsWithCurrency:(NSString *)paymentCurrency
                                                         companyName:(NSString *)companyName
                                                      shippingMethod:(STPShippingMethod *)shippingMethod {
    PKPaymentSummaryItem *shippingItem = nil;
    if (shippingMethod != nil) {
        NSDecimalNumber *shippingAmount = [NSDecimalNumber stp_decimalNumberWithAmount:shippingMethod.amount
                                                                              currency:paymentCurrency];
        shippingItem = [PKPaymentSummaryItem summaryItemWithLabel:shippingMethod.label
                                                           amount:shippingAmount];
    }
    if (_paymentSummaryItems == nil) {
        NSDecimalNumber *total = [NSDecimalNumber stp_decimalNumberWithAmount:_paymentAmount + shippingMethod.amount
                                                                     currency:paymentCurrency];
        PKPaymentSummaryItem *totalItem = [PKPaymentSummaryItem summaryItemWithLabel:companyName
                                                                              amount:total];
        NSMutableArray *items = [@[totalItem] mutableCopy];
        if (shippingItem != nil) {
            [items insertObject:shippingItem atIndex:0];
        }
        return [items copy];
    }
    else {
        if ([_paymentSummaryItems count] > 0 && shippingItem != nil) {
            NSMutableArray *items = [_paymentSummaryItems mutableCopy];
            PKPaymentSummaryItem *origTotalItem = [items lastObject];
            NSDecimalNumber *newTotal = [origTotalItem.amount decimalNumberByAdding:shippingItem.amount];
            PKPaymentSummaryItem *totalItem = [PKPaymentSummaryItem summaryItemWithLabel:origTotalItem.label amount:newTotal];
            [items removeLastObject];
            return [[items arrayByAddingObjectsFromArray:@[shippingItem, totalItem]] copy];
        }
        else {
            return _paymentSummaryItems;
        }
    }
}

@end
