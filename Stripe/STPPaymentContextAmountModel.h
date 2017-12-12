//
//  STPPaymentContextAmountModel.h
//  Stripe
//
//  Created by Brian Dorfman on 8/16/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PassKit/PassKit.h>

/**
 Internal model for STPPaymentContext's `paymentAmount` and 
 `paymentSummaryItems` properties.
 */
@interface STPPaymentContextAmountModel : NSObject

- (instancetype)initWithAmount:(NSInteger)paymentAmount;
- (instancetype)initWithPaymentSummaryItems:(NSArray<PKPaymentSummaryItem *> *)paymentSummaryItems;

- (NSInteger)paymentAmountWithCurrency:(NSString *)currency
                        shippingMethod:(PKShippingMethod *)shippingMethod;
- (NSArray<PKPaymentSummaryItem *> *)paymentSummaryItemsWithCurrency:(NSString *)currency
                                                         companyName:(NSString *)companyName
                                                      shippingMethod:(PKShippingMethod *)shippingMethod;

@end
