//
//  STPOptimizationMetrics.h
//  Stripe
//
//  Created by Ben Guo on 7/15/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STPOptimizationMetrics : NSObject
+ (instancetype)sharedInstance;
- (NSDictionary *)serialize;
@end
