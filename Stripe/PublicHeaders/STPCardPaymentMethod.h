//
//  STPCardPaymentMethod.h
//  Stripe
//
//  Created by Ben Guo on 4/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPPaymentMethod.h"

NS_ASSUME_NONNULL_BEGIN

@class STPCard;

/**
 *  This represents a payment method backed by a specific card, as opposed to for example Apple Pay.
 */
@interface STPCardPaymentMethod : NSObject <STPPaymentMethod>

/**
 *  The underlying card the user has selected.
 */
@property (nonatomic, readonly) STPCard *card;

- (instancetype)initWithCard:(STPCard *)card;

@end

NS_ASSUME_NONNULL_END
