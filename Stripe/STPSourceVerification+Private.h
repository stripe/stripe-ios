//
//  STPSourceVerification+Private.h
//  Stripe
//
//  Created by Joey Dong on 6/21/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPSourceVerification.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPSourceVerification ()

+ (STPSourceVerificationStatus)statusFromString:(NSString *)string;
+ (nullable NSString *)stringFromStatus:(STPSourceVerificationStatus)status;

@end

NS_ASSUME_NONNULL_END
