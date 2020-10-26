//
//  STPViewWithSeparator.m
//  StripeiOS
//
//  Created by Cameron Sabol on 3/11/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPViewWithSeparator.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STPViewWithSeparator {
    UIView *_topSeparator;
    NSLayoutConstraint *_separatorHeightConstraint;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self _addSeparators];
    }

    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self _addSeparators];
    }

    return self;
}

- (void)_addSeparators {
    UIView *topSeparator = [UIView new];
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        topSeparator.backgroundColor = [UIColor opaqueSeparatorColor];
    } else
#endif
    {
        // Fallback on earlier versions
        topSeparator.backgroundColor = [UIColor lightGrayColor];
    }

    topSeparator.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:topSeparator];

    _separatorHeightConstraint = [topSeparator.heightAnchor constraintEqualToConstant:[self _currentPixelHeight]];

    UIView *bottomSeparator = [UIView new];
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        bottomSeparator.backgroundColor = [UIColor opaqueSeparatorColor];
    } else
#endif
    {
        // Fallback on earlier versions
        bottomSeparator.backgroundColor = [UIColor lightGrayColor];
    }

    bottomSeparator.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:bottomSeparator];

    [NSLayoutConstraint activateConstraints:@[

        [topSeparator.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [topSeparator.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],

        [topSeparator.topAnchor constraintEqualToAnchor:self.topAnchor],
        _separatorHeightConstraint,

        [bottomSeparator.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [bottomSeparator.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],

        [bottomSeparator.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [bottomSeparator.heightAnchor constraintEqualToAnchor:topSeparator.heightAnchor multiplier:1.f],
    ]];

    _topSeparator = topSeparator;
}

- (void)setTopSeparatorHidden:(BOOL)topSeparatorHidden {
    _topSeparator.hidden = topSeparatorHidden;
}

- (BOOL)isTopSeparatorHidden {
    return _topSeparator.isHidden;
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    _separatorHeightConstraint.constant = [self _currentPixelHeight];
}

- (CGFloat)_currentPixelHeight {
    UIScreen *screen = self.window.screen ?: [UIScreen mainScreen];
    if (screen.nativeScale > 0) {
        return 1.f / screen.nativeScale;
    } else {
        return 0.5f;
    }
}



@end

NS_ASSUME_NONNULL_END
