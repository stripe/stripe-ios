//
//  NSDictionary+Stripe.h
//  Stripe
//
//  Created by Jack Flintermann on 10/15/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (Stripe)

- (nullable NSDictionary *)stp_dictionaryByRemovingNullsValidatingRequiredFields:(NSArray *)requiredFields;

- (NSDictionary *)stp_dictionaryByRemovingNulls;

- (NSDictionary<NSString *, NSString *> *)stp_dictionaryByRemovingNonStrings;

@end

NS_ASSUME_NONNULL_END

void linkNSDictionaryCategory(void);
