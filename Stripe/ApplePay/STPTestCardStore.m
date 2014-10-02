//
//  STPTestCardStore.m
//  StripeExample
//
//  Created by Jack Flintermann on 9/30/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#import "STPCard.h"
#import "STPTestCardStore.h"

@interface STPTestCardStore()
@property(nonatomic)NSArray *allItems;
@end

@implementation STPTestCardStore

@synthesize selectedItem;

+ (STPCard *)defaultCard {
    STPCard *card = [STPCard new];
    card.name = @"Stripe Test Card";
    card.number = @"4242424242424242";
    card.expMonth = 12;
    card.expYear = 2030;
    card.cvc = @"123";
    return card;
}

+ (STPCard *)defaultFailingCard {
    STPCard *card = [STPCard new];
    card.name = @"Stripe Test Failing Card";
    card.number = @"4000000000000002";
    card.expMonth = 12;
    card.expYear = 2030;
    card.cvc = @"123";
    return card;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.allItems = @[ [self.class defaultCard], [self.class defaultFailingCard] ];
        self.selectedItem = self.allItems[0];
    }
    return self;
}

- (NSArray *)descriptionsForItem:(id)item {
    STPCard *card = (STPCard *)item;
    return @[card.name, [NSString stringWithFormat:@"**** **** **** %@", card.last4]];
}

@end
