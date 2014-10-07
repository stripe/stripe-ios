//
//  STPCheckoutViewController.h
//  StripeExample
//
//  Created by Jack Flintermann on 9/15/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>

@class STPCheckoutOptions, STPCheckoutViewController, STPToken;

@protocol STPCheckoutViewControllerDelegate<NSObject>

- (void)checkoutController:(STPCheckoutViewController *)controller
        didFinishWithToken:(STPToken *)token;

@optional

- (void)checkoutController:(STPCheckoutViewController *)controller
       didFailWithError:(NSError *)error;
- (void)checkoutControllerDidCancel:(STPCheckoutViewController *)controller;

@end

@interface STPCheckoutViewController : UIViewController

- (instancetype)initWithOptions:(STPCheckoutOptions *)options;
@property(nonatomic)id<STPCheckoutViewControllerDelegate>delegate;

@end
