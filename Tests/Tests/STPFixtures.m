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

+ (STPAddress *)address {
    STPAddress *address = [STPAddress new];
    address.email = @"foo@example.com";
    address.name = @"John Smith";
    address.line1 = @"55 John St";
    address.line2 = @"#3B";
    address.city = @"New York";
    address.state = @"NY";
    address.postalCode = @"10002";
    address.country = @"US";
    address.phone = @"555-555-5555";
    return address;
}

+ (STPCardParams *)cardParams {
    STPCardParams *cardParams = [STPCardParams new];
    cardParams.number = @"4242424242424242";
    cardParams.expMonth = 10;
    cardParams.expYear = 99;
    cardParams.cvc = @"123";
    cardParams.currency = @"usd";
    cardParams.name = @"Jenny Rosen";
    cardParams.addressLine1 = @"123 Fake Street";
    cardParams.addressLine2 = @"Apartment 4";
    cardParams.addressCity = @"New York";
    cardParams.addressState = @"NY";
    cardParams.addressCountry = @"USA";
    cardParams.addressZip = @"10002";
    return cardParams;
}

+ (STPSource *)cardSource {
    return [STPSource decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"CardSource"]];
}

+ (STPToken *)cardToken {
    NSDictionary *cardDict = [STPTestUtils jsonNamed:@"Card"];
    NSDictionary *tokenDict = @{
                                @"id": @"id_for_token",
                                @"object": @"token",
                                @"livemode": @NO,
                                @"created": @1353025450.0,
                                @"used": @NO,
                                @"card": cardDict
                                };
    return [STPToken decodedObjectFromAPIResponse:tokenDict];
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

+ (STPSource *)iDEALSource {
    return [STPSource decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"iDEALSource"]];
}

+ (STPPaymentConfiguration *)paymentConfiguration {
    STPPaymentConfiguration *config = [STPPaymentConfiguration new];
    config.publishableKey = @"pk_fake_publishable_key";
    return config;
}

+ (STPAddress *)sepaAddress {
    STPAddress *address = [STPAddress new];
    address.line1 = @"Nollendorfstraße 27";
    address.city = @"Berlin";
    address.postalCode = @"10777";
    address.country = @"DE";
    return address;
}

+ (STPSource *)sepaDebitSource {
    return [STPSource decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"SEPADebitSource"]];
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
