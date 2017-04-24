//
//  STPSource+Private.h
//  Stripe
//
//  Created by Ben Guo on 2/17/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPSource.h"

@interface STPSource (Private)
+ (NSString *)stringFromType:(STPSourceType)type;
+ (STPSourceType)typeFromString:(NSString *)string;
+ (NSString *)stringFromFlow:(STPSourceFlow)flow;
+ (NSString *)stringFromUsage:(STPSourceUsage)usage;
@end


