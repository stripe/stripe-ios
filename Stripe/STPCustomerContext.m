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

static NSTimeInterval const MinExpirationInterval = 100;

@interface STPCustomerContext ()

@property (nonatomic) STPAPIClient *apiClient;
@property (nonatomic, readwrite) STPCustomer *customer;
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
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleWillForegroundNotification)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
        [self refreshResourceKeyIfNecessary];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification
                                                  object:nil];
}

- (void)handleWillForegroundNotification {
    [self refreshResourceKeyIfNecessary];
}

- (void)refreshResourceKeyIfNecessary {
    if (!self.resourceKey || self.resourceKey.expirationDate.timeIntervalSinceNow < MinExpirationInterval) {
        [self.keyProvider retrieveKey:^(STPResourceKey *resourceKey, __unused NSError *error) {
            if (resourceKey) {
                self.resourceKey = resourceKey;
                self.apiClient = [[STPAPIClient alloc] initWithAPIKey:resourceKey.key];
            }
        }];
    }
}

- (void)retrieveCustomer:(STPCustomerCompletionBlock)completion {
    if (!self.apiClient) {
        completion(nil, [NSError stp_genericConnectionError]);
        return;
    }
    [self.apiClient retrieveCustomerWithId:self.customerId completion:^(STPCustomer *customer, NSError *error) {
        if (customer) {
            self.customer = customer;
        }
        completion(customer, error);
    }];
}

- (void)attachSourceToCustomer:(id<STPSourceProtocol>)source completion:(STPErrorBlock)completion {
     if (!self.apiClient) {
        completion([NSError stp_genericConnectionError]);
        return;
    }
    [self.apiClient updateCustomerWithId:self.customerId addingSource:source.stripeID completion:^(STPCustomer *customer, NSError *error) {
        if (customer) {
            self.customer = customer;
        }
        completion(error);
    }];
}

- (void)selectDefaultCustomerSource:(id<STPSourceProtocol>)source completion:(STPErrorBlock)completion {
    if (!self.apiClient) {
        completion([NSError stp_genericConnectionError]);
        return;
    }
    [self.apiClient updateCustomerWithId:self.customerId
                              parameters:@{@"default_source": source.stripeID}
                              completion:^(STPCustomer *customer, NSError *error) {
                                  if (customer) {
                                      self.customer = customer;
                                  }
                                  completion(error);
                              }];
}

@end
