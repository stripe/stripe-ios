//
//  STPShippingAddressCell.h
//  Stripe
//
//  Created by Jack Flintermann on 4/14/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class STPAddress;

@interface STPShippingAddressCell : UITableViewCell

- (void)configureWithAddress:(STPAddress *)address;

@end
