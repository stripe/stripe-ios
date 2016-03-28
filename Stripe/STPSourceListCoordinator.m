//
//  STPSourceListCoordinator.m
//  Stripe
//
//  Created by Jack Flintermann on 3/28/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPSourceListCoordinator.h"
#import "STPSourceListViewController.h"
#import "STPPaymentCardEntryViewController.h"
#import "STPAPIClient.h"
#import "STPSourceProvider.h"
#import "STPToken.h"
#import "UINavigationController+Stripe_Completion.h"

@interface STPSourceListCoordinator()<STPPaymentCardEntryViewControllerDelegate, STPSourceListViewControllerDelegate>

@property(nonatomic)UINavigationController *navigationController;
@property(nonatomic)STPSourceListViewController *sourceListViewController;
@property(nonatomic)STPAPIClient *apiClient;
@property(nonatomic)id<STPSourceProvider> sourceProvider;
@property(nonatomic, weak)id<STPSourceListCoordinatorDelegate> delegate;

@end

@implementation STPSourceListCoordinator

- (instancetype)initWithNavigationController:(UINavigationController *)navigationController
                                   apiClient:(STPAPIClient *)apiClient
                              sourceProvider:(id<STPSourceProvider>)sourceProvider
                                    delegate:(id<STPSourceListCoordinatorDelegate>)delegate {
    self = [super init];
    if (self) {
        _navigationController = navigationController;
        _apiClient = apiClient;
        _sourceProvider = sourceProvider;
        _sourceListViewController = [[STPSourceListViewController alloc] initWithSourceProvider:_sourceProvider delegate:self];
        _delegate = delegate;
    }
    return self;
}

- (void)showSourceList {
    [self.navigationController pushViewController:self.sourceListViewController animated:YES];
}

#pragma mark STPPaymentCardEntryViewControllerDelegate

- (void)paymentCardEntryViewController:(__unused STPPaymentCardEntryViewController *)viewController
                    didEnterCardParams:(STPCardParams *)cardParams
                            completion:(STPErrorBlock)completion {
    __weak typeof(self) weakself = self;
    [self.apiClient createTokenWithCard:cardParams completion:^(__unused STPToken * _Nullable token, __unused NSError * _Nullable error) {
        if (error) {
            NSLog(@"TODO");
            completion(error);
            return;
        }
        
        [self.sourceProvider addSource:token completion:^(__unused id<STPSource> selectedSource, __unused NSArray<id<STPSource>> * _Nullable sources, __unused NSError * _Nullable addSourceError) {
            if (error) {
                NSLog(@"TODO");
                completion(error);
                return;
            }
            [weakself.sourceListViewController reload];
            [weakself.navigationController popViewControllerAnimated:true];
        }];
    }];
}


#pragma mark STPSourceListViewControllerDelegate

- (void)sourceListViewControllerDidTapAddButton:(__unused STPSourceListViewController *)viewController {
    STPPaymentCardEntryViewController *paymentCardViewController = [[STPPaymentCardEntryViewController alloc] initWithDelegate:self];
    [self.navigationController stp_pushViewController:paymentCardViewController animated:YES completion:nil];
}

- (void)sourceListViewController:(__unused STPSourceListViewController *)viewController
                 didSelectSource:(id<STPSource>)source {
    [self.sourceProvider selectSource:source completion:^(__unused id<STPSource>  _Nullable selectedSource, __unused NSArray<id<STPSource>> * _Nullable sources, NSError * _Nullable error) {
        if (error) {
            NSLog(@"TODO");
            return;
        }
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

@end
