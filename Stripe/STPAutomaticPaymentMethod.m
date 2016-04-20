//
//  STPAutomaticPaymentMethod.m
//  Stripe
//
//  Created by Ben Guo on 4/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPAutomaticPaymentMethod.h"

@interface STPAutomaticPaymentMethod()

@property (nonatomic) STPPaymentMethodType supportedPaymentMethods;

@end

@implementation STPAutomaticPaymentMethod

- (instancetype)initWithSupportedPaymentMethods:(STPPaymentMethodType)supportedPaymentMethods {
    self = [super init];
    if (self) {
        _supportedPaymentMethods = supportedPaymentMethods;
    }
    return self;
}

- (UIImage *)image {
    // TODO: can't be displayed
    return nil;
}

- (NSString *)label {
    // TODO: can't be displayed
    return nil;
}

@end
