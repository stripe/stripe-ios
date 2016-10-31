//
//  TestSTPBackendAPIAdapter.m
//  Stripe
//
//  Created by Brian Dorfman on 8/1/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "TestSTPBackendAPIAdapter.h"

#import "STPTestUtils.h"

@implementation TestSTPBackendAPIAdapter

- (STPCustomer *)createTestCustomer {
    NSMutableDictionary *card1 = [[STPTestUtils jsonNamed:@"Card"] mutableCopy];
    card1[@"id"] = @"card_123";
    
    NSMutableDictionary *customer = [[STPTestUtils jsonNamed:@"Customer"] mutableCopy];
    NSMutableDictionary *sources = [customer[@"sources"] mutableCopy];
    sources[@"data"] = @[card1];
    customer[@"default_source"] = card1[@"id"];
    customer[@"sources"] = sources;
    
    STPCustomerDeserializer *deserializer = [[STPCustomerDeserializer alloc] initWithJSONResponse:customer];
    return deserializer.customer;
    
}

- (void)retrieveCustomer:(STPCustomerCompletionBlock)completion {
    completion([self createTestCustomer], nil);
}

- (void)attachSourceToCustomer:(__unused id<STPSource>)source completion:(STPErrorBlock)completion {
    completion(nil);
}

- (void)selectDefaultCustomerSource:(__unused id<STPSource>)source completion:(STPErrorBlock)completion {
    completion(nil);
}
@end
