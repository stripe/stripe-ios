//
//  UIColor+Stripe.m
//  Stripe
//
//  Created by Ben Guo on 4/20/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "UIColor+Stripe.h"

@implementation UIColor (Stripe)

+ (UIColor *)stp_backgroundGreyColor {
    return [UIColor colorWithRed:0.95f green:0.95f blue:0.96f alpha:1];
}

+ (UIColor *)stp_linkBlueColor {
    return [UIColor colorWithRed:0 green:122.0f/255.0f blue:1 alpha:1];
}

+ (UIColor *)stp_darkTextColor {
    return [UIColor colorWithRed:43.0f/255.0f green:43.0f/255.0f blue:45.0f/255.0f alpha:1];
}

@end
