//
//  STPPaymentSummaryViewController.m
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentSummaryViewController.h"
#import "STPPaymentAuthorizationViewController.h"
#import "STPPaymentRequest.h"
#import "UIViewController+Stripe_ParentViewController.h"
#import "NSArray+Stripe_BoundSafe.h"
#import "STPLineItem.h"
#import "STPLineItemCell.h"
#import "STPSource.h"
#import "STPBasicSourceProvider.h"
#import "STPPaymentMethodCell.h"
#import "STPPaymentResult.h"
#import "STPPaymentSummaryView.h"

@interface STPPaymentSummaryViewController()<STPPaymentSummaryViewDelegate>

@property(nonatomic, weak, nullable) id<STPPaymentSummaryViewControllerDelegate> delegate;
@property(nonatomic, readwrite)STPPaymentSummaryView *view;
@property(nonatomic, nonnull) STPPaymentRequest *paymentRequest;
@property(nonatomic, nonnull, readonly) id<STPSourceProvider> sourceProvider;

@end

@implementation STPPaymentSummaryViewController
@dynamic view;

- (nonnull instancetype)initWithPaymentRequest:(nonnull STPPaymentRequest *)paymentRequest
                                sourceProvider:(nonnull id<STPSourceProvider>) sourceProvider
                                      delegate:(nonnull id<STPPaymentSummaryViewControllerDelegate>)delegate {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _delegate = delegate;
        _paymentRequest = paymentRequest;
        _sourceProvider = sourceProvider;
    }
    return self;
}

- (void)loadView {
    self.view = [[STPPaymentSummaryView alloc] initWithPaymentRequest:self.paymentRequest
                                                       sourceProvider:self.sourceProvider
                                                             delegate:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = self.view.cancelButton;
    self.navigationItem.rightBarButtonItem = self.view.payButton;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.view reload];
}

- (void)paymentSummaryViewDidEditPaymentMethod:(nonnull STPPaymentSummaryView *)__unused summaryView {
    [self.delegate paymentSummaryViewControllerDidEditPaymentMethod:self];
}

- (void)paymentSummaryViewDidCancel:(nonnull STPPaymentSummaryView *)__unused summaryView {
    [self.delegate paymentSummaryViewControllerDidCancel:self];
}

- (void)paymentSummaryViewDidPressBuy:(nonnull STPPaymentSummaryView*)__unused summaryView {
    [self.delegate paymentSummaryViewControllerDidPressBuy:self];
}


@end
