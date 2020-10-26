//
//  STPCardBINMetadata.h
//  Stripe
//
//  Created by Cameron Sabol on 7/17/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"

@class STPBINRange;

NS_ASSUME_NONNULL_BEGIN

@interface STPCardBINMetadata : NSObject <STPAPIResponseDecodable>

@property (nonatomic, readonly) NSArray<STPBINRange *> *ranges;

@end

NS_ASSUME_NONNULL_END
