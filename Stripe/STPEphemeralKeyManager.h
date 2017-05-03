//
//  STPEphemeralKeyManager.h
//  Stripe
//
//  Created by Ben Guo on 5/9/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPEphemeralKeyProvider.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^STPEphemeralKeyCompletionBlock)(STPEphemeralKey * __nullable ephemeralKey, NSError * __nullable error);

@interface STPEphemeralKeyManager : NSObject

/**
 If the current ephemeral key expires in less than this time interval, a call
 to `getCustomerKey` will request a new key from the manager's key provider.
 The maximum allowed value is one hour – higher values will be clamped.
 */
@property (nonatomic, assign) NSTimeInterval expirationInterval;

/**
 Initializes a new `STPEphemeralKeyManager` with the specified key provider.

 @param keyProvider    The key provider the manager will use.
 @param apiVersion     The Stripe API version the manager will use.
 @return the newly-initiated `STPEphemeralKeyManager`.
 */
- (instancetype)initWithKeyProvider:(id<STPEphemeralKeyProvider>)keyProvider apiVersion:(NSString *)apiVersion;

/**
 If the retriever's stored customer ephemeral key has not expired, it will be
 returned immediately to the given callback. If the stored key is expiring, a
 new key will be requested from the key provider, and returned to the callback. 
 If the retriever is unable to provide an unexpired key, an error will be returned.

 @param completion The callback to be run with the returned key, or an error.
 */
- (void)getCustomerKey:(STPEphemeralKeyCompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END
