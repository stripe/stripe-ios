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
#import "STPResourceKeyRetriever.h"
#import "STPWeakStrongMacros.h"
#import "StripeError.h"

static NSTimeInterval const DefaultCachedCustomerMaxAge = 60;

@interface STPCustomerContext ()

@property (nonatomic) STPAPIClient *apiClient;
@property (nonatomic) STPCustomer *customer;
@property (nonatomic) NSDate *customerRetrievedDate;
@property (nonatomic) NSString *customerId;
@property (nonatomic) STPResourceKeyRetriever *keyRetriever;

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
        _apiClient = apiClient;
        _cachedCustomerMaxAge = DefaultCachedCustomerMaxAge;
        _keyRetriever = [[STPResourceKeyRetriever alloc] initWithKeyProvider:keyProvider];
        [self retrieveCustomer:nil];
    }
    return self;
}

- (void)setCustomer:(STPCustomer *)customer {
    _customer = customer;
    _customerRetrievedDate = [NSDate date];
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
    [self.keyRetriever retrieveResourceKey:^(STPResourceKey *resourceKey, NSError *retrieveKeyError) {
        if (retrieveKeyError) {
            if (completion) {
                completion(nil, retrieveKeyError);
            }
            return;
        }
        self.apiClient.apiKey = resourceKey.key;
        [self.apiClient retrieveCustomerWithId:self.customerId completion:^(STPCustomer *customer, NSError *error) {
            if (customer) {
                self.customer = customer;
            }
            if (completion) {
                completion(customer, error);
            }
        }];
    }];
}

- (void)attachSourceToCustomer:(id<STPSourceProtocol>)source completion:(STPErrorBlock)completion {
    [self.keyRetriever retrieveResourceKey:^(STPResourceKey *resourceKey, NSError *retrieveKeyError) {
        if (retrieveKeyError) {
            if (completion) {
                completion(retrieveKeyError);
            }
            return;
        }
        self.apiClient.apiKey = resourceKey.key;
        [self.apiClient addSource:source.stripeID
                 toCustomerWithId:self.customerId
                       completion:^(__unused id<STPSourceProtocol> object, NSError *error) {
                           if (completion) {
                               completion(error);
                           }
                       }];
    }];
}

- (void)selectDefaultCustomerSource:(id<STPSourceProtocol>)source completion:(STPErrorBlock)completion {
    [self.keyRetriever retrieveResourceKey:^(STPResourceKey *resourceKey, NSError *retrieveKeyError) {
        if (retrieveKeyError) {
            if (completion) {
                completion(retrieveKeyError);
            }
            return;
        }
        self.apiClient.apiKey = resourceKey.key;
        [self.apiClient updateCustomerWithId:self.customerId
                                  parameters:@{@"default_source": source.stripeID}
                                  completion:^(STPCustomer *customer, NSError *error) {
                                      if (customer) {
                                          self.customer = customer;
                                      }
                                      if (completion) {
                                          completion(error);
                                      }
                                  }];
    }];
}

@end
