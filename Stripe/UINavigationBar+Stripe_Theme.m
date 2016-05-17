//
//  UINavigationBar+Stripe_Theme.m
//  Stripe
//
//  Created by Jack Flintermann on 5/17/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "UINavigationBar+Stripe_Theme.h"
#import "STPTheme.h"

@implementation UINavigationBar (Stripe_Theme)

- (void)stp_setTheme:(STPTheme *)theme {
    self.barTintColor = theme.secondaryBackgroundColor;
    self.tintColor = theme.accentColor;
}

@end
