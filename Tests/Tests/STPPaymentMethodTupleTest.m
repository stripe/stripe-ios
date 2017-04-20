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
                                                                        availablePaymentTypes:@[[STPPaymentMethodType card],
                                                                                                [STPPaymentMethodType giropay]]
                                                                        selectedPaymentMethod:source];

    XCTAssertEqualObjects(tuple.selectedPaymentMethod, source);
}

- (void)testAllowedAvailableSelectedPaymentMethod {

    STPCard *card = [STPCard decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"Card"]];
    STPSource *source = [STPSource decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"CardSource"]];

    STPPaymentMethodTuple *tuple = [[STPPaymentMethodTuple alloc] initWithSavedPaymentMethods:@[card, source]
                                                                        availablePaymentTypes:@[[STPPaymentMethodType card],
                                                                                                [STPPaymentMethodType giropay]]
                                                                        selectedPaymentMethod:[STPPaymentMethodType giropay]];

    XCTAssertEqualObjects(tuple.selectedPaymentMethod, [STPPaymentMethodType giropay]);
}

- (void)testNotAllowedAvailableSelectedPaymentMethod {

    STPCard *card = [STPCard decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"Card"]];
    STPSource *source = [STPSource decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"CardSource"]];

    STPPaymentMethodTuple *tuple = [[STPPaymentMethodTuple alloc] initWithSavedPaymentMethods:@[card, source]
                                                                        availablePaymentTypes:@[[STPPaymentMethodType card],
                                                                                                [STPPaymentMethodType giropay]]
                                                                        selectedPaymentMethod:[STPPaymentMethodType card]];

    XCTAssertNil(tuple.selectedPaymentMethod);
}

- (void)testMissingSelectedPaymentMethod {

    STPCard *card = [STPCard decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"Card"]];
    STPSource *source = [STPSource decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"CardSource"]];

    STPPaymentMethodTuple *tuple = [[STPPaymentMethodTuple alloc] initWithSavedPaymentMethods:@[card, source]
                                                                        availablePaymentTypes:@[[STPPaymentMethodType card],
                                                                                                [STPPaymentMethodType giropay]]
                                                                        selectedPaymentMethod:[STPPaymentMethodType sofort]];

    XCTAssertNil(tuple.selectedPaymentMethod);
}

- (void)testOnlyOneAvailableNotAllowedPaymentMethod {
    STPPaymentMethodTuple *tuple = [[STPPaymentMethodTuple alloc] initWithSavedPaymentMethods:nil
                                                                        availablePaymentTypes:@[[STPPaymentMethodType card]]
                                                                        selectedPaymentMethod:nil];

    XCTAssertNil(tuple.selectedPaymentMethod);
}

- (void)testOnlyOneAvailableAllowedPaymentMethod {
    STPPaymentMethodTuple *tuple = [[STPPaymentMethodTuple alloc] initWithSavedPaymentMethods:nil
                                                                        availablePaymentTypes:@[[STPPaymentMethodType bancontact]]
                                                                        selectedPaymentMethod:nil];

    XCTAssertEqualObjects(tuple.selectedPaymentMethod, [STPPaymentMethodType bancontact]);
}


/**
 When there are no saved payment methods, and apple pay and card are available,
 apple pay should become a saved payment method and the selected payment method
 */
- (void)testApplePayAndCardAvailable {
    STPPaymentMethodTuple *tuple = [[STPPaymentMethodTuple alloc] initWithSavedPaymentMethods:nil
                                                                        availablePaymentTypes:@[
                                                                                                [STPPaymentMethodType applePay],
                                                                                                [STPPaymentMethodType card]
                                                                                                ]
                                                                        selectedPaymentMethod:nil];

    XCTAssertEqualObjects(tuple.savedPaymentMethods, @[[STPPaymentMethodType applePay]]);
    XCTAssertEqualObjects(tuple.availablePaymentTypes, @[[STPPaymentMethodType card]]);
    XCTAssertEqualObjects(tuple.selectedPaymentMethod, [STPPaymentMethodType applePay]);
}

/**
 When there are saved payment methods in addition to apple pay, apple pay should become the first option
 */
- (void)testSavedMethodsWithApplePay {
    STPCard *card = [STPCard decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"Card"]];
    STPSource *source = [STPSource decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"CardSource"]];
    STPPaymentMethodTuple *tuple = [[STPPaymentMethodTuple alloc] initWithSavedPaymentMethods:@[card, source, [STPPaymentMethodType applePay]]
                                                                        availablePaymentTypes:@[[STPPaymentMethodType card]]
                                                                        selectedPaymentMethod:card];
    NSArray *expectedSavedMethods = @[[STPPaymentMethodType applePay], card, source];
    XCTAssertEqualObjects(tuple.savedPaymentMethods, expectedSavedMethods);
    XCTAssertEqualObjects(tuple.availablePaymentTypes, @[[STPPaymentMethodType card]]);
    XCTAssertEqualObjects(tuple.selectedPaymentMethod, card);
}

@end
