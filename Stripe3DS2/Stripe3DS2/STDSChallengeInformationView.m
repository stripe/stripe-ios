//
//  STDSChallengeInformationView.m
//  Stripe3DS2
//
//  Created by Andrew Harrison on 3/4/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSChallengeInformationView.h"
#import "STDSStackView.h"
#import "STDSSpacerView.h"
#import "UIView+LayoutSupport.h"
#import "NSString+EmptyChecking.h"

NS_ASSUME_NONNULL_BEGIN

@interface STDSChallengeInformationView ()

@property (nonatomic, strong) STDSStackView *informationStackView;
@property (nonatomic, strong) STDSStackView *indicatorStackView;

@property (nonatomic, strong) UILabel *headerLabel;
@property (nonatomic, strong) UIImageView *textIndicatorImageView;
@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UILabel *informationLabel;
@property (nonatomic, strong) UIView *indicatorStackViewSpacerView;
@property (nonatomic, strong) UIView *indicatorImageTextSpacerView;

@end

@implementation STDSChallengeInformationView

static const CGFloat kHeaderTextBottomPadding = 8;
static const CGFloat kInformationTextBottomPadding = 20;
static const CGFloat kChallengeInformationViewBottomPadding = 6;
static const CGFloat kTextIndicatorHorizontalPadding = 8;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        [self _setupViewHierarchy];
    }
    
    return self;
}

- (void)setHeaderText:(NSString * _Nullable)headerText {
    _headerText = headerText;
    
    self.headerLabel.text = headerText;
    self.headerLabel.hidden = [NSString _stds_isStringEmpty:headerText];
}

- (void)setTextIndicatorImage:(UIImage * _Nullable)textIndicatorImage {
    _textIndicatorImage = textIndicatorImage;
    
    self.textIndicatorImageView.image = textIndicatorImage;
    self.textIndicatorImageView.hidden = textIndicatorImage == nil;
    self.indicatorImageTextSpacerView.hidden = textIndicatorImage == nil;
}

- (void)setChallengeInformationText:(NSString * _Nullable)challengeInformationText {
    _challengeInformationText = challengeInformationText;
    
    self.textLabel.text = challengeInformationText;
    self.textLabel.hidden = [NSString _stds_isStringEmpty:challengeInformationText];
}

- (void)setChallengeInformationLabel:(NSString * _Nullable)challengeInformationLabel {
    _challengeInformationLabel = challengeInformationLabel;
    
    self.informationLabel.text = challengeInformationLabel;
    self.informationLabel.hidden = [NSString _stds_isStringEmpty:challengeInformationLabel];
    self.indicatorStackViewSpacerView.hidden = self.informationLabel.hidden;
}

- (void)_setupViewHierarchy {
    self.layoutMargins = UIEdgeInsetsMake(0, 0, kChallengeInformationViewBottomPadding, 0);

    self.headerLabel = [self _newInformationLabel];
    
    self.textIndicatorImageView = [[UIImageView alloc] init];
    self.textIndicatorImageView.contentMode = UIViewContentModeTop;
    self.textIndicatorImageView.hidden = YES;
    
    self.textLabel = [self _newInformationLabel];
    self.informationLabel = [self _newInformationLabel];
    
    self.indicatorStackView = [[STDSStackView alloc] initWithAlignment:STDSStackViewLayoutAxisHorizontal];

    [self.indicatorStackView addArrangedSubview:self.textIndicatorImageView];
    self.indicatorImageTextSpacerView = [[STDSSpacerView alloc] initWithLayoutAxis:STDSStackViewLayoutAxisHorizontal dimension:kTextIndicatorHorizontalPadding];
    self.indicatorImageTextSpacerView.hidden = YES;
    [self.indicatorStackView addArrangedSubview:self.indicatorImageTextSpacerView];
    [self.indicatorStackView addArrangedSubview:self.textLabel];

    self.informationStackView = [[STDSStackView alloc] initWithAlignment:STDSStackViewLayoutAxisVertical];
    [self.informationStackView addArrangedSubview:self.headerLabel];
    [self.informationStackView addSpacer:kHeaderTextBottomPadding];
    [self.informationStackView addArrangedSubview:self.indicatorStackView];
    self.indicatorStackViewSpacerView = [[STDSSpacerView alloc] initWithLayoutAxis:STDSStackViewLayoutAxisVertical dimension:kInformationTextBottomPadding];
    [self.informationStackView addArrangedSubview:self.indicatorStackViewSpacerView];
    [self.informationStackView addArrangedSubview:self.informationLabel];
    
    [self addSubview:self.informationStackView];
    
    [self.informationStackView _stds_pinToSuperviewBounds];
    
    NSLayoutConstraint *imageViewWidthConstraint = [NSLayoutConstraint constraintWithItem:self.textIndicatorImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:35];
    [NSLayoutConstraint activateConstraints:@[imageViewWidthConstraint]];
}

- (void)setLabelCustomization:(STDSLabelCustomization * _Nullable)labelCustomization {
    _labelCustomization = labelCustomization;
    
    self.headerLabel.font = labelCustomization.headingFont;
    self.headerLabel.textColor = labelCustomization.headingTextColor;
    
    self.textLabel.font = labelCustomization.font;
    self.textLabel.textColor = labelCustomization.textColor;
    
    self.informationLabel.font = labelCustomization.font;
    self.informationLabel.textColor = labelCustomization.textColor;
}

- (UILabel *)_newInformationLabel {
    UILabel *label = [[UILabel alloc] init];
    label.numberOfLines = 0;
    label.hidden = YES;
    
    return label;
}

@end

NS_ASSUME_NONNULL_END
