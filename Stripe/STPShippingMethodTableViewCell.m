//
//  STPShippingMethodTableViewCell.m
//  Stripe
//
//  Created by Ben Guo on 8/30/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPShippingMethodTableViewCell.h"

#import "NSDecimalNumber+Stripe_Currency.h"
#import "STPImageLibrary+Private.h"
#import "STPLocalizationUtils.h"

@interface STPShippingMethodTableViewCell ()
@property(nonatomic, weak) UILabel *titleLabel;
@property(nonatomic, weak) UILabel *subtitleLabel;
@property(nonatomic, weak) UILabel *amountLabel;
@property(nonatomic, weak) UIImageView *checkmarkIcon;
@property(nonatomic)PKShippingMethod *shippingMethod;
@property(nonatomic) NSNumberFormatter *numberFormatter;
@end

@implementation STPShippingMethodTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _theme = [STPTheme new];
        UILabel *titleLabel = [UILabel new];
        _titleLabel = titleLabel;
        UILabel *subtitleLabel = [UILabel new];
        _subtitleLabel = subtitleLabel;
        UILabel *amountLabel = [UILabel new];
        _amountLabel = amountLabel;
        UIImageView *checkmarkIcon = [[UIImageView alloc] initWithImage:[STPImageLibrary checkmarkIcon]];
        _checkmarkIcon = checkmarkIcon;
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        formatter.numberStyle = NSNumberFormatterCurrencyStyle;
        formatter.usesGroupingSeparator = YES;
        _numberFormatter = formatter;
        [self.contentView addSubview:titleLabel];
        [self.contentView addSubview:subtitleLabel];
        [self.contentView addSubview:amountLabel];
        [self.contentView addSubview:checkmarkIcon];
        [self updateAppearance];
    }
    return self;
}

- (void)setTheme:(STPTheme *)theme {
    _theme = theme;
    [self updateAppearance];
}

- (void)setShippingMethod:(PKShippingMethod *)method currency:(NSString *)currency {
    _shippingMethod = method;
    self.titleLabel.text = method.label;
    self.subtitleLabel.text = method.detail;
    NSMutableDictionary<NSString *,NSString *>*localeInfo = [@{NSLocaleCurrencyCode: currency} mutableCopy];
    localeInfo[NSLocaleLanguageCode] = [[NSLocale preferredLanguages] firstObject];
    NSString *localeID = [NSLocale localeIdentifierFromComponents:localeInfo];
    NSLocale *locale = [NSLocale localeWithLocaleIdentifier:localeID];
    self.numberFormatter.locale = locale;
    NSInteger amount = [method.amount stp_amountWithCurrency:currency];
    if (amount == 0) {
        self.amountLabel.text = STPLocalizedString(@"Free", @"Label for free shipping method");
    }
    else {
        NSDecimalNumber *number = [NSDecimalNumber stp_decimalNumberWithAmount:amount
                                                                      currency:currency];
        self.amountLabel.text = [self.numberFormatter stringFromNumber:number];
    }
    [self setNeedsLayout];
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    [self updateAppearance];
}

- (void)updateAppearance {
    self.contentView.backgroundColor = self.theme.secondaryBackgroundColor;
    self.backgroundColor = [UIColor clearColor];
    self.titleLabel.font = self.theme.font;
    self.subtitleLabel.font = self.theme.smallFont;
    self.amountLabel.font = self.theme.font;
    self.titleLabel.textColor = self.selected ? self.theme.accentColor : self.theme.primaryForegroundColor;
    self.amountLabel.textColor = self.titleLabel.textColor;
    self.subtitleLabel.textColor = self.selected ? [self.theme.accentColor colorWithAlphaComponent:0.6f] : self.theme.secondaryForegroundColor;
    self.checkmarkIcon.tintColor = self.theme.accentColor;
    self.checkmarkIcon.hidden = !self.selected;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat midY = CGRectGetMidY(self.bounds);
    self.checkmarkIcon.frame = CGRectMake(0, 0, 14, 14);
    self.checkmarkIcon.center = CGPointMake(CGRectGetWidth(self.bounds) - 15 - CGRectGetMidX(self.checkmarkIcon.bounds), midY);
    [self.amountLabel sizeToFit];
    self.amountLabel.center = CGPointMake(CGRectGetMinX(self.checkmarkIcon.frame) - 15 - CGRectGetMidX(self.amountLabel.bounds), midY);
    CGFloat labelWidth = CGRectGetMinX(self.amountLabel.frame) - 30;
    [self.titleLabel sizeToFit];
    self.titleLabel.frame = CGRectMake(15, 8, labelWidth, self.titleLabel.frame.size.height);
    [self.subtitleLabel sizeToFit];
    self.subtitleLabel.frame = CGRectMake(15, self.bounds.size.height - 8 - self.subtitleLabel.frame.size.height, labelWidth, self.subtitleLabel.frame.size.height);
}

@end
