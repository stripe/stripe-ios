//
//  UIView+LayoutSupport.h
//  Stripe3DS2
//
//  Created by Andrew Harrison on 2/27/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (LayoutSupport)

/**
 Pins the view to its superview's bounds.
 */
- (void)_stds_pinToSuperviewBounds;

- (void)_stds_pinToSuperviewBoundsWithoutMargin;

@end

NS_ASSUME_NONNULL_END

void _stds_import_uiview_layoutsupport(void);
