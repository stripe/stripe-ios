//
//  UIView+Stripe_SafeAreaBounds.h
//  Stripe
//
//  Created by Ben Guo on 12/12/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (Stripe_SafeAreaBounds)

/**
 Returns this view's bounds inset to `safeAreaInsets.left` and `safeAreaInsets.right`.
 Top and bottom safe area insets are ignored. On iOS <11, this returns self.bounds.
 */
- (CGRect)stp_boundsWithHorizontalSafeAreaInsets;

@end

void linkUIViewSafeAreaBoundsCategory(void);

NS_ASSUME_NONNULL_END
