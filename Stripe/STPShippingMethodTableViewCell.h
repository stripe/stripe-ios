//
//  STPShippingMethodTableViewCell.h
//  Stripe
//
//  Created by Ben Guo on 8/30/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STPShippingMethod.h"
#import "STPTheme.h"

@interface STPShippingMethodTableViewCell : UITableViewCell
@property(nonatomic)STPTheme *theme;
@property(nonatomic)STPShippingMethod *shippingMethod;
@end
