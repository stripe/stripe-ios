//
//  STPResourceKey.h
//  Stripe
//
//  Created by Ben Guo on 5/4/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"

/**
 // TODO docs
 */
@interface STPResourceKey : NSObject <STPAPIResponseDecodable>

/**
 The resource key
 */
@property (nonatomic, readonly) NSString *key;

/**
 When the key expires
 */
@property (nonatomic, readonly) NSDate *expirationDate;

@end
