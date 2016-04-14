//
//  STPPaymentAuthorizationViewController.h
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STPBlocks.h"

@class STPAPIClient, STPPaymentResult, STPPaymentAuthorizationViewController;

@protocol STPSourceProvider;

@protocol STPPaymentAuthorizationViewControllerDelegate <NSObject>

- (void)paymentAuthorizationViewControllerDidCancel:(nonnull STPPaymentAuthorizationViewController *)paymentAuthorizationViewController;
- (void)paymentAuthorizationViewController:(nonnull STPPaymentAuthorizationViewController *)paymentAuthorizationViewController didFailWithError:(nonnull NSError *)error;
- (void)paymentAuthorizationViewController:(nonnull STPPaymentAuthorizationViewController *)paymentAuthorizationViewController didCreatePaymentResult:(nonnull STPPaymentResult *)result completion:(nonnull STPErrorBlock)completion;
- (void)paymentAuthorizationViewControllerDidSucceed:(nonnull STPPaymentAuthorizationViewController *)paymentAuthorizationViewController;

@end

@interface STPPaymentAuthorizationViewController : UIViewController

- (nonnull instancetype)initWithPaymentRequest:(nonnull PKPaymentRequest *)paymentRequest
                                     apiClient:(nonnull STPAPIClient *)apiClient
                                sourceProvider:(nullable id<STPSourceProvider>)sourceProvider;
;
@property(nonatomic, readonly, nonnull) PKPaymentRequest *paymentRequest;
@property(nonatomic, weak, nullable) id<STPPaymentAuthorizationViewControllerDelegate> delegate;

@end
