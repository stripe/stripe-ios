//
//  UIView+Stripe_SafeAreaBounds.m
//  Stripe
//
//  Created by Ben Guo on 12/12/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "UIView+Stripe_SafeAreaBounds.h"

NS_ASSUME_NONNULL_BEGIN

@implementation UIView (Stripe_SafeAreaBounds)

- (CGRect)stp_boundsWithHorizontalSafeAreaInsets {
    if (@available(iOS 11.0, *)) {
        UIEdgeInsets insets = self.safeAreaInsets;
        CGRect safeBounds = CGRectMake(self.bounds.origin.x + insets.left,
                                       self.bounds.origin.y,
                                       self.bounds.size.width - (insets.left + insets.right),
                                       self.bounds.size.height);
        return safeBounds;
    }
    else {
        return self.bounds;
    }
}

@end

void linkUIViewSafeAreaBoundsCategory(void){}

NS_ASSUME_NONNULL_END
