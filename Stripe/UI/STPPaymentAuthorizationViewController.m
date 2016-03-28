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
#import "STPSourceProvider.h"
#import "STPBasicSourceProvider.h"
#import "STPAPIClient.h"
#import "STPToken.h"
#import "STPPaymentResult.h"
#import "STPPaymentAuthorizationCoordinator.h"
#import "STPSourceListCoordinator.h"
#import "STPInitialPaymentDetailsCoordinator.h"

@interface STPPaymentAuthorizationViewController()<STPCoordinatorDelegate>
@property(nonatomic, weak) UINavigationController *navigationController;
@property(nonatomic, readwrite, nonnull) STPPaymentRequest *paymentRequest;
@property(nonatomic, readwrite, nonnull) STPAPIClient *apiClient;
@property(nonatomic) id<STPSourceProvider> sourceProvider;
@property(nonatomic) STPPaymentAuthorizationCoordinator *coordinator;
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
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.navigationController.view];
    self.coordinator = [[STPPaymentAuthorizationCoordinator alloc] initWithNavigationController:self.navigationController paymentRequest:self.paymentRequest apiClient:self.apiClient sourceProvider:self.sourceProvider delegate:self];
    [self.coordinator begin];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.navigationController.view.frame = self.view.bounds;
}

#pragma mark - STPPaymentAuthorizationCoordinatorDelegate

- (void)coordinatorDidCancel:(__unused STPBaseCoordinator *)coordinator {
    [self.delegate paymentAuthorizationViewControllerDidCancel:self];
}

- (void)coordinator:(__unused STPBaseCoordinator *)coordinator willFinishWithCompletion:(STPErrorBlock)completion {
    STPPaymentResult *result = [[STPPaymentResult alloc] initWithSource:self.sourceProvider.selectedSource customer:nil];
    [self.delegate paymentAuthorizationViewController:self didCreatePaymentResult:result completion:completion];
}

@end
