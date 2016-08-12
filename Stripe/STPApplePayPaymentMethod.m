//
//  STPApplePayPaymentMethod.m
//  Stripe
//
//  Created by Ben Guo on 4/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPApplePayPaymentMethod.h"
#import "STPImageLibrary.h"
#import "STPLocalizationUtils.h"

@implementation STPApplePayPaymentMethod

- (UIImage *)image {
    return [STPImageLibrary applePayCardImage];
}

- (NSString *)label {
    return STPLocalizedString(@"Apple Pay", nil);
}

- (BOOL)isEqual:(id)object {
    return [object isKindOfClass:[STPApplePayPaymentMethod class]];
}

- (NSUInteger)hash {
    return [NSStringFromClass(self.class) hash];
}

@end
