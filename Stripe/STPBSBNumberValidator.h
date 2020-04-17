//
//  STPBSBNumberValidator.h
//  StripeiOS
//
//  Created by Cameron Sabol on 3/5/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "STPNumericStringValidator.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPBSBNumberValidator : STPNumericStringValidator

+ (STPTextValidationState)validationStateForText:(NSString *)text;

+ (nullable NSString *)formattedSantizedTextFromString:(NSString *)string;

+ (nullable NSString *)identityForText:(NSString *)text;
+ (UIImage *)iconForText:(nullable NSString *)text;

@end

NS_ASSUME_NONNULL_END
