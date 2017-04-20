//
//  STPPaymentMethodTuple.m
//  Stripe
//
//  Created by Jack Flintermann on 5/17/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodTuple.h"

#import "STPPaymentMethodType+Private.h"

@implementation STPPaymentMethodTuple

- (instancetype)initWithSavedPaymentMethods:(nullable NSArray<id<STPPaymentMethod>> *)savedPaymentMethods
                      availablePaymentTypes:(nullable NSArray<STPPaymentMethodType *> *)availablePaymentTypes
                      selectedPaymentMethod:(nullable id<STPPaymentMethod>)selectedPaymentMethod {
    if ((self = [super init])) {
        NSMutableArray *mSavedPaymentMethods = savedPaymentMethods ? [savedPaymentMethods mutableCopy] : [NSMutableArray new];
        NSMutableArray *mAvailablePaymentTypes = availablePaymentTypes ? [availablePaymentTypes mutableCopy] : [NSMutableArray new];
        STPPaymentMethodType *applePay = [STPPaymentMethodType applePay];
        // Display Apple Pay with saved payment methods
        if ([mAvailablePaymentTypes containsObject:applePay]) {
            [mAvailablePaymentTypes removeObject:applePay];
            if (![mSavedPaymentMethods containsObject:applePay]) {
                [mSavedPaymentMethods insertObject:applePay atIndex:0];
            }
        }
        // Always show Apple Pay on top
        if ([mSavedPaymentMethods containsObject:applePay] && ([mSavedPaymentMethods indexOfObject:applePay] != 0)) {
            [mSavedPaymentMethods removeObject:applePay];
            [mSavedPaymentMethods insertObject:applePay atIndex:0];
        }

        _savedPaymentMethods = mSavedPaymentMethods;
        _availablePaymentTypes = mAvailablePaymentTypes;

        _allPaymentMethods = [NSSet setWithArray:[_savedPaymentMethods arrayByAddingObjectsFromArray:_availablePaymentTypes]];

        if ([_allPaymentMethods containsObject:selectedPaymentMethod]) {
            _selectedPaymentMethod = selectedPaymentMethod;
        }
        else if (_allPaymentMethods.count == 1) {
            _selectedPaymentMethod = _allPaymentMethods.anyObject;
        }
        else {
            _selectedPaymentMethod = nil;
        }

        if ([_selectedPaymentMethod isKindOfClass:[STPPaymentMethodType class]]) {
            STPPaymentMethodType *paymentType = (STPPaymentMethodType *)_selectedPaymentMethod;
            if (paymentType.convertsToSourceAtSelection) {
                // Can't already be selected
                _selectedPaymentMethod = nil;
            }
        }
        // Select Apple Pay if it's available and no other method is selected
        if (_selectedPaymentMethod == nil && [_allPaymentMethods containsObject:applePay]) {
            _selectedPaymentMethod = applePay;
        }
    }
    return self;
}

@end
