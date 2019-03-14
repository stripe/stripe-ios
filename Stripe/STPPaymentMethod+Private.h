//
//  STPPaymentMethod+Private.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/12/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethod.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPPaymentMethod ()

+ (STPPaymentMethodType)typeFromString:(NSString *)string;
+ (NSArray<NSNumber *> *)typesFromStrings:(NSArray<NSString *> *)strings;
+ (nullable NSString *)stringFromType:(STPPaymentMethodType)type;

@end

NS_ASSUME_NONNULL_END
