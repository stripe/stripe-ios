//
//  STPPaymentOptionTuple.h
//  Stripe
//
//  Created by Jack Flintermann on 5/17/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPPaymentOption.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPPaymentOptionTuple : NSObject

+ (instancetype)tupleWithPaymentOptions:(NSArray<id<STPPaymentOption>> *)paymentOptions
                  selectedPaymentOption:(nullable id<STPPaymentOption>)selectedPaymentOption;

+ (instancetype)tupleWithPaymentOptions:(NSArray<id<STPPaymentOption>> *)paymentOptions
                  selectedPaymentOption:(nullable id<STPPaymentOption>)selectedPaymentOption
                      addApplePayOption:(BOOL)applePayEnabled;

@property (nonatomic, nullable, readonly) id<STPPaymentOption> selectedPaymentOption;
@property (nonatomic, readonly) NSArray<id<STPPaymentOption>> *paymentOptions;

@end

NS_ASSUME_NONNULL_END
