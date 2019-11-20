//
//  STPKlarnaLineItem.m
//  Stripe
//
//  Created by David Estes on 11/19/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPKlarnaLineItem.h"

@implementation STPKlarnaLineItem

- (instancetype)initWithItemType:(STPKlarnaLineItemType)itemType itemDescription:(NSString *)itemDescription quantity:(NSNumber *)quantity totalAmount:(NSNumber *)totalAmount {
    self = [self init];
    if (self) {
        self.itemType = itemType;
        self.itemDescription = itemDescription;
        self.quantity = quantity;
        self.totalAmount = totalAmount;
    }
    return self;
}

@end
