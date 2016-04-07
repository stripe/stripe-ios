//
//  STPPaymentRequest.h
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STPLineItem;

@interface STPPaymentRequest : NSObject

- (instancetype)initWithAppleMerchantId:(NSString *)appleMerchantId;

@property(nonatomic, readonly) NSString *appleMerchantId;
@property(nonatomic) NSArray<STPLineItem *> *lineItems;

@end
