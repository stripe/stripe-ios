//
//  STPResourceKeyRetriever.m
//  Stripe
//
//  Created by Ben Guo on 5/9/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPResourceKeyRetriever.h"

#import "STPCustomerContext.h"
#import "STPResourceKey.h"
#import "StripeError.h"

static NSTimeInterval const DefaultExpirationInterval = 60;

@interface STPResourceKeyRetriever ()
@property (nonatomic) STPResourceKey *resourceKey;
@property (nonatomic, weak) id<STPResourceKeyProvider> keyProvider;
@end

@implementation STPResourceKeyRetriever

- (instancetype)initWithKeyProvider:(id<STPResourceKeyProvider>)keyProvider {
    self = [super init];
    if (self) {
        _expirationInterval = DefaultExpirationInterval;
        _keyProvider = keyProvider;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleWillForegroundNotification)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification
                                                  object:nil];
}

- (void)handleWillForegroundNotification {
    [self retrieveResourceKey:^(__unused STPResourceKey *resourceKey, __unused NSError *error) {
        // noop
    }];
}

- (BOOL)shouldUseCurrentResourceKey {
    return self.resourceKey && self.resourceKey.expirationDate.timeIntervalSinceNow > self.expirationInterval;
}

- (void)retrieveResourceKey:(STPResourceKeyCompletionBlock)completion {
    if ([self shouldUseCurrentResourceKey]) {
        completion(self.resourceKey, nil);
    } else {
        [self.keyProvider retrieveKey:^(STPResourceKey *resourceKey, NSError *error) {
            if (resourceKey) {
                self.resourceKey = resourceKey;
            }
            if (self.resourceKey && self.resourceKey.expirationDate.timeIntervalSinceNow > 0) {
                completion(self.resourceKey, nil);
            } else {
                completion(nil, error ?: [NSError stp_genericConnectionError]);
            }
        }];
    }
}

@end
