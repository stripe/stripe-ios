//
//  UIBarButtonItem+Stripe.h
//  Stripe
//
//  Created by Jack Flintermann on 5/18/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class STPTheme;

@interface UIBarButtonItem (Stripe)

+ (instancetype)stp_backButtonItemWithTitle:(NSString *)title
                                      style:(UIBarButtonItemStyle)style
                                     target:(id)target
                                     action:(SEL)action;

- (void)stp_setTheme:(STPTheme *)theme;

@end
