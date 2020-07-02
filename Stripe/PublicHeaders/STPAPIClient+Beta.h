//
//  STPAPIClient+Beta.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 6/22/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIClient.h"

NS_ASSUME_NONNULL_BEGIN

/**
 STPAPIClient category for beta support.
 */
@interface STPAPIClient (Beta)

/**
 An option set of betas to pass to the Stripe API.
 
 @warning Since these betas may have bugs, we don't recommend using this in production unless your backend can turn off your app's usage of the beta feature.
 */
@property (nonatomic) STPBeta betas;

@end

NS_ASSUME_NONNULL_END
