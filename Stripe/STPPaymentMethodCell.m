//
//  STPSourceCell.m
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodCell.h"
#import "STPSource.h"
#import "STPPaymentMethod.h"

@implementation STPPaymentMethodCell

- (void)configureWithPaymentMethod:(id<STPPaymentMethod>)paymentMethod selected:(BOOL)selected {
    self.textLabel.text = paymentMethod.label;
    self.imageView.image = paymentMethod.image;
    self.accessoryType = selected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
}

@end
