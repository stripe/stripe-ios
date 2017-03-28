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

- (instancetype)initWithSavedPaymentMethods:(nullable NSArray<id<STPPaymentMethod>> *)savedPaymentMethods
                      availablePaymentTypes:(nullable NSArray<STPPaymentMethodType *> *)availablePaymentTypes
                      selectedPaymentMethod:(nullable id<STPPaymentMethod>)selectedPaymentMethod;

/**
 The users currently chosen payment method.
 
 Must be in one of the other two arrays or will be nil'd.
 
 If there is only one payment method total, it will be automatically set as
 the selected one if it is allowed to be selected (but not if its a generic
 type that converts to source at selection like credit cards)
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

/**
 Unique set of all payment methods in tuple
 */
@property(nonatomic, readonly)NSSet<id<STPPaymentMethod>> *allPaymentMethods;

@end

NS_ASSUME_NONNULL_END
