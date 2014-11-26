//
//  STPCheckoutViewController.h
//  StripeExample
//
//  Created by Jack Flintermann on 9/15/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>

@class STPCheckoutOptions, STPCheckoutViewController, STPToken;

typedef NS_ENUM(NSInteger, STPBackendChargeResult) {
    STPBackendChargeResultSuccess, // Merchant auth'd (or expects to auth) the transaction successfully.
    STPBackendChargeResultFailure, // Merchant failed to auth the transaction.
};

typedef void (^STPTokenSubmissionHandler)(STPBackendChargeResult status, NSError *error);

@protocol STPCheckoutViewControllerDelegate<NSObject>

- (void)checkoutControllerDidCancel:(STPCheckoutViewController *)controller;
- (void)checkoutControllerDidFinish:(STPCheckoutViewController *)controller;
- (void)checkoutController:(STPCheckoutViewController *)controller didCreateToken:(STPToken *)token completion:(STPPaymentCompletionHandler)completion;
- (void)checkoutController:(STPCheckoutViewController *)controller didFailWithError:(NSError *)error;

@end

@interface STPCheckoutViewController : UIViewController

- (instancetype)initWithOptions:(STPCheckoutOptions *)options;
@property (nonatomic, weak) id<STPCheckoutViewControllerDelegate> delegate;

@end
