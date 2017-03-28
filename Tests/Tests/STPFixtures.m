//
//  STPFixtures.m
//  Stripe
//
//  Created by Ben Guo on 3/28/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPFixtures.h"
#import "STPTestUtils.h"

@implementation STPFixtures

+ (STPCardParams *)cardParams {
    STPCardParams *cardParams = [STPCardParams new];
    cardParams.number = @"4242424242424242";
    cardParams.expMonth = 10;
    cardParams.expYear = 99;
    cardParams.cvc = @"123";
    return cardParams;
}

+ (STPCustomer *)customerWithSingleCardTokenSource {
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

+ (STPPaymentConfiguration *)paymentConfiguration {
    STPPaymentConfiguration *config = [STPPaymentConfiguration new];
    config.publishableKey = @"pk_fake_publishable_key";
    return config;
}

+ (id<STPBackendAPIAdapter>)staticAPIAdapter {
    return [self staticAPIAdapterWithCustomer:[self customerWithSingleCardTokenSource]];
}

+ (id<STPBackendAPIAdapter>)staticAPIAdapterWithCustomer:(STPCustomer *)customer {
    id mockAPIAdapter = OCMProtocolMock(@protocol(STPBackendAPIAdapter));
    OCMStub([mockAPIAdapter retrieveCustomer:[OCMArg any]]).andDo(^(NSInvocation *invocation){
        STPCustomerCompletionBlock completion;
        [invocation getArgument:&completion atIndex:2];
        completion(customer, nil);
    });
    OCMStub([mockAPIAdapter selectDefaultCustomerSource:[OCMArg any] completion:[OCMArg invokeBlock]]);
    OCMStub([mockAPIAdapter attachSourceToCustomer:[OCMArg any] completion:[OCMArg invokeBlock]]);
    return mockAPIAdapter;
}

@end
