//
//  STPSourceCell.m
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPSourceCell.h"
#import "STPSource.h"

@implementation STPSourceCell

- (void)configureWithSource:(id<STPSource>)source selected:(BOOL)selected {
    self.textLabel.text = source.label;
    self.imageView.image = source.image;
    self.accessoryType = selected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
}

@end
