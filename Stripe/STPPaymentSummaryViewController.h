//
//  STPPaymentSummaryViewController.h
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class STPPaymentRequest, STPPaymentSummaryViewController;
@protocol STPPaymentAuthorizationViewControllerDelegate, STPSourceProvider;

@protocol STPPaymentSummaryViewControllerDelegate <NSObject>

- (void)paymentSummaryViewControllerDidEditPaymentMethod:(nonnull STPPaymentSummaryViewController *)summaryViewController;

@end

@interface STPPaymentSummaryViewController : UIViewController

- (nonnull instancetype)initWithPaymentRequest:(nonnull STPPaymentRequest *)paymentRequest;
@property(nonatomic, nonnull) STPPaymentRequest *paymentRequest;
@property(nonatomic, weak, nullable) id<STPPaymentAuthorizationViewControllerDelegate> delegate;
@property(nonatomic, weak, nullable) id<STPPaymentSummaryViewControllerDelegate> summaryDelegate;
@property(nonatomic, null_resettable) id<STPSourceProvider> sourceProvider;

@end
