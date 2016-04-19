//
//  STPSourceListCoordinator.m
//  Stripe
//
//  Created by Jack Flintermann on 3/28/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPSourceListCoordinator.h"
#import "STPPaymentMethodsViewController.h"
#import "STPPaymentCardEntryViewController.h"
#import "STPAPIClient.h"
#import "STPBackendAPIAdapter.h"
#import "STPToken.h"
#import "UINavigationController+Stripe_Completion.h"

@interface STPSourceListCoordinator()<STPPaymentCardEntryViewControllerDelegate, STPSourceListViewControllerDelegate>

@property(nonatomic, weak) STPPaymentMethodsViewController *sourceListViewController;
@property(nonatomic, weak, readonly)id<STPCoordinatorDelegate>delegate;
@property(nonatomic, readonly)UINavigationController *navigationController;
@property(nonatomic, readonly)STPAPIClient *apiClient;
@property(nonatomic, readonly)id<STPBackendAPIAdapter> apiAdapter;

@end

@implementation STPSourceListCoordinator

- (instancetype)initWithNavigationController:(UINavigationController *)navigationController
                                   apiClient:(STPAPIClient *)apiClient
                              apiAdapter:(id<STPBackendAPIAdapter>)apiAdapter
                                    delegate:(id<STPCoordinatorDelegate>)delegate {
    self = [super init];
    if (self) {
        _navigationController = navigationController;
        _apiClient = apiClient;
        _apiAdapter = apiAdapter;
        _delegate = delegate;
    }
    return self;
}

- (void)begin {
    [super begin];
    STPPaymentMethodsViewController *sourceListViewController = [[STPPaymentMethodsViewController alloc] initWithapiAdapter:self.apiAdapter delegate:self];
    self.sourceListViewController = sourceListViewController;
    [self.navigationController pushViewController:sourceListViewController animated:YES];
}

#pragma mark STPPaymentCardEntryViewControllerDelegate

- (void)paymentCardEntryViewControllerDidCancel:(__unused STPPaymentCardEntryViewController *)paymentCardViewController {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)paymentCardEntryViewController:(__unused STPPaymentCardEntryViewController *)viewController
                    didEnterCardParams:(STPCardParams *)cardParams
                            completion:(STPErrorBlock)completion {
    __weak typeof(self) weakself = self;
    [self.apiClient createTokenWithCard:cardParams completion:^(__unused STPToken * _Nullable token, __unused NSError * _Nullable error) {
        if (error) {
            NSLog(@"TODO");
            if (completion) {
                completion(error);
            }
            return;
        }
        
        [self.apiAdapter addSource:token completion:^(__unused id<STPSource> selectedSource, __unused NSArray<id<STPSource>> * _Nullable sources, __unused NSError * _Nullable addSourceError) {
            if (addSourceError) {
                NSLog(@"TODO");
                if (completion) {
                    completion(addSourceError);
                }
                return;
            }
            [weakself.sourceListViewController reload];
            [weakself.navigationController popViewControllerAnimated:true];
            if (completion) {
                completion(nil);
            }
        }];
    }];
}


#pragma mark STPSourceListViewControllerDelegate

- (void)sourceListViewControllerDidTapAddButton:(__unused STPPaymentMethodsViewController *)viewController {
    STPPaymentCardEntryViewController *paymentCardViewController = [[STPPaymentCardEntryViewController alloc] initWithDelegate:self];
    [self.navigationController stp_pushViewController:paymentCardViewController animated:YES completion:nil];
}

- (void)sourceListViewController:(__unused STPPaymentMethodsViewController *)viewController
                 didSelectSource:(id<STPSource>)source {
    [self.apiAdapter selectSource:source completion:^(__unused id<STPSource>  _Nullable selectedSource, __unused NSArray<id<STPSource>> * _Nullable sources, NSError * _Nullable error) {
        if (error) {
            NSLog(@"TODO");
            return;
        }
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

@end
