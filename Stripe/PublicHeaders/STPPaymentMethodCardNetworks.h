//
//  STPPaymentMethodCardNetworks.h
//  Stripe
//
//  Created by Cameron Sabol on 7/15/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 `STPPaymentMethodCardNetworks` contains information about card networks that can be used to process a payment.
 */
@interface STPPaymentMethodCardNetworks : NSObject <STPAPIResponseDecodable>

/**
 All available networks for the card.
 */
@property (nonatomic, nonnull, readonly) NSArray<NSString *> *available;

/**
 The preferred network for the card if one exists.
 */
@property (nonatomic, nullable, copy, readonly) NSString *preferred;

#pragma mark - Unavailable

/**
You cannot directly instantiate an `STPPaymentMethodCardNetworks` instance. You should only use one that is part of an existing `STPPaymentMethodCard` object.
*/
- (instancetype)init __attribute__((unavailable("You cannot directly instantiate an instance STPPaymentMethodCardNetworks.")));

/**
You cannot directly instantiate an `STPPaymentMethodCardNetworks` instance. You should only use one that is part of an existing `STPPaymentMethodCard` object.
*/
+ (instancetype)new __attribute__((unavailable("You cannot directly instantiate an instance STPPaymentMethodCardNetworks.")));


@end

NS_ASSUME_NONNULL_END
