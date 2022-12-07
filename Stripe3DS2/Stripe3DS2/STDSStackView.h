//
//  STDSStackView.h
//  Stripe3DS2
//
//  Created by Andrew Harrison on 2/27/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, STDSStackViewLayoutAxis) {
    
    /// A horizontal layout for the stack view to use.
    STDSStackViewLayoutAxisHorizontal = 0,
    
    /// A vertical layout for the stack view to use.
    STDSStackViewLayoutAxisVertical = 1,
};

@interface STDSStackView: UIView

/**
 Initializes an `STDSStackView`.

 @param alignment The alignment for the stack view to use.
 @return An initialized `STDSStackView`.
 */
- (instancetype)initWithAlignment:(STDSStackViewLayoutAxis)alignment;

/**
 Adds a subview to the list of arranged subviews. Views will be displayed in the order they are added.

 @param view The view to add to the stack view.
 */
- (void)addArrangedSubview:(UIView *)view;

/**
 Removes a subview from the list of arranged subviews.
 
 @param view The view to remove.
 */
- (void)removeArrangedSubview:(UIView *)view;

/**
 Adds a spacer that fits the layout axis of the `STDSStackView`.

 @param dimension How wide or tall the spacer should be, depending on the axis of the `STDSStackView`.
 @note Spacers added through this function will not be removed or hidden automatically when they no longer fall between two views. For more precise interactions, add an `STDSSpacerView` manually through `addArrangedSubview:`.
 */
- (void)addSpacer:(CGFloat)dimension;

@end

NS_ASSUME_NONNULL_END
