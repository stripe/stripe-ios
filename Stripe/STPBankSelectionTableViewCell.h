//
//  STPBankSelectionTableViewCell.h
//  Stripe
//
//  Created by David Estes on 8/9/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STPFPXBankBrand.h"

@class STPTheme;

NS_ASSUME_NONNULL_BEGIN

@interface STPBankSelectionTableViewCell : UITableViewCell

- (void)configureWithBank:(STPFPXBankBrand)bankBrand theme:(STPTheme *)theme selected:(BOOL)selected offline:(BOOL)offline enabled:(BOOL)enabled;

@end

NS_ASSUME_NONNULL_END
