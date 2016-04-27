//
//  STPAnalyticsClient.h
//  Stripe
//
//  Created by Ben Guo on 4/22/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, STPTokenType) {
    STPTokenTypeCard,
    STPTokenTypeBankAccount,
    STPTokenTypeApplePay,
};

@interface STPAnalyticsClient : NSObject

+ (void)disableAnalytics;

- (void)logRUMWithTokenType:(STPTokenType)tokenType
             publishableKey:(NSString *)publishableKey
                   response:(NSHTTPURLResponse *)response
                      start:(NSDate *)startTime
                        end:(NSDate *)endTime;

@end
