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
 A set of beta headers to add to Stripe API requests e.g. `[NSSet setWithArray:@[@"alipay_beta=v1"]]`
 */
@property (nonatomic) NSSet<NSString *> *betas;

@end

NS_ASSUME_NONNULL_END
