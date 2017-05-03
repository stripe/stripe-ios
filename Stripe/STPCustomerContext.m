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

@interface STPCustomerContext ()

@property (nonatomic) STPAPIClient *apiClient;
@property (nonatomic, readwrite) STPCustomer *customer;
@property (nonatomic) NSString *customerId;

@end

@implementation STPCustomerContext

- (instancetype)initWithCustomerId:(NSString *)customerId
                       resourceKey:(NSString *)apiKey {
    self = [super init];
    if (self) {
        _customerId = customerId;
        _apiClient = [[STPAPIClient alloc] initWithAPIKey:apiKey];
    }
    return self;
}

- (void)retrieveCustomer:(STPCustomerCompletionBlock)completion {
    [self.apiClient retrieveCustomerWithId:self.customerId completion:^(STPCustomer *customer, NSError *error) {
        if (customer) {
            self.customer = customer;
        }
        completion(customer, error);
    }];
}

- (void)attachSourceToCustomer:(id<STPSourceProtocol>)source completion:(STPErrorBlock)completion {
    [self.apiClient updateCustomerWithId:self.customerId addingSource:source.stripeID completion:^(STPCustomer *customer, NSError *error) {
        if (customer) {
            self.customer = customer;
        }
        completion(error);
    }];
}

- (void)selectDefaultCustomerSource:(id<STPSourceProtocol>)source completion:(STPErrorBlock)completion {
    [self.apiClient updateCustomerWithId:self.customerId
                              parameters:@{@"default_source": source.stripeID}
                              completion:^(__unused STPCustomer *customer, NSError *error) {
                                  if (customer) {
                                      self.customer = customer;
                                  }
                                  completion(error);
                              }];
}

@end
