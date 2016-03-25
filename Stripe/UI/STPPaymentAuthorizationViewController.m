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

@interface STPPaymentAuthorizationViewController()<STPEmailEntryViewControllerDelegate, STPPaymentCardEntryViewControllerDelegate, STPPaymentSummaryViewControllerDelegate, STPSourceListViewControllerDelegate>
@property(nonatomic, weak) UINavigationController *navigationController;
@property(nonatomic, readwrite, nonnull) STPPaymentRequest *paymentRequest;
@property(nonatomic, readwrite, nonnull) STPAPIClient *apiClient;
@property(nonatomic) id<STPSourceProvider> sourceProvider;
@end

@implementation STPPaymentAuthorizationViewController

- (nonnull instancetype)initWithPaymentRequest:(nonnull STPPaymentRequest *)paymentRequest
                                     apiClient:(nonnull STPAPIClient *)apiClient {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _apiClient = apiClient;
        _paymentRequest = paymentRequest;
        _sourceProvider = [STPBasicSourceProvider new];
        STPEmailEntryViewController *emailViewController = [[STPEmailEntryViewController alloc] initWithDelegate:self];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:emailViewController];
        _navigationController = navigationController;
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

#pragma mark - STPEmailEntryViewControllerDelegate

- (void)emailEntryViewController:(__unused STPEmailEntryViewController *)viewController didEnterEmailAddress:(__unused NSString *)emailAddress completion:(STPErrorBlock)completion {
    STPPaymentCardEntryViewController *paymentCardViewController = [[STPPaymentCardEntryViewController alloc] initWithDelegate:self];
    [self.navigationController stp_pushViewController:paymentCardViewController animated:YES completion:^{
        completion(nil);
    }];
}

#pragma mark - STPPaymentCardEntryViewControllerDelegate

- (void)paymentCardEntryViewController:(__unused STPPaymentCardEntryViewController *)viewController didEnterCardParams:(STPCardParams *)cardParams completion:(STPErrorBlock)completion {
    
    __weak typeof(self) weakself = self;
    
    [self.apiClient createTokenWithCard:cardParams completion:^(STPToken *token, NSError *error) {
        if (error) {
            NSLog(@"TODO");
            completion(error);
            return;
        }
        
        [weakself.sourceProvider addSource:token completion:^(__unused id<STPSource> selectedSource, __unused NSArray<id<STPSource>> *sources, NSError *sourceError) {
            if (sourceError) {
                NSLog(@"TODO");
                completion(error);
                return;
            }
            STPPaymentSummaryViewController *summaryViewController = [[STPPaymentSummaryViewController alloc] initWithPaymentRequest:weakself.paymentRequest sourceProvider:weakself.sourceProvider delegate:self];
            [weakself.navigationController stp_pushViewController:summaryViewController animated:YES completion:^{
                completion(nil);
            }];
        }];
    }];
}

#pragma mark - STPPaymentSummaryViewControllerDelegate

- (void)paymentSummaryViewControllerDidEditPaymentMethod:(__unused STPPaymentSummaryViewController *)viewController {
    STPSourceListViewController *destination = [[STPSourceListViewController alloc] initWithSourceProvider:self.sourceProvider
                                                                                                 apiClient:self.apiClient
                                                                                                  delegate:self];
    [self.navigationController pushViewController:destination animated:YES];
}

- (void)paymentSummaryViewControllerDidCancel:(__unused STPPaymentSummaryViewController *)summaryViewController {
    [self.delegate paymentAuthorizationViewControllerDidCancel:self];
}

- (void)paymentSummaryViewControllerDidPressBuy:(__unused STPPaymentSummaryViewController *)viewController {
    STPPaymentResult *result = [[STPPaymentResult alloc] initWithSource:self.sourceProvider.selectedSource customer:nil];
    [self.delegate paymentAuthorizationViewController:self didCreatePaymentResult:result];
}

#pragma mark - STPSourceListViewControllerDelegate

- (void)sourceListViewController:(__unused STPSourceListViewController *)viewController didSelectSource:(id<STPSource>)source {
    [self.sourceProvider selectSource:source completion:^(__unused id<STPSource>  _Nullable selectedSource, __unused NSArray<id<STPSource>> * _Nullable sources, NSError * _Nullable error) {
        if (error) {
            NSLog(@"TODO");
            return;
        }
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

@end
