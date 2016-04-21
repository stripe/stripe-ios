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

@interface STPCardPaymentMethod : NSObject <STPPaymentMethod>

@property (nonatomic, readonly) STPCard *card;

- (instancetype)initWithCard:(STPCard *)card;

@end

NS_ASSUME_NONNULL_END
