//
//  STPInitialPaymentDetailsCoordinator.m
//  Stripe
//
//  Created by Jack Flintermann on 3/28/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPInitialPaymentDetailsCoordinator.h"
#import "STPAPIClient.h"
#import "STPBackendAPIAdapter.h"
#import "STPPaymentCardEntryViewController.h"
#import "STPShippingEntryViewController.h"
#import "UINavigationController+Stripe_Completion.h"
#import "STPToken.h"
#import "STPInitialLoadingViewController.h"

@interface STPInitialPaymentDetailsCoordinator()<STPPaymentCardEntryViewControllerDelegate, STPShippingEntryViewControllerDelegate>

@property(nonatomic)PKPaymentRequest *paymentRequest;
@property(nonatomic, weak, readonly)id<STPCoordinatorDelegate>delegate;
@property(nonatomic, readonly)UINavigationController *navigationController;
@property(nonatomic, readonly)STPAPIClient *apiClient;
@property(nonatomic, readonly)id<STPBackendAPIAdapter> apiAdapter;

@end

@implementation STPInitialPaymentDetailsCoordinator

- (instancetype)initWithNavigationController:(UINavigationController *)navigationController
                              paymentRequest:(PKPaymentRequest *)paymentRequest
                                   apiClient:(STPAPIClient *)apiClient
                              apiAdapter:(id<STPBackendAPIAdapter>)apiAdapter
                                    delegate:(id<STPCoordinatorDelegate>)delegate {
    self = [super init];
    if (self) {
        _navigationController = navigationController;
        _apiClient = apiClient;
        _apiAdapter = apiAdapter;
        _delegate = delegate;
        _paymentRequest = paymentRequest;
    }
    return self;
}

- (void)begin {
    [super begin];
    STPInitialLoadingViewController *loadingViewController = [[STPInitialLoadingViewController alloc] init];
    self.navigationController.viewControllers = @[loadingViewController];
    [self.apiAdapter retrieveSources:^(id<STPSource> selectedSource, __unused NSArray<id<STPSource>> *sources, __unused NSError *error) {
        if (selectedSource) {
            [self showShippingIfNecessaryCompletion:nil];
        } else {
            STPPaymentCardEntryViewController *paymentCardViewController = [[STPPaymentCardEntryViewController alloc] initWithDelegate:self];
            BOOL animated = loadingViewController.isViewLoaded && loadingViewController.view.window;
            [self.navigationController setViewControllers:@[loadingViewController, paymentCardViewController] animated:animated];
        }
    }];
}

- (void)showShippingIfNecessaryCompletion:(STPErrorBlock)completion {
    if (self.paymentRequest.requiredShippingAddressFields != PKAddressFieldNone) {
        if ([self.apiAdapter respondsToSelector:@selector(retrieveCustomerShippingAddress:)]) {
            [self.apiAdapter retrieveCustomerShippingAddress:^(STPAddress *address, NSError *shippingError) {
                if (shippingError || ![address containsRequiredFields:self.paymentRequest.requiredShippingAddressFields]) {
                    STPShippingEntryViewController *shippingViewController = [[STPShippingEntryViewController alloc] initWithAddress:address delegate:self requiredAddressFields:self.paymentRequest.requiredShippingAddressFields];
                    BOOL animated = self.navigationController.isViewLoaded && self.navigationController.view.window;
                    [self.navigationController stp_pushViewController:shippingViewController animated:animated completion:^{
                        completion(nil);
                    }];
                } else {
                    [self.delegate coordinator:self willFinishWithCompletion:completion];
                }
            }];
        } else {
            STPShippingEntryViewController *shippingViewController = [[STPShippingEntryViewController alloc] initWithAddress:nil delegate:self requiredAddressFields:self.paymentRequest.requiredShippingAddressFields];
            BOOL animated = self.navigationController.isViewLoaded && self.navigationController.view.window;
            [self.navigationController stp_pushViewController:shippingViewController animated:animated completion:^{
                completion(nil);
            }];
        }
    } else {
        [self.delegate coordinator:self willFinishWithCompletion:completion];
    }
}

#pragma mark - STPPaymentCardEntryViewControllerDelegate

- (void)paymentCardEntryViewControllerDidCancel:(__unused STPPaymentCardEntryViewController *)paymentCardViewController {
    [self.delegate coordinatorDidCancel:self];
}

- (void)paymentCardEntryViewController:(__unused STPPaymentCardEntryViewController *)viewController didEnterCardParams:(STPCardParams *)cardParams completion:(STPErrorBlock)completion {
    
    __weak typeof(self) weakself = self;
    
    [self.apiClient createTokenWithCard:cardParams completion:^(STPToken *token, NSError *error) {
        if (error) {
            NSLog(@"TODO");
            completion(error);
            return;
        }
        
        [weakself.apiAdapter addSource:token completion:^(__unused id<STPSource> selectedSource, __unused NSArray<id<STPSource>> *sources, NSError *sourceError) {
            if (sourceError) {
                NSLog(@"TODO");
                completion(sourceError);
                return;
            }
            [self showShippingIfNecessaryCompletion:completion];
        }];
    }];
}

#pragma mark - STPShippingEntryViewControllerDelegate

- (void)shippingEntryViewControllerDidCancel:(__unused STPShippingEntryViewController *)paymentCardViewController {
    [self.delegate coordinatorDidCancel:self];
}

- (void)shippingEntryViewController:(__unused STPShippingEntryViewController *)paymentCardViewController
            didEnterShippingAddress:(__unused STPAddress *)address
                         completion:(STPErrorBlock)completion {
    if ([self.apiAdapter respondsToSelector:@selector(updateCustomerShippingAddress:completion:)]) {
        [self.apiAdapter updateCustomerShippingAddress:address completion:^(__unused STPAddress *retrievedAddress, NSError *error) {
            if (error) {
                // TODO handle error
            } else {
                [self.delegate coordinator:self willFinishWithCompletion:completion];
            }
        }];
    } else {
        [self.delegate coordinator:self willFinishWithCompletion:completion];
    }
}

@end
