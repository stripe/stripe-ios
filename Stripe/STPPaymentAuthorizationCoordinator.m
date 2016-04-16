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
#import "STPShippingEntryViewController.h"
#import "STPBlocks.h"
#import "UINavigationController+Stripe_Completion.h"
#import "STPBackendAPIAdapter.h"
#import "STPAddress.h"

@interface STPPaymentAuthorizationCoordinator()<STPCoordinatorDelegate, STPPaymentSummaryViewControllerDelegate, STPShippingEntryViewControllerDelegate>

@property(nonatomic)PKPaymentRequest *paymentRequest;
@property(nonatomic, weak, readonly)id<STPCoordinatorDelegate>delegate;
@property(nonatomic, readonly)UINavigationController *navigationController;
@property(nonatomic, readonly)STPAPIClient *apiClient;
@property(nonatomic, readonly)id<STPBackendAPIAdapter> apiAdapter;

@end

@implementation STPPaymentAuthorizationCoordinator

- (instancetype)initWithNavigationController:(UINavigationController *)navigationController
                              paymentRequest:(PKPaymentRequest *)paymentRequest
                                   apiClient:(STPAPIClient *)apiClient
                                  apiAdapter:(id<STPBackendAPIAdapter>)apiAdapter
                                    delegate:(id<STPCoordinatorDelegate>)delegate {
    self = [super init];
    if (self) {
        _navigationController = navigationController;
        _paymentRequest = paymentRequest;
        _apiClient = apiClient;
        _apiAdapter = apiAdapter;
        _delegate = delegate;
    }
    return self;
}

- (void)begin {
    [super begin];
    STPInitialPaymentDetailsCoordinator *coordinator = [[STPInitialPaymentDetailsCoordinator alloc] initWithNavigationController:self.navigationController paymentRequest:self.paymentRequest apiClient:self.apiClient apiAdapter:self.apiAdapter delegate:self];
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
        STPPaymentSummaryViewController *summaryViewController = [[STPPaymentSummaryViewController alloc] initWithPaymentRequest:self.paymentRequest apiAdapter:self.apiAdapter delegate:self];
        [self.navigationController stp_pushViewController:summaryViewController animated:YES completion:^{
            if (completion) {
                completion(nil);
            }
        }];
    }
}

#pragma mark - STPPaymentSummaryViewControllerDelegate

- (void)paymentSummaryViewControllerDidEditPaymentMethod:(__unused STPPaymentSummaryViewController *)viewController {
    STPSourceListCoordinator *coordinator = [[STPSourceListCoordinator alloc] initWithNavigationController:self.navigationController apiClient:self.apiClient apiAdapter:self.apiAdapter delegate:self];
    [self addChildCoordinator:coordinator];
    [coordinator begin];
}

- (void)paymentSummaryViewControllerDidEditShipping:(__unused STPPaymentSummaryViewController *)summaryViewController {
    STPAddress *shippingAddress = nil;
    if ([self.apiAdapter respondsToSelector:@selector(shippingAddress)]) {
        shippingAddress = [self.apiAdapter shippingAddress];
    }
    STPShippingEntryViewController *shippingViewController = [[STPShippingEntryViewController alloc] initWithAddress:shippingAddress delegate:self requiredAddressFields:self.paymentRequest.requiredShippingAddressFields];
    [self.navigationController stp_pushViewController:shippingViewController animated:YES completion:nil];
}

- (void)paymentSummaryViewControllerDidCancel:(__unused STPPaymentSummaryViewController *)summaryViewController {
    [self.delegate coordinatorDidCancel:self];
}

- (void)paymentSummaryViewController:(__unused STPPaymentSummaryViewController *)summaryViewController didPressBuyCompletion:(STPErrorBlock)completion {
    [self.delegate coordinator:self willFinishWithCompletion:completion];
}

#pragma mark - STPShippingEntryViewControllerDelegate

- (void)shippingEntryViewController:(__unused STPShippingEntryViewController *)paymentCardViewController didEnterShippingAddress:(STPAddress *)address completion:(STPErrorBlock)completion {
    [self.apiAdapter updateCustomerShippingAddress:address completion:^(__unused STPAddress *retrievedAddress, NSError *error) {
        if (error) {
            // TODO handle error
            if (completion) {
                completion(error);
            }
            return;
        }
        [self.navigationController popViewControllerAnimated:YES];
        if (completion) {
            completion(nil);
        }
    }];
}

- (void)shippingEntryViewControllerDidCancel:(__unused STPShippingEntryViewController *)paymentCardViewController {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
