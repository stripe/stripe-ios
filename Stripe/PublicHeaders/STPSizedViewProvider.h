//
//  STPSizedViewProvider.h
//  Stripe
//
//  Created by Bryan Irace on 8/11/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

/**
 Defines a type capable of providing a view that already has its frame populated. A width is provided because a view’s
 frame’s height will often depend on its width.
 */
@protocol STPSizedViewProvider

/**
 Returns a view that already has its frame populated, calculated using the provided width.
 */
- (UIView *)sizedViewForWidth:(CGFloat)width;

@end
