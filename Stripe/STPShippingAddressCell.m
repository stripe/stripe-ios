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
    NSArray *components = @[
                            address.name ?: @"",
                            address.line1 ?: @"",
                            address.line2 ?: @"",
                            address.city ?: @"",
                            address.state ?: @"",
                            address.postalCode ?: @"",
                            address.country ?: @"",
                            address.phone ?: @"",
                            address.email ?: @"",
                            ];
    self.textLabel.text = [[components componentsJoinedByString:@" "] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

@end
