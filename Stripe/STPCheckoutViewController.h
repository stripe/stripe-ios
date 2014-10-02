//
//  STPCheckoutViewController.h
//  StripeExample
//
//  Created by Jack Flintermann on 9/15/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface STPCheckoutViewController : UIViewController

+ (STPCheckoutViewController *)viewController;
- (NSString *)initialJavascript;

@end
