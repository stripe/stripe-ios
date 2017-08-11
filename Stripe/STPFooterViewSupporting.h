//
//  STPFooterViewSupporting.h
//  Stripe
//
//  Created by Bryan Irace on 8/11/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 A type that supports being provided with a footer view.
 */
@protocol STPFooterViewSupporting

/**
 Provide this view controller with a footer view. This view should already have a frame.
 */
- (void)setFooterView:(UIView *)footerView;

@end
