//
//  STPPaymentAuthorizationViewController.m
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentAuthorizationViewController.h"
#import "STPPaymentRequest.h"
#import "STPEmailEntryViewController.h"
#import "STPPaymentSummaryViewController.h"
#import "STPSourceListViewController.h"
#import "UINavigationController+Stripe_Completion.h"
#import "STPBasicSourceProvider.h"

@interface STPPaymentAuthorizationViewController()<STPPaymentSummaryViewControllerDelegate, STPEmailEntryViewControllerDelegate>
@property(nonatomic, weak) UINavigationController *navigationController;
@property(nonatomic, readwrite, nonnull) STPPaymentRequest *paymentRequest;
@property(nonatomic) id<STPSourceProvider> sourceProvider;
@end

@implementation STPPaymentAuthorizationViewController

- (instancetype)initWithPaymentRequest:(__unused STPPaymentRequest *)paymentRequest {
    STPEmailEntryViewController *emailViewController = [STPEmailEntryViewController new];

    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:emailViewController];
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _sourceProvider = [STPBasicSourceProvider new];
        _navigationController = navigationController;
//        summaryViewController.summaryDelegate = self;
//        _summaryViewController = summaryViewController;
        emailViewController.delegate = self;
        [self addChildViewController:_navigationController];
        [_navigationController didMoveToParentViewController:self];
    }
    return self;
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

- (void)paymentEmailViewController:(__unused STPEmailEntryViewController *)emailViewController didEnterEmailAddress:(__unused NSString *)emailAddress completion:(STPErrorBlock)completion {
    STPPaymentSummaryViewController *summaryViewController = [[STPPaymentSummaryViewController alloc] initWithPaymentRequest:self.paymentRequest sourceProvider:self.sourceProvider];
    [self.navigationController stp_pushViewController:summaryViewController animated:YES completion:^{
        completion(nil);
    }];
}

@end
