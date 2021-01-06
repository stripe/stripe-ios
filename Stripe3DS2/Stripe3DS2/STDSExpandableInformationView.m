//
//  STDSExpandableInformationView.m
//  Stripe3DS2
//
//  Created by Andrew Harrison on 3/11/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSLocalizedString.h"
#import "STDSBundleLocator.h"
#import "STDSExpandableInformationView.h"
#import "STDSStackView.h"
#import "UIView+LayoutSupport.h"
#import "NSString+EmptyChecking.h"

NS_ASSUME_NONNULL_BEGIN

@interface STDSExpandableInformationView()

@property (nonatomic, strong) UIView *tappableView;
@property (nonatomic, strong) STDSStackView *textContainerView;
@property (nonatomic, strong) STDSStackView *imageViewStackView;
@property (nonatomic, strong) UIView *imageViewSpacerView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UIImageView *titleImageView;

@end

@implementation STDSExpandableInformationView

static const CGFloat kTitleContainerSpacing = 20;
static const CGFloat kTextContainerSpacing = 13;
static const CGFloat kExpandableInformationViewBottomMargin = 30;
static const CGFloat kTitleImageViewRotationAnimationDuration = (CGFloat)0.2;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        [self _setupViewHierarchy];
        self.accessibilityIdentifier = @"STDSExpandableInformationView";
    }
    
    return self;
}

- (void)_setupViewHierarchy {
    self.layoutMargins = UIEdgeInsetsMake(0, 0, kExpandableInformationViewBottomMargin, 0);

    self.titleLabel = [[UILabel alloc] init];
    // Set titleLabel as not an accessibility element because we make the
    // container, which is the actual control, have the same accessibility label
    // and accurately reflects that interactivity and state of the control
    self.titleLabel.isAccessibilityElement = NO;
    self.titleLabel.numberOfLines = 0;
    
    self.textLabel = [[UILabel alloc] init];
    self.textLabel.numberOfLines = 0;
    
    UIImage *chevronImage = [[UIImage imageNamed:@"Chevron" inBundle:[STDSBundleLocator stdsResourcesBundle] compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.titleImageView = [[UIImageView alloc] initWithImage:chevronImage];
    self.titleImageView.contentMode = UIViewContentModeScaleAspectFit;

    STDSStackView *containerView = [[STDSStackView alloc] initWithAlignment:STDSStackViewLayoutAxisHorizontal];
    [self addSubview:containerView];
    [containerView _stds_pinToSuperviewBounds];

    STDSStackView *titleContainerView = [[STDSStackView alloc] initWithAlignment:STDSStackViewLayoutAxisVertical];
    [titleContainerView addArrangedSubview:self.titleLabel];
    
    self.imageViewStackView = [[STDSStackView alloc] initWithAlignment:STDSStackViewLayoutAxisVertical];
    self.imageViewSpacerView = [UIView new];
    [self.imageViewStackView addArrangedSubview:self.titleImageView];
    
    [containerView addArrangedSubview:self.imageViewStackView];
    [containerView addSpacer:kTitleContainerSpacing];
    [containerView addArrangedSubview:titleContainerView];
    [containerView addArrangedSubview:[UIView new]];
    
    self.textContainerView = [[STDSStackView alloc] initWithAlignment:STDSStackViewLayoutAxisVertical];
    self.textContainerView.hidden = YES;
    [self.textContainerView addSpacer:kTextContainerSpacing];
    [self.textContainerView addArrangedSubview:self.textLabel];
    [titleContainerView addArrangedSubview:self.textContainerView];
    
    UITapGestureRecognizer *expandTextTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_toggleTextExpansion)];
    [containerView addGestureRecognizer:expandTextTapRecognizer];
    containerView.accessibilityTraits |= UIAccessibilityTraitButton;
    containerView.isAccessibilityElement = YES;
    self.tappableView = containerView;
    [self _updateTappableViewAccessibilityValue];
}

- (void)setTitle:(NSString * _Nullable)title {
    _title = title;
    
    self.titleLabel.text = title;
    self.tappableView.accessibilityLabel = title;
}

- (void)setText:(NSString * _Nullable)text {
    _text = text;
    
    self.textLabel.text = text;
}

- (void)_updateTappableViewAccessibilityValue {
    if (self.textContainerView.isHidden) {
        self.tappableView.accessibilityValue = STDSLocalizedString(@"Collapsed", @"Accessibility label for expandandable text control to indicate text is hidden.");
    } else {
        self.tappableView.accessibilityValue = STDSLocalizedString(@"Expanded", @"Accessibility label for expandandable text control to indicate that the UI has been expanded and additional text is available.");
    }
}

- (void)_toggleTextExpansion {
    if (self.didTap) {
        self.didTap();
    }
    self.textContainerView.hidden = !self.textContainerView.hidden;
    
    CGFloat rotationValue = (CGFloat)M_PI_2;
    if (self.textContainerView.isHidden) {
        rotationValue = (CGFloat)0;
        [self.imageViewStackView removeArrangedSubview:self.imageViewSpacerView];
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, self.titleLabel);
    } else {
        [self.imageViewStackView addArrangedSubview:self.imageViewSpacerView];
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, self.textLabel);
    }
    [self _updateTappableViewAccessibilityValue];
    
    [UIView animateWithDuration:kTitleImageViewRotationAnimationDuration animations:^{
        self.titleImageView.transform = CGAffineTransformMakeRotation(rotationValue);
    }];
}

- (void)setCustomization:(STDSFooterCustomization * _Nullable)customization {
    self.titleLabel.font = customization.headingFont;
    self.titleLabel.textColor = customization.headingTextColor;
    
    self.textLabel.font = customization.font;
    self.textLabel.textColor = customization.textColor;
    
    self.titleImageView.tintColor = customization.chevronColor;
}

@end

NS_ASSUME_NONNULL_END
