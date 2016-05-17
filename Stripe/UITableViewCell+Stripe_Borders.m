//
//  UITableViewCell+Stripe_Borders.m
//  Stripe
//
//  Created by Jack Flintermann on 5/16/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "UITableViewCell+Stripe_Borders.h"

static NSInteger const STPTableViewCellTopBorderTag = 787473;
static NSInteger const STPTableViewCellBottomBorderTag = 787474;

@implementation UITableViewCell (Stripe_Borders)

- (UIView *)stp_topBorderView {
    UIView *view = [self viewWithTag:STPTableViewCellTopBorderTag];
    if (!view) {
        view = [[UIView alloc] initWithFrame:CGRectMake(0, 0.5f, self.bounds.size.width, 0.5f)];
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        view.tag = STPTableViewCellTopBorderTag;
        view.backgroundColor = self.backgroundColor;
        view.hidden = YES;
        [self addSubview:view];
    }
    return view;
}

- (UIView *)stp_bottomBorderView {
    UIView *view = [self viewWithTag:STPTableViewCellBottomBorderTag];
    if (!view) {
        view = [[UIView alloc] initWithFrame:CGRectMake(0, self.bounds.size.height - 1, self.bounds.size.width, 0.5f)];
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        view.tag = STPTableViewCellBottomBorderTag;
        view.backgroundColor = self.backgroundColor;
        view.hidden = YES;
        view.accessibilityIdentifier = @"bottomBorderView";
        [self addSubview:view];
    }
    return view;
}

- (void)stp_setBorderColor:(UIColor *)color {
    [self stp_topBorderView].backgroundColor = color;
    [self stp_bottomBorderView].backgroundColor = color;
}

- (void)stp_setTopBorderHidden:(BOOL)hidden {
    [self bringSubviewToFront:[self stp_topBorderView]];
    [self stp_topBorderView].hidden = hidden;
}

- (void)stp_setBottomBorderHidden:(BOOL)hidden {
    [self bringSubviewToFront:[self stp_bottomBorderView]];
    [self stp_bottomBorderView].hidden = hidden;
}

@end
