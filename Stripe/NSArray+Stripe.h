//
//  NSArray+Stripe.h
//  Stripe
//
//  Created by Jack Flintermann on 1/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (Stripe)

- (nullable id)stp_boundSafeObjectAtIndex:(NSInteger)index;

@end

void linkNSArrayCategory(void);
