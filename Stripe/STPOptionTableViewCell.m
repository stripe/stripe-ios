//
//  STPOptionTableViewCell.m
//  Stripe
//
//  Created by Ben Guo on 3/20/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPOptionTableViewCell.h"

#import "STPImageLibrary+Private.h"

@interface STPOptionTableViewCell ()

@end

@implementation STPOptionTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        UIImageView *leftIcon = [[UIImageView alloc] init];
        _leftIcon = leftIcon;
        UILabel *titleLabel = [UILabel new];
        _titleLabel = titleLabel;
        UIImageView *checkmarkIcon = [[UIImageView alloc] initWithImage:[STPImageLibrary checkmarkIcon]];
        _checkmarkIcon = checkmarkIcon;
        [self.contentView addSubview:leftIcon];
        [self.contentView addSubview:titleLabel];
        [self.contentView addSubview:checkmarkIcon];
        [self updateAppearance];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat midY = CGRectGetMidY(self.bounds);
    [self.leftIcon sizeToFit];
    CGFloat padding = 15.0f;
    CGFloat iconWidth = 26.0f;
    self.leftIcon.center = CGPointMake(padding + iconWidth/2.0f, midY);
    [self.titleLabel sizeToFit];
    self.titleLabel.center = CGPointMake(padding*2.0f + iconWidth + CGRectGetMidX(self.titleLabel.bounds), midY);
    self.checkmarkIcon.frame = CGRectMake(0, 0, 14.0f, 14.0f);
    self.checkmarkIcon.center = CGPointMake(CGRectGetWidth(self.bounds) - padding - CGRectGetMidX(self.checkmarkIcon.bounds), midY);
}

- (void)setTheme:(STPTheme *)theme {
    _theme = theme;
    [self updateAppearance];
}

- (UIColor *)colorForSelectedState:(BOOL)isSelected {
    return isSelected ? self.theme.accentColor : self.theme.primaryForegroundColor;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    [self updateAppearance];
}

- (void)updateAppearance {
    self.contentView.backgroundColor = self.theme.secondaryBackgroundColor;
    self.backgroundColor = [UIColor clearColor];
    self.titleLabel.font = self.theme.font;
    self.titleLabel.textColor = [self colorForSelectedState:self.selected];
    self.leftIcon.tintColor = [self colorForSelectedState:self.selected];
    self.checkmarkIcon.tintColor = self.theme.accentColor;
    self.checkmarkIcon.hidden = !self.selected;
}

@end
