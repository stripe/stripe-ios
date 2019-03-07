//
//  STPPaymentOptionTableViewCell.h
//  Stripe
//
//  Created by Ben Guo on 8/30/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class STPTheme;

@protocol STPPaymentOption;

NS_ASSUME_NONNULL_BEGIN

@interface STPPaymentOptionTableViewCell : UITableViewCell

- (void)configureForNewCardRowWithTheme:(STPTheme *)theme;
- (void)configureWithPaymentOption:(id<STPPaymentOption>)paymentOption theme:(STPTheme *)theme selected:(BOOL)selected;

@end

NS_ASSUME_NONNULL_END
