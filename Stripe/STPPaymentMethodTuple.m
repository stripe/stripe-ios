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
        _savedPaymentMethods = savedPaymentMethods ? savedPaymentMethods.copy : @[];
        _availablePaymentTypes = availablePaymentTypes ? availablePaymentTypes.copy : @[];

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
    }
    return self;
}

@end
