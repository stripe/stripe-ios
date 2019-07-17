//
//  STPIntentAction.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 6/27/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"

@class STPIntentActionRedirectToURL, STPIntentActionRedirectToURL;

NS_ASSUME_NONNULL_BEGIN

/**
 Types of next actions for `STPPaymentIntent` and `STPSetupIntent`.
 
 You shouldn't need to inspect this yourself; `STPPaymentHandler` will handle any next actions for you.
 */
typedef NS_ENUM(NSUInteger, STPIntentActionType)  {
    
    /**
     This is an unknown action, that's been added since the SDK
     was last updated.
     Update your SDK, or use the `nextAction.allResponseFields`
     for custom handling.
     */
    STPIntentActionTypeUnknown,
    
    /**
     The payment intent needs to be authorized by the user. We provide
     `STPPaymentHandler` to handle the url redirections necessary.
     */
    STPIntentActionTypeRedirectToURL,
    
    /**
     The payment intent requires additional action handled by `STPPaymentHandler`.
     */
    STPIntentActionTypeUseStripeSDK,
    
};

/**
 Next action details for `STPPaymentIntent` and `STPSetupIntent`.
 
 This is a container for the various types that are available.
 Check the `type` to see which one it is, and then use the related
 property for the details necessary to handle it.
 */
@interface STPIntentAction : NSObject <STPAPIResponseDecodable>

/**
 You cannot directly instantiate an `STPIntentAction`.
 */
- (instancetype)init __attribute__((unavailable("You cannot directly instantiate an STPIntentAction.")));

/**
 The type of action needed. The value of this field determines which
 property of this object contains further details about the action.
 */
@property (nonatomic, readonly) STPIntentActionType type;

/**
 The details for authorizing via URL, when `type == STPIntentActionRedirectToURL`
 */
@property (nonatomic, strong, nullable, readonly) STPIntentActionRedirectToURL *redirectToURL;

#pragma mark - Deprecated

/**
 The details for authorizing via URL, when `type == STPIntentActionTypeRedirectToURL`
 
 @deprecated Use `redirectToURL` instead.
 */
@property (nonatomic, strong, nullable, readonly) STPIntentActionRedirectToURL *authorizeWithURL __attribute__((deprecated("Use `redirectToURL` instead", "redirectToURL")));

@end

NS_ASSUME_NONNULL_END
