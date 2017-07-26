//
//  STPPaymentMethodTableViewCell.h
//  Stripe
//
//  Created by Ben Guo on 8/30/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class STPTheme;

@protocol STPPaymentMethod;

NS_ASSUME_NONNULL_BEGIN

@interface STPPaymentMethodTableViewCell : UITableViewCell

- (void)configureForNewCardRowWithTheme:(STPTheme *)theme;
- (void)configureWithPaymentMethod:(id<STPPaymentMethod>)paymentMethod theme:(STPTheme *)theme selected:(BOOL)selected;

@end

NS_ASSUME_NONNULL_END
