//
//  STPTelemetryClient.h
//  Stripe
//
//  Created by Ben Guo on 4/18/17.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STPTelemetryClient : NSObject

+ (instancetype)sharedInstance;
- (void)addTelemetryFieldsToParams:(NSMutableDictionary *)params;
- (void)sendTelemetryData;

@end
