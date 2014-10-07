//
//  STPCheckoutOptions.m
//  StripeExample
//
//  Created by Jack Flintermann on 10/6/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#import "STPCheckoutOptions.h"
#import "Stripe.h"

@implementation STPCheckoutOptions

- (instancetype)init {
    self = [super init];
    if (self) {
        _publishableKey = [Stripe defaultPublishableKey];
        _currency = @"USD";
        _validateZipCode = NO;
        _allowRememberMe = YES;
    }
    return self;
}

- (NSString *)stringifiedJavaScriptRepresentation {
    NSMutableDictionary *values = [NSMutableDictionary dictionary];
    if (self.publishableKey) {
        values[@"key"] = self.publishableKey;
    }
    if (self.logoImage) {
        values[@"image"] = [UIImagePNGRepresentation(self.logoImage) base64EncodedStringWithOptions:0];
    }
    if (self.companyName) {
        values[@"name"] = self.companyName;
    }
    if (self.productDescription) {
        values[@"description"] = self.productDescription;
    }
    if (self.purchaseAmount) {
        values[@"amount"] = @(self.purchaseAmount);
    }
    if (self.currency) {
        values[@"currency"] = [self.currency uppercaseString];
    }
    if (self.panelLabel) {
        values[@"panelLabel"] = self.panelLabel;
    }
    if (self.customerEmail) {
        values[@"email"] = self.customerEmail;
    }
    
    values[@"allowRememberMe"] = @(self.allowRememberMe);
    values[@"zipCode"] = @(self.validateZipCode);
    
    return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:values options:0 error:nil] encoding:NSUTF8StringEncoding];
}

@end
