//
//  STPPaymentMethodTableViewCell.m
//  Stripe
//
//  Created by Ben Guo on 8/30/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodTableViewCell.h"

#import "STPCard.h"
#import "STPImageLibrary+Private.h"
#import "STPLocalizationUtils.h"
#import "STPPaymentMethod.h"
#import "STPPaymentMethodType.h"
#import "STPSource.h"

@interface STPPaymentMethodTableViewCell ()
@property(nonatomic) id<STPPaymentMethod> paymentMethod;
@end

@implementation STPPaymentMethodTableViewCell

- (void)configureWithPaymentMethod:(id<STPPaymentMethod>)paymentMethod theme:(STPTheme *)theme {
    _paymentMethod = paymentMethod;
    self.theme = theme;
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = self.theme.secondaryBackgroundColor;
    self.leftIcon.image = paymentMethod.paymentMethodTemplateImage;
    self.titleLabel.font = self.theme.font;
    self.checkmarkIcon.tintColor = self.theme.accentColor;
    self.selected = NO;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    if (self.paymentMethod != nil) {
        self.checkmarkIcon.hidden = !self.selected;
        self.leftIcon.tintColor = [self primaryColorForPaymentMethodWithSelectedState:self.selected];
        self.titleLabel.attributedText = [self buildAttributedStringForPaymentMethod:self.paymentMethod selected:self.selected];
    }
}

- (UIColor *)primaryColorForPaymentMethodWithSelectedState:(BOOL)isSelected {
    return isSelected ? self.theme.accentColor : [self.theme.primaryForegroundColor colorWithAlphaComponent:0.6f];
}

- (NSAttributedString *)buildAttributedStringForPaymentMethod:(id<STPPaymentMethod>)paymentMethod
                                                     selected:(BOOL)selected {
    if ([paymentMethod.paymentMethodType isEqual:[STPPaymentMethodType creditCard]]) {
        NSString *last4 = nil;
        NSString *cardBrand = nil;

        if ([paymentMethod isKindOfClass:[STPCard class]]) {
            STPCard *card = (STPCard *)paymentMethod;
            last4 = card.last4;
            cardBrand = [STPCard stringFromBrand:card.brand];
        }
        else if ([paymentMethod isKindOfClass:[STPSource class]]) {
            STPSource *source = (STPSource *)paymentMethod;
            last4 = source.cardDetails.last4;
            cardBrand = [STPCard stringFromBrand:source.cardDetails.brand];
        }

        if (last4 && cardBrand) {
            return [self buildAttributedStringForCardBrand:cardBrand
                                                     last4:last4
                                                  selected:selected];
        }

    }

    NSString *label = paymentMethod.paymentMethodLabel;
    UIColor *primaryColor = [self primaryColorForPaymentMethodWithSelectedState:selected];
    return [[NSAttributedString alloc] initWithString:label attributes:@{NSForegroundColorAttributeName: primaryColor}];

}

- (NSAttributedString *)buildAttributedStringForCardBrand:(NSString *)brandString
                                                    last4:(NSString *)last4
                                                 selected:(BOOL)selected {
    NSString *template = STPLocalizedString(@"%@ Ending In %@", @"{card brand} ending in {last4}");
    NSString *label = [NSString stringWithFormat:template, brandString, last4];
    UIColor *primaryColor = selected ? self.theme.accentColor : self.theme.primaryForegroundColor;
    UIColor *secondaryColor = [primaryColor colorWithAlphaComponent:0.6f];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:label attributes:@{
                                                                                                                       NSForegroundColorAttributeName: secondaryColor,
                                                                                                                       NSFontAttributeName: self.theme.font}];
    [attributedString addAttribute:NSForegroundColorAttributeName value:primaryColor range:[label rangeOfString:brandString]];
    [attributedString addAttribute:NSForegroundColorAttributeName value:primaryColor range:[label rangeOfString:last4]];
    [attributedString addAttribute:NSFontAttributeName value:self.theme.emphasisFont range:[label rangeOfString:brandString]];
    [attributedString addAttribute:NSFontAttributeName value:self.theme.emphasisFont range:[label rangeOfString:last4]];
    return [attributedString copy];
}

@end
