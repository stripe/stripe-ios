//
//  STDSTextChallengeView.m
//  Stripe3DS2
//
//  Created by Andrew Harrison on 3/5/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSTextChallengeView.h"
#import "STDSStackView.h"
#import "STDSVisionSupport.h"
#import "UIView+LayoutSupport.h"
#import "NSString+EmptyChecking.h"
#import "UIColor+ThirteenSupport.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STDSTextField

static const CGFloat kTextFieldMargin = (CGFloat)8.0;

- (CGRect)textRectForBounds:(CGRect)bounds {
    return CGRectInset(bounds, kTextFieldMargin, 0);
}

- (CGRect)editingRectForBounds:(CGRect)bounds {
    return CGRectInset(bounds, kTextFieldMargin, 0);
}

- (nullable NSString *)accessibilityIdentifier {
    return @"STDSTextField";
}

@end

@interface STDSTextChallengeView() <UITextFieldDelegate>

@property (nonatomic, strong) STDSStackView *containerView;
@property (nonatomic, strong) NSLayoutConstraint *borderViewHeightConstraint;

@end

@implementation STDSTextChallengeView

static const CGFloat kBorderViewHeight = 1;
static const CGFloat kTextFieldKernSpacing = 3;
static const CGFloat kTextFieldPlaceholderKernSpacing = 14;
static const CGFloat kTextChallengeViewBottomPadding = 11;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        [self _setupViewHierarchy];
    }
    
    return self;
}

- (void)_setupViewHierarchy {
    self.layoutMargins = UIEdgeInsetsMake(0, 0, kTextChallengeViewBottomPadding, 0);

    self.containerView = [[STDSStackView alloc] initWithAlignment:STDSStackViewLayoutAxisVertical];
    
    self.textField = [[STDSTextField alloc] init];
    self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.textField.delegate = self;
    self.textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.textField.textContentType = UITextContentTypeOneTimeCode;
    [self.textField.defaultTextAttributes setValue:@(kTextFieldKernSpacing) forKey:NSKernAttributeName];

    UIView *borderView = [UIView new];
    borderView.backgroundColor = [UIColor _stds_colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
        return [[UIColor _stds_systemGray2Color] colorWithAlphaComponent:(CGFloat)0.6];
    }];
    
    [self.containerView addArrangedSubview:self.textField];
    [self.containerView addArrangedSubview:borderView];
    [self addSubview:self.containerView];
    [self.containerView _stds_pinToSuperviewBounds];
    
    self.borderViewHeightConstraint = [NSLayoutConstraint constraintWithItem:borderView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:kBorderViewHeight];
    [NSLayoutConstraint activateConstraints:@[self.borderViewHeightConstraint]];
}

- (void)setTextFieldCustomization:(STDSTextFieldCustomization * _Nullable)textFieldCustomization {
    _textFieldCustomization = textFieldCustomization;
    
    self.textField.font = textFieldCustomization.font;
    self.textField.textColor = textFieldCustomization.textColor;
    self.textField.layer.borderColor = textFieldCustomization.borderColor.CGColor;
    self.textField.layer.borderWidth = textFieldCustomization.borderWidth;
    self.textField.layer.cornerRadius = textFieldCustomization.cornerRadius;
    self.textField.keyboardAppearance = textFieldCustomization.keyboardAppearance;
    NSDictionary *placeholderTextAttributes = @{
                                                NSKernAttributeName: @(kTextFieldPlaceholderKernSpacing),
                                                NSBaselineOffsetAttributeName: @(3.0f),
                                                NSForegroundColorAttributeName: textFieldCustomization.placeholderTextColor,
                                                };
    self.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"••••••" attributes:placeholderTextAttributes];
}

- (NSString * _Nullable)inputText {
    return self.textField.text;
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    
#if !STP_TARGET_VISION
    if (self.window.screen.nativeScale > 0) {
        self.borderViewHeightConstraint.constant = kBorderViewHeight / self.window.screen.nativeScale;
    }
#endif
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return NO;
}

@end

NS_ASSUME_NONNULL_END
