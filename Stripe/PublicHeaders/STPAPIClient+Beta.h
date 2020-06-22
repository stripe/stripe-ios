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
 
 @warning Setting this property is not sufficient to participate in a beta, and passing a beta you are not registered in will result in API errors.
 */
@property (nonatomic) STPBeta betas;

@end

NS_ASSUME_NONNULL_END
