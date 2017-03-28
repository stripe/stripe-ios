//
//  STPPaymentMethodTupleTest.m
//  Stripe
//
//  Created by Brian Dorfman on 3/27/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Stripe/Stripe.h>
#import "STPPaymentMethodTuple.h"
#import "STPTestUtils.h"

@interface STPPaymentMethodTupleTest : XCTestCase

@end

@implementation STPPaymentMethodTupleTest

- (void)testSavedSelectedPaymentMethod {

    STPCard *card = [STPCard decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"Card"]];
    STPSource *source = [STPSource decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"CardSource"]];

    STPPaymentMethodTuple *tuple = [[STPPaymentMethodTuple alloc] initWithSavedPaymentMethods:@[card, source]
                                                                        availablePaymentTypes:@[[STPPaymentMethodType creditCard],
                                                                                                [STPPaymentMethodType giropay]]
                                                                        selectedPaymentMethod:source];

    XCTAssertEqualObjects(tuple.selectedPaymentMethod, source);
}

- (void)testAllowedAvailableSelectedPaymentMethod {

    STPCard *card = [STPCard decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"Card"]];
    STPSource *source = [STPSource decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"CardSource"]];

    STPPaymentMethodTuple *tuple = [[STPPaymentMethodTuple alloc] initWithSavedPaymentMethods:@[card, source]
                                                                        availablePaymentTypes:@[[STPPaymentMethodType creditCard],
                                                                                                [STPPaymentMethodType giropay]]
                                                                        selectedPaymentMethod:[STPPaymentMethodType giropay]];

    XCTAssertEqualObjects(tuple.selectedPaymentMethod, [STPPaymentMethodType giropay]);
}

- (void)testNotAllowedAvailableSelectedPaymentMethod {

    STPCard *card = [STPCard decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"Card"]];
    STPSource *source = [STPSource decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"CardSource"]];

    STPPaymentMethodTuple *tuple = [[STPPaymentMethodTuple alloc] initWithSavedPaymentMethods:@[card, source]
                                                                        availablePaymentTypes:@[[STPPaymentMethodType creditCard],
                                                                                                [STPPaymentMethodType giropay]]
                                                                        selectedPaymentMethod:[STPPaymentMethodType creditCard]];

    XCTAssertNil(tuple.selectedPaymentMethod);
}

- (void)testMissingSelectedPaymentMethod {

    STPCard *card = [STPCard decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"Card"]];
    STPSource *source = [STPSource decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"CardSource"]];

    STPPaymentMethodTuple *tuple = [[STPPaymentMethodTuple alloc] initWithSavedPaymentMethods:@[card, source]
                                                                        availablePaymentTypes:@[[STPPaymentMethodType creditCard],
                                                                                                [STPPaymentMethodType giropay]]
                                                                        selectedPaymentMethod:[STPPaymentMethodType sofort]];

    XCTAssertNil(tuple.selectedPaymentMethod);
}

- (void)testOnlyOneAvailableNotAllowedPaymentMethod {
    STPPaymentMethodTuple *tuple = [[STPPaymentMethodTuple alloc] initWithSavedPaymentMethods:nil
                                                                        availablePaymentTypes:@[[STPPaymentMethodType creditCard]]
                                                                        selectedPaymentMethod:nil];

    XCTAssertNil(tuple.selectedPaymentMethod);
}

- (void)testOnlyOneAvailableAllowedPaymentMethod {
    STPPaymentMethodTuple *tuple = [[STPPaymentMethodTuple alloc] initWithSavedPaymentMethods:nil
                                                                        availablePaymentTypes:@[[STPPaymentMethodType bancontact]]
                                                                        selectedPaymentMethod:nil];

    XCTAssertEqualObjects(tuple.selectedPaymentMethod, [STPPaymentMethodType bancontact]);
}

@end
