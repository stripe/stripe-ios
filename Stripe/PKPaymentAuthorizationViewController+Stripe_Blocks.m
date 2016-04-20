//
//  PKPaymentAuthorizationViewController+Stripe_Blocks.m
//  Stripe
//
//  Created by Ben Guo on 4/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <objc/runtime.h>
#import "PKPaymentAuthorizationViewController+Stripe_Blocks.h"
#import "Stripe+ApplePay.h"
#import "STPPaymentMethod.h"

static char kSTPBlockBasedApplePayDelegateAssociatedObjectKey;

@interface STPBlockBasedApplePayDelegate : NSObject <PKPaymentAuthorizationViewControllerDelegate>
@property (nonatomic, readwrite) STPAPIClient *apiClient;
@property (nonatomic, readwrite) STPSourceHandlerBlock onTokenCreation;
@property (nonatomic, readwrite) STPPaymentCompletionBlock onFinish;
@property (nonatomic, readwrite) NSError *lastError;
@property (nonatomic, readwrite) BOOL didSucceed;
@end


@implementation STPBlockBasedApplePayDelegate

- (void)paymentAuthorizationViewController:(__unused PKPaymentAuthorizationViewController *)controller didAuthorizePayment:(PKPayment *)payment completion:(void (^)(PKPaymentAuthorizationStatus))completion {
    [self.apiClient createTokenWithPayment:payment completion:^(STPToken * _Nullable token, NSError * _Nullable error) {
        if (error) {
            self.lastError = error;
            completion(PKPaymentAuthorizationStatusFailure);
            return;
        }
        self.onTokenCreation(STPPaymentMethodTypeApplePay, token, ^(NSError *tokenCreationError){
            if (tokenCreationError) {
                self.lastError = tokenCreationError;
                completion(PKPaymentAuthorizationStatusFailure);
                return;
            }
            self.didSucceed = YES;
            completion(PKPaymentAuthorizationStatusSuccess);
        });
    }];
}

- (void)paymentAuthorizationViewControllerDidFinish:(__unused PKPaymentAuthorizationViewController *)controller {
    if (self.didSucceed) {
        self.onFinish(STPPaymentStatusSuccess, nil);
    }
    else if (self.lastError) {
        self.onFinish(STPPaymentStatusError, self.lastError);
    }
    else {
        self.onFinish(STPPaymentStatusUserCancellation, nil);
    }
}

@end

@interface PKPaymentAuthorizationViewController()

@end

@implementation PKPaymentAuthorizationViewController (Stripe_Blocks)

+ (instancetype)stp_controllerWithPaymentRequest:(PKPaymentRequest *)paymentRequest
                                       apiClient:(STPAPIClient *)apiClient
                             onTokenCreation:(STPSourceHandlerBlock)onTokenCreation
                                    onFinish:(STPPaymentCompletionBlock)onFinish {
    STPBlockBasedApplePayDelegate *delegate = [STPBlockBasedApplePayDelegate new];
    delegate.apiClient = apiClient;
    delegate.onTokenCreation = onTokenCreation;
    delegate.onFinish = onFinish;
    PKPaymentAuthorizationViewController *viewController = [[PKPaymentAuthorizationViewController alloc] initWithPaymentRequest:paymentRequest];
    viewController.delegate = delegate;
    objc_setAssociatedObject(viewController, &kSTPBlockBasedApplePayDelegateAssociatedObjectKey, delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return viewController;
}

@end


