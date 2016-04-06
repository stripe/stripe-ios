//
//  MockSTPCoordinatorDelegate.m
//  Stripe iOS Example (Simple)
//
//  Created by Ben Guo on 3/29/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

#import "MockSTPCoordinatorDelegate.h"
#import <Stripe/Stripe.h>

@implementation MockSTPCoordinatorDelegate

- (void)coordinatorDidCancel:(STPBaseCoordinator *)coordinator {
    if (self.onDidCancel) {
        self.onDidCancel();
    }
}

- (void)coordinator:(STPBaseCoordinator *)coordinator willFinishWithCompletion:(STPErrorBlock)completion {
    if (self.onWillFinishWithCompletion) {
        self.onWillFinishWithCompletion(completion);
    }
}

@end
