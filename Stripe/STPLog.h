//
//  STPLog.h
//  Stripe
//
//  Created by Joseph Gardi on 7/25/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#ifndef STPLog_h
#define STPLog_h

typedef NS_ENUM(NSUInteger, STPLogLevel) {
    /**
     The highest logging level
     */
    STPLogLevelDebug,
    /**
     Log all the important events that you might care about such as authorization from a user, a call to a delegate method, or a successful payment
     */
    STPLogLevelInfo,
    /**
     The default log level
     */
    STPLogLevelWarning,
    STPLogLevelError
};

@interface STPLog : NSObject
+(void)setLogLevel:(int)var;
+(STPLogLevel)getLogLevel;
-(void)info:(NSString *)msg;
@end
#endif /* STPLog_h */
