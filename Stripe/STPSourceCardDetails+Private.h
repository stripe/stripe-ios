//
//  STPSourceCardDetails+Private.h
//  Stripe
//
//  Created by Joey Dong on 6/21/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPSourceCardDetails.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPSourceCardDetails ()

+ (STPSourceCard3DSecureStatus)threeDSecureStatusFromString:(NSString *)string;
+ (nullable NSString *)stringFromThreeDSecureStatus:(STPSourceCard3DSecureStatus)threeDSecureStatus;

@end

NS_ASSUME_NONNULL_END
