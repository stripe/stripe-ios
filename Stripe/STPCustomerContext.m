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

static NSTimeInterval const MinResourceKeyExpirationInterval = 60;
static NSTimeInterval const DefaultCachedCustomerMaxAge = 60;

@interface STPCustomerContext ()

@property (nonatomic) STPAPIClient *apiClient;
@property (nonatomic) STPCustomer *customer;
@property (nonatomic) NSDate *customerRetrievedDate;
@property (nonatomic) NSString *customerId;
@property (nonatomic, weak) id<STPResourceKeyProvider> keyProvider;
@property (nonatomic) STPResourceKey *resourceKey;

@end

@implementation STPCustomerContext

- (instancetype)initWithCustomerId:(NSString *)customerId
                       keyProvider:(nonnull id<STPResourceKeyProvider>)keyProvider {
    STPAPIClient *apiClient = [[STPAPIClient alloc] initWithAPIKey:nil];
    return [self initWithCustomerId:customerId keyProvider:keyProvider apiClient:apiClient];
}

- (instancetype)initWithCustomerId:(NSString *)customerId
                       keyProvider:(nonnull id<STPResourceKeyProvider>)keyProvider
                         apiClient:(STPAPIClient *)apiClient {
    self = [super init];
    if (self) {
        _customerId = customerId;
        _keyProvider = keyProvider;
        _apiClient = apiClient;
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
        self.resourceKey.expirationDate.timeIntervalSinceNow < MinResourceKeyExpirationInterval;
}

- (BOOL)resourceKeyHasExpired {
    return !self.resourceKey || self.resourceKey.expirationDate.timeIntervalSinceNow <= 0;
}

- (void)refreshResourceKeyIfNecessary:(STPErrorBlock)completion {
    if (![self needsNewResourceKey]) {
        if (completion) {
            completion(nil);
        }
    } else {
        [self.keyProvider retrieveKey:^(STPResourceKey *resourceKey, NSError *error) {
            if (resourceKey) {
                self.resourceKey = resourceKey;
                self.apiClient.apiKey = resourceKey.key;
            }
            if (completion) {
                completion(error);
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
        if (completion) {
            completion(self.customer, nil);
        }
        return;
    }
    [self refreshResourceKeyIfNecessary:^(NSError *refreshKeyError){
        if (refreshKeyError && [self resourceKeyHasExpired]) {
            if (completion) {
                completion(nil, refreshKeyError);
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
    [self refreshResourceKeyIfNecessary:^(NSError *refreshKeyError){
        if (refreshKeyError && [self resourceKeyHasExpired]) {
            if (completion) {
                completion(refreshKeyError);
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
    [self refreshResourceKeyIfNecessary:^(NSError *refreshKeyError){
        if (refreshKeyError && [self resourceKeyHasExpired]) {
            if (completion) {
                completion(refreshKeyError);
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
