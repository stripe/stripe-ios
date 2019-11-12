//
//  STPPaymentOptionTableViewCell.m
//  Stripe
//
//  Created by Ben Guo on 8/30/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentOptionTableViewCell.h"

#import "STPApplePayPaymentOption.h"
#import "STPCard.h"
#import "STPCardValidator+Private.h"
#import "STPImageLibrary+Private.h"
#import "STPLocalizationUtils.h"
#import "STPPaymentMethod.h"
#import "STPPaymentMethodCard.h"
#import "STPPaymentMethodCardParams.h"
#import "STPPaymentMethodFPX.h"
#import "STPPaymentMethodFPXParams.h"
#import "STPPaymentMethodParams.h"
#import "STPPaymentOption.h"
#import "STPSource.h"
#import "STPTheme.h"

@interface STPPaymentOptionTableViewCell ()

@property (nonatomic, strong, nullable, readwrite) id<STPPaymentOption> paymentOption;
@property (nonatomic, strong, readwrite) STPTheme *theme;

@property (nonatomic, strong, readwrite) UIImageView *leftIcon;
@property (nonatomic, strong, readwrite) UILabel *titleLabel;
@property (nonatomic, strong, readwrite) UIImageView *checkmarkIcon;

@end

static const CGFloat kDefaultIconWidth = 26.f;
static const CGFloat kPadding = 15.f;
static const CGFloat kCheckmarkWidth = 14.f;

@implementation STPPaymentOptionTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Left icon
        UIImageView *leftIcon = [[UIImageView alloc] init];
        leftIcon.translatesAutoresizingMaskIntoConstraints = NO;
        _leftIcon = leftIcon;
        [self.contentView addSubview:leftIcon];

        // Title label
        UILabel *titleLabel = [UILabel new];
        titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabel = titleLabel;
        [self.contentView addSubview:titleLabel];

        // Checkmark icon
        UIImageView *checkmarkIcon = [[UIImageView alloc] initWithImage:[STPImageLibrary checkmarkIcon]];
        checkmarkIcon.translatesAutoresizingMaskIntoConstraints = NO;
        _checkmarkIcon = checkmarkIcon;
        [self.contentView addSubview:checkmarkIcon];

        [NSLayoutConstraint activateConstraints:@[
            [self.leftIcon.centerXAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:kPadding + 0.5f*kDefaultIconWidth],
            [self.leftIcon.centerYAnchor constraintLessThanOrEqualToAnchor:self.contentView.centerYAnchor],

            [self.checkmarkIcon.widthAnchor constraintEqualToConstant:kCheckmarkWidth],
            [self.checkmarkIcon.heightAnchor constraintEqualToAnchor:self.checkmarkIcon.widthAnchor multiplier:1.f],
            [self.checkmarkIcon.centerXAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-kPadding],
            [self.checkmarkIcon.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],

            // Constrain label to leadingAnchor with the default
            // icon width so that the text always aligns vertically
            // even if the icond widths differ
            [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:2.f*kPadding + kDefaultIconWidth],
            [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.checkmarkIcon.leadingAnchor constant:-kPadding],
            [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],

        ]];
        self.isAccessibilityElement = YES;
    }
    return self;
}

- (void)configureForNewCardRowWithTheme:(STPTheme *)theme {
    self.paymentOption = nil;
    self.theme = theme;

    self.backgroundColor = theme.secondaryBackgroundColor;

    // Left icon
    self.leftIcon.image = [STPImageLibrary addIcon];
    self.leftIcon.tintColor = theme.accentColor;

    // Title label
    self.titleLabel.font = theme.font;
    self.titleLabel.textColor = theme.accentColor;
    self.titleLabel.text = STPLocalizedString(@"Add New Card…", @"Button to add a new credit card.");

    // Checkmark icon
    self.checkmarkIcon.hidden = YES;

    [self setNeedsLayout];
}

- (void)configureWithPaymentOption:(id<STPPaymentOption>)paymentOption theme:(STPTheme *)theme selected:(BOOL)selected {
    self.paymentOption = paymentOption;
    self.theme = theme;

    self.backgroundColor = theme.secondaryBackgroundColor;

    // Left icon
    self.leftIcon.image = paymentOption.templateImage;
    self.leftIcon.tintColor = [self primaryColorForPaymentOptionWithSelected:selected];

    // Title label
    self.titleLabel.font = theme.font;
    self.titleLabel.attributedText = [self buildAttributedStringWithPaymentOption:paymentOption selected:selected];

    // Checkmark icon
    self.checkmarkIcon.tintColor = theme.accentColor;
    self.checkmarkIcon.hidden = !selected;
    
    // Accessibility
    if (selected) {
        self.accessibilityTraits |= UIAccessibilityTraitSelected;
    } else {
        self.accessibilityTraits &= ~UIAccessibilityTraitSelected;
    }

    [self setNeedsLayout];
}

- (void)configureForFPXRowWithTheme:(STPTheme *)theme {
    self.paymentOption = nil;
    self.theme = theme;

    self.backgroundColor = theme.secondaryBackgroundColor;
    
    // Left icon
    self.leftIcon.image = [STPImageLibrary bankIcon];
    self.leftIcon.tintColor = [self primaryColorForPaymentOptionWithSelected:NO];

    // Title label
    self.titleLabel.font = theme.font;
    self.titleLabel.textColor = self.theme.primaryForegroundColor;
    self.titleLabel.text = STPLocalizedString(@"Online Banking (FPX)", @"Button to pay with a Bank Account (using FPX).");

    // Checkmark icon
    self.checkmarkIcon.hidden = YES;
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    [self setNeedsLayout];
}

- (UIColor *)primaryColorForPaymentOptionWithSelected:(BOOL)selected {
    UIColor *fadedColor = nil;
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        fadedColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * __unused _Nonnull traitCollection) {
            return [self.theme.primaryForegroundColor colorWithAlphaComponent:0.6f];
        }];
    } else {
#endif
        fadedColor = [self.theme.primaryForegroundColor colorWithAlphaComponent:0.6f];
#ifdef __IPHONE_13_0
    }
#endif

    return selected ? self.theme.accentColor : fadedColor;
}

- (NSAttributedString *)buildAttributedStringWithPaymentOption:(id<STPPaymentOption>)paymentOption selected:(BOOL)selected {
    if ([paymentOption isKindOfClass:[STPCard class]]) {
        return [self buildAttributedStringWithCard:(STPCard *)paymentOption selected:selected];
    } else if ([paymentOption isKindOfClass:[STPSource class]]) {
        STPSource *source = (STPSource *)paymentOption;
        if (source.type == STPSourceTypeCard
            && source.cardDetails != nil) {
            return [self buildAttributedStringWithCardSource:source selected:selected];
        }
    } else if ([paymentOption isKindOfClass:[STPPaymentMethod class]]) {
        STPPaymentMethod *paymentMethod = (STPPaymentMethod *)paymentOption;
        if (paymentMethod.type == STPPaymentMethodTypeCard
            && paymentMethod.card != nil) {
            return [self buildAttributedStringWithCardPaymentMethod:paymentMethod selected:selected];
        }
        if (paymentMethod.type == STPPaymentMethodTypeFPX
            && paymentMethod.fpx != nil) {
            return [self buildAttributedStringWithFPXBankBrand:STPFPXBankBrandFromIdentifier(paymentMethod.fpx.bankIdentifierCode) selected:selected];
        }
    } else if ([paymentOption isKindOfClass:[STPApplePayPaymentOption class]]) {
        NSString *label = STPLocalizedString(@"Apple Pay", @"Text for Apple Pay payment method");
        UIColor *primaryColor = [self primaryColorForPaymentOptionWithSelected:selected];
        return [[NSAttributedString alloc] initWithString:label attributes:@{NSForegroundColorAttributeName: primaryColor}];
    } else if ([paymentOption isKindOfClass:[STPPaymentMethodParams class]]) {
        STPPaymentMethodParams *paymentMethodParams = (STPPaymentMethodParams *)paymentOption;
        if (paymentMethodParams.type == STPPaymentMethodTypeCard
            && paymentMethodParams.card != nil) {
            return [self buildAttributedStringWithCardPaymentMethodParams:paymentMethodParams selected:selected];
        }
        if (paymentMethodParams.type == STPPaymentMethodTypeFPX
            && paymentMethodParams.fpx != nil) {
            return [self buildAttributedStringWithFPXBankBrand:paymentMethodParams.fpx.bank selected:selected];
        }
    }

    // Unrecognized payment method
    return nil;
}

- (NSAttributedString *)buildAttributedStringWithCard:(STPCard *)card selected:(BOOL)selected {
    return [self buildAttributedStringWithBrand:card.brand
                                          last4:card.last4
                                       selected:selected];
}

- (NSAttributedString *)buildAttributedStringWithCardSource:(STPSource *)card selected:(BOOL)selected {
    return [self buildAttributedStringWithBrand:card.cardDetails.brand
                                          last4:card.cardDetails.last4
                                       selected:selected];
}

- (NSAttributedString *)buildAttributedStringWithCardPaymentMethod:(STPPaymentMethod *)paymentMethod selected:(BOOL)selected {
    return [self buildAttributedStringWithBrand:paymentMethod.card.brand
                                          last4:paymentMethod.card.last4
                                       selected:selected];
}

- (NSAttributedString *)buildAttributedStringWithCardPaymentMethodParams:(STPPaymentMethodParams *)paymentMethodParams selected:(BOOL)selected {
    STPCardBrand brand = [STPCardValidator brandForNumber:paymentMethodParams.card.number];
    return [self buildAttributedStringWithBrand:brand
                                          last4:paymentMethodParams.card.last4
                                       selected:selected];
}

- (NSAttributedString *)buildAttributedStringWithFPXBankBrand:(STPFPXBankBrand)bankBrand selected:(BOOL)selected {
    NSString *label = [STPStringFromFPXBankBrand(bankBrand) stringByAppendingString:@" (FPX)"];
    UIColor *primaryColor = [self primaryColorForPaymentOptionWithSelected:selected];
    return [[NSAttributedString alloc] initWithString:label attributes:@{NSForegroundColorAttributeName: primaryColor}];
}

- (NSAttributedString *)buildAttributedStringWithBrand:(STPCardBrand)brand
                                                 last4:(NSString *)last4
                                              selected:(BOOL)selected {
    NSString *format = STPLocalizedString(@"%@ Ending In %@", @"{card brand} ending in {last4}");
    NSString *brandString = [STPCard stringFromBrand:brand];
    NSString *label = [NSString stringWithFormat:format, brandString, last4];

    UIColor *primaryColor = selected ? self.theme.accentColor : self.theme.primaryForegroundColor;
    
    UIColor *secondaryColor = nil;
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        secondaryColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * __unused _Nonnull traitCollection) {
            return [primaryColor colorWithAlphaComponent:0.6f];
        }];
    } else {
#endif
        secondaryColor = [primaryColor colorWithAlphaComponent:0.6f];
#ifdef __IPHONE_13_0
    }
#endif

    NSDictionary *attributes = @{NSForegroundColorAttributeName: secondaryColor,
                                 NSFontAttributeName: self.theme.font};

    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:label attributes:attributes];
    [attributedString addAttribute:NSForegroundColorAttributeName value:primaryColor range:[label rangeOfString:brandString]];
    [attributedString addAttribute:NSForegroundColorAttributeName value:primaryColor range:[label rangeOfString:last4]];
    [attributedString addAttribute:NSFontAttributeName value:self.theme.emphasisFont range:[label rangeOfString:brandString]];
    [attributedString addAttribute:NSFontAttributeName value:self.theme.emphasisFont range:[label rangeOfString:last4]];

    return [attributedString copy];
}

@end
