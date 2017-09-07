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
 Provide this view controller with a footer view.
 
 When the footer view needs to be resized, it will be sent a 
 `sizeThatFits:` call. The view should respond correctly to this method in order
 to be sized and positioned properly.
 */
- (void)setStripeViewControllerFooterView:(UIView *)footerView;

@end
