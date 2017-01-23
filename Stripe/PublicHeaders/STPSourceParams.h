//
//  STPSourceParams.h
//  Stripe
//
//  Created by Ben Guo on 1/23/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPFormEncodable.h"

/**
 *  An object representing parameters used to create a Source object. 
 *  @see https://stripe.com/docs/api#create_source
 */
@interface STPSourceParams : NSObject<STPFormEncodable>

/**
 *  The type of the source to create. Required.
 */
@property (nonatomic, copy, nullable) NSString *type;

/**
 *  A positive integer in the smallest currency unit representing the
 *  amount to charge the customer (e.g., @1099 for a €10.99 payment).
 *  Required for `single_use` sources.
 */
@property (nonatomic, copy, nullable) NSNumber *amount;

/**
 *  The currency associated with the source. This is the currency for which the source 
 *  will be chargeable once ready.
 */
@property (nonatomic, copy, nullable) NSString *currency;

/**
 *  The authentication flow of the source to create. `flow` may be "redirect",
 *  "receiver", "verification", or "none". It is generally inferred unless a type
 *  supports multiple flows.
 */
@property (nonatomic, copy, nullable) NSString *flow;

/**
 *  A set of key/value pairs that you can attach to a source object.
 */
@property (nonatomic, copy, nullable) NSDictionary *metadata;

/**
 *  Information about the owner of the payment instrument. May be used or required
 *  by particular source types.
 */
@property (nonatomic, copy, nullable) NSDictionary *owner;

/**
 *  Parameters required for the redirect flow. Required if the source is authenticated by 
 *  a redirect (`flow` is "redirect").
 */
@property (nonatomic, copy, nullable) NSDictionary *redirect;

/**
 *  An optional token used to create the source. When passed, token properties will override 
 *  source parameters.
 */
@property (nonatomic, copy, nullable) NSString *token;

/**
 *  Whether this source should be reusable or not. `usage` may be "reusable" or "single_use".
 *  Some source types may or may not be reusable by construction, while other may leave the
 *  option at creation.
 */
@property (nonatomic, copy, nullable) NSString *usage;

@end
