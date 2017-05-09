//
//  STPDropInAPIClient.m
//  Stripe
//
//  Created by Ben Guo on 5/9/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPDropInAPIClient.h"

#import "STPAPIClient+Private.h"
#import "STPDropInConfiguration.h"

static NSTimeInterval const MinResourceKeyExpirationInterval = 60;

@interface STPDropInAPIClient ()

@property (nonatomic) STPAPIClient *resourceKeyClient;
@property (nonatomic) STPAPIClient *publishableKeyClient;
@property (nonatomic) STPDropInConfiguration *configuration;
@property (nonatomic, weak) id<STPDropInConfigurationProvider> configurationProvider;

@end

@implementation STPDropInAPIClient

- (instancetype)initWithConfigurationProvider:(id<STPDropInConfigurationProvider>)provider {
    self = [super init];
    if (self) {
        _configurationProvider = provider;
        _resourceKeyClient = [[STPAPIClient alloc] initWithAPIKey:nil];
        _publishableKeyClient = [[STPAPIClient alloc] initWithAPIKey:nil];
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
    [self refreshConfigurationIfNecessary:nil];
}

- (BOOL)needsNewResourceKey {
    return !self.configuration ||
    self.configuration.customerResourceKeyExpirationDate.timeIntervalSinceNow < MinResourceKeyExpirationInterval;
}

- (BOOL)resourceKeyHasExpired {
    return !self.configuration || self.configuration.customerResourceKeyExpirationDate.timeIntervalSinceNow <= 0;
}

- (void)refreshConfigurationIfNecessary:(STPErrorBlock)completion {
    if (![self needsNewResourceKey]) {
        if (completion) {
            completion(nil);
        }
    } else {
        [self.configurationProvider retrieveConfiguration:^(STPDropInConfiguration *configuration, NSError *error) {
            if (configuration) {
                self.configuration = configuration;
                self.resourceKeyClient.apiKey = configuration.customerResourceKey;
                self.publishableKeyClient.publishableKey = configuration.publishableKey;
            }
            if (completion) {
                completion(error);
            }
        }];
    }
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

@end
