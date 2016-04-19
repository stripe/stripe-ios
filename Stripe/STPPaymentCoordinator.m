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

static char kSTPPaymentCoordinatorAssociatedObjectKey;

@implementation STPPaymentCoordinator

- (void)performPaymentRequest:(STPPaymentRequest *)request
                    apiClient:(STPAPIClient *)apiClient
                   apiAdapter:(__unused id<STPBackendAPIAdapter>)apiAdapter
           fromViewController:(UIViewController *)fromViewController
                sourceHandler:(STPSourceHandlerBlock)sourceHandler
                   completion:(STPPaymentCompletionBlock)completion {
    [self artificiallyRetain:fromViewController];
    if (request.paymentMethod.type == STPPaymentMethodTypeCard) {
        STPCardPaymentMethod *cardPaymentMethod = (STPCardPaymentMethod *)request.paymentMethod;
        sourceHandler(request.paymentMethod.type, cardPaymentMethod.source, ^(NSError *error) {
            if (error) {
                completion(STPPaymentStatusError, error);
                [self artificiallyRelease:fromViewController];
                return;
            }
            completion(STPPaymentStatusSuccess, nil);
            [self artificiallyRelease:fromViewController];
        });
    }
    if (request.paymentMethod.type == STPPaymentMethodTypeApplePay) {
        PKPaymentRequest *paymentRequest = [Stripe paymentRequestWithMerchantIdentifier:request.appleMerchantIdentifier];
        PKPaymentSummaryItem *totalItem = [PKPaymentSummaryItem summaryItemWithLabel:@"" amount:request.decimalAmount];
        paymentRequest.paymentSummaryItems = @[totalItem];
        PKPaymentAuthorizationViewController *paymentAuthViewController = [PKPaymentAuthorizationViewController stp_controllerWithPaymentRequest:paymentRequest publishableKey:apiClient.publishableKey onTokenCreation:sourceHandler
         onFinish:^(STPPaymentStatus status, NSError * _Nullable error) {
             [fromViewController dismissViewControllerAnimated:YES completion:^{
                 completion(status, error);
                 [self artificiallyRelease:fromViewController];
             }];
        }];
        [fromViewController presentViewController:paymentAuthViewController animated:YES completion:nil];
    }
}

- (void)artificiallyRetain:(NSObject *)host {
    objc_setAssociatedObject(host, &kSTPPaymentCoordinatorAssociatedObjectKey, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)artificiallyRelease:(NSObject *)host {
    objc_setAssociatedObject(host, &kSTPPaymentCoordinatorAssociatedObjectKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
