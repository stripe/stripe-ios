//
//  STPPaymentOptionsViewControllerTest.m
//  Stripe
//
//  Created by Brian Dorfman on 10/10/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "STPFixtures.h"
#import "STPMocks.h"
#import "STPPaymentOptionsInternalViewController.h"

@interface STPPaymentOptionsViewController (Testing)
@property(nonatomic, weak)UIViewController *internalViewController;
@end

@interface STPPaymentOptionsViewControllerTest : XCTestCase
@end

@implementation STPPaymentOptionsViewControllerTest

- (STPPaymentOptionsViewController *)buildViewControllerWithCustomer:(STPCustomer *)customer
                                                       configuration:(STPPaymentConfiguration *)config
                                                            delegate:(id<STPPaymentOptionsViewControllerDelegate>)delegate {
    STPTheme *theme = [STPTheme defaultTheme];
    STPCustomerContext *mockCustomerContext = [STPMocks staticCustomerContextWithCustomer:customer];
    STPPaymentOptionsViewController *vc = [[STPPaymentOptionsViewController alloc] initWithConfiguration:config
                                                                                                   theme:theme
                                                                                         customerContext:mockCustomerContext
                                                                                                delegate:delegate];
    if (vc) {
        XCTAssertNotNil(vc.view);
    }
    return vc;
}

/**
 When the customer has no sources, and card is the sole available payment 
 method, STPAddCardViewController should be shown.
 */
- (void)testInitWithNoSourcesAndConfigWithUseSourcesOffAndCardAvailable {
    STPCustomer *customer = [STPFixtures customerWithNoSources];
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
    config.additionalPaymentOptions = STPPaymentOptionTypeNone;
    id<STPPaymentOptionsViewControllerDelegate>delegate = OCMProtocolMock(@protocol(STPPaymentOptionsViewControllerDelegate));
    STPPaymentOptionsViewController *sut = [self buildViewControllerWithCustomer:customer
                                                                   configuration:config
                                                                        delegate:delegate];
    XCTAssertTrue([sut.internalViewController isKindOfClass:[STPAddCardViewController class]]);
}

/**
 When the customer has a single card token source and the available payment methods
 are card and apple pay, STPPaymentOptionsInternalVC should be shown.
 */
- (void)testInitWithSingleCardTokenSourceAndCardAvailable {
    STPCustomer *customer = [STPFixtures customerWithSingleCardTokenSource];
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
    config.additionalPaymentOptions = STPPaymentOptionTypeAll;
    id<STPPaymentOptionsViewControllerDelegate>delegate = OCMProtocolMock(@protocol(STPPaymentOptionsViewControllerDelegate));
    STPPaymentOptionsViewController *sut = [self buildViewControllerWithCustomer:customer
                                                                   configuration:config
                                                                        delegate:delegate];
    XCTAssertTrue([sut.internalViewController isKindOfClass:[STPPaymentOptionsInternalViewController class]]);
}

/**
 When the customer has a single card source source and the available payment methods
 are card only, STPPaymentOptionsInternalVC should be shown.
 */
- (void)testInitWithSingleCardSourceSourceAndCardAvailable {
    STPCustomer *customer = [STPFixtures customerWithSingleCardSourceSource];
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
    config.additionalPaymentOptions = STPPaymentOptionTypeNone;
    id<STPPaymentOptionsViewControllerDelegate>delegate = OCMProtocolMock(@protocol(STPPaymentOptionsViewControllerDelegate));
    STPPaymentOptionsViewController *sut = [self buildViewControllerWithCustomer:customer
                                                                   configuration:config
                                                                        delegate:delegate];
    XCTAssertTrue([sut.internalViewController isKindOfClass:[STPPaymentOptionsInternalViewController class]]);
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

/**
 Tapping cancel in an internal AddCard view controller should result in a call to
 didCancel:
 */
- (void)testAddCardCancelForwardsToDelegate {
    STPCustomer *customer = [STPFixtures customerWithNoSources];
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
    id<STPPaymentOptionsViewControllerDelegate>delegate = OCMProtocolMock(@protocol(STPPaymentOptionsViewControllerDelegate));
    STPPaymentOptionsViewController *sut = [self buildViewControllerWithCustomer:customer
                                                                   configuration:config
                                                                        delegate:delegate];
    XCTAssertTrue([sut.internalViewController isKindOfClass:[STPAddCardViewController class]]);
    UIBarButtonItem *cancelButton = sut.internalViewController.navigationItem.leftBarButtonItem;
    [cancelButton.target performSelector:cancelButton.action withObject:cancelButton];

    OCMVerify([delegate paymentOptionsViewControllerDidCancel:[OCMArg any]]);
}

/**
 Tapping cancel in an internal PaymentOptionsInternal view controller should
 result in a call to didCancel:
 */
- (void)testInternalCancelForwardsToDelegate {
    STPCustomer *customer = [STPFixtures customerWithSingleCardTokenSource];
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
    id<STPPaymentOptionsViewControllerDelegate>delegate = OCMProtocolMock(@protocol(STPPaymentOptionsViewControllerDelegate));
    STPPaymentOptionsViewController *sut = [self buildViewControllerWithCustomer:customer
                                                                   configuration:config
                                                                        delegate:delegate];
    XCTAssertTrue([sut.internalViewController isKindOfClass:[STPPaymentOptionsInternalViewController class]]);
    UIBarButtonItem *cancelButton = sut.internalViewController.navigationItem.leftBarButtonItem;
    [cancelButton.target performSelector:cancelButton.action withObject:cancelButton];

    OCMVerify([delegate paymentOptionsViewControllerDidCancel:[OCMArg any]]);
}

/**
 When an AddCard view controller creates a card token, it should be attached to the
 customer and the correct delegate methods should be called.
 */
- (void)testAddCardAttachesToCustomerAndFinishes {
    STPTheme *theme = [STPTheme defaultTheme];
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
    STPCustomer *customer = [STPFixtures customerWithNoSources];
    STPCustomerContext *mockCustomerContext = [STPMocks staticCustomerContextWithCustomer:customer];
    id<STPPaymentOptionsViewControllerDelegate>delegate = OCMProtocolMock(@protocol(STPPaymentOptionsViewControllerDelegate));
    STPPaymentOptionsViewController *sut = [[STPPaymentOptionsViewController alloc] initWithConfiguration:config
                                                                                                    theme:theme
                                                                                          customerContext:mockCustomerContext
                                                                                                 delegate:delegate];
    XCTAssertNotNil(sut.view);
    XCTAssertTrue([sut.internalViewController isKindOfClass:[STPAddCardViewController class]]);

    OCMStub([mockCustomerContext attachSourceToCustomer:[OCMArg any] completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation){
        STPErrorBlock completion;
        [invocation getArgument:&completion atIndex:3];
        completion(nil);
    });

    STPAddCardViewController *internal = (STPAddCardViewController *)sut.internalViewController;
    XCTestExpectation *exp = [self expectationWithDescription:@"completion"];
    STPToken *expectedToken = [STPFixtures cardToken];
    [internal.delegate addCardViewController:internal didCreateToken:expectedToken completion:^(NSError *error) {
        XCTAssertNil(error);
        [exp fulfill];
    }];

    BOOL (^tokenChecker)(id) = ^BOOL(id obj) {
        STPToken *token = (STPToken *)obj;
        return token.stripeID == expectedToken.stripeID;
    };
    BOOL (^cardChecker)(id) = ^BOOL(id obj) {
        STPCard *card = (STPCard *)obj;
        return card.stripeID == expectedToken.card.stripeID;
    };
    OCMVerify([mockCustomerContext attachSourceToCustomer:[OCMArg checkWithBlock:tokenChecker] completion:[OCMArg any]]);
    OCMVerify([mockCustomerContext selectDefaultCustomerSource:[OCMArg checkWithBlock:cardChecker] completion:[OCMArg any]]);
    OCMVerify([delegate paymentOptionsViewController:[OCMArg any] didSelectPaymentOption:[OCMArg checkWithBlock:cardChecker]]);
    OCMVerify([delegate paymentOptionsViewControllerDidFinish:[OCMArg any]]);
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

/**
 When createCardSources is enabled, AddCardVC should create a card source and
 the correct delegate methods should be called.
 */
- (void)testCreatesCardSources {
    STPTheme *theme = [STPTheme defaultTheme];
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
    config.createCardSources = YES;
    STPCustomer *customer = [STPFixtures customerWithNoSources];
    STPCustomerContext *mockCustomerContext = [STPMocks staticCustomerContextWithCustomer:customer];
    id<STPPaymentOptionsViewControllerDelegate>delegate = OCMProtocolMock(@protocol(STPPaymentOptionsViewControllerDelegate));
    STPPaymentOptionsViewController *sut = [[STPPaymentOptionsViewController alloc] initWithConfiguration:config
                                                                                                    theme:theme
                                                                                          customerContext:mockCustomerContext
                                                                                                 delegate:delegate];
    XCTAssertNotNil(sut.view);
    XCTAssertTrue([sut.internalViewController isKindOfClass:[STPAddCardViewController class]]);

    OCMStub([mockCustomerContext attachSourceToCustomer:[OCMArg any] completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation){
        STPErrorBlock completion;
        [invocation getArgument:&completion atIndex:3];
        completion(nil);
    });

    STPAddCardViewController *internal = (STPAddCardViewController *)sut.internalViewController;
    XCTestExpectation *exp = [self expectationWithDescription:@"completion"];
    STPSource *expectedSource = [STPFixtures cardSource];
    [internal.delegate addCardViewController:internal didCreateSource:expectedSource completion:^(NSError *error) {
        XCTAssertNil(error);
        [exp fulfill];
    }];

    BOOL (^sourceChecker)(id<STPSourceProtocol>) = ^BOOL(id<STPSourceProtocol> obj) {
        STPSource *source = (STPSource *)obj;
        return source.stripeID == expectedSource.stripeID;
    };
    BOOL (^paymentOptionChecker)(id<STPPaymentOption>) = ^BOOL(id<STPPaymentOption> obj) {
        STPSource *source = (STPSource *)obj;
        return source.cardDetails.last4 == expectedSource.cardDetails.last4;
    };

    OCMVerify([mockCustomerContext attachSourceToCustomer:[OCMArg checkWithBlock:sourceChecker] completion:[OCMArg any]]);
    OCMVerify([mockCustomerContext selectDefaultCustomerSource:[OCMArg checkWithBlock:sourceChecker] completion:[OCMArg any]]);
    OCMVerify([delegate paymentOptionsViewController:[OCMArg any] didSelectPaymentOption:[OCMArg checkWithBlock:paymentOptionChecker]]);
    OCMVerify([delegate paymentOptionsViewControllerDidFinish:[OCMArg any]]);
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

#pragma clang diagnostic pop

@end
