//
//  STPSourceReceiver.h
//  Stripe
//
//  Created by Ben Guo on 1/25/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPAPIResponseDecodable.h"

/**
 *  Information related to a source's receiver flow.
 */
@interface STPSourceReceiver : NSObject<STPAPIResponseDecodable>

/**
 *  You cannot directly instantiate an `STPSourceReceiver`. You should only use one that is part of an existing `STPSource` object.
 */
- (nonnull instancetype) init __attribute__((unavailable("You cannot directly instantiate an STPSourceReceiver. You should only use one that is part of an existing STPSource object.")));

/**
 *  The address of the receiver source. This is the value that should be communicated to the customer to send their funds to.
 */
@property (nonatomic, readonly, nullable) NSString *address;

/**
 *  The total amount charged by you.
 */
@property (nonatomic, readonly, nullable) NSNumber *amountCharged;

/**
 *  The total amount received by the receiver source.
 */
@property (nonatomic, readonly, nullable) NSNumber *amountReceived;

/**
 *  The total amount that was returned to the customer.
 */
@property (nonatomic, readonly, nullable) NSNumber *amountReturned;

@end
