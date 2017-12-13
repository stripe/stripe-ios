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

- (NSInteger)paymentAmountWithCurrency:(NSString *)currency shippingMethod:(PKShippingMethod *)shippingMethod {
    NSInteger shippingAmount = (shippingMethod != nil) ? [shippingMethod.amount stp_amountWithCurrency:currency] : 0;
    if (_paymentSummaryItems == nil) {
        return _paymentAmount + shippingAmount;
    }
    else {
        PKPaymentSummaryItem *lastItem = _paymentSummaryItems.lastObject;
        return [lastItem.amount stp_amountWithCurrency:currency] + shippingAmount;
    }
}

- (NSArray<PKPaymentSummaryItem *> *)paymentSummaryItemsWithCurrency:(NSString *)currency
                                                         companyName:(NSString *)companyName
                                                      shippingMethod:(PKShippingMethod *)shippingMethod {
    PKPaymentSummaryItem *shippingItem = nil;
    if (shippingMethod != nil) {
        shippingItem = [PKPaymentSummaryItem summaryItemWithLabel:shippingMethod.label
                                                           amount:shippingMethod.amount];
    }
    if (_paymentSummaryItems == nil) {
        NSInteger shippingAmount = [shippingMethod.amount stp_amountWithCurrency:currency];
        NSDecimalNumber *total = [NSDecimalNumber stp_decimalNumberWithAmount:_paymentAmount + shippingAmount
                                                                     currency:currency];
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
