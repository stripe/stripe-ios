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
#import "STPShippingEntryViewController.h"
#import "UINavigationController+Stripe_Completion.h"
#import "STPToken.h"

@interface STPInitialPaymentDetailsCoordinator()<STPPaymentCardEntryViewControllerDelegate, STPShippingEntryViewControllerDelegate>

@end

@implementation STPInitialPaymentDetailsCoordinator

- (void)begin {
    [super begin];
    STPShippingEntryViewController *shippingEntryViewController = [[STPShippingEntryViewController alloc] initWithAddress:nil delegate:self requiredAddressFields:PKAddressFieldAll];
//    STPPaymentCardEntryViewController *paymentCardViewController = [[STPPaymentCardEntryViewController alloc] initWithDelegate:self];
    self.navigationController.viewControllers = @[shippingEntryViewController];
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
            // TODO: pass in prefilled address & required fields
            STPShippingEntryViewController *shippingViewController = [[STPShippingEntryViewController alloc] initWithAddress:nil delegate:self requiredAddressFields:PKAddressFieldName|PKAddressFieldPhone];
            [self.navigationController stp_pushViewController:shippingViewController animated:YES completion:^{
                completion(nil);
            }];

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
    // TODO: do stuff
    [self.delegate coordinator:self willFinishWithCompletion:nil];
    completion(nil);
}

@end
