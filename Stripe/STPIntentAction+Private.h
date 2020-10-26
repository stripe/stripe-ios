//
//  STPIntentAction+Private.h
//  Stripe
//
//  Created by Cameron Sabol on 5/22/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPIntentAction.h"

@class STPIntentActionUseStripeSDK;

NS_ASSUME_NONNULL_BEGIN

@interface STPIntentAction (Private)

@property (nonatomic, strong, nullable, readonly) STPIntentActionUseStripeSDK *useStripeSDK;

/**
 Parse the string and return the correct `STPIntentActionType`,
 or `STPIntentActionTypeUnknown` if it's unrecognized by this version of the SDK.
 
 @param string the NSString with the `next_action.type`
 */
+ (STPIntentActionType)actionTypeFromString:(NSString *)string;

/**
 Return the string representing the provided `STPIntentActionType`.
 
 @param actionType the enum value to convert to a string
 @return the string, or @"unknown" if this was an unrecognized type
 */
+ (NSString *)stringFromActionType:(STPIntentActionType)actionType;


@end

NS_ASSUME_NONNULL_END
