//
//  STPShippingAddressCell.m
//  Stripe
//
//  Created by Jack Flintermann on 4/14/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPShippingAddressCell.h"
#import "STPAddress.h"

@implementation STPShippingAddressCell

- (void)configureWithAddress:(STPAddress *)address {
    self.textLabel.text = address.line1;
}

@end
