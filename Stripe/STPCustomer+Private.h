//
//  STPCustomer+Private.h
//  Stripe
//
//  Created by Ben Guo on 12/18/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPCustomer.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPCustomer ()

/**
 Replaces the customer's sources and defaultSource with the contents of a
 Customer API response.

 @param response            The Customer API response
 @param filterApplePay      If YES, Apple Pay sources will be ignored
 */
- (void)updateSourcesWithResponse:(NSDictionary *)response
                filteringApplePay:(BOOL)filterApplePay;

@end

NS_ASSUME_NONNULL_END
