//
//  STPAnalyticsClient.h
//  Stripe
//
//  Created by Ben Guo on 4/22/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STPPaymentConfiguration, STPToken;
@protocol STPFormEncodable;

typedef NS_ENUM(NSUInteger, STPAddCardRememberMeUsage) {
    STPAddCardRememberMeUsageNotSelected        = 0,
    STPAddCardRememberMeUsageSelected           = 1,
    STPAddCardRememberMeUsageDeveloperDisabled  = 2,
    STPAddCardRememberMeUsageIneligible         = 3,
    STPAddCardRememberMeUsageAddedFromSMS       = 4,
};

@interface STPAnalyticsClient : NSObject

+ (instancetype)sharedClient;

+ (void)initializeIfNeeded;

+ (NSString *)tokenTypeFromParameters:(NSDictionary *)parameters;

- (void)logRememberMeConversion:(STPAddCardRememberMeUsage)selected;

- (void)logTokenCreationAttemptWithConfiguration:(STPPaymentConfiguration *)configuration
                                       tokenType:(NSString *)tokenType;

- (void)logSourceCreationAttemptWithConfiguration:(STPPaymentConfiguration *)configuration
                                       sourceType:(NSString *)sourceType;

- (void)logRUMWithToken:(STPToken *)token
          configuration:(STPPaymentConfiguration *)config
               response:(NSHTTPURLResponse *)response
                  start:(NSDate *)startTime
                    end:(NSDate *)endTime;

@end
