//
//  STPAddCardViewControllerTest.m
//  Stripe
//
//  Created by Ben Guo on 7/5/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <Stripe/Stripe.h>
#import "NSError+Stripe.h"
#import "NSLocale+STPSwizzling.h"
#import "STPCard.h"
#import "STPFixtures.h"
#import "STPPaymentCardTextFieldCell.h"
#import "STPPostalCodeValidator.h"

@interface STPAddCardViewController (Testing)
@property (nonatomic) STPPaymentCardTextFieldCell *paymentCell;
@property (nonatomic) STPAPIClient *apiClient;
@property (nonatomic) BOOL loading;
@end

@interface STPToken (Testing)
@property (nonatomic, nonnull) NSString *tokenId;
@end

@interface STPAddCardViewControllerTest : XCTestCase
@end

@implementation STPAddCardViewControllerTest

- (STPAddCardViewController *)buildAddCardViewController {
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
    STPTheme *theme = [STPTheme defaultTheme];
    STPAddCardViewController *vc = [[STPAddCardViewController alloc] initWithConfiguration:config
                                                                                     theme:theme];
    XCTAssertNotNil(vc.view);
    return vc;
}

- (void)testPrefilledBillingAddress_removeAddress {
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
    config.requiredBillingAddressFields = STPBillingAddressFieldsZip;
    STPAddCardViewController *sut = [[STPAddCardViewController alloc] initWithConfiguration:config
                                                                                      theme:[STPTheme defaultTheme]];
    STPAddress *address = [STPAddress new];
    address.name = @"John Smith Doe";
    address.phone = @"8885551212";
    address.email = @"foo@example.com";
    address.line1 = @"55 John St";
    address.city = @"Harare";
    address.postalCode = @"10002";
    address.country = @"ZW"; // Zimbabwe does not require zip codes, while the default locale for tests (US) does
    // Sanity checks
    XCTAssertFalse([STPPostalCodeValidator postalCodeIsRequiredForCountryCode:@"ZW"]);
    XCTAssertTrue([STPPostalCodeValidator postalCodeIsRequiredForCountryCode:@"US"]);

    STPUserInformation *prefilledInfo = [[STPUserInformation alloc] init];
    prefilledInfo.billingAddress = address;
    sut.prefilledInformation = prefilledInfo;

    XCTAssertNoThrow([sut loadView]);
    XCTAssertNoThrow([sut viewDidLoad]);
}

- (void)testPrefilledBillingAddress_addAddress {
    [NSLocale stp_setCurrentLocale:[NSLocale localeWithLocaleIdentifier:@"en_ZW"]]; // Zimbabwe does not require zip codes, while the default locale for tests (US) does
    // Sanity checks
    XCTAssertFalse([STPPostalCodeValidator postalCodeIsRequiredForCountryCode:@"ZW"]);
    XCTAssertTrue([STPPostalCodeValidator postalCodeIsRequiredForCountryCode:@"US"]);
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
    config.requiredBillingAddressFields = STPBillingAddressFieldsZip;
    STPAddCardViewController *sut = [[STPAddCardViewController alloc] initWithConfiguration:config
                                                                                      theme:[STPTheme defaultTheme]];
    STPAddress *address = [STPAddress new];
    address.name = @"John Smith Doe";
    address.phone = @"8885551212";
    address.email = @"foo@example.com";
    address.line1 = @"55 John St";
    address.city = @"New York";
    address.state = @"NY";
    address.postalCode = @"10002";
    address.country = @"US";

    STPUserInformation *prefilledInfo = [[STPUserInformation alloc] init];
    prefilledInfo.billingAddress = address;
    sut.prefilledInformation = prefilledInfo;

    XCTAssertNoThrow([sut loadView]);
    XCTAssertNoThrow([sut viewDidLoad]);
    [NSLocale stp_resetCurrentLocale];
}


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

- (void)testNextWithCreatePaymentMethodError {
    STPAddCardViewController *sut = [self buildAddCardViewController];
    STPPaymentMethodCardParams *expectedCardParams = [STPFixtures paymentMethodCardParams];
    sut.paymentCell.paymentField.cardParams = expectedCardParams;

    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    sut.apiClient = mockAPIClient;
    XCTestExpectation *exp = [self expectationWithDescription:@"createPaymentMethodWithCard"];
    OCMStub([mockAPIClient createPaymentMethodWithParams:[OCMArg any] completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation){
        STPPaymentMethodParams *paymentMethodParams;
        STPPaymentMethodCompletionBlock completion;
        [invocation getArgument:&paymentMethodParams atIndex:2];
        [invocation getArgument:&completion atIndex:3];
        XCTAssertEqualObjects(paymentMethodParams.card.number, expectedCardParams.number);
        XCTAssertTrue(sut.loading);
        NSError *error = [NSError stp_genericFailedToParseResponseError];
        completion(nil, error);
        XCTAssertFalse(sut.loading);
        [exp fulfill];
    });

    // tap next button
    UIBarButtonItem *nextButton = sut.navigationItem.rightBarButtonItem;
    [nextButton.target performSelector:nextButton.action withObject:nextButton];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testNextWithCreatePaymentMethodSuccessAndDidCreatePaymentMethodError {
    STPAddCardViewController *sut = [self buildAddCardViewController];

    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    id mockDelegate = OCMProtocolMock(@protocol(STPAddCardViewControllerDelegate));
    sut.apiClient = mockAPIClient;
    sut.delegate = mockDelegate;
    STPPaymentMethodCardParams *expectedCardParams = [STPFixtures paymentMethodCardParams];
    sut.paymentCell.paymentField.cardParams = expectedCardParams;

    STPPaymentMethod *expectedPaymentMethod = [STPFixtures paymentMethod];
    XCTestExpectation *createPaymentMethodExp = [self expectationWithDescription:@"createPaymentMethodWithCard"];
    OCMStub([mockAPIClient createPaymentMethodWithParams:[OCMArg any] completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation){
        STPPaymentMethodParams *paymentMethodParams;
        STPPaymentMethodCompletionBlock completion;
        [invocation getArgument:&paymentMethodParams atIndex:2];
        [invocation getArgument:&completion atIndex:3];
        XCTAssertEqualObjects(paymentMethodParams.card.number, expectedCardParams.number);
        XCTAssertTrue(sut.loading);
        completion(expectedPaymentMethod, nil);
        [createPaymentMethodExp fulfill];
    });
    
    XCTestExpectation *didCreatePaymentMethodExp = [self expectationWithDescription:@"didCreatePaymentMethod"];
    OCMStub([mockDelegate addCardViewController:[OCMArg any] didCreatePaymentMethod:[OCMArg any] completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation){
        STPPaymentMethod *paymentMethod;
        STPErrorBlock completion;
        [invocation getArgument:&paymentMethod atIndex:3];
        [invocation getArgument:&completion atIndex:4];
        XCTAssertTrue(sut.loading);
        NSError *error = [NSError stp_genericFailedToParseResponseError];
        XCTAssertEqualObjects(paymentMethod.stripeId, expectedPaymentMethod.stripeId);
        completion(error);
        XCTAssertFalse(sut.loading);
        [didCreatePaymentMethodExp fulfill];
    });

    // tap next button
    UIBarButtonItem *nextButton = sut.navigationItem.rightBarButtonItem;
    [nextButton.target performSelector:nextButton.action withObject:nextButton];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testNextWithCreateTokenSuccessAndDidCreateTokenSuccess {
    STPAddCardViewController *sut = [self buildAddCardViewController];

    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    id mockDelegate = OCMProtocolMock(@protocol(STPAddCardViewControllerDelegate));
    sut.apiClient = mockAPIClient;
    sut.delegate = mockDelegate;
    STPPaymentMethodCardParams *expectedCardParams = [STPFixtures paymentMethodCardParams];
    sut.paymentCell.paymentField.cardParams = expectedCardParams;

    STPPaymentMethod *expectedPaymentMethod = [STPFixtures paymentMethod];
    XCTestExpectation *createPaymentMethodExp = [self expectationWithDescription:@"createPaymentMethodWithCard"];
    OCMStub([mockAPIClient createPaymentMethodWithParams:[OCMArg any] completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation){
        STPPaymentMethodParams *paymentMethodParams;
        STPPaymentMethodCompletionBlock completion;
        [invocation getArgument:&paymentMethodParams atIndex:2];
        [invocation getArgument:&completion atIndex:3];
        XCTAssertEqualObjects(paymentMethodParams.card.number, expectedCardParams.number);
        XCTAssertTrue(sut.loading);
        completion(expectedPaymentMethod, nil);
        [createPaymentMethodExp fulfill];
    });

    XCTestExpectation *didCreatePaymentMethodExp = [self expectationWithDescription:@"didCreatePaymentMethod"];
    OCMStub([mockDelegate addCardViewController:[OCMArg any] didCreatePaymentMethod:[OCMArg any] completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation){
        STPPaymentMethod *paymentMethod;
        STPErrorBlock completion;
        [invocation getArgument:&paymentMethod atIndex:3];
        [invocation getArgument:&completion atIndex:4];
        XCTAssertTrue(sut.loading);
        XCTAssertEqualObjects(paymentMethod.stripeId, expectedPaymentMethod.stripeId);
        completion(nil);
        XCTAssertFalse(sut.loading);
        [didCreatePaymentMethodExp fulfill];
    });

    // tap next button
    UIBarButtonItem *nextButton = sut.navigationItem.rightBarButtonItem;
    [nextButton.target performSelector:nextButton.action withObject:nextButton];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

#pragma clang diagnostic pop

@end
