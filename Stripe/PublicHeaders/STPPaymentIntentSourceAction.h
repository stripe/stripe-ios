//
//  STPPaymentIntentSourceAction.h
//  Stripe
//
//  Created by Daniel Jackson on 11/7/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"
#import "STPPaymentIntentEnums.h"

NS_ASSUME_NONNULL_BEGIN

@class STPPaymentIntentSourceActionAuthorizeWithURL;

/**
 Source Action details for an STPPaymentIntent. This is a container for
 the various types that are available. Check the `type` to see which one
 it is, and then use the related property for the details necessary to handle
 it.
 */
@interface STPPaymentIntentSourceAction: NSObject<STPAPIResponseDecodable>

/**
 You cannot directly instantiate an `STPPaymentIntentSourceAction`.
 */
- (instancetype)init __attribute__((unavailable("You cannot directly instantiate an STPPaymentIntentSourceAction.")));

/**
 The type of source action needed. The value of this field determines which
 property of this object contains further details about the action.
 */
@property (nonatomic, readonly) STPPaymentIntentSourceActionType type;

/**
 The details for authorizing via URL, when `type == STPPaymentIntentSourceActionTypeAuthorizeWithURL`
 */
@property (nonatomic, nullable, readonly) STPPaymentIntentSourceActionAuthorizeWithURL* authorizeWithURL;

@end

NS_ASSUME_NONNULL_END
