//
//  TestImageLoader.m
//  ManualInstallationTest
//
//  Created by Ben Guo on 6/24/16.
//  Copyright © 2016 stripe. All rights reserved.
//

#import "TestImageLoader.h"
#import <Stripe/Stripe.h>

@implementation TestImageLoader

- (instancetype)init {
    self = [super init];
    if (self) {
        self.image = [STPPaymentCardTextField brandImageForCardBrand:STPCardBrandVisa];
    }
    return self;
}

@end
