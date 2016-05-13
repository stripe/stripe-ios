//
//  STPPaymentActivityIndicatorView.h
//  Stripe
//
//  Created by Jack Flintermann on 5/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface STPPaymentActivityIndicatorView : UIView

- (void)setAnimating:(BOOL)animating
            animated:(BOOL)animated;

@property(nonatomic)BOOL animating;
@property(nonatomic)BOOL hidesWhenStopped;

@end
