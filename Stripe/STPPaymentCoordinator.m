//
//  STPPaymentCoordinator.m
//  Stripe
//
//  Created by Jack Flintermann on 4/6/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <PassKit/PassKit.h>
#import <objc/runtime.h>
#import "Stripe+ApplePay.h"
#import "STPPaymentCoordinator.h"
#import "STPAPIClient.h"
#import "STPPaymentRequest.h"
#import "STPPaymentMethod.h"
#import "STPCardPaymentMethod.h"
#import "PKPaymentAuthorizationViewController+Stripe_Blocks.h"
#import "STPPaymentMethodsStore.h"
#import "STPPaymentMethodsViewController.h"

static char kSTPPaymentCoordinatorAssociatedObjectKey;

@interface STPPaymentCoordinator() <STPPaymentMethodsViewControllerDelegate>

@property (nonatomic) STPPaymentRequest *paymentRequest;
@property (nonatomic, weak) UIViewController *fromViewController;
@property (nonatomic) STPSourceHandlerBlock sourceHandler;
@property (nonatomic) STPPaymentCompletionBlock completion;

@end

@implementation STPPaymentCoordinator

- (void)performPaymentRequest:(STPPaymentRequest *)paymentRequest
          paymentMethodsStore:(STPPaymentMethodsStore *)paymentMethodsStore
           fromViewController:(UIViewController *)fromViewController
                sourceHandler:(STPSourceHandlerBlock)sourceHandler
                   completion:(STPPaymentCompletionBlock)completion {
    _paymentRequest = paymentRequest;
    _fromViewController = fromViewController;
    _sourceHandler = sourceHandler;
    _completion = completion;
    [self artificiallyRetain:fromViewController];
    if ([paymentRequest.paymentMethod isKindOfClass:[STPAutomaticPaymentMethod class]]) {
        STPPaymentMethodsViewController *paymentMethodsViewController = [[STPPaymentMethodsViewController alloc] initWithPaymentMethodsStore:paymentMethodsStore delegate:self];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:paymentMethodsViewController];
        [fromViewController presentViewController:navigationController animated:YES completion:nil];
    }
    else {
        [self finishPaymentMethod:paymentRequest.paymentMethod];
    }
}

- (void)finishPaymentMethod:(id<STPPaymentMethod>)paymentMethod {
    if (paymentMethod.type == STPPaymentMethodTypeCard) {
        STPCardPaymentMethod *cardPaymentMethod = (STPCardPaymentMethod *)paymentMethod;
        self.sourceHandler(paymentMethod.type, cardPaymentMethod.source, ^(NSError *error) {
            if (error) {
                self.completion(STPPaymentStatusError, error);
                [self artificiallyRelease:self.fromViewController];
                return;
            }
            self.completion(STPPaymentStatusSuccess, nil);
            [self artificiallyRelease:self.fromViewController];
        });
    }
    else if (paymentMethod.type == STPPaymentMethodTypeApplePay) {
        PKPaymentRequest *paymentRequest = [Stripe paymentRequestWithMerchantIdentifier:self.paymentRequest.appleMerchantIdentifier];
        PKPaymentSummaryItem *totalItem = [PKPaymentSummaryItem summaryItemWithLabel:self.paymentRequest.merchantName
                                                                              amount:self.paymentRequest.decimalAmount];
        paymentRequest.paymentSummaryItems = @[totalItem];
        PKPaymentAuthorizationViewController *paymentAuthViewController = [PKPaymentAuthorizationViewController stp_controllerWithPaymentRequest:paymentRequest publishableKey:self.apiClient.publishableKey onTokenCreation:self.sourceHandler
         onFinish:^(STPPaymentStatus status, NSError * _Nullable error) {
             [self.fromViewController dismissViewControllerAnimated:YES completion:^{
                 self.completion(status, error);
                 [self artificiallyRelease:self.fromViewController];
             }];
        }];
        [self.fromViewController presentViewController:paymentAuthViewController animated:YES completion:nil];
    }
}

- (void)artificiallyRetain:(NSObject *)host {
    objc_setAssociatedObject(host, &kSTPPaymentCoordinatorAssociatedObjectKey, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)artificiallyRelease:(NSObject *)host {
    objc_setAssociatedObject(host, &kSTPPaymentCoordinatorAssociatedObjectKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - STPPaymentMethodsViewControllerDelegate

- (void)paymentMethodsViewController:(STPPaymentMethodsViewController *)viewController didFinishWithPaymentMethod:(id<STPPaymentMethod>)paymentMethod {
    NSLog(@"%@ %@", viewController, paymentMethod);
    [self.fromViewController dismissViewControllerAnimated:YES completion:^{
        [self finishPaymentMethod:paymentMethod];
        [self artificiallyRelease:self.fromViewController];
    }];
}

@end
