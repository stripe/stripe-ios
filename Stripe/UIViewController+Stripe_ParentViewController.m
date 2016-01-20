//
//  UIViewController+Stripe_ParentViewController.m
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "UIViewController+Stripe_ParentViewController.h"

@implementation UIViewController (Stripe_ParentViewController)

- (nullable UIViewController *)stp_parentViewControllerOfClass:(nonnull Class)klass {
    if ([self isKindOfClass:klass]) {
        return self;
    }
    return [self.parentViewController stp_parentViewControllerOfClass:klass];
//    for (UIViewController *vc in self.parentViewController.childViewControllers)
//    for vc in (self.parentViewController?.childViewControllers ?? []) {
//        if let cards = vc as? STPCardsViewController {
//            return cards
//        }
//    }
//    return self.parentViewController?.cardsViewController ?? nil

}

@end
