//
//  STPPaymentMethodThreeDSecureUsage.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/5/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface STPPaymentMethodThreeDSecureUsage : NSObject

/**
 `@YES` if 3D Secure is support on this card.
 */
@property (nonatomic, readonly) BOOL supported;

@end

NS_ASSUME_NONNULL_END
