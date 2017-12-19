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

- (NSDictionary *)stp_dictionaryByRemovingNulls;

- (NSDictionary<NSString *, NSString *> *)stp_dictionaryByRemovingNonStrings;

// Getters

- (nullable NSArray *)stp_arrayForKey:(NSString *)key;

- (BOOL)stp_boolForKey:(NSString *)key or:(BOOL)defaultValue;

- (nullable NSDate *)stp_dateForKey:(NSString *)key;

- (nullable NSDictionary *)stp_dictionaryForKey:(NSString *)key;

- (NSInteger)stp_intForKey:(NSString *)key or:(NSInteger)defaultValue;

- (nullable NSNumber *)stp_numberForKey:(NSString *)key;

- (nullable NSString *)stp_stringForKey:(NSString *)key;

- (nullable NSURL *)stp_urlForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END

void linkNSDictionaryCategory(void);
