//
//  NSArray+Stripe.h
//  Stripe
//
//  Created by Jack Flintermann on 1/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray (Stripe)

- (nullable id)stp_boundSafeObjectAtIndex:(NSInteger)index;
- (NSArray *)stp_arrayByRemovingNulls;

@end

NS_ASSUME_NONNULL_END

void linkNSArrayCategory(void);
