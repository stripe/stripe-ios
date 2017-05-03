//
//  STPCustomerContext.h
//  Stripe
//
//  Created by Ben Guo on 5/2/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPBackendAPIAdapter.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPCustomerContext : NSObject <STPBackendAPIAdapter>

- (instancetype)initWithCustomerId:(NSString *)customerId
                       resourceKey:(NSString *)resourceKey;

@end

NS_ASSUME_NONNULL_END
