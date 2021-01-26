//
//  STDSException.m
//  Stripe3DS2
//
//  Created by Cameron Sabol on 1/22/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSException.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STDSException

+ (instancetype)exceptionWithMessage:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    STDSException *exception = [[[self class] alloc] initWithName:NSStringFromClass([self class]) reason:message userInfo:nil];
    exception->_message = [message copy];
    return exception;
}

@end

NS_ASSUME_NONNULL_END
