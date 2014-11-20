//
//  STPCheckoutViewController.h
//  StripeExample
//
//  Created by Jack Flintermann on 9/15/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>

@class STPCheckoutOptions, STPCheckoutViewController, STPToken;

typedef NS_ENUM(NSInteger, STPPaymentAuthorizationStatus) {
    STPPaymentAuthorizationStatusSuccess, // Merchant auth'd (or expects to auth) the transaction successfully.
    STPPaymentAuthorizationStatusFailure, // Merchant failed to auth the transaction.
};

typedef void (^STPPaymentCompletionHandler)(STPPaymentAuthorizationStatus status);

@protocol STPCheckoutViewControllerDelegate<NSObject>

- (void)checkoutController:(STPCheckoutViewController *)controller didCreateToken:(STPToken *)token completion:(STPPaymentCompletionHandler)completion;
- (void)checkoutControllerDidFinish:(STPCheckoutViewController *)controller;
- (void)checkoutController:(STPCheckoutViewController *)controller didFailWithError:(NSError *)error;
- (void)checkoutControllerDidCancel:(STPCheckoutViewController *)controller;

@end

@interface STPCheckoutViewController : UIViewController

- (instancetype)initWithOptions:(STPCheckoutOptions *)options;
@property (nonatomic, weak) id<STPCheckoutViewControllerDelegate> delegate;

@end
