//
//  MockUINavigationController.m
//  Stripe
//
//  Created by Ben Guo on 4/11/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "MockUINavigationController.h"
#import "STPBlocks.h"

@implementation MockUINavigationController

- (void)stp_pushViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(STPVoidBlock)completion {
    void (^completionBlock)() = ^() {
        if (completion) {
            completion();
        }
        if (self.onPushViewController) {
            self.onPushViewController(viewController, animated);
        }
    };
    [CATransaction begin];
    [CATransaction setCompletionBlock:completionBlock];
    [super pushViewController:viewController animated:animated];
    [CATransaction commit];
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    void (^completion)() = ^() {
        if (self.onPushViewController) {
            self.onPushViewController(viewController, animated);
        }
    };
    [CATransaction begin];
    [CATransaction setCompletionBlock:completion];
    [super pushViewController:viewController animated:animated];
    [CATransaction commit];
}

- (void)stp_popViewControllerAnimated:(BOOL)animated
                           completion:(STPVoidBlock)completion {
    void (^completionBlock)() = ^() {
        if (completion) {
            completion();
        }
        if (self.onPopViewController) {
            self.onPopViewController(animated);
        }
    };
    [CATransaction begin];
    [CATransaction setCompletionBlock:completionBlock];
    [super popViewControllerAnimated:animated];
    [CATransaction commit];
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated {
    void (^completion)() = ^() {
        if (self.onPopViewController) {
            self.onPopViewController(animated);
        }
    };
    [CATransaction begin];
    [CATransaction setCompletionBlock:completion];
    UIViewController *vc = [super popViewControllerAnimated:animated];
    [CATransaction commit];
    return vc;
}

@end
