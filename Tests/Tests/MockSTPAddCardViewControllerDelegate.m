//
//  MockSTPAddCardViewControllerDelegate.m
//  Stripe
//
//  Created by Ben Guo on 7/5/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "MockSTPAddCardViewControllerDelegate.h"

@implementation MockSTPAddCardViewControllerDelegate

- (void)addCardViewControllerDidCancel:(__unused STPAddCardViewController *)addCardViewController {
    if (self.onDidCancel) {
        self.onDidCancel();
    }
}

- (void)addCardViewController:(__unused STPAddCardViewController *)addCardViewController didCreateToken:(STPToken *)token completion:(STPErrorBlock)completion {
    if (self.onDidCreateToken) {
        self.onDidCreateToken(token, completion);
    }
}

@end
