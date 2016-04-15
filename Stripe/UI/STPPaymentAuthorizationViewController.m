//
//  STPPaymentAuthorizationViewController.m
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <PassKit/PassKit.h>
#import "STPPaymentAuthorizationViewController.h"
#import "STPPaymentSummaryViewController.h"
#import "STPBackendAPIAdapter.h"
#import "STPBasicAPIAdapter.h"
#import "STPAPIClient.h"
#import "STPToken.h"
#import "STPPaymentResult.h"
#import "STPPaymentAuthorizationCoordinator.h"
#import "STPSourceListCoordinator.h"
#import "STPInitialPaymentDetailsCoordinator.h"

@interface STPPaymentAuthorizationViewController()<STPCoordinatorDelegate>
@property(nonatomic, weak) UINavigationController *navigationController;
@property(nonatomic, readwrite, nonnull) PKPaymentRequest *paymentRequest;
@property(nonatomic, readwrite, nonnull) STPAPIClient *apiClient;
@property(nonatomic) id<STPBackendAPIAdapter> apiAdapter;
@property(nonatomic) STPPaymentAuthorizationCoordinator *coordinator;
@end

@implementation STPPaymentAuthorizationViewController

- (nonnull instancetype)initWithPaymentRequest:(nonnull PKPaymentRequest *)paymentRequest
                                     apiClient:(nonnull STPAPIClient *)apiClient
                                apiAdapter:(nullable id<STPBackendAPIAdapter>)apiAdapter {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _apiClient = apiClient;
        _paymentRequest = paymentRequest;
        STPBasicAPIAdapter *adapter = [STPBasicAPIAdapter new];
        _apiAdapter = apiAdapter ?: adapter;
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
    self.coordinator = [[STPPaymentAuthorizationCoordinator alloc] initWithNavigationController:self.navigationController
                                                                                 paymentRequest:self.paymentRequest
                                                                                      apiClient:self.apiClient
                                                                                 apiAdapter:self.apiAdapter
                                                                                       delegate:self];
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
    STPPaymentResult *result = [[STPPaymentResult alloc] initWithSource:self.apiAdapter.selectedSource customer:nil shippingAddress:nil];
    [self.delegate paymentAuthorizationViewController:self didCreatePaymentResult:result completion:^(NSError * _Nullable error) {
        completion(error);
        if (error) {
            [self.delegate paymentAuthorizationViewController:self didFailWithError:error];
        } else {
            [self.delegate paymentAuthorizationViewControllerDidSucceed:self];
        }
    }];
}

@end
