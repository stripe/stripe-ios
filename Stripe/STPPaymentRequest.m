//
//  STPPaymentRequest.m
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentRequest.h"
#import "Stripe+ApplePay.h"

@interface STPPaymentRequest()
@end

@implementation STPPaymentRequest

- (instancetype)init {
    self = [super init];
    if (self) {
        NSString *bundleNameKey = (NSString *)kCFBundleNameKey;
        _merchantName = [NSBundle mainBundle].infoDictionary[bundleNameKey];        
        _lineItems = @[];
    }
    return self;
}

- (PKPaymentRequest *)asPKPayment {
    if (![PKPayment class]) {
        return nil;
    }
    if (self.appleMerchantId == nil) {
        return nil;
    }
    PKPaymentRequest *paymentRequest = [Stripe paymentRequestWithMerchantIdentifier:self.appleMerchantId];
    NSMutableArray *paymentSummaryItems = [@[] mutableCopy];
    NSDecimalNumber *totalAmount = [NSDecimalNumber decimalNumberWithString:@"0"];
    for (STPLineItem *lineItem in self.lineItems) {
        PKPaymentSummaryItem *summaryItem = [PKPaymentSummaryItem summaryItemWithLabel:lineItem.label amount:lineItem.amount];
        [paymentSummaryItems addObject:summaryItem];
        totalAmount = [totalAmount decimalNumberByAdding:lineItem.amount];
    }
    PKPaymentSummaryItem *totalItem = [PKPaymentSummaryItem summaryItemWithLabel:self.merchantName amount:totalAmount];
    [paymentSummaryItems addObject:totalItem];
    if ([totalItem.amount compare:@0] != NSOrderedDescending) {
        NSLog(@"Caution: your lineItems array must have a total count greater than zero to use Apple Pay.");
        return nil;
    }
    paymentRequest.paymentSummaryItems = paymentSummaryItems;
    
    return paymentRequest;
}

@end
