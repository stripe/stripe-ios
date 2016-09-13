//
//  STPShippingMethod+Private.h
//  Stripe
//
//  Created by Ben Guo on 8/31/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPShippingMethod.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPShippingMethod (Private)

- (instancetype)initWithPKShippingMethod:(PKShippingMethod *)method currency:(NSString *)currency;
- (PKShippingMethod *)pkShippingMethod;
- (NSString *)amountString;
+ (NSArray<PKShippingMethod *>*)pkShippingMethods:(nullable NSArray<STPShippingMethod *>*)methods selectedMethod:(nullable STPShippingMethod *)selectedMethod;

@end

NS_ASSUME_NONNULL_END
