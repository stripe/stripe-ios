//
//  STPSourceRedirect+Private.h
//  Stripe
//
//  Created by Joey Dong on 6/21/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPSourceRedirect.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPSourceRedirect ()

+ (STPSourceRedirectStatus)statusFromString:(NSString *)string;
+ (nullable NSString *)stringFromStatus:(STPSourceRedirectStatus)status;

@end

NS_ASSUME_NONNULL_END
