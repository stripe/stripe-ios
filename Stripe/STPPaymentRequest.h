//
//  STPPaymentRequest.h
//  Stripe
//
//  Created by Ben Guo on 4/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol STPPaymentMethod;

@interface STPPaymentRequest : NSObject

@property (nonatomic, readonly) NSString *merchantName;
@property (nonatomic, readonly) NSString *appleMerchantIdentifier;
@property (nonatomic, readonly) id<STPPaymentMethod> paymentMethod;
@property (nonatomic, readonly) NSUInteger amount;
@property (nonatomic, readonly) NSString *currency;
@property (nonatomic, readonly) NSDecimalNumber *decimalAmount;

- (instancetype)initWithMerchantName:(NSString *)merchantName
             appleMerchantIdentifier:(NSString *)appleMerchantIdentifier
                             paymentMethod:(id<STPPaymentMethod>)paymentMethod
                               amount:(NSUInteger)amount
                             currency:(NSString *)currency;

@end
