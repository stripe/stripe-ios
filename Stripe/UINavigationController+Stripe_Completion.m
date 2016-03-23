//
//  UINavigationController+Stripe_Completion.m
//  Stripe
//
//  Created by Jack Flintermann on 3/23/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "UINavigationController+Stripe_Completion.h"

@implementation UINavigationController (Stripe_Completion)

- (void)stp_pushViewController:(UIViewController *)viewController
                      animated:(BOOL)animated
                    completion:(STPVoidBlock)completion {
    [CATransaction begin];
    [CATransaction setCompletionBlock:completion];
    [self pushViewController:viewController animated:animated];
    [CATransaction commit];
}

@end
