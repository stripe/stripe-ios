//
//  STPPaymentSummaryView.h
//  Stripe
//
//  Created by Ben Guo on 3/24/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class STPPaymentSummaryView, STPPaymentRequest;
@protocol STPSourceProvider;

@protocol STPPaymentSummaryViewDelegate <NSObject>

- (void)paymentSummaryViewDidEditPaymentMethod:(nonnull STPPaymentSummaryView *)summaryView;
- (void)paymentSummaryViewDidCancel:(nonnull STPPaymentSummaryView *)summaryView;
- (void)paymentSummaryViewDidPressBuy:(nonnull STPPaymentSummaryView*)summaryView;

@end

@interface STPPaymentSummaryView : UIView

@property(nonatomic, nonnull) UIBarButtonItem *cancelButton;
@property(nonatomic, nonnull) UIBarButtonItem *payButton;

- (nonnull instancetype)initWithPaymentRequest:(nonnull STPPaymentRequest *)paymentRequest
                                sourceProvider:(nonnull id<STPSourceProvider>) sourceProvider
                                      delegate:(nonnull id<STPPaymentSummaryViewDelegate>)delegate;
- (void)reload;

@end
