//
//  STPCustomerContext.m
//  Stripe
//
//  Created by Ben Guo on 5/2/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPCustomerContext.h"

#import "STPAPIClient+Private.h"
#import "STPCustomer.h"
#import "STPResourceKey.h"
#import "StripeError.h"

static NSTimeInterval const MinExpirationInterval = 60;
static NSTimeInterval const DefaultCachedCustomerMaxAge = 60;

@interface STPCustomerContext ()

@property (nonatomic) STPAPIClient *apiClient;
@property (nonatomic) STPCustomer *customer;
@property (nonatomic) NSDate *customerRetrievedDate;
@property (nonatomic) NSString *customerId;
@property (nonatomic) id<STPResourceKeyProvider> keyProvider;
@property (nonatomic) STPResourceKey *resourceKey;

@end

@implementation STPCustomerContext

- (instancetype)initWithCustomerId:(NSString *)customerId
                       keyProvider:(nonnull id<STPResourceKeyProvider>)keyProvider {
    self = [super init];
    if (self) {
        _customerId = customerId;
        _keyProvider = keyProvider;
        _cachedCustomerMaxAge = DefaultCachedCustomerMaxAge;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleWillForegroundNotification)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
        [self retrieveCustomer:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification
                                                  object:nil];
}

- (void)handleWillForegroundNotification {
    [self refreshResourceKeyIfNecessary:nil];
}

- (BOOL)needsNewResourceKey {
    return !self.resourceKey ||
        self.resourceKey.expirationDate.timeIntervalSinceNow < MinExpirationInterval;
}

- (void)refreshResourceKeyIfNecessary:(STPVoidBlock)completion {
    if (![self needsNewResourceKey]) {
        if (completion) {
            completion();
        }
    } else {
        [self.keyProvider retrieveKey:^(STPResourceKey *resourceKey, __unused NSError *error) {
            if (resourceKey) {
                self.resourceKey = resourceKey;
                self.apiClient = [[STPAPIClient alloc] initWithAPIKey:resourceKey.key];
            }
            if (completion) {
                completion();
            }
        }];
    }
}

- (BOOL)shouldUseCachedCustomer {
    if (!self.customer || !self.customerRetrievedDate) {
        return NO;
    }
    NSDate *now = [NSDate date];
    return [now timeIntervalSinceDate:self.customerRetrievedDate] < self.cachedCustomerMaxAge;
}

- (void)retrieveCustomer:(STPCustomerCompletionBlock)completion {
    if ([self shouldUseCachedCustomer]) {
        completion(self.customer, nil);
        return;
    }
    [self refreshResourceKeyIfNecessary:^{
        if (!self.apiClient) {
            if (completion) {
                completion(nil, [NSError stp_genericConnectionError]);
            }
            return;
        }
        [self.apiClient retrieveCustomerWithId:self.customerId completion:^(STPCustomer *customer, NSError *error) {
            if (customer) {
                self.customer = customer;
                self.customerRetrievedDate = [NSDate date];
            }
            if (completion) {
                completion(customer, error);
            }
        }];
    }];
}

- (void)attachSourceToCustomer:(id<STPSourceProtocol>)source completion:(STPErrorBlock)completion {
    [self refreshResourceKeyIfNecessary:^{
        if (!self.apiClient) {
            if (completion) {
                completion([NSError stp_genericConnectionError]);
            }
            return;
        }
        [self.apiClient updateCustomerWithId:self.customerId
                                addingSource:source.stripeID
                                  completion:^(STPCustomer *customer, NSError *error) {
                                      if (customer) {
                                          self.customer = customer;
                                          self.customerRetrievedDate = [NSDate date];
                                      }
                                      if (completion) {
                                          completion(error);
                                      }
                                  }];
    }];
}

- (void)selectDefaultCustomerSource:(id<STPSourceProtocol>)source completion:(STPErrorBlock)completion {
    [self refreshResourceKeyIfNecessary:^{
        if (!self.apiClient) {
            if (completion) {
                completion([NSError stp_genericConnectionError]);
            }
            return;
        }
        [self.apiClient updateCustomerWithId:self.customerId
                                  parameters:@{@"default_source": source.stripeID}
                                  completion:^(STPCustomer *customer, NSError *error) {
                                      if (customer) {
                                          self.customer = customer;
                                          self.customerRetrievedDate = [NSDate date];
                                      }
                                      if (completion) {
                                          completion(error);
                                      }
                                  }];
    }];
}

@end
