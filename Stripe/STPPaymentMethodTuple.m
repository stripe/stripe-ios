//
//  STPPaymentMethodTuple.m
//  Stripe
//
//  Created by Jack Flintermann on 5/17/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodTuple.h"

#import "STPPaymentMethodType.h"

@implementation STPPaymentMethodTuple

- (instancetype)initWithSavedPaymentMethods:(NSArray<id<STPPaymentMethod>> *)savedPaymentMethods
                      availablePaymentTypes:(NSArray<STPPaymentMethodType *> *)availablePaymentTypes
                      selectedPaymentMethod:(nullable id<STPPaymentMethod>)selectedPaymentMethod {
    if ((self = [super init])) {
        _savedPaymentMethods = savedPaymentMethods ? savedPaymentMethods.copy : @[];
        _availablePaymentTypes = availablePaymentTypes ? availablePaymentTypes.copy : @[];

        _allPaymentMethods = [NSSet setWithArray:[_savedPaymentMethods arrayByAddingObjectsFromArray:_availablePaymentTypes]];

        if (_allPaymentMethods.count == 1) {
            _selectedPaymentMethod = _allPaymentMethods.anyObject;
        }
        else if ([_allPaymentMethods containsObject:selectedPaymentMethod]) {
            _selectedPaymentMethod = selectedPaymentMethod;
        }
        else {
            _selectedPaymentMethod = nil;
        }
    }
    return self;
}

@end
