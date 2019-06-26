//
//  STPPaymentIntentAction+Private.h
//  Stripe
//
//  Created by Cameron Sabol on 5/22/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPPaymentIntentAction.h"

@class STPPaymentIntentActionUseStripeSDK;

NS_ASSUME_NONNULL_BEGIN

@interface STPPaymentIntentAction (Private)

@property (nonatomic, strong, nullable, readonly) STPPaymentIntentActionUseStripeSDK *useStripeSDK;

@end

NS_ASSUME_NONNULL_END
