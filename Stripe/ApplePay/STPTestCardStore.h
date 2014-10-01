//
//  STPTestCardStore.h
//  StripeExample
//
//  Created by Jack Flintermann on 9/30/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STPCard;

@interface STPTestCardStore : NSObject

@property(nonatomic)STPCard *selectedCard;
@property(nonatomic, readonly)NSArray *allCards;

@end
