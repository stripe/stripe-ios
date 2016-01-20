//
//  UIViewController+Stripe_ParentViewController.h
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (Stripe_ParentViewController)

- (nullable UIViewController *)stp_parentViewControllerOfClass:(nonnull Class)klass;

@end
