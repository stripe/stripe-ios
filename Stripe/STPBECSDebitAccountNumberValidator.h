//
//  STPBECSDebitAccountNumberValidator.h
//  StripeiOS
//
//  Created by Cameron Sabol on 3/13/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPNumericStringValidator.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPBECSDebitAccountNumberValidator: STPNumericStringValidator

+ (STPTextValidationState)validationStateForText:(NSString *)text
                                   withBSBNumber:(nullable NSString *)bsbNumber
                         completeOnMaxLengthOnly:(BOOL)completeOnMaxLengthOnly;

+ (nullable NSString *)formattedSantizedTextFromString:(NSString *)string withBSBNumber:(nullable NSString *)bsbNumber;

@end

NS_ASSUME_NONNULL_END
