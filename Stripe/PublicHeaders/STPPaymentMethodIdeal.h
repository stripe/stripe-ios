//
//  STPPaymentMethodIdeal.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/9/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPPaymentMethodIdeal : NSObject <STPAPIResponseDecodable>

/**
 The customer’s bank.
 */
@property (nonatomic, nullable, readonly) NSString *bank;

/**
 The Bank Identifier Code of the customer’s bank.
 */
@property (nonatomic, nullable, readonly) NSString *bic;

@end

NS_ASSUME_NONNULL_END
