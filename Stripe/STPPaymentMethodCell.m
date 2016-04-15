//
//  STPPaymentMethodCell.m
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodCell.h"
#import "STPSource.h"

@implementation STPPaymentMethodCell

- (void)configureWithSource:(id<STPSource>)source {
    if (source) {
        self.textLabel.text = source.label;
    } else {
        self.textLabel.text = @"No selected payment method";
    }
}

@end
