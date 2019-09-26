//
//  STPPaymentOptionTuple.h
//  Stripe
//
//  Created by Jack Flintermann on 5/17/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPPaymentOption.h"

@class STPPaymentMethod, STPPaymentConfiguration;

NS_ASSUME_NONNULL_BEGIN

@interface STPPaymentOptionTuple : NSObject

+ (instancetype)tupleWithPaymentOptions:(NSArray<id<STPPaymentOption>> *)paymentOptions
                  selectedPaymentOption:(nullable id<STPPaymentOption>)selectedPaymentOption;

+ (instancetype)tupleWithPaymentOptions:(NSArray<id<STPPaymentOption>> *)paymentOptions
                  selectedPaymentOption:(nullable id<STPPaymentOption>)selectedPaymentOption
                      addApplePayOption:(BOOL)applePayEnabled
                      additionalOptions:(STPPaymentOptionType)additionalPaymentOptions;

/**
 Returns a tuple for the given array of STPPaymentMethod, filtered to only include the
 the types supported by STPPaymentContext/STPPaymentOptionsViewController and adding
 Apple Pay as a method if appropriate.
 
 @return A new tuple ready to be used by the SDK's UI elements
 */
+ (instancetype)tupleFilteredForUIWithPaymentMethods:(NSArray<STPPaymentMethod *> *)paymentMethods
                               selectedPaymentMethod:(nullable NSString *)selectedPaymentMethod
                                       configuration:(STPPaymentConfiguration *)configuration;

@property (nonatomic, nullable, readonly) id<STPPaymentOption> selectedPaymentOption;
@property (nonatomic, readonly) NSArray<id<STPPaymentOption>> *paymentOptions;

@end

NS_ASSUME_NONNULL_END
