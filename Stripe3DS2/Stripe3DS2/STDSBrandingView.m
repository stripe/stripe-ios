//
//  STDSBrandingView.m
//  Stripe3DS2
//
//  Created by Andrew Harrison on 2/27/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSBrandingView.h"
#import "STDSStackView.h"
#import "UIView+LayoutSupport.h"
#import "STDSVisionSupport.h"

NS_ASSUME_NONNULL_BEGIN

@interface STDSBrandingView()

@property (nonatomic, strong) STDSStackView *stackView;

@property (nonatomic, strong) UIImageView *issuerImageView;
@property (nonatomic, strong) UIImageView *paymentSystemImageView;

@property (nonatomic, strong) UIView *issuerView;
@property (nonatomic, strong) UIView *paymentSystemView;

@end

@implementation STDSBrandingView

static const CGFloat kBrandingViewBottomPadding = 24;
static const CGFloat kBrandingViewSpacing = 16;
#if !STP_TARGET_VISION
static const CGFloat kImageViewBorderWidth = 1;
#endif
static const CGFloat kImageViewHorizontalInset = 7;
static const CGFloat kImageViewVerticalInset = 19;
static const CGFloat kImageViewCornerRadius = 6;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        [self _setupViewHierarchy];
    }
    
    return self;
}

- (void)setPaymentSystemImage:(UIImage *)paymentSystemImage {
    _paymentSystemImage = paymentSystemImage;
    
    self.paymentSystemImageView.image = paymentSystemImage;
}

- (void)setIssuerImage:(UIImage *)issuerImage {
    _issuerImage = issuerImage;
    
    self.issuerImageView.image = issuerImage;
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    
#if !STP_TARGET_VISION
    if (self.window.screen.nativeScale > 0) {
        self.issuerView.layer.borderWidth = kImageViewBorderWidth / self.window.screen.nativeScale;
        self.paymentSystemView.layer.borderWidth = kImageViewBorderWidth / self.window.screen.nativeScale;
    }
#endif
}

- (void)_setupViewHierarchy {
    self.layoutMargins = UIEdgeInsetsMake(0, 0, kBrandingViewBottomPadding, 0);
    
    self.stackView = [[STDSStackView alloc] initWithAlignment:STDSStackViewLayoutAxisHorizontal];
    [self addSubview:self.stackView];
    
    [self.stackView _stds_pinToSuperviewBounds];
    
    self.issuerImageView = [self _newBrandingImageView];
    self.issuerView = [self _newInsetViewWithImageView:self.issuerImageView];
    [self.stackView addArrangedSubview:self.issuerView];
    
    [self.stackView addSpacer:kBrandingViewSpacing];
    
    self.paymentSystemImageView = [self _newBrandingImageView];
    self.paymentSystemView = [self _newInsetViewWithImageView:self.paymentSystemImageView];
    [self.stackView addArrangedSubview:self.paymentSystemView];
    
    NSLayoutConstraint *imageViewWidthConstraint = [NSLayoutConstraint constraintWithItem:self.issuerView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:0.5 constant:0];
    // Setting the priority of the width constraint, so that the priority of the equal widths constraint below takes precedence, allowing both image views to take half of the remaining space equally.
    imageViewWidthConstraint.priority = UILayoutPriorityDefaultHigh;
    NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:self.paymentSystemView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.issuerView attribute:NSLayoutAttributeWidth multiplier:1 constant:0];

    [NSLayoutConstraint activateConstraints:@[imageViewWidthConstraint, width]];
}

- (UIView *)_newInsetViewWithImageView:(UIImageView *)imageView {
    UIView *insetView = [UIView new];
    insetView.layoutMargins = UIEdgeInsetsMake(kImageViewHorizontalInset, kImageViewVerticalInset, kImageViewHorizontalInset, kImageViewVerticalInset);
    insetView.layer.cornerRadius = kImageViewCornerRadius;
    insetView.backgroundColor = [UIColor whiteColor]; // Issuer images always expect a white background.
    insetView.layer.masksToBounds = YES;
    insetView.layer.borderColor = (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight) ?
    [UIColor colorWithRed:(CGFloat)0.0 green:(CGFloat)57.0/(CGFloat)255.0 blue:(CGFloat)69.0/(CGFloat)255.0 alpha:(CGFloat)0.25].CGColor :
    [UIColor colorWithRed:(CGFloat)195.0/(CGFloat)255.0 green:(CGFloat)214.0/(CGFloat)255.0 blue:(CGFloat)218.0/(CGFloat)255.0 alpha:(CGFloat)0.25].CGColor;

    [insetView addSubview:imageView];
    [imageView _stds_pinToSuperviewBounds];
    
    return insetView;
}

- (UIImageView *)_newBrandingImageView {
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    return imageView;
}

#if !STP_TARGET_VISION
- (void)traitCollectionDidChange:(UITraitCollection * _Nullable)previousTraitCollection {
    CGColorRef borderColor = (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight) ?
    [UIColor colorWithRed:(CGFloat)0.0 green:(CGFloat)57.0/(CGFloat)255.0 blue:(CGFloat)69.0/(CGFloat)255.0 alpha:(CGFloat)0.25].CGColor :
    [UIColor colorWithRed:(CGFloat)195.0/(CGFloat)255.0 green:(CGFloat)214.0/(CGFloat)255.0 blue:(CGFloat)218.0/(CGFloat)255.0 alpha:(CGFloat)0.25].CGColor;
    self.issuerView.layer.borderColor = borderColor;
    self.paymentSystemView.layer.borderColor = borderColor;
}
#endif

@end

NS_ASSUME_NONNULL_END
