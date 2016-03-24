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
#import "STPBasicSourceProvider.h"
#import "STPAPIClient.h"
#import "STPToken.h"

@interface STPPaymentAuthorizationViewController()<STPPaymentSummaryViewControllerDelegate, STPEmailEntryViewControllerDelegate, STPPaymentCardEntryViewControllerDelegate>
@property(nonatomic, weak) UINavigationController *navigationController;
@property(nonatomic, readwrite, nonnull) STPPaymentRequest *paymentRequest;
@property(nonatomic, readwrite, nonnull) STPAPIClient *apiClient;
@property(nonatomic) id<STPSourceProvider> sourceProvider;
@end

@implementation STPPaymentAuthorizationViewController

- (nonnull instancetype)initWithPaymentRequest:(nonnull STPPaymentRequest *)paymentRequest
                                     apiClient:(nonnull STPAPIClient *)apiClient {
    STPEmailEntryViewController *emailViewController = [STPEmailEntryViewController new];
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:emailViewController];
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _apiClient = apiClient;
        _paymentRequest = paymentRequest;
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
    STPSourceListViewController *destination = [[STPSourceListViewController alloc] initWithSourceProvider:self.sourceProvider apiClient:self.apiClient];
    [self.navigationController pushViewController:destination animated:YES];
}

- (void)paymentEmailViewController:(__unused STPEmailEntryViewController *)emailViewController didEnterEmailAddress:(__unused NSString *)emailAddress completion:(STPErrorBlock)completion {
    STPPaymentCardEntryViewController *paymentCardViewController = [STPPaymentCardEntryViewController new];
    paymentCardViewController.delegate = self;
    [self.navigationController stp_pushViewController:paymentCardViewController animated:YES completion:^{
        completion(nil);
    }];
}

- (void)paymentCardEntryViewController:(__unused STPPaymentCardEntryViewController *)emailViewController didEnterCardParams:(STPCardParams *)cardParams completion:(STPErrorBlock)completion {
    
    __weak typeof(self) weakself = self;
    
    [self.apiClient createTokenWithCard:cardParams completion:^(STPToken *token, NSError *error) {
        if (error) {
            completion(error);
            return;
        }
        
        [weakself.sourceProvider addSource:token completion:^(__unused id<STPSource> selectedSource, __unused NSArray<id<STPSource>> *sources, NSError *sourceError) {
            if (sourceError) {
                completion(error);
                return;
            }
            STPPaymentSummaryViewController *summaryViewController = [[STPPaymentSummaryViewController alloc] initWithPaymentRequest:weakself.paymentRequest sourceProvider:weakself.sourceProvider];
            [weakself.navigationController stp_pushViewController:summaryViewController animated:YES completion:^{
                completion(nil);
            }];
        }];
    }];
}

@end
