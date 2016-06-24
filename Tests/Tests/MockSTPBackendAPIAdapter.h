//
//  MockSTPBackendAPIAdapter.h
//  Stripe iOS Example (Simple)
//
//  Created by Ben Guo on 3/29/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Stripe/Stripe.h>

@interface MockSTPBackendAPIAdapter : NSObject <STPBackendAPIAdapter>

@property(nonatomic, nullable)NSArray<STPCard *>* cards;
@property(nonatomic, nullable)STPCard *selectedCard;

/// If set, the appropriate functions will complete with these errors
@property(nonatomic, nullable)NSError *retrieveCardsError;
@property(nonatomic, nullable)NSError *addTokenError;
@property(nonatomic, nullable)NSError *selectCardError;

@end
