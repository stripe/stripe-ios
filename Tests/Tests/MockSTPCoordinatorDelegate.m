//
//  MockSTPCoordinatorDelegate.m
//  Stripe iOS Example (Simple)
//
//  Created by Ben Guo on 3/29/16.
//  Copyright © 2016 Stripe. All rights reserved.
//


#import "MockSTPCoordinatorDelegate.h"
#import "STPBaseCoordinator.h"

@implementation MockSTPCoordinatorDelegate

- (void)coordinatorDidCancel:(__unused STPBaseCoordinator *)coordinator {
    if (self.onDidCancel) {
        self.onDidCancel();
    }
}

- (void)coordinator:(__unused STPBaseCoordinator *)coordinator willFinishWithCompletion:(STPErrorBlock)completion {
    if (self.onWillFinishWithCompletion) {
        self.onWillFinishWithCompletion(completion);
    }
}

@end
