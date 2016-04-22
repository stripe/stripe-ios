//
//  STPAnalyticsClient.h
//  Stripe
//
//  Created by Ben Guo on 4/22/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STPAnalyticsClient : NSObject

- (void)logRUMWithTokenType:(NSString *)tokenType
                   response:(NSURLResponse *)response
                      start:(NSDate *)startTime
                        end:(NSDate *)endTime;

@end
