//
//  STDSSelectionButton.h
//  Stripe3DS2
//
//  Created by Yuki Tokuhiro on 6/11/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSSelectionButton.h"

#import "STDSSelectionCustomization.h"

@interface _STDSSelectionButtonView: UIView
@property (nonatomic) BOOL isCheckbox;
@property (nonatomic) STDSSelectionCustomization *customization;
@property (nonatomic, getter = isSelected) BOOL selected;
@end

@implementation _STDSSelectionButtonView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.opaque = NO;
    }

    return self;
}

- (void)setSelected:(BOOL)selected {
    _selected = selected;
    [self setNeedsDisplay];
}


- (void)setCustomization:(STDSSelectionCustomization *)customization {
    _customization = customization;
    [self setNeedsDisplay];
}


- (void)drawRect:(CGRect)rect {
    if (self.isCheckbox) {
        [self _drawCheckboxWithRect:rect];
    } else {
        [self _drawRadioButtonWithRect:rect];
    }
}

- (void)_drawRadioButtonWithRect:(CGRect)rect {
    // Draw background
    UIBezierPath *background = [UIBezierPath bezierPathWithOvalInRect:rect];
    if (self.isSelected) {
        [self.customization.primarySelectedColor setFill];
    } else {
        [self.customization.unselectedBackgroundColor setFill];
    }
    [background fill];

    // Draw unselected border
    if (!self.isSelected) {
        UIBezierPath *border = [UIBezierPath bezierPathWithOvalInRect:CGRectInset(rect, 0.5, 0.5)];
        [self.customization.unselectedBorderColor setStroke];
        [border stroke];
    }

    // Draw inner circle if selected
    if (self.isSelected) {
        CGRect selectedRect = CGRectInset(rect, 9, 9);
        UIBezierPath *selected = [UIBezierPath bezierPathWithOvalInRect:selectedRect];
        [self.customization.secondarySelectedColor setFill];
        [selected fill];
    }
}

- (void)_drawCheckboxWithRect:(CGRect)rect {
    // Draw background
    UIBezierPath *background = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:8];
    if (self.isSelected) {
        [self.customization.primarySelectedColor setFill];
    } else {
        [self.customization.unselectedBackgroundColor setFill];
    }
    [background fill];

    // Draw unselected border
    if (!self.isSelected) {
        UIBezierPath *border = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(rect, 0.5, 0.5) cornerRadius:8];
        border.lineWidth = 0.5;
        [self.customization.unselectedBorderColor setStroke];
        [border stroke];
    }

    // Draw check mark if selected
    if (self.isSelected) {
        UIBezierPath *checkmark = [UIBezierPath bezierPath];
        [checkmark moveToPoint: CGPointMake(10, 15)];
        [checkmark addLineToPoint:CGPointMake(13.5, 18.5)];
        [checkmark addLineToPoint:CGPointMake(22, 10)];
        [self.customization.secondarySelectedColor setStroke];
        checkmark.lineWidth = 2;
        [checkmark stroke];
    }
}

@end

static const CGFloat kMinimumTouchAreaDimension = 42.f;
static const CGFloat kContentSizeDimension = 30.f;

@implementation STDSSelectionButton {
    _STDSSelectionButtonView *_contentView;
}

- (instancetype)initWithCustomization:(STDSSelectionCustomization *)customization {
    self = [super init];
    if (self) {
        _contentView = [[_STDSSelectionButtonView alloc] initWithFrame:CGRectZero];
        _contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _contentView.userInteractionEnabled = NO;
        [self addSubview:_contentView];
        self.customization = customization;
    }
    return self;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    BOOL pointInside = [super pointInside:point withEvent:event];
    if (!pointInside &&
        self.enabled &&
        !self.isHidden &&
        (CGRectGetWidth(self.bounds) < kMinimumTouchAreaDimension || CGRectGetHeight(self.bounds) < kMinimumTouchAreaDimension)
        ) {
        // Make sure that we intercept touch events even outside our bounds if they are within the
        // minimum touch area. Otherwise this button is too hard to tap
        CGRect expandedBounds = CGRectInset(self.bounds, MIN(CGRectGetWidth(self.bounds) - kMinimumTouchAreaDimension, 0), MIN(CGRectGetHeight(self.bounds) < kMinimumTouchAreaDimension, 0));
        pointInside = CGRectContainsPoint(expandedBounds, point);
    }

    return pointInside;
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(kContentSizeDimension, kContentSizeDimension);
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    _contentView.selected = selected;
}

- (void)setCustomization:(STDSSelectionCustomization *)customization {
    _contentView.customization = customization;
}

- (STDSSelectionCustomization *)customization {
    return _contentView.customization;
}

- (void)setIsCheckbox:(BOOL)isCheckbox {
    _contentView.isCheckbox = isCheckbox;
}

- (BOOL)isCheckbox {
    return _contentView.isCheckbox;
}

@end
