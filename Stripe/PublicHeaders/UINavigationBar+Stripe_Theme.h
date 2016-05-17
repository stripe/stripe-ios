//
//  UINavigationBar+Stripe_Theme.h
//  Stripe
//
//  Created by Jack Flintermann on 5/17/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
@class STPTheme;

@interface UINavigationBar (Stripe_Theme)

- (void)stp_setTheme:(STPTheme *)theme;

@end
