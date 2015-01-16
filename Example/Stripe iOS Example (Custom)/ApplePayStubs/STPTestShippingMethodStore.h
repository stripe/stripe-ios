//
//  STPTestShippingMethodStore.h
//  StripeExample
//
//  Created by Jack Flintermann on 10/1/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//



#import <Foundation/Foundation.h>
#import "STPTestDataStore.h"

@interface STPTestShippingMethodStore : NSObject<STPTestDataStore>

- (instancetype)initWithShippingMethods:(NSArray *)shippingMethods;
- (void)setShippingMethods:(NSArray *)shippingMethods;

@end

