//
//  STPCheckoutOptions.m
//  StripeExample
//
//  Created by Jack Flintermann on 10/6/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#import "STPCheckoutOptions.h"
#import "Stripe.h"
#import "STPColorUtils.h"

@implementation STPCheckoutOptions

- (NSString *)stringifiedJSONRepresentation {
    NSMutableDictionary *values = [NSMutableDictionary dictionary];
    if (self.publishableKey) {
        values[@"publishableKey"] = self.publishableKey;
    }
    if (self.logoURL) {
        values[@"logoURL"] = [self.logoURL absoluteString];
    }
    if (self.logoImage && !self.logoURL) {
        //        NSString *fileName = [[NSUUID UUID] UUIDString];
        //        NSURL *fileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
    }
    if (self.logoColor) {
        values[@"logoColor"] = [STPColorUtils hexCodeForColor:self.logoColor];
    }
    if (self.companyName) {
        values[@"companyName"] = self.companyName;
    }
    if (self.purchaseDescription) {
        values[@"purchaseDescription"] = self.purchaseDescription;
    }
    if (self.purchaseLabel) {
        values[@"purchaseLabel"] = self.purchaseLabel;
    }
    if (self.purchaseCurrency) {
        values[@"purchaseCurrency"] = [self.purchaseCurrency uppercaseString];
    }
    if (self.purchaseAmount) {
        values[@"purchaseAmount"] = self.purchaseAmount;
    }
    if (self.customerEmail) {
        values[@"customerEmail"] = self.customerEmail;
    }
    if (self.enableRememberMe) {
        values[@"enableRememberMe"] = self.enableRememberMe;
    }
    if (self.enablePostalCode) {
        values[@"enablePostalCode"] = self.enablePostalCode;
    }

    return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:values options:0 error:nil] encoding:NSUTF8StringEncoding];
}

@end
