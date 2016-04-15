//
//  STPLineItemCell.m
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPLineItemCell.h"

@implementation STPLineItemCell

- (instancetype)initWithStyle:(__unused UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    return [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
}

- (void)configureWithPaymentSummaryItem:(PKPaymentSummaryItem *)summaryItem {
    self.textLabel.text = summaryItem.label;
    self.detailTextLabel.text = summaryItem.amount.stringValue;
}

@end
