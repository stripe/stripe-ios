//
//  STPApplePayPaymentOption.m
//  Stripe
//
//  Created by Ben Guo on 4/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPApplePayPaymentOption.h"

#import "STPImageLibrary.h"
#import "STPImageLibrary+Private.h"
#import "STPLocalizationUtils.h"

@implementation STPApplePayPaymentOption

#pragma mark - STPPaymentOption

- (UIImage *)image {
    return [STPImageLibrary applePayCardImage];
}

- (UIImage *)templateImage {
    // No template for Apple Pay
    return [STPImageLibrary applePayCardImage];
}

- (NSString *)label {
    return STPLocalizedString(@"Apple Pay", @"Text for Apple Pay payment method");
}

#pragma mark - Equality

- (BOOL)isEqual:(id)object {
    return [object isKindOfClass:[STPApplePayPaymentOption class]];
}

- (NSUInteger)hash {
    return [NSStringFromClass(self.class) hash];
}

- (BOOL)isReusable {
    return YES;
}

@end
