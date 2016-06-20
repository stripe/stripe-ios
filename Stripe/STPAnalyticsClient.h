//
//  STPAnalyticsClient.h
//  Stripe
//
//  Created by Ben Guo on 4/22/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPBlocks.h"

typedef NS_ENUM(NSUInteger, STPTokenType) {
    STPTokenTypeCard,
    STPTokenTypeBankAccount,
    STPTokenTypeApplePay,
};

typedef NS_ENUM(NSUInteger, STPAnalyticsEventType) {
    STPAnalyticsEventTypeOpen,
    STPAnalyticsEventTypeCancel,
    STPAnalyticsEventTypeSuccess,
    STPAnalyticsEventTypeError,
};

@class STPPaymentContext, STPAddCardViewController;

@interface STPAnalyticsClient : NSObject

+ (STPAnalyticsEventType)eventTypeForPaymentStatus:(STPPaymentStatus)status;

+ (instancetype)sharedClient;

+ (void)disableAnalytics;

- (void)logEvent:(STPAnalyticsEventType)event
forPaymentContext:(STPPaymentContext *)paymentContext;

- (void)logEvent:(STPAnalyticsEventType)event
forAddCardViewController:(STPAddCardViewController *)viewController;

- (void)logRUMWithTokenType:(STPTokenType)tokenType
             publishableKey:(NSString *)publishableKey
                   response:(NSHTTPURLResponse *)response
                      start:(NSDate *)startTime
                        end:(NSDate *)endTime;

@end
