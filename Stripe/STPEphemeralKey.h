//
//  STPEphemeralKey.h
//  Stripe
//
//  Created by Ben Guo on 5/4/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPEphemeralKey : NSObject <STPAPIResponseDecodable>

@property (nonatomic, readonly) NSString *stripeID;
@property (nonatomic, readonly) NSDate *created;
@property (nonatomic, readonly) BOOL livemode;
@property (nonatomic, readonly) NSString *secret;
@property (nonatomic, readonly) NSDate *expires;
@property (nonatomic, readonly, nullable) NSString *customerID;
@property (nonatomic, readonly, nullable) NSString *issuingCardID;

/**
 You cannot directly instantiate an `STPEphemeralKey`. You should instead use
 `decodedObjectFromAPIResponse:` to create a key from a JSON response.
 */
- (nonnull instancetype) init __attribute__((unavailable("You cannot directly instantiate an STPEphemeralKey. You should instead use `decodedObjectFromAPIResponse:` to create a key from a JSON response.")));

@end

NS_ASSUME_NONNULL_END
