//
//  STPPaymentAuthorizationViewController.h
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class STPPaymentRequest, STPAPIClient, STPPaymentResult, STPPaymentAuthorizationViewController;

@protocol STPSourceProvider;

@protocol STPPaymentAuthorizationViewControllerDelegate <NSObject>

- (void)paymentAuthorizationViewControllerDidCancel:(nonnull STPPaymentAuthorizationViewController *)paymentAuthorizationViewController;
- (void)paymentAuthorizationViewController:(nonnull STPPaymentAuthorizationViewController *)paymentAuthorizationViewController didFailWithError:(nonnull NSError *)error;
- (void)paymentAuthorizationViewController:(nonnull STPPaymentAuthorizationViewController *)paymentAuthorizationViewController didCreateCheckoutResult:(nonnull STPPaymentResult *)result;

@end

@interface STPPaymentAuthorizationViewController : UIViewController

- (nonnull instancetype)initWithPaymentRequest:(nonnull STPPaymentRequest *)paymentRequest apiClient:(nonnull STPAPIClient *)apiClient;
@property(nonatomic, readonly, nonnull) STPPaymentRequest *paymentRequest;
@property(nonatomic, weak, nullable) id<STPPaymentAuthorizationViewControllerDelegate> delegate;

@end
