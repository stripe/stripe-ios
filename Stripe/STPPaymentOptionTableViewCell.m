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
#import "STPImageLibrary+Private.h"
#import "STPLocalizationUtils.h"
#import "STPPaymentMethod.h"
#import "STPPaymentMethodCard.h"
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

@implementation STPPaymentOptionTableViewCell

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

        // Checkmark icon
        UIImageView *checkmarkIcon = [[UIImageView alloc] initWithImage:[STPImageLibrary checkmarkIcon]];
        _checkmarkIcon = checkmarkIcon;
        [self.contentView addSubview:checkmarkIcon];
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

    // Checkmark icon
    self.checkmarkIcon.frame = CGRectMake(0.0, 0.0, 14.0f, 14.0f);
    self.checkmarkIcon.center = CGPointMake(CGRectGetWidth(self.bounds) - padding - CGRectGetMidX(self.checkmarkIcon.bounds), midY);

    // Title label
    CGRect labelFrame = self.bounds;
    // not every icon is `iconWidth` wide, but give them all the same amount of space:
    labelFrame.origin.x = padding + iconWidth + padding;
    labelFrame.size.width = CGRectGetMinX(self.checkmarkIcon.frame) - padding - labelFrame.origin.x;
    self.titleLabel.frame = labelFrame;
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

    [self setNeedsLayout];
}

- (UIColor *)primaryColorForPaymentOptionWithSelected:(BOOL)selected {
    return selected ? self.theme.accentColor : [self.theme.primaryForegroundColor colorWithAlphaComponent:0.6f];
}

- (NSAttributedString *)buildAttributedStringWithPaymentOption:(id<STPPaymentOption>)paymentOption selected:(BOOL)selected {
    if ([paymentOption isKindOfClass:[STPCard class]]) {
        return [self buildAttributedStringWithCard:(STPCard *)paymentOption selected:selected];
    }
    else if ([paymentOption isKindOfClass:[STPSource class]]) {
        STPSource *source = (STPSource *)paymentOption;
        if (source.type == STPSourceTypeCard
            && source.cardDetails != nil) {
            return [self buildAttributedStringWithCardSource:source selected:selected];
        }
    }
    else if ([paymentOption isKindOfClass:[STPPaymentMethod class]]) {
        STPPaymentMethod *paymentMethod = (STPPaymentMethod *)paymentOption;
        if (paymentMethod.type == STPPaymentMethodTypeCard
            && paymentMethod.card != nil) {
            return [self buildAttributedStringWithCardPaymentMethod:paymentMethod selected:selected];
        }
    }
    else if ([paymentOption isKindOfClass:[STPApplePayPaymentOption class]]) {
        NSString *label = STPLocalizedString(@"Apple Pay", @"Text for Apple Pay payment method");
        UIColor *primaryColor = [self primaryColorForPaymentOptionWithSelected:selected];
        return [[NSAttributedString alloc] initWithString:label attributes:@{NSForegroundColorAttributeName: primaryColor}];
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

- (NSAttributedString *)buildAttributedStringWithBrand:(STPCardBrand)brand
                                                 last4:(NSString *)last4
                                              selected:(BOOL)selected {
    NSString *format = STPLocalizedString(@"%@ Ending In %@", @"{card brand} ending in {last4}");
    NSString *brandString = [STPCard stringFromBrand:brand];
    NSString *label = [NSString stringWithFormat:format, brandString, last4];

    UIColor *primaryColor = selected ? self.theme.accentColor : self.theme.primaryForegroundColor;
    UIColor *secondaryColor = [primaryColor colorWithAlphaComponent:0.6f];

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
