//
//  STPNumericStringValidator.h
//  StripeiOS
//
//  Created by Cameron Sabol on 3/6/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, STPTextValidationState) {
    STPTextValidationStateEmpty,
    STPTextValidationStateIncomplete,
    STPTextValidationStateComplete,
    STPTextValidationStateInvalid,
};


@interface STPNumericStringValidator : NSObject

/**
 Whether or not the target string contains only numeric characters.
 */
+ (BOOL)isStringNumeric:(NSString *)string;

/**
 Returns a copy of the passed string with all non-numeric characters removed.
 */
+ (NSString *)sanitizedNumericStringForString:(NSString *)string;

@end


NS_ASSUME_NONNULL_END
