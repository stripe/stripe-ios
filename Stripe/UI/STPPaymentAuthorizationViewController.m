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
#import "STPPaymentCardEntryViewController.h"
#import "STPPaymentSummaryViewController.h"
#import "STPSourceListViewController.h"
#import "UINavigationController+Stripe_Completion.h"
#import "STPSourceProvider.h"
#import "STPBasicSourceProvider.h"
#import "STPAPIClient.h"
#import "STPToken.h"
#import "STPPaymentResult.h"
#import "STPSourceListCoordinator.h"

@interface STPPaymentAuthorizationViewController()<STPPaymentSummaryViewControllerDelegate, STPCoordinatorDelegate>
@property(nonatomic, weak) UINavigationController *navigationController;
@property(nonatomic, readwrite, nonnull) STPPaymentRequest *paymentRequest;
@property(nonatomic, readwrite, nonnull) STPAPIClient *apiClient;
@property(nonatomic) id<STPSourceProvider> sourceProvider;
@property(nonatomic) NSMutableArray<STPBaseCoordinator *> *childCoordinators;
@end

@implementation STPPaymentAuthorizationViewController

- (nonnull instancetype)initWithPaymentRequest:(nonnull STPPaymentRequest *)paymentRequest
                                     apiClient:(nonnull STPAPIClient *)apiClient {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _apiClient = apiClient;
        _paymentRequest = paymentRequest;
        _sourceProvider = [STPBasicSourceProvider new];
        UINavigationController *navigationController = [[UINavigationController alloc] init];
        _navigationController = navigationController;
        [self addChildViewController:_navigationController];
        [_navigationController didMoveToParentViewController:self];
        _childCoordinators = [@[] mutableCopy];
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

#pragma mark - STPPaymentSummaryViewControllerDelegate

- (void)paymentSummaryViewControllerDidEditPaymentMethod:(__unused STPPaymentSummaryViewController *)viewController {
    STPSourceListCoordinator *coordinator = [[STPSourceListCoordinator alloc] initWithNavigationController:_navigationController apiClient:_apiClient sourceProvider:_sourceProvider delegate:self];
    [self.childCoordinators addObject:coordinator];
    [coordinator begin];
}

- (void)paymentSummaryViewControllerDidCancel:(__unused STPPaymentSummaryViewController *)summaryViewController {
    [self.delegate paymentAuthorizationViewControllerDidCancel:self];
}

- (void)paymentSummaryViewControllerDidPressBuy:(__unused STPPaymentSummaryViewController *)viewController {
    STPPaymentResult *result = [[STPPaymentResult alloc] initWithSource:self.sourceProvider.selectedSource customer:nil];
    [self.delegate paymentAuthorizationViewController:self didCreatePaymentResult:result];
}

#pragma mark - STPSourceListCoordinatorDelegate

- (void)coordinatorDidFinish:(STPBaseCoordinator *)coordinator {
    [self.childCoordinators removeObject:coordinator];
}

@end
