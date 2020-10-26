//
//  STPShippingMethodTableViewCell.h
//  Stripe
//
//  Created by Ben Guo on 8/30/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PassKit/PassKit.h>
#import "STPTheme.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPShippingMethodTableViewCell : UITableViewCell
@property (nonatomic) STPTheme *theme;
- (void)setShippingMethod:(PKShippingMethod *)method currency:(NSString *)currency;
@end

NS_ASSUME_NONNULL_END
