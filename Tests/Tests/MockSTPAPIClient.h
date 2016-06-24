//
//  MockSTPAPIClient.h
//  Stripe iOS Example (Simple)
//
//  Created by Ben Guo on 3/29/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

#import <Stripe/Stripe.h>

@interface MockSTPAPIClient : STPAPIClient

@property(nonatomic, nullable)NSError *error;
@property(nonatomic, nullable)STPToken *token;

+ (nonnull instancetype)mockWithToken:(nonnull STPToken *)token;
+ (nonnull instancetype)mockWithError:(nonnull NSError *)error;

@end
