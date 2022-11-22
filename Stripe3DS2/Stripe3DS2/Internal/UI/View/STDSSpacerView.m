//
//  STDSSpacerView.m
//  Stripe3DS2
//
//  Created by Andrew Harrison on 3/4/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSSpacerView.h"

@implementation STDSSpacerView

- (instancetype)initWithLayoutAxis:(STDSStackViewLayoutAxis)layoutAxis dimension:(CGFloat)dimension {
    self = [super initWithFrame:CGRectZero];
    
    if (self) {
        NSLayoutConstraint *constraint;

        switch (layoutAxis) {
            case STDSStackViewLayoutAxisHorizontal:
                constraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:dimension];
                break;
            case STDSStackViewLayoutAxisVertical:
                constraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:dimension];
                break;
        }
        
        [NSLayoutConstraint activateConstraints:@[constraint]];
    }
    
    return self;
}

@end
