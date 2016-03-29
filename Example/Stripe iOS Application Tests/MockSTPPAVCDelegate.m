//
//  MockSTPPAVCDelegate.m
//  Stripe iOS Example (Simple)
//
//  Created by Ben Guo on 3/29/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

#import "MockSTPPAVCDelegate.h"
#import <Stripe/Stripe.h>

@implementation MockSTPPAVCDelegate

- (void)paymentAuthorizationViewControllerDidCancel:(STPPaymentAuthorizationViewController *)paymentAuthorizationViewController {
    if (self.onDidCancel) {
        self.onDidCancel();
    }
}

- (void)paymentAuthorizationViewController:(STPPaymentAuthorizationViewController *)paymentAuthorizationViewController didFailWithError:(NSError *)error {
    if (self.onDidFailWithError) {
        self.onDidFailWithError(error);
    }
}

- (void)paymentAuthorizationViewController:(STPPaymentAuthorizationViewController *)paymentAuthorizationViewController didCreatePaymentResult:(STPPaymentResult *)result completion:(STPErrorBlock)completion {
    if (self.onDidCreatePaymentResult) {
        self.onDidCreatePaymentResult(result, completion);
    }
}

@end
