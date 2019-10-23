//
//  STPBankSelectionTableViewCell.m
//  Stripe
//
//  Created by David Estes on 8/9/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPBankSelectionTableViewCell.h"

#import "STPApplePayPaymentOption.h"
#import "STPCard.h"
#import "STPImageLibrary+Private.h"
#import "STPSource.h"
#import "STPLocalizationUtils.h"
#import "STPTheme.h"

@interface STPBankSelectionTableViewCell ()

@property (nonatomic, readwrite) STPFPXBankBrand bank;
@property (nonatomic, strong, readwrite) STPTheme *theme;

@property (nonatomic, strong, readwrite) UIImageView *leftIcon;
@property (nonatomic, strong, readwrite) UILabel *titleLabel;
@property (nonatomic, strong, readwrite) UIActivityIndicatorView *activityIndicator;

@end

@implementation STPBankSelectionTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Left icon
        UIImageView *leftIcon = [[UIImageView alloc] init];
        _leftIcon = leftIcon;
        [self.contentView addSubview:leftIcon];

        // Title label
        UILabel *titleLabel = [UILabel new];
        _titleLabel = titleLabel;
        [self.contentView addSubview:titleLabel];

        // Loading indicator
        UIActivityIndicatorView *activityIndicator = nil;
#ifdef __IPHONE_13_0
        if (@available(iOS 13.0, *)) {
            activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
        } else {
#endif
#if !(defined(TARGET_OS_MACCATALYST) && (TARGET_OS_MACCATALYST != 0))
            activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
#endif
#ifdef __IPHONE_13_0
        }
#endif
        _activityIndicator = activityIndicator;
        _activityIndicator.hidesWhenStopped = YES;
        [self.contentView addSubview:activityIndicator];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat midY = CGRectGetMidY(self.bounds);
    CGFloat padding = 15.0;
    CGFloat iconWidth = 26.0;

    // Left icon
    [self.leftIcon sizeToFit];
    self.leftIcon.center = CGPointMake(padding + (iconWidth / 2.0f), midY);

    // Activity indicator
    self.activityIndicator.center = CGPointMake(CGRectGetWidth(self.bounds) - padding - CGRectGetMidX(self.activityIndicator.bounds), midY);

    // Title label
    CGRect labelFrame = self.bounds;
    // not every icon is `iconWidth` wide, but give them all the same amount of space:
    labelFrame.origin.x = padding + iconWidth + padding;
    labelFrame.size.width = CGRectGetMinX(self.activityIndicator.frame) - padding - labelFrame.origin.x;
    self.titleLabel.frame = labelFrame;
}

- (void)configureWithBank:(STPFPXBankBrand)bankBrand theme:(STPTheme *)theme selected:(BOOL)selected offline:(BOOL)offline enabled:(BOOL)enabled {
    self.bank = bankBrand;
    self.theme = theme;

    self.backgroundColor = theme.secondaryBackgroundColor;

    // Left icon
    self.leftIcon.image = [STPImageLibrary brandImageForFPXBankBrand:self.bank];
    self.leftIcon.tintColor = [self primaryColorForPaymentOptionWithSelected:selected enabled: enabled];

    // Title label
    self.titleLabel.font = theme.font;
    self.titleLabel.text = STPStringFromFPXBankBrand(self.bank);
    if (offline) {
        NSString *format = STPLocalizedString(@"%@ - Offline", @"Bank name when bank is offline for maintenance.");
        self.titleLabel.text = [NSString stringWithFormat:format, STPStringFromFPXBankBrand(self.bank)];
    }
    self.titleLabel.textColor = [self primaryColorForPaymentOptionWithSelected:self.selected enabled:enabled];

    // Loading indicator
    self.activityIndicator.tintColor = theme.accentColor;
    if (selected) {
        [self.activityIndicator startAnimating];
    } else {
        [self.activityIndicator stopAnimating];
    }
    
    [self setNeedsLayout];
}

- (UIColor *)primaryColorForPaymentOptionWithSelected:(BOOL)selected enabled:(BOOL)enabled {
    if (selected) {
        return self.theme.accentColor;
    } else {
        return enabled ? self.theme.primaryForegroundColor : [self.theme.primaryForegroundColor colorWithAlphaComponent:0.6f];
    }
}


@end
