//
//  STDSConfigParameters.m
//  Stripe3DS2
//
//  Created by Cameron Sabol on 1/22/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSConfigParameters.h"

#import "STDSException+Internal.h"
#import "STDSInvalidInputException.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const kSTDSConfigDefaultGroupName = @"STDSConfigParameters.group.default";

@implementation STDSConfigParameters
{
    NSMutableDictionary *_parameters;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _parameters = [[NSMutableDictionary alloc] init];
    }

    return self;
}

- (instancetype)initWithStandardParameters {
    self = [self init];
    if (self) {
        // Nothing for now because we don't have any standard parameters
    }

    return self;
}

- (void)addParameterNamed:(NSString *)paramName withValue:(NSString *)paramValue {
    [self _addParameterNamed:paramName withValue:paramValue toGroup:kSTDSConfigDefaultGroupName];
}

- (void)addParameterNamed:(NSString *)paramName withValue:(NSString *)paramValue toGroup:(nullable NSString *)paramGroup {
    [self _addParameterNamed:paramName withValue:paramValue toGroup:paramGroup ?: kSTDSConfigDefaultGroupName];
}

- (void)_addParameterNamed:(NSString *)paramName withValue:(NSString *)paramValue toGroup:(NSString *)paramGroup {
    if (paramName == nil) {
        @throw [STDSInvalidInputException exceptionWithMessage:@"nil paramName passed to instance %@", self];
    } else if (paramValue == nil) {
        @throw [STDSInvalidInputException exceptionWithMessage:@"nil paramValue passed to instance %@", self];
    } else if (paramGroup == nil) {
        @throw [STDSInvalidInputException exceptionWithMessage:@"nil paramGroup passed to instance %@", self];
    }

    NSMutableDictionary *groupParameters = _parameters[paramGroup];
    if (groupParameters == nil) {
        groupParameters = [[NSMutableDictionary alloc] init];
        _parameters[paramGroup] = groupParameters;
    }

    if (groupParameters[paramName] != nil) {
        @throw [STDSInvalidInputException exceptionWithMessage:@"Cannot override value of %@ for parameter %@ in group %@ with value %@", groupParameters[paramName], paramName, paramGroup, paramValue];
    }

    groupParameters[paramName] = paramValue;
}

- (nullable NSString *)parameterValue:(NSString *)paramName {
    return [self _parameterValue:paramName inGroup:kSTDSConfigDefaultGroupName];
}

- (nullable NSString *)parameterValue:(NSString *)paramName inGroup:(nullable NSString *)paramGroup {
    return [self _parameterValue:paramName inGroup:paramGroup ?: kSTDSConfigDefaultGroupName];
}

- (nullable NSString *)_parameterValue:(NSString *)paramName inGroup:(NSString *)paramGroup {
    if (paramName == nil) {
        @throw [STDSInvalidInputException exceptionWithMessage:@"nil paramName passed to instance %@", self];
    } else if (paramGroup == nil) {
        @throw [STDSInvalidInputException exceptionWithMessage:@"nil paramGroup passed to instance %@", self];
    }

    NSMutableDictionary *groupParameters = _parameters[paramGroup];
    return groupParameters[paramName];
}

- (nullable NSString *)removeParameterNamed:(NSString *)paramName {
    return [self _removeParameterNamed:paramName fromGroup:kSTDSConfigDefaultGroupName];
}

- (nullable NSString *)removeParameterNamed:(NSString *)paramName fromGroup:(nullable NSString *)paramGroup {
    return [self _removeParameterNamed:paramName fromGroup:paramGroup ?: kSTDSConfigDefaultGroupName];
}

- (nullable NSString *)_removeParameterNamed:(NSString *)paramName fromGroup:(NSString *)paramGroup {
    if (paramName == nil) {
        @throw [STDSInvalidInputException exceptionWithMessage:@"nil paramName passed to instance %@", self];
    } else if (paramGroup == nil) {
        @throw [STDSInvalidInputException exceptionWithMessage:@"nil paramGroup passed to instance %@", self];
    }

    NSMutableDictionary *groupParameters = _parameters[paramGroup];
    NSString *paramValue = groupParameters[paramName];
    [groupParameters removeObjectForKey:paramName];
    return paramValue;
}

@end

NS_ASSUME_NONNULL_END
