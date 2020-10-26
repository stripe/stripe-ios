//
//  STDSConfigParameters.h
//  Stripe3DS2
//
//  Created by Cameron Sabol on 1/22/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 The default group name that will be used to group additional
 configuration parameters.
 */
extern NSString * const kSTDSConfigDefaultGroupName;

/**
 `STDSConfigParameters` represents additional configuration parameters
 that can be passed to the Stripe3DS2 SDK during initialization.

 There are currently no supported additional parameters and apps can
 just pass `[STDSConfigParameters alloc] initWithStandardParameters`
 to the `STDSThreeDS2Service` instance.
 */
@interface STDSConfigParameters : NSObject

/**
 Convenience initializer to get an `STDSConfigParameters` instance
 with the default expected configuration parameters.
 */
- (instancetype)initWithStandardParameters;

/**
 Adds the parameter to this instance.

 @param paramName The name of the parameter to add
 @param paramValue The value of the parameter to add
 @param paramGroup The group to which this parameter will be added. If `nil` the parameter will be added to `kSTDSConfigDefaultGroupName`

 @exception STDSInvalidInputException Will throw an `STDSInvalidInputException` if `paramName` or `paramValue` are `nil`. @see STDSInvalidInputException
 */
- (void)addParameterNamed:(NSString *)paramName withValue:(NSString *)paramValue toGroup:(nullable NSString *)paramGroup;

/**
 Adds the parameter to the default group in this instance.

 @param paramName The name of the parameter to add
 @param paramValue The value of the parameter to add

 @exception STDSInvalidInputException Will throw an `STDSInvalidInputException` if `paramName` or `paramValue` are `nil`. @see STDSInvalidInputException
 */
- (void)addParameterNamed:(NSString *)paramName withValue:(NSString *)paramValue;

/**
 Returns the value for `paramName` in `paramGroup` or `nil` if the parameter value is not set.

 @param paramName The name of the parameter to return
 @param paramGroup The group from which to fetch the parameter value. If `nil` will default to `kSTDSConfigDefaultGroupName`

 @exception STDSInvalidInputException Will throw an `STDSInvalidInputException` if `paramName` is `nil`. @see STDSInvalidInputException
 */
- (nullable NSString *)parameterValue:(NSString *)paramName inGroup:(nullable NSString *)paramGroup;

/**
 Returns the value for `paramName` in the default group or `nil` if the parameter value is not set.

 @param paramName The name of the parameter to return

 @exception STDSInvalidInputException Will throw an `STDSInvalidInputException` if `paramName` is `nil`. @see STDSInvalidInputException
 */
- (nullable NSString *)parameterValue:(NSString *)paramName;

/**
 Removes the specified parameter from the group and returns the value or `nil` if the parameter was not found.

 @param paramName The name of the parameter to remove
 @param paramGroup The group from which to remove this parameter. If `nil` will default to `kSTDSConfigDefaultGroupName`

 @exception STDSInvalidInputException Will throw an `STDSInvalidInputException` if `paramName` is `nil`. @see STDSInvalidInputException
 */
- (nullable NSString *)removeParameterNamed:(NSString *)paramName fromGroup:(nullable NSString *)paramGroup;

/**
 Removes the specified parameter from the default group and returns the value or `nil` if the parameter was not found.

 @param paramName The name of the parameter to remove

 @exception STDSInvalidInputException Will throw an `STDSInvalidInputException` if `paramName` is `nil`. @see STDSInvalidInputException
 */
- (nullable NSString *)removeParameterNamed:(NSString *)paramName;

@end

NS_ASSUME_NONNULL_END
