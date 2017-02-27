//
//  STPSourceVerification.h
//  Stripe
//
//  Created by Ben Guo on 1/25/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPAPIResponseDecodable.h"

/**
 *  Verification status types for a Source
 */
typedef NS_ENUM(NSInteger, STPSourceVerificationStatus) {
    STPSourceVerificationStatusPending,
    STPSourceVerificationStatusSucceeded,
    STPSourceVerificationStatusFailed,
    STPSourceVerificationStatusUnknown
};

/**
 *  Information related to a source's verification flow.
 */
@interface STPSourceVerification : NSObject<STPAPIResponseDecodable>

/**
 *  You cannot directly instantiate an `STPSourceVerification`. You should only use one that is part of an existing `STPSource` object.
 */
- (nonnull instancetype) init __attribute__((unavailable("You cannot directly instantiate an STPSourceVerification. You should only use one that is part of an existing STPSource object.")));

/**
 *  The number of attempts remaining to authenticate the source object with a verification code.
 */
@property (nonatomic, readonly, nullable) NSNumber *attemptsRemaining;

/**
 *  The status of the verification.
 */
@property (nonatomic, readonly) STPSourceVerificationStatus status;

@end
