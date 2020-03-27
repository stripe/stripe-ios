//
//  STPAUBECSFormViewModelTests.m
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 3/13/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPAUBECSFormViewModel.h"
#import "STPPaymentMethodAUBECSDebitParams.h"
#import "STPPaymentMethodBillingDetails.h"
#import "STPPaymentMethodParams.h"

@interface STPAUBECSFormViewModelTests : XCTestCase

@end

@implementation STPAUBECSFormViewModelTests

- (void)testBECSDebitParams {
    { // Test empty data
        STPAUBECSFormViewModel *model = [STPAUBECSFormViewModel new];
        XCTAssertNil(model.becsDebitParams, @"params with no data should be nil");
    }

    { // Test complete/valid data
        STPAUBECSFormViewModel *model = [STPAUBECSFormViewModel new];
        model.accountNumber = @"123456";
        model.bsbNumber = @"111-111";

        STPPaymentMethodAUBECSDebitParams *params = model.becsDebitParams;
        XCTAssertNotNil(params, @"Failed to create BECS Debit params");
        XCTAssertEqualObjects(params.accountNumber, @"123456", @"account number %@ not equal to `123456` from view model", params.accountNumber);
        XCTAssertEqualObjects(params.bsbNumber, @"111111", @"bsb number %@ not correct from `111-111` in view model.", params.bsbNumber);
    }

    { // Test complete/valid data w/o formatting
        STPAUBECSFormViewModel *model = [STPAUBECSFormViewModel new];
        model.accountNumber = @"123456";
        model.bsbNumber = @"111111";

        STPPaymentMethodAUBECSDebitParams *params = model.becsDebitParams;
        XCTAssertNotNil(params, @"Failed to create BECS Debit params");
        XCTAssertEqualObjects(params.accountNumber, @"123456", @"account number %@ not equal to `123456` from view model", params.accountNumber);
        XCTAssertEqualObjects(params.bsbNumber, @"111111", @"bsb number %@ not correct from `111111` in view model.", params.bsbNumber);
    }

    { // Test complete/valid accountNumber, incomplete bsb number
        STPAUBECSFormViewModel *model = [STPAUBECSFormViewModel new];
        model.accountNumber = @"123456";
        model.bsbNumber = @"111-";

        STPPaymentMethodAUBECSDebitParams *params = model.becsDebitParams;
        XCTAssertNil(params, @"Should not create params with incomplete bsb number");
    }

    { // Test incomplete accountNumber, complete/valid bsb number
        STPAUBECSFormViewModel *model = [STPAUBECSFormViewModel new];
        model.accountNumber = @"1234";
        model.bsbNumber = @"111-111";

        STPPaymentMethodAUBECSDebitParams *params = model.becsDebitParams;
        XCTAssertNil(params, @"Should not create params with incomplete account number");
    }

    { // Test invalid accountNumber, complete/valid bsb number
        STPAUBECSFormViewModel *model = [STPAUBECSFormViewModel new];
        model.accountNumber = @"12345678910";
        model.bsbNumber = @"111-111";

        STPPaymentMethodAUBECSDebitParams *params = model.becsDebitParams;
        XCTAssertNil(params, @"Should not create params with invalid account number");
    }

    { // Test complete/valid accountNumber, invalid bsb number
        STPAUBECSFormViewModel *model = [STPAUBECSFormViewModel new];
        model.accountNumber = @"123456";
        model.bsbNumber = @"666-666";

        STPPaymentMethodAUBECSDebitParams *params = model.becsDebitParams;
        XCTAssertNil(params, @"Should not create params with incomplete bsb number");
    }
}



- (void)testPaymentMethodParams {
    {
        /**
         Test empty
         */
        STPAUBECSFormViewModel *model = [STPAUBECSFormViewModel new];
        XCTAssertNil(model.paymentMethodParams, @"params with no data should be nil");
    }

    {
        /**
         name: +
         email: +
         bsb: + (formatting)
         account: +
         */
        STPAUBECSFormViewModel *model = [STPAUBECSFormViewModel new];
        model.name = @"Jenny Rosen";
        model.email = @"jrosen@example.com";
        model.accountNumber = @"123456";
        model.bsbNumber = @"111-111";

        STPPaymentMethodParams *params = model.paymentMethodParams;
        XCTAssertNotNil(params, @"Failed to create BECS Debit params");
        XCTAssertEqualObjects(params.billingDetails.name, @"Jenny Rosen", @"billingDetails.name %@ not equal to `Jenny Rosen` from view model", params.billingDetails.name);
        XCTAssertEqualObjects(params.billingDetails.email, @"jrosen@example.com", @"billingDetails.email %@ not equal to `jrosen@example.com from view mode", params.billingDetails.email);
        XCTAssertEqualObjects(params.auBECSDebit.accountNumber, @"123456", @"account number %@ not equal to `123456` from view model", params.auBECSDebit.accountNumber);
        XCTAssertEqualObjects(params.auBECSDebit.bsbNumber, @"111111", @"bsb number %@ not correct from `111-111` in view model.", params.auBECSDebit.bsbNumber);
    }

    {
        /**
        name: +
        email: +
        bsb: +
        account: +
        */
        STPAUBECSFormViewModel *model = [STPAUBECSFormViewModel new];
        model.name = @"Jenny Rosen";
        model.email = @"jrosen@example.com";
        model.accountNumber = @"123456";
        model.bsbNumber = @"111111";

        STPPaymentMethodParams *params = model.paymentMethodParams;
        XCTAssertNotNil(params, @"Failed to create BECS Debit params");
        XCTAssertEqualObjects(params.billingDetails.name, @"Jenny Rosen", @"billingDetails.name %@ not equal to `Jenny Rosen` from view model", params.billingDetails.name);
        XCTAssertEqualObjects(params.billingDetails.email, @"jrosen@example.com", @"billingDetails.email %@ not equal to `jrosen@example.com from view mode", params.billingDetails.email);
        XCTAssertEqualObjects(params.auBECSDebit.accountNumber, @"123456", @"account number %@ not equal to `123456` from view model", params.auBECSDebit.accountNumber);
        XCTAssertEqualObjects(params.auBECSDebit.bsbNumber, @"111111", @"bsb number %@ not correct from `111111` in view model.", params.auBECSDebit.bsbNumber);
    }

    {
        /**
        name: +
        email: +
        bsb: x (incomplete)
        account: +
        */
        STPAUBECSFormViewModel *model = [STPAUBECSFormViewModel new];
        model.name = @"Jenny Rosen";
        model.email = @"jrosen@example.com";
        model.accountNumber = @"123456";
        model.bsbNumber = @"111-";

        STPPaymentMethodParams *params = model.paymentMethodParams;
        XCTAssertNil(params, @"Should not create params with incomplete bsb number");
    }

    {
        /**
        name: +
        email: +
        bsb: +
        account: x (incomplete)
        */
        STPAUBECSFormViewModel *model = [STPAUBECSFormViewModel new];
        model.name = @"Jenny Rosen";
        model.email = @"jrosen@example.com";
        model.accountNumber = @"1234";
        model.bsbNumber = @"111-111";

        STPPaymentMethodParams *params = model.paymentMethodParams;
        XCTAssertNil(params, @"Should not create params with incomplete account number");
    }

    {
        /**
        name: +
        email: +
        bsb: +
        account: x
        */
        STPAUBECSFormViewModel *model = [STPAUBECSFormViewModel new];
        model.name = @"Jenny Rosen";
        model.email = @"jrosen@example.com";
        model.accountNumber = @"12345678910";
        model.bsbNumber = @"111-111";

        STPPaymentMethodParams *params = model.paymentMethodParams;
        XCTAssertNil(params, @"Should not create params with invalid account number");
    }

    {
        /**
        name: +
        email: +
        bsb: x
        account: +
        */
        STPAUBECSFormViewModel *model = [STPAUBECSFormViewModel new];
        model.name = @"Jenny Rosen";
        model.email = @"jrosen@example.com";
        model.accountNumber = @"123456";
        model.bsbNumber = @"666-666";

        STPPaymentMethodParams *params = model.paymentMethodParams;
        XCTAssertNil(params, @"Should not create params with incomplete bsb number");
    }

    {
        /**
         name: x
         email: +
         bsb: + (formatting)
         account: +
         */
        STPAUBECSFormViewModel *model = [STPAUBECSFormViewModel new];
        model.name = @"";
        model.email = @"jrosen@example.com";
        model.accountNumber = @"123456";
        model.bsbNumber = @"111-111";

        STPPaymentMethodParams *params = model.paymentMethodParams;
        XCTAssertNil(params, @"Should not create payment method params without name.");
    }

    {
        /**
         name: +
         email: x
         bsb: + (formatting)
         account: +
         */
        STPAUBECSFormViewModel *model = [STPAUBECSFormViewModel new];
        model.name = @"Jenny Rosen";
        model.email = @"jrose";
        model.accountNumber = @"123456";
        model.bsbNumber = @"111-111";

        STPPaymentMethodParams *params = model.paymentMethodParams;
        XCTAssertNil(params, @"Should not create payment method params with invalid email.");
    }
}

- (void)testBSBLabelForInput {
    { // empty test
        STPAUBECSFormViewModel *model = [STPAUBECSFormViewModel new];
        BOOL isErrorString = YES;
        NSString *bsbLabel = [model bsbLabelForInput:@"" editing:NO isErrorString:&isErrorString];
        XCTAssertFalse(isErrorString, @"Empty input shouldn't be an error.");
        XCTAssertNil(bsbLabel, @"No bsb label for empty input.");

        isErrorString = YES;
        bsbLabel = [model bsbLabelForInput:nil editing:YES isErrorString:&isErrorString];
        XCTAssertFalse(isErrorString, @"nil input shouldn't be an error.");
        XCTAssertNil(bsbLabel, @"No bsb label for nil input.");
    }


    { // invalid test
        STPAUBECSFormViewModel *model = [STPAUBECSFormViewModel new];
        BOOL isErrorString = NO;
        NSString *bsbLabel = [model bsbLabelForInput:@"666-666" editing:NO isErrorString:&isErrorString];
        XCTAssertTrue(isErrorString, @"Invalid input should be an error.");
        XCTAssertEqualObjects(bsbLabel, @"The BSB you entered is invalid.", @"Should have bsb label indicating invalid.");

        isErrorString = NO;
        bsbLabel = [model bsbLabelForInput:@"666-666" editing:YES isErrorString:&isErrorString];
        XCTAssertTrue(isErrorString, @"Invalid input should be an error (editing).");
        XCTAssertEqualObjects(bsbLabel, @"The BSB you entered is invalid.", @"Should have bsb label indicating invalid.");
    }

    { // incomplete test
        STPAUBECSFormViewModel *model = [STPAUBECSFormViewModel new];
        BOOL isErrorString = NO;
        NSString *bsbLabel = [model bsbLabelForInput:@"111-11" editing:NO isErrorString:&isErrorString];
        XCTAssertTrue(isErrorString, @"Incomplete input should be an error when not editing.");
        XCTAssertEqualObjects(bsbLabel, @"The BSB you entered is incomplete.", @"Should have bsb label indicating incomplete.");

        isErrorString = YES;
        bsbLabel = [model bsbLabelForInput:@"111-11" editing:YES isErrorString:&isErrorString];
        XCTAssertFalse(isErrorString, @"Incomplete input should not be an error when editing.");
        XCTAssertEqualObjects(bsbLabel, @"St George Bank (division of Westpac Bank)", @"Should have bsb label with bank name.");
    }

    { // valid test
        STPAUBECSFormViewModel *model = [STPAUBECSFormViewModel new];
        BOOL isErrorString = YES;
        NSString *bsbLabel = [model bsbLabelForInput:@"111-111" editing:NO isErrorString:&isErrorString];
        XCTAssertFalse(isErrorString, @"Complete input should be not an error when not editing.");
        XCTAssertEqualObjects(bsbLabel, @"St George Bank (division of Westpac Bank)", @"Should have bsb label with bank name.");

        isErrorString = YES;
        bsbLabel = [model bsbLabelForInput:@"111-111" editing:YES isErrorString:&isErrorString];
        XCTAssertFalse(isErrorString, @"Complete input should not be an error when editing.");
        XCTAssertEqualObjects(bsbLabel, @"St George Bank (division of Westpac Bank)", @"Should have bsb label with bank name.");
    }
}

- (void)testIsInputValid {
     { // name
         STPAUBECSFormViewModel *model = [STPAUBECSFormViewModel new];
         XCTAssertTrue([model isInputValid:@"" forField:STPAUBECSFormViewFieldName editing:NO], @"Name should always be valid.");
         XCTAssertTrue([model isInputValid:@"Jen" forField:STPAUBECSFormViewFieldName editing:YES], @"Name should always be valid.");
     }

    { // email
        STPAUBECSFormViewModel *model = [STPAUBECSFormViewModel new];
        XCTAssertFalse([model isInputValid:@"jrosen" forField:STPAUBECSFormViewFieldEmail editing:NO], @"Partial email is invalid when not editing.");
        XCTAssertTrue([model isInputValid:@"jrosen" forField:STPAUBECSFormViewFieldEmail editing:YES], @"Partial email is valid when editing.");

        XCTAssertTrue([model isInputValid:@"" forField:STPAUBECSFormViewFieldEmail editing:NO], @"Empty email is always valid.");
        XCTAssertTrue([model isInputValid:@"" forField:STPAUBECSFormViewFieldEmail editing:YES], @"Empty email is always valid.");

        XCTAssertTrue([model isInputValid:@"jrosen@example.com" forField:STPAUBECSFormViewFieldEmail editing:NO], @"Valid email.");
        XCTAssertTrue([model isInputValid:@"jrosen@example.com" forField:STPAUBECSFormViewFieldEmail editing:YES], @"Valid email.");
    }

    { // bsb
        STPAUBECSFormViewModel *model = [STPAUBECSFormViewModel new];
        XCTAssertFalse([model isInputValid:@"111-1" forField:STPAUBECSFormViewFieldBSBNumber editing:NO], @"Partial bsb is invalid when not editing.");
        XCTAssertTrue([model isInputValid:@"111-1" forField:STPAUBECSFormViewFieldBSBNumber editing:YES], @"Partial bsb is valid when editing.");

        XCTAssertTrue([model isInputValid:@"" forField:STPAUBECSFormViewFieldBSBNumber editing:NO], @"Empty bsb is always valid.");
        XCTAssertTrue([model isInputValid:@"" forField:STPAUBECSFormViewFieldBSBNumber editing:YES], @"Empty bsb is always valid.");

        XCTAssertTrue([model isInputValid:@"111-111" forField:STPAUBECSFormViewFieldBSBNumber editing:NO], @"Valid bsb.");
        XCTAssertTrue([model isInputValid:@"111-111" forField:STPAUBECSFormViewFieldBSBNumber editing:YES], @"Valid bsb.");

        XCTAssertFalse([model isInputValid:@"666-6" forField:STPAUBECSFormViewFieldBSBNumber editing:NO], @"Invalid partial bsb is always invalid.");
        XCTAssertFalse([model isInputValid:@"666-6" forField:STPAUBECSFormViewFieldBSBNumber editing:YES], @"Invalid partial bsb is always invalid.");

        XCTAssertFalse([model isInputValid:@"666-666" forField:STPAUBECSFormViewFieldBSBNumber editing:NO], @"Invalid full bsb is always invalid.");
        XCTAssertFalse([model isInputValid:@"666-666" forField:STPAUBECSFormViewFieldBSBNumber editing:YES], @"Invalid full bsb is always invalid.");
    }

    { // account
        STPAUBECSFormViewModel *model = [STPAUBECSFormViewModel new];
        XCTAssertFalse([model isInputValid:@"1234" forField:STPAUBECSFormViewFieldAccountNumber editing:NO], @"Partial account number is invalid when not editing.");
        XCTAssertTrue([model isInputValid:@"1234" forField:STPAUBECSFormViewFieldAccountNumber editing:YES], @"Partial  account number is valid when editing.");

        XCTAssertTrue([model isInputValid:@"" forField:STPAUBECSFormViewFieldAccountNumber editing:NO], @"Empty  account number is always valid.");
        XCTAssertTrue([model isInputValid:@"" forField:STPAUBECSFormViewFieldAccountNumber editing:YES], @"Empty  account number is always valid.");

        XCTAssertTrue([model isInputValid:@"12345" forField:STPAUBECSFormViewFieldAccountNumber editing:NO], @"Valid  account number.");
        XCTAssertTrue([model isInputValid:@"12345" forField:STPAUBECSFormViewFieldAccountNumber editing:YES], @"Valid  account number.");

        XCTAssertFalse([model isInputValid:@"12345678910" forField:STPAUBECSFormViewFieldAccountNumber editing:NO], @"Invalid  account number is always invalid.");
        XCTAssertFalse([model isInputValid:@"12345678910" forField:STPAUBECSFormViewFieldAccountNumber editing:YES], @"Invalid  account number is always invalid.");
    }
}

- (void)testIsFieldComplete {
    { // name
        STPAUBECSFormViewModel *model = [STPAUBECSFormViewModel new];
        XCTAssertFalse([model isFieldCompleteWithInput:@"" inField:STPAUBECSFormViewFieldName editing:NO], @"Empty name is not complete.");
        XCTAssertFalse([model isFieldCompleteWithInput:@"" inField:STPAUBECSFormViewFieldName editing:YES], @"Empty name is not complete.");

        XCTAssertTrue([model isFieldCompleteWithInput:@"Jen" inField:STPAUBECSFormViewFieldName editing:NO], @"Non-empty name is complete.");
        XCTAssertTrue([model isFieldCompleteWithInput:@"Jenny Rosen" inField:STPAUBECSFormViewFieldName editing:YES], @"Non-empty name is complete.");
     }

    { // email
        STPAUBECSFormViewModel *model = [STPAUBECSFormViewModel new];
        XCTAssertFalse([model isFieldCompleteWithInput:@"jrosen" inField:STPAUBECSFormViewFieldEmail editing:NO], @"Partial email is not complete.");
        XCTAssertFalse([model isFieldCompleteWithInput:@"jrosen" inField:STPAUBECSFormViewFieldEmail editing:YES], @"Partial email is not complete.");

        XCTAssertTrue([model isFieldCompleteWithInput:@"jrosen@example.com" inField:STPAUBECSFormViewFieldEmail editing:NO], @"Full email is complete.");
        XCTAssertTrue([model isFieldCompleteWithInput:@"jrosen@example.com" inField:STPAUBECSFormViewFieldEmail editing:YES], @"Full email is complete.");
    }

    { // bsb
        STPAUBECSFormViewModel *model = [STPAUBECSFormViewModel new];
        XCTAssertFalse([model isFieldCompleteWithInput:@"111-1" inField:STPAUBECSFormViewFieldBSBNumber editing:NO], @"Partial bsb is not complete.");
        XCTAssertFalse([model isFieldCompleteWithInput:@"111-1" inField:STPAUBECSFormViewFieldBSBNumber editing:YES], @"Partial bsb is not complete.");

        XCTAssertFalse([model isFieldCompleteWithInput:@"" inField:STPAUBECSFormViewFieldBSBNumber editing:NO], @"Empty bsb is not complete.");
        XCTAssertFalse([model isFieldCompleteWithInput:@"" inField:STPAUBECSFormViewFieldBSBNumber editing:YES], @"Empty bsb is not complete.");

        XCTAssertTrue([model isFieldCompleteWithInput:@"111-111" inField:STPAUBECSFormViewFieldBSBNumber editing:NO], @"Full bsb is complete.");
        XCTAssertTrue([model isFieldCompleteWithInput:@"111-111" inField:STPAUBECSFormViewFieldBSBNumber editing:YES], @"Full bsb is complete.");

        XCTAssertFalse([model isFieldCompleteWithInput:@"666-6" inField:STPAUBECSFormViewFieldBSBNumber editing:NO], @"Invalid partial bsb is not complete.");
        XCTAssertFalse([model isFieldCompleteWithInput:@"666-6" inField:STPAUBECSFormViewFieldBSBNumber editing:YES], @"Invalid partial bsb is not complete.");

        XCTAssertFalse([model isFieldCompleteWithInput:@"666-666" inField:STPAUBECSFormViewFieldBSBNumber editing:NO], @"Invalid full bsb is not complete.");
               XCTAssertFalse([model isFieldCompleteWithInput:@"666-666" inField:STPAUBECSFormViewFieldBSBNumber editing:YES], @"Invalid full bsb is not complete.");
    }

    { // account
        STPAUBECSFormViewModel *model = [STPAUBECSFormViewModel new];
        XCTAssertFalse([model isFieldCompleteWithInput:@"1234" inField:STPAUBECSFormViewFieldAccountNumber editing:NO], @"Partial account number is not complete.");
        XCTAssertFalse([model isFieldCompleteWithInput:@"1234" inField:STPAUBECSFormViewFieldAccountNumber editing:YES], @"Partial account number is not complete.");

        XCTAssertFalse([model isFieldCompleteWithInput:@"" inField:STPAUBECSFormViewFieldAccountNumber editing:NO], @"Empty account number is not complete.");
        XCTAssertFalse([model isFieldCompleteWithInput:@"" inField:STPAUBECSFormViewFieldAccountNumber editing:YES], @"Empty account number is not complete.");

        XCTAssertTrue([model isFieldCompleteWithInput:@"12345" inField:STPAUBECSFormViewFieldAccountNumber editing:NO], @"Min length account number is complete when not editing.");
        XCTAssertFalse([model isFieldCompleteWithInput:@"12345" inField:STPAUBECSFormViewFieldAccountNumber editing:YES], @"Min length account number is not complete when editing.");

        XCTAssertTrue([model isFieldCompleteWithInput:@"123456789" inField:STPAUBECSFormViewFieldAccountNumber editing:YES], @"Max length account number is complete when editing.");

        XCTAssertFalse([model isFieldCompleteWithInput:@"12345678910" inField:STPAUBECSFormViewFieldAccountNumber editing:NO], @"Invalid  account number is not complete.");
        XCTAssertFalse([model isFieldCompleteWithInput:@"12345678910" inField:STPAUBECSFormViewFieldAccountNumber editing:YES], @"Invalid  account number is not complete.");
    }
}

@end
