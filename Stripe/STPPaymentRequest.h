//
//  STPPaymentRequest.h
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PassKit/PassKit.h>

@interface STPPaymentRequest : NSObject

@property(nonatomic, nonnull) NSString *merchantName;
@property(nonatomic, nullable) NSString *appleMerchantId;
@property(nonatomic, nonnull) NSArray<PKPaymentSummaryItem *> *lineItems;

- (nullable PKPaymentRequest *)asPKPayment;

@end
