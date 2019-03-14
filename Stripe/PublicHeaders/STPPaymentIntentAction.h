//
//  STPPaymentIntentAction.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/8/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"
#import "STPPaymentIntentEnums.h"

NS_ASSUME_NONNULL_BEGIN

@class STPPaymentIntentActionRedirectToURL;

/**
 Action details for an STPPaymentIntent. This is a container for
 the various types that are available. Check the `type` to see which one
 it is, and then use the related property for the details necessary to handle it.
 */
@interface STPPaymentIntentAction : NSObject <STPAPIResponseDecodable>

/**
 You cannot directly instantiate an `STPPaymentIntentAction`.
 */
- (instancetype)init __attribute__((unavailable("You cannot directly instantiate an STPPaymentIntentAction.")));

/**
 The type of action needed. The value of this field determines which
 property of this object contains further details about the action.
 */
@property (nonatomic, readonly) STPPaymentIntentActionType type;

/**
 The details for authorizing via URL, when `type == STPPaymentIntentActionTypeRedirectToURL`
 */
@property (nonatomic, strong, nullable, readonly) STPPaymentIntentActionRedirectToURL *redirectToURL;

#pragma mark - Deprecated

/**
 The details for authorizing via URL, when `type == STPPaymentIntentActionTypeRedirectToURL`
 
 @deprecated Use `redirectToURL` instead.
 */
@property (nonatomic, strong, nullable, readonly) STPPaymentIntentActionRedirectToURL *authorizeWithURL __attribute__((deprecated("Use `redirectToURL` instead", "redirectToURL")));

@end

NS_ASSUME_NONNULL_END
