//
//  STDSStackView.m
//  Stripe3DS2
//
//  Created by Andrew Harrison on 2/27/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSStackView.h"
#import "STDSSpacerView.h"
#import "NSLayoutConstraint+LayoutSupport.h"

@interface STDSStackView()

@property (nonatomic) STDSStackViewLayoutAxis layoutAxis;
@property (nonatomic, strong) NSMutableArray<UIView *> *arrangedSubviews;
@property (nonatomic, strong, readonly) NSArray<UIView *> *visibleArrangedSubviews;

@end

@implementation STDSStackView

static NSString *UIViewHiddenKeyPath = @"hidden";

- (instancetype)initWithAlignment:(STDSStackViewLayoutAxis)layoutAxis {
    self = [super initWithFrame:CGRectZero];
    
    if (self) {
        _layoutAxis = layoutAxis;
        _arrangedSubviews = [NSMutableArray array];
    }
    
    return self;
}

- (NSArray<UIView *> *)visibleArrangedSubviews {
    return [self.arrangedSubviews filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(UIView *object, NSDictionary *bindings) {
        return !object.isHidden;
    }]];
}

- (void)addArrangedSubview:(UIView *)view {
    view.translatesAutoresizingMaskIntoConstraints = false;
    
    [self _deactivateExistingConstraints];
    
    [self.arrangedSubviews addObject:view];
    [self addSubview:view];
    
    [self _applyConstraints];
    
    [view addObserver:self forKeyPath:UIViewHiddenKeyPath options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
}

- (void)removeArrangedSubview:(UIView *)view {
    if (![self.arrangedSubviews containsObject:view]) {
        return;
    }
    
    [self _deactivateExistingConstraints];
    
    [view removeObserver:self forKeyPath:UIViewHiddenKeyPath];
    
    [self.arrangedSubviews removeObject:view];
    [view removeFromSuperview];
    
    [self _applyConstraints];
}

- (void)addSpacer:(CGFloat)dimension {
    STDSSpacerView *spacerView = [[STDSSpacerView alloc] initWithLayoutAxis:self.layoutAxis dimension:dimension];
    
    [self addArrangedSubview:spacerView];
}

- (void)dealloc {
    for (UIView *view in self.arrangedSubviews) {
        [view removeObserver:self forKeyPath:UIViewHiddenKeyPath];
    }
}

- (void)_applyConstraints {
    if (self.layoutAxis == STDSStackViewLayoutAxisHorizontal) {
        [self _applyHorizontalConstraints];
    } else {
        [self _applyVerticalConstraints];
    }
}

- (void)_deactivateExistingConstraints {
    [NSLayoutConstraint deactivateConstraints:self.constraints];
}

- (void)_applyVerticalConstraints {
    UIView *previousView;
    
    for (UIView *view in self.visibleArrangedSubviews) {
        NSLayoutConstraint *leftConstraint = [NSLayoutConstraint _stds_leftConstraintWithItem:view toItem:self];
        NSLayoutConstraint *rightConstraint = [NSLayoutConstraint _stds_rightConstraintWithItem:view toItem:self];
        NSLayoutConstraint *topConstraint;
        
        if (previousView == nil) {
            topConstraint = [NSLayoutConstraint _stds_topConstraintWithItem:view toItem:self];
        } else {
            topConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:previousView attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
        }
        
        [NSLayoutConstraint activateConstraints:@[topConstraint, leftConstraint, rightConstraint]];
        
        if (view == self.visibleArrangedSubviews.lastObject) {
            NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint _stds_bottomConstraintWithItem:view toItem:self];
            
            [NSLayoutConstraint activateConstraints:@[bottomConstraint]];
        }
        
        previousView = view;
    }
}

- (void)_applyHorizontalConstraints {
    UIView *previousView;
    NSLayoutConstraint *previousRightConstraint;
    
    for (UIView *view in self.visibleArrangedSubviews) {
        NSLayoutConstraint *topConstraint = [NSLayoutConstraint _stds_topConstraintWithItem:view toItem:self];
        NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint _stds_bottomConstraintWithItem:view toItem:self];
        NSLayoutConstraint *rightConstraint = [NSLayoutConstraint _stds_rightConstraintWithItem:view toItem:self];
        
        if (previousView == nil) {
            NSLayoutConstraint *leftConstraint = [NSLayoutConstraint _stds_leftConstraintWithItem:view toItem:self];
            
            [NSLayoutConstraint activateConstraints:@[topConstraint, leftConstraint, rightConstraint, bottomConstraint]];
        } else {
            NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:previousView attribute:NSLayoutAttributeRight multiplier:1 constant:0];
            
            if (previousRightConstraint != nil) {
                [NSLayoutConstraint deactivateConstraints:@[previousRightConstraint]];
            }
            
            NSLayoutConstraint *previousConstraint = [NSLayoutConstraint constraintWithItem:previousView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeLeft multiplier:1 constant:0];
            
            [NSLayoutConstraint activateConstraints:@[topConstraint, leftConstraint, rightConstraint, previousConstraint, bottomConstraint]];
        }
        
        previousView = view;
        previousRightConstraint = rightConstraint;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([object isKindOfClass:[UIView class]] && [keyPath isEqualToString:UIViewHiddenKeyPath]) {
        BOOL hiddenStatusChanged = [change[NSKeyValueChangeNewKey] boolValue] != [change[NSKeyValueChangeOldKey] boolValue];

        if (hiddenStatusChanged) {
            [self _deactivateExistingConstraints];
            
            [self _applyConstraints];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
