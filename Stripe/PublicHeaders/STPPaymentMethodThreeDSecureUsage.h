//
//  STPPaymentMethodThreeDSecureUsage.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/5/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Contains details on how an `STPPaymentMethodCard` maybe be used for 3D Secure authentication.
 */
@interface STPPaymentMethodThreeDSecureUsage : NSObject <STPAPIResponseDecodable>

/**
 You cannot directly instantiate an `STPPaymentMethodThreeDSecureUsage`.
 */
- (instancetype)init __attribute__((unavailable("You cannot directly instantiate an STPPaymentMethodThreeDSecureUsage.")));

/**
 `YES` if 3D Secure is supported on this card.
 */
@property (nonatomic, readonly) BOOL supported;

@end

NS_ASSUME_NONNULL_END
