//
//  STPCheckoutViewController.m
//  StripeExample
//
//  Created by Jack Flintermann on 9/15/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#import "STPCheckoutViewController.h"
#import "STPCheckoutLegacyViewController.h"
#import "STPCheckoutModernViewController.h"

@implementation STPCheckoutViewController

+ (STPCheckoutViewController *)viewController {
    if ([STPCheckoutModernViewController class]) {
        return [STPCheckoutModernViewController new];
    }
    return [STPCheckoutLegacyViewController new];
}

- (NSString *)initialJavascript {
    return [NSString stringWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"checkoutBridge" withExtension:@"js"] encoding:NSUTF8StringEncoding error:nil];
}

@end
