//
//  STPOptionTableViewCell.h
//  Stripe
//
//  Created by Ben Guo on 3/20/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STPTheme.h"

static NSString *const STPOptionCellReuseIdentifier = @"STPOptionCellReuseIdentifier";

@interface STPOptionTableViewCell : UITableViewCell

@property(nonatomic) STPTheme *theme;
@property(nonatomic, weak) UIImageView *leftIcon;
@property(nonatomic, weak) UILabel *titleLabel;
@property(nonatomic, weak) UIImageView *checkmarkIcon;

@end
