//
//  STPLog.m
//  Stripe
//
//  Created by Joseph Gardi on 7/25/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPLog.h"

@implementation STPLog

static STPLogLevel logLevel = STPLogLevelWarning;

+(STPLogLevel)getLogLevel{
    return logLevel;
}

+(void)setLogLevel:(int)var {
    logLevel = var;
}

-(void)info:(NSString *)msg {
    printf("%s\n", [msg UTF8String]);
}
@end
