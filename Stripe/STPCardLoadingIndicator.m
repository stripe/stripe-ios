//
//  STPCardLoadingIndicator.m
//  StripeiOS
//
//  Created by Cameron Sabol on 8/24/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPCardLoadingIndicator.h"

NS_ASSUME_NONNULL_BEGIN

static const CGFloat kCardLoadingIndicatorDiameter = 14.f;
static const CGFloat kCardLoadingInnerCircleDiameter = 10.f;
static const CFTimeInterval kLoadingAnimationSpinDuration = 0.6;

static NSString * const kLoadingAnimationIdentifier = @"STPCardLoadingIndicator.spinning";

@implementation STPCardLoadingIndicator {
    CALayer *_indicatorLayer;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:79.f/255.f green:86.f/255.f blue:107.f/255.f alpha:1.f];
        
        // Make us a circle
        CAShapeLayer *shape = [CAShapeLayer layer];
        UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(0.5f*kCardLoadingIndicatorDiameter, 0.5f*kCardLoadingIndicatorDiameter)
                                                            radius:0.5f*kCardLoadingIndicatorDiameter
                                                        startAngle:0.f
                                                          endAngle:(2.f*M_PI)
                                                         clockwise:YES];
        shape.path = path.CGPath;
        self.layer.mask = shape;
        
        // Add the inner circle
        CAShapeLayer *innerCircle = [CAShapeLayer layer];
        innerCircle.anchorPoint = CGPointMake(0.5f, 0.5f);
        innerCircle.position = CGPointMake(0.5f*kCardLoadingIndicatorDiameter, 0.5f*kCardLoadingIndicatorDiameter);

        UIBezierPath *indicatorPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(0.f, 0.f)
                                                                     radius:0.5f*kCardLoadingInnerCircleDiameter
                                                                 startAngle:0.f
                                                                   endAngle:(9.f*M_PI/6.f)
                                                                  clockwise:YES];
        innerCircle.path = indicatorPath.CGPath;
        innerCircle.strokeColor = [UIColor colorWithWhite:1.f alpha:0.8f].CGColor;
        innerCircle.fillColor = [UIColor clearColor].CGColor;
        [self.layer addSublayer:innerCircle];
        _indicatorLayer = (CALayer *)innerCircle;
    }
    
    return self;
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(kCardLoadingIndicatorDiameter, kCardLoadingIndicatorDiameter);
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    [self startAnimating];
}

- (void)startAnimating {
    CABasicAnimation *spinAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    spinAnimation.byValue = [NSNumber numberWithFloat:(float)(2.0f*M_PI)];
    spinAnimation.duration = kLoadingAnimationSpinDuration;
    spinAnimation.repeatCount = INFINITY;

    [_indicatorLayer addAnimation:spinAnimation forKey:kLoadingAnimationIdentifier];
}

- (void)stopAnimating {
    [_indicatorLayer removeAnimationForKey:kLoadingAnimationIdentifier];
}

@end

NS_ASSUME_NONNULL_END
