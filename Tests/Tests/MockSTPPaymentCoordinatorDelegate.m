//
//  MockSTPPaymentCoordinatorDelegate.m
//  Stripe
//
//  Created by Jack Flintermann on 4/11/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MockSTPPaymentCoordinatorDelegate.h"

static NSString *const __nonnull STPUnexpectedPaymentCoordinatorCallback = @"STPUnexpectedPaymentCoordinatorCallback";

@implementation MockSTPPaymentCoordinatorDelegate

- (void)reportUnexpectedCallback:(NSString *)callback {
    NSString *reason = [@"Unexpected Callback: " stringByAppendingString:callback];
    [[NSException exceptionWithName:STPUnexpectedPaymentCoordinatorCallback reason:reason userInfo:nil] raise];
}

- (void)paymentCoordinator:(__unused STPPaymentCoordinator *)coordinator
    didCreatePaymentResult:(STPPaymentResult *)result
                completion:(STPErrorBlock)completion {
    if (self.onDidCreatePaymentResult) {
        self.onDidCreatePaymentResult(result, completion);
    } else if (!self.ignoresUnexpectedCallbacks) {
        [self reportUnexpectedCallback: NSStringFromSelector(_cmd)];
    }
}

- (void)paymentCoordinator:(__unused STPPaymentCoordinator *)coordinator
          didFailWithError:(NSError *)error {
    if (self.onDidFailWithError) {
        self.onDidFailWithError(error);
    } else if (!self.ignoresUnexpectedCallbacks) {
        [self reportUnexpectedCallback: NSStringFromSelector(_cmd)];
    }
}

- (void)paymentCoordinatorDidCancel:(__unused STPPaymentCoordinator *)coordinator {
    if (self.onDidCancel) {
        self.onDidCancel();
    } else if (!self.ignoresUnexpectedCallbacks) {
        [self reportUnexpectedCallback: NSStringFromSelector(_cmd)];
    }
}

- (void)paymentCoordinatorDidSucceed:(__unused STPPaymentCoordinator *)coordinator {
    if (self.onDidSucceed) {
        self.onDidSucceed();
    } else if (!self.ignoresUnexpectedCallbacks) {
        [self reportUnexpectedCallback: NSStringFromSelector(_cmd)];
    }
}


@end
