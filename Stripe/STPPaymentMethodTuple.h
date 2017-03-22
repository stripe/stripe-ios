//
//  STPPaymentMethodTuple.h
//  Stripe
//
//  Created by Jack Flintermann on 5/17/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPPaymentMethod.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPPaymentMethodTuple : NSObject

- (instancetype)initWithSavedPaymentMethods:(NSArray<id<STPPaymentMethod>> *)savedPaymentMethods
                      availablePaymentTypes:(NSArray<STPPaymentMethodType *> *)availablePaymentTypes
                      selectedPaymentMethod:(nullable id<STPPaymentMethod>)selectedPaymentMethod;

/**
 The users currently chosen payment method
 */
@property(nonatomic, nullable, readonly)id<STPPaymentMethod> selectedPaymentMethod;

/**
 New payment methods the user can choose from (eg New Card, new iDEAL payment, etc)
 */
@property(nonatomic, readonly)NSArray<STPPaymentMethodType *> *availablePaymentTypes;


/**
 Available previously known payment methods (eg saved cards, saved sepa debits)
 */
@property(nonatomic, readonly)NSArray<id<STPPaymentMethod>> *savedPaymentMethods;

@end

NS_ASSUME_NONNULL_END
