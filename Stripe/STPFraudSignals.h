//
//  STPFraudSignals.h
//  Stripe
//
//  Created by Ben Guo on 7/15/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STPFraudSignals : NSObject
+ (instancetype)sharedInstance;
+ (void)enable;
- (NSDictionary *)serialize;
@end
