//
//  STPTestShippingMethodStore.m
//  StripeExample
//
//  Created by Jack Flintermann on 10/1/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000

#import "STPTestShippingMethodStore.h"
#import <PassKit/PassKit.h>

@interface STPTestShippingMethodStore()
@property(nonatomic)NSArray *shippingMethods;
@end

@implementation STPTestShippingMethodStore
@synthesize selectedItem;

- (instancetype)initWithShippingMethods:(NSArray *)shippingMethods {
    self = [super init];
    if (self) {
        [self setShippingMethods:shippingMethods];
    }
    return self;
}

- (NSArray *)allItems {
    return self.shippingMethods;
}

- (NSArray *)descriptionsForItem:(id)item {
    PKShippingMethod *method = (PKShippingMethod *)item;
    return @[method.label, method.amount.stringValue];
}

- (void)setShippingMethods:(NSArray *)shippingMethods {
    _shippingMethods = shippingMethods;
    for (PKShippingMethod *method in shippingMethods) {
        if ([self.selectedItem isEqual:method]) {
            self.selectedItem = method;
            return;
        }
    }
    self.selectedItem = shippingMethods[0];
}

@end

#endif