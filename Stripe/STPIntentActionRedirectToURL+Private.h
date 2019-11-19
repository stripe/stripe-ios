//
//  STPIntentActionRedirectToURL+Private.h
//  Stripe
//
//  Created by Cameron Sabol on 11/13/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPIntentActionRedirectToURL.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPIntentActionRedirectToURL (Private)

@property (nonatomic, readonly, nullable) NSString *threeDSSourceID;

@end

NS_ASSUME_NONNULL_END
