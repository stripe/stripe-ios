//
//  STPPaymentAuthorizationViewController.m
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentAuthorizationViewController.h"
#import "STPPaymentRequest.h"
#import "STPPaymentSummaryViewController.h"
#import "STPSourceListViewController.h"

@interface STPPaymentAuthorizationViewController()<STPPaymentSummaryViewControllerDelegate>
@property(nonatomic, weak) UINavigationController *navigationController;
@property(nonatomic, weak) STPPaymentSummaryViewController *summaryViewController;
@end

@implementation STPPaymentAuthorizationViewController

- (instancetype)initWithPaymentRequest:(STPPaymentRequest *)paymentRequest {
    STPPaymentSummaryViewController *summaryViewController = [[STPPaymentSummaryViewController alloc] initWithPaymentRequest:paymentRequest];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:summaryViewController];
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _navigationController = navigationController;
        summaryViewController.summaryDelegate = self;
        _summaryViewController = summaryViewController;
        [self addChildViewController:_navigationController];
        [_navigationController didMoveToParentViewController:self];
    }
    return self;
}

- (void)setDelegate:(id<STPPaymentAuthorizationViewControllerDelegate>)delegate {
    self.summaryViewController.delegate = delegate;
}

- (id<STPPaymentAuthorizationViewControllerDelegate>)delegate {
    return self.summaryViewController.delegate;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.navigationController.view];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.navigationController.view.frame = self.view.bounds;
}

- (void)paymentSummaryViewControllerDidEditPaymentMethod:(__unused STPPaymentSummaryViewController *)summaryViewController {
    STPSourceListViewController *destination = [[STPSourceListViewController alloc] initWithSourceProvider:self.sourceProvider];
    [self.navigationController pushViewController:destination animated:YES];
}

- (STPPaymentRequest *)paymentRequest {
    return self.summaryViewController.paymentRequest;
}

- (void)setSourceProvider:(id<STPSourceProvider>)sourceProvider {
    self.summaryViewController.sourceProvider = sourceProvider;
}

- (id<STPSourceProvider>)sourceProvider {
    return self.summaryViewController.sourceProvider;
}

@end
