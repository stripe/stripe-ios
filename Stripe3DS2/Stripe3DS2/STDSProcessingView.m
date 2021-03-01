//
//  STDSProcessingView.m
//  Stripe3DS2
//
//  Created by Andrew Harrison on 3/19/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSProcessingView.h"
#import "STDSStackView.h"
#import "UIView+LayoutSupport.h"
#import "UIFont+DefaultFonts.h"
#import "STDSUICustomization.h"
#import "STDSBundleLocator.h"

NS_ASSUME_NONNULL_BEGIN

@interface STDSProcessingView()

@property (nonatomic, strong) STDSStackView *imageStackView;
@property (nonatomic, strong) UIView *blurViewPlaceholder;
@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation STDSProcessingView

static const CGFloat kProcessingViewHorizontalMargin = 8;
static const CGFloat kProcessingViewTopPadding = 22;
static const CGFloat kProcessingViewBottomPadding = 36;

- (instancetype)initWithCustomization:(STDSUICustomization *)customization directoryServerLogo:(nullable UIImage *)directoryServerLogo {
    self = [super initWithFrame:CGRectZero];
    
    if (self) {
        _blurViewPlaceholder = [UIView new];
        _imageView = [[UIImageView alloc] initWithImage:directoryServerLogo];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        _shouldDisplayDSLogo = YES;
        [self _setupViewHierarchyWithCustomization:customization];
    }
    
    return self;
}

- (void)setShouldDisplayBlurView:(BOOL)shouldDisplayBlurView {
    _shouldDisplayBlurView = shouldDisplayBlurView;
    self.blurViewPlaceholder.hidden = shouldDisplayBlurView;
}

- (void)setShouldDisplayDSLogo:(BOOL)shouldDisplayDSLogo {
    _shouldDisplayDSLogo = shouldDisplayDSLogo;
    self.imageView.hidden = !shouldDisplayDSLogo;
}

- (void)_setupViewHierarchyWithCustomization:(STDSUICustomization *)customization {
    self.blurViewPlaceholder.backgroundColor = customization.backgroundColor;
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:customization.blurStyle]];
    blurView.translatesAutoresizingMaskIntoConstraints = NO;

    STDSStackView *containerView = [[STDSStackView alloc] initWithAlignment:STDSStackViewLayoutAxisVertical];
    containerView.backgroundColor = customization.backgroundColor;
    containerView.layer.cornerRadius = 13;
    containerView.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:customization.activityIndicatorViewStyle];

    [self addSubview:blurView];
    [blurView.contentView addSubview:self.blurViewPlaceholder];
    [self addSubview:containerView];
    
    [self.blurViewPlaceholder _stds_pinToSuperviewBoundsWithoutMargin];
    [blurView _stds_pinToSuperviewBoundsWithoutMargin];
    
    NSLayoutConstraint *centerXConstraint = [NSLayoutConstraint constraintWithItem:containerView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0];
    NSLayoutConstraint *centerYConstraint = [NSLayoutConstraint constraintWithItem:containerView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0];
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:containerView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:1.0 constant:-kProcessingViewHorizontalMargin * 2];

    [NSLayoutConstraint activateConstraints:@[
        centerXConstraint,
        centerYConstraint,
        widthConstraint,
        [containerView.topAnchor constraintGreaterThanOrEqualToAnchor:self.topAnchor],
        [self.bottomAnchor constraintGreaterThanOrEqualToAnchor:containerView.bottomAnchor],
    ]];
    
    [containerView addSpacer:kProcessingViewTopPadding];
    [containerView addArrangedSubview:self.imageView];
    [containerView addSpacer:20];
    [containerView addArrangedSubview:indicatorView];
    [containerView addSpacer:kProcessingViewBottomPadding];
    
    [indicatorView startAnimating];
}

@end

NS_ASSUME_NONNULL_END
