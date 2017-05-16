//
//  STPSourcePrecheckResult.h
//  Stripe
//
//  Created by Brian Dorfman on 5/8/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const STPSourcePrecheckRequiredActionCreateThreeDSecureSource = @"create_three_d_secure_source";

@interface STPSourcePrecheckResult : NSObject <STPAPIResponseDecodable>

/**
 * Constants at top of file for known actions
 */
@property (nonatomic, nonnull, readonly) NSArray<NSString *> *requiredActions;

@property (nonatomic, nullable, readonly) NSString *reason;

@property (nonatomic, nullable, readonly) NSString *rule;

@end

NS_ASSUME_NONNULL_END
