//
//  STPPaymentMethodTuple.h
//  Stripe
//
//  Created by Jack Flintermann on 5/17/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPPaymentOption.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPPaymentMethodTuple : NSObject

+ (instancetype)tupleWithPaymentMethods:(NSArray<id<STPPaymentOption>> *)paymentMethods
                  selectedPaymentMethod:(nullable id<STPPaymentOption>)selectedPaymentMethod;

+ (instancetype)tupleWithPaymentMethods:(NSArray<id<STPPaymentOption>> *)paymentMethods
                  selectedPaymentMethod:(nullable id<STPPaymentOption>)selectedPaymentMethod
                      addApplePayMethod:(BOOL)applePayEnabled;

@property (nonatomic, nullable, readonly) id<STPPaymentOption> selectedPaymentMethod;
@property (nonatomic, readonly) NSArray<id<STPPaymentOption>> *paymentMethods;

@end

NS_ASSUME_NONNULL_END
