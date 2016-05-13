//
//  STPSwitchTableViewCell.m
//  Stripe
//
//  Created by Jack Flintermann on 5/6/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPSwitchTableViewCell.h"

@interface STPSwitchTableViewCell()

@property(nonatomic, weak)UILabel *captionLabel;
@property(nonatomic, weak)UISwitch *switchView;
@property(nonatomic, weak)id<STPSwitchTableViewCellDelegate> delegate;

@end

@implementation STPSwitchTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        UISwitch *switchView = [[UISwitch alloc] init];
        [self addSubview:switchView];
        [switchView addTarget:self action:@selector(switchToggled:) forControlEvents:UIControlEventValueChanged];
        _switchView = switchView;
        
        UILabel *captionLabel = [[UILabel alloc] init];
        [self addSubview:captionLabel];
        _captionLabel = captionLabel;
        _theme = [STPTheme new];
        [self updateAppearance];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat padding = 15;
    self.switchView.center = CGPointMake(self.bounds.size.width - (self.switchView.bounds.size.width / 2) - padding, self.bounds.size.height / 2);
    self.captionLabel.frame = CGRectMake(padding, 0, CGRectGetMinX(self.switchView.frame) - padding, self.bounds.size.height);
}

- (void)switchToggled:(UISwitch *)sender {
    [self.delegate switchTableViewCell:self didToggleSwitch:sender.on];
}

- (void)updateAppearance {
    self.switchView.tintColor = self.theme.primaryBackgroundColor;
    self.switchView.onTintColor = self.theme.accentColor;
    self.captionLabel.font = self.theme.font;
    self.backgroundColor = self.theme.secondaryBackgroundColor;
    self.captionLabel.textColor = self.theme.secondaryTextColor;
}

- (void)configureWithLabel:(NSString *)label
                  delegate:(id<STPSwitchTableViewCellDelegate>)delegate {
    self.captionLabel.text = label;
    self.delegate = delegate;
}

- (void)setSelected:(__unused BOOL)selected animated:(__unused BOOL)animated {
}

- (BOOL)on {
    return self.switchView.on;
}

@end
