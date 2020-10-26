//
//  STPGenericStripeObject.h
//  Stripe
//
//  Created by Daniel Jackson on 7/11/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"
#import "STPSourceProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Generic decodable Stripe object. It only has an `id`

 `STPAPIRequest` expects to be able to parse an object out of the result, otherwise
 it considers the request to have failed.
 This primarily exists to handle the response to calls like these:
 - https://stripe.com/docs/api#delete_card + https://stripe.com/docs/api#detach_source
 - https://stripe.com/docs/api#customer_delete_bank_account

 This will probably never be useful to expose publicly, the caller probably already has the
 id.
 */
@interface STPGenericStripeObject : NSObject <STPAPIResponseDecodable>

/**
 The stripe id of this object.
 */
@property (nonatomic, readonly) NSString *stripeId;

@end

NS_ASSUME_NONNULL_END
