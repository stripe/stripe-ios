//
//  NSLayoutConstraint+LayoutSupport.h
//  Stripe3DS2
//
//  Created by Andrew Harrison on 2/27/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSLayoutConstraint (LayoutSupport)

/**
 Provides an NSLayoutConstraint where the `NSLayoutAttributeTop` is equal for both views, with a multiplier of 1, and a constant of 0.
 
 @param view1 The view to constrain.
 @param view2 The view to constraint to.
 @return An NSLayoutConstraint that is constraining the first view to the second at the top.
 */
+ (NSLayoutConstraint *)_stds_topConstraintWithItem:(id)view1 toItem:(id)view2;

/**
 Provides an NSLayoutConstraint where the `NSLayoutAttributeLeft` is equal for both views, with a multiplier of 1, and a constant of 0.
 
 @param view1 The view to constrain.
 @param view2 The view to constraint to.
 @return An NSLayoutConstraint that is constraining the first view to the second on the left.
 */
+ (NSLayoutConstraint *)_stds_leftConstraintWithItem:(id)view1 toItem:(id)view2;

/**
 Provides an NSLayoutConstraint where the `NSLayoutAttributeRight` is equal for both views, with a multiplier of 1, and a constant of 0.
 
 @param view1 The view to constrain.
 @param view2 The view to constraint to.
 @return An NSLayoutConstraint that is constraining the first view to the second on the right.
 */
+ (NSLayoutConstraint *)_stds_rightConstraintWithItem:(id)view1 toItem:(id)view2;

/**
 Provides an NSLayoutConstraint where the `NSLayoutAttributeBottom` is equal for both views, with a multiplier of 1, and a constant of 0.
 
 @param view1 The view to constrain.
 @param view2 The view to constraint to.
 @return An NSLayoutConstraint that is constraining the first view to the second at the bottom.
 */
+ (NSLayoutConstraint *)_stds_bottomConstraintWithItem:(id)view1 toItem:(id)view2;

@end

NS_ASSUME_NONNULL_END

void _stds_import_nslayoutconstraint_layoutsupport(void);
