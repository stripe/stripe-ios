//
//  STPPaymentAuthorizationCoordinator.m
//  Stripe
//
//  Created by Jack Flintermann on 3/28/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <PassKit/PassKit.h>
#import "STPPaymentAuthorizationCoordinator.h"
#import "STPInitialPaymentDetailsCoordinator.h"
#import "STPPaymentSummaryViewController.h"
#import "STPSourceListCoordinator.h"
#import "STPBlocks.h"
#import "UINavigationController+Stripe_Completion.h"
#import "STPAddress.h"

@interface STPPaymentAuthorizationCoordinator()<STPCoordinatorDelegate, STPPaymentSummaryViewControllerDelegate>
@property(nonatomic)PKPaymentRequest *paymentRequest;
@property(nonatomic)STPAddress *shippingAddress;
@property(nonatomic)PKAddressField requiredAddressFields;
@end

@implementation STPPaymentAuthorizationCoordinator

- (instancetype)initWithNavigationController:(UINavigationController *)navigationController
                              paymentRequest:(PKPaymentRequest *)paymentRequest
                             shippingAddress:(STPAddress *)shippingAddress
                       requiredAddressFields:(PKAddressField)requiredAddressFields
                                   apiClient:(STPAPIClient *)apiClient
                              sourceProvider:(id<STPSourceProvider>)sourceProvider
                                    delegate:(id<STPCoordinatorDelegate>)delegate {
    self = [super init];
    if (self) {
        _navigationController = navigationController;
        _paymentRequest = paymentRequest;
        _apiClient = apiClient;
        _sourceProvider = sourceProvider;
        _shippingAddress = shippingAddress;
        _requiredAddressFields = requiredAddressFields;
        _delegate = delegate;
    }
    return self;
}

- (void)begin {
    [super begin];
    STPInitialPaymentDetailsCoordinator *coordinator = [[STPInitialPaymentDetailsCoordinator alloc] initWithNavigationController:self.navigationController paymentRequest:self.paymentRequest apiClient:self.apiClient sourceProvider:self.sourceProvider delegate:self];
    [self addChildCoordinator:coordinator];
    [coordinator begin];
}

- (void)coordinatorDidCancel:(STPBaseCoordinator *)coordinator {
    if ([coordinator isKindOfClass:[STPInitialPaymentDetailsCoordinator class]]) {
        [self.delegate coordinatorDidCancel:self];
    }
}

- (void)coordinator:(__unused STPBaseCoordinator *)coordinator willFinishWithCompletion:(STPErrorBlock)completion {
    if ([coordinator isKindOfClass:[STPInitialPaymentDetailsCoordinator class]]) {
        STPPaymentSummaryViewController *summaryViewController = [[STPPaymentSummaryViewController alloc] initWithPaymentRequest:self.paymentRequest sourceProvider:self.sourceProvider delegate:self];
        [self.navigationController stp_pushViewController:summaryViewController animated:YES completion:^{
            if (completion) {
                completion(nil);
            }
        }];
    }
}

#pragma mark - STPPaymentSummaryViewControllerDelegate

- (void)paymentSummaryViewControllerDidEditPaymentMethod:(__unused STPPaymentSummaryViewController *)viewController {
    STPSourceListCoordinator *coordinator = [[STPSourceListCoordinator alloc] initWithNavigationController:self.navigationController apiClient:self.apiClient sourceProvider:self.sourceProvider delegate:self];
    [self addChildCoordinator:coordinator];
    [coordinator begin];
}

- (void)paymentSummaryViewControllerDidCancel:(__unused STPPaymentSummaryViewController *)summaryViewController {
    [self.delegate coordinatorDidCancel:self];
}

- (void)paymentSummaryViewController:(__unused STPPaymentSummaryViewController *)summaryViewController didPressBuyCompletion:(STPErrorBlock)completion {
    [self.delegate coordinator:self willFinishWithCompletion:completion];
}

@end
