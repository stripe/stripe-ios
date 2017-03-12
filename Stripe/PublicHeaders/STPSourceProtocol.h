//
//  STPSourceProtocol.h
//  Stripe
//
//  Created by Jack Flintermann on 1/15/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 *  Objects conforming to this protocol can be attached to a Stripe Customer object as a payment source.
 *  @see https://stripe.com/docs/api#customer_object-sources
 */
@protocol STPSourceProtocol <NSObject>

/**
 *  The stripe ID of the source.
 */
@property(nonatomic, readonly, copy, nonnull)NSString *stripeID;

@end
