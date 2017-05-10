//
//  STPResourceKeyRetriever.h
//  Stripe
//
//  Created by Ben Guo on 5/9/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPResourceKeyProvider.h"

NS_ASSUME_NONNULL_BEGIN

/**
 An `STPResourceKeyRetriever` manages retrieving and storing a resource key, 
 a short-lived API key with a specific set of permissions. If you're using 
 `STPAPIClient` methods that require a resource key, e.g. retrieving or updating 
 a Stripe customer, you can use `STPResourceKeyRetriever` to get an unexpired 
 API key before making a request.
 */
@interface STPResourceKeyRetriever : NSObject

/**
 If the current resource key expires in less than this time interval, a call
 to `retrieveResourceKey` will retrieve a new key.
 */
@property (nonatomic, assign) NSTimeInterval expirationInterval;

/**
 Initializes a new `STPResourceKeyRetriever` with the specified key provider.

 @param keyProvider    The key provider the key manager will use.
 @return the newly-initiated ResourceKeyRetriever
 */
- (instancetype)initWithKeyProvider:(id<STPResourceKeyProvider>)keyProvider;

/**
 If the retriever's stored resource key has not expired, it will be returned
 immediately to the given callback. If the stored resource key is expiring, a
 new key will be requested from the key provider, and returned to the callback. 
 If the retriever is unable to provide an unexpired key, an error will be returned.

 @param completion The callback to be run with the returned resource key, or an error.
 */
- (void)retrieveResourceKey:(STPResourceKeyCompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END
