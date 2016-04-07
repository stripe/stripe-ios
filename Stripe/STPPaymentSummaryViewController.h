//
//  STPPaymentSummaryViewController.h
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STPBlocks.h"

@class STPPaymentRequest, STPPaymentSummaryViewController;
@protocol STPSourceProvider;

@protocol STPPaymentSummaryViewControllerDelegate <NSObject>

- (void)paymentSummaryViewControllerDidEditPaymentMethod:(nonnull STPPaymentSummaryViewController *)summaryViewController;
- (void)paymentSummaryViewControllerDidCancel:(nonnull STPPaymentSummaryViewController *)summaryViewController;
- (void)paymentSummaryViewController:(nonnull STPPaymentSummaryViewController *)summaryViewController didPressBuyCompletion:(nonnull STPErrorBlock)completion;

@end

@interface STPPaymentSummaryViewController : UIViewController

- (nonnull instancetype)initWithPaymentRequest:(nonnull STPPaymentRequest *)paymentRequest
                                sourceProvider:(nonnull id<STPSourceProvider>) sourceProvider
                                      delegate:(nonnull id<STPPaymentSummaryViewControllerDelegate>)delegate;


@end
