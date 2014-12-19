//
//  STPAPIClient+CreditCards.h
//  Stripe
//
//  Created by Jack Flintermann on 12/19/14.
//  Copyright (c) 2014 Stripe, Inc. All rights reserved.
//

#import "STPAPIClient.h"
@class STPCard;

@interface STPAPIClient (CreditCards)
- (void)createTokenWithCard:(STPCard *)card completion:(STPCompletionBlock)completion;
+ (NSData *)formEncodedDataForCard:(STPCard *)card;
@end
