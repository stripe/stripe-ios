//
//  STPInitialPaymentDetailsCoordinator.m
//  Stripe
//
//  Created by Jack Flintermann on 3/28/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPInitialPaymentDetailsCoordinator.h"
#import "STPAPIClient.h"
#import "STPSourceProvider.h"
#import "STPPaymentCardEntryViewController.h"
#import "UINavigationController+Stripe_Completion.h"
#import "STPToken.h"

@interface STPInitialPaymentDetailsCoordinator()<STPPaymentCardEntryViewControllerDelegate>

@end

@implementation STPInitialPaymentDetailsCoordinator

- (void)begin {
    [super begin];
    STPPaymentCardEntryViewController *paymentCardViewController = [[STPPaymentCardEntryViewController alloc] initWithDelegate:self];
    self.navigationController.viewControllers = @[paymentCardViewController];
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
        
        [weakself.sourceProvider addSource:token completion:^(__unused id<STPSource> selectedSource, __unused NSArray<id<STPSource>> *sources, NSError *sourceError) {
            if (sourceError) {
                NSLog(@"TODO");
                completion(sourceError);
                return;
            }
            [self.delegate coordinator:self willFinishWithCompletion:nil];
            completion(nil);
        }];
    }];
}

@end
