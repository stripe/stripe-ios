//
//  STPPaymentMethodsViewControllerTest.m
//  Stripe
//
//  Created by Ben Guo on 4/10/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "STPFixtures.h"
#import "STPMocks.h"
#import "STPPaymentMethodsInternalViewController.h"

@interface STPPaymentMethodsViewController (Testing)
@property(nonatomic, weak)UIViewController *internalViewController;
@end

@interface STPPaymentMethodsViewControllerTest : XCTestCase

@end

@implementation STPPaymentMethodsViewControllerTest

- (STPPaymentMethodsViewController *)buildViewControllerWithCustomer:(STPCustomer *)customer
                                                       configuration:(STPPaymentConfiguration *)config
                                                            delegate:(id<STPPaymentMethodsViewControllerDelegate>)delegate {
    STPTheme *theme = [STPTheme defaultTheme];
    id<STPBackendAPIAdapter> mockAPIAdapter = [STPMocks staticAPIAdapterWithCustomer:customer];
    STPPaymentMethodsViewController *vc = [[STPPaymentMethodsViewController alloc] initWithConfiguration:config
                                                                                                   theme:theme
                                                                                              apiAdapter:mockAPIAdapter
                                                                                                delegate:delegate];
    if (vc) {
        XCTAssertNotNil(vc.view);
    }
    return vc;
}

/**
 When the customer has no sources and the configuration doesn't use sources,
 STPAddCardViewController should be shown.
 */
- (void)testInitWithNoSourcesAndUseSourcesOff {
    STPCustomer *customer = [STPFixtures customerWithNoSources];
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
    config.useSourcesForCards = NO;
    id<STPPaymentMethodsViewControllerDelegate>delegate = OCMProtocolMock(@protocol(STPPaymentMethodsViewControllerDelegate));
    STPPaymentMethodsViewController *sut = [self buildViewControllerWithCustomer:customer
                                                                   configuration:config
                                                                        delegate:delegate];
    XCTAssertTrue([sut.internalViewController isKindOfClass:[STPAddCardViewController class]]);
}

/**
 When the customer has no sources and the configuration uses sources,
 STPAddSourceViewController should be shown.
 */
- (void)testInitWithNoSourcesAndUseSourcesOn {
    STPCustomer *customer = [STPFixtures customerWithNoSources];
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
    config.useSourcesForCards = YES;
    id<STPPaymentMethodsViewControllerDelegate>delegate = OCMProtocolMock(@protocol(STPPaymentMethodsViewControllerDelegate));
    STPPaymentMethodsViewController *sut = [self buildViewControllerWithCustomer:customer
                                                                   configuration:config
                                                                        delegate:delegate];
    XCTAssertTrue([sut.internalViewController isKindOfClass:[STPAddSourceViewController class]]);
}

/**
 When the customer has no sources and the configuration uses sources,
 STPPaymentMethodsInternalVC should be shown.
 */
- (void)testInitWithSingleCardSource {
    STPCustomer *customer = [STPFixtures customerWithSingleCardTokenSource];
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
    id<STPPaymentMethodsViewControllerDelegate>delegate = OCMProtocolMock(@protocol(STPPaymentMethodsViewControllerDelegate));
    STPPaymentMethodsViewController *sut = [self buildViewControllerWithCustomer:customer
                                                                   configuration:config
                                                                        delegate:delegate];
    XCTAssertTrue([sut.internalViewController isKindOfClass:[STPPaymentMethodsInternalViewController class]]);
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
    config.useSourcesForCards = NO;
    id<STPPaymentMethodsViewControllerDelegate>delegate = OCMProtocolMock(@protocol(STPPaymentMethodsViewControllerDelegate));
    STPPaymentMethodsViewController *sut = [self buildViewControllerWithCustomer:customer
                                                                   configuration:config
                                                                        delegate:delegate];
    XCTAssertTrue([sut.internalViewController isKindOfClass:[STPAddCardViewController class]]);
    UIBarButtonItem *cancelButton = sut.internalViewController.navigationItem.leftBarButtonItem;
    [cancelButton.target performSelector:cancelButton.action withObject:cancelButton];

    OCMVerify([delegate paymentMethodsViewControllerDidCancel:[OCMArg any]]);
}

/**
 Tapping cancel in an internal AddSource view controller should result in a call to
 didCancel:
 */
- (void)testAddSourceCancelForwardsToDelegate {
    STPCustomer *customer = [STPFixtures customerWithNoSources];
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
    config.useSourcesForCards = YES;
    id<STPPaymentMethodsViewControllerDelegate>delegate = OCMProtocolMock(@protocol(STPPaymentMethodsViewControllerDelegate));
    STPPaymentMethodsViewController *sut = [self buildViewControllerWithCustomer:customer
                                                                   configuration:config
                                                                        delegate:delegate];
    XCTAssertTrue([sut.internalViewController isKindOfClass:[STPAddSourceViewController class]]);
    UIBarButtonItem *cancelButton = sut.internalViewController.navigationItem.leftBarButtonItem;
    [cancelButton.target performSelector:cancelButton.action withObject:cancelButton];

    OCMVerify([delegate paymentMethodsViewControllerDidCancel:[OCMArg any]]);
}

/**
 Tapping cancel in an internal PaymentMethodsInternal view controller should
 result in a call to didCancel:
 */
- (void)testInternalCancelForwardsToDelegate {
    STPCustomer *customer = [STPFixtures customerWithSingleCardTokenSource];
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
    id<STPPaymentMethodsViewControllerDelegate>delegate = OCMProtocolMock(@protocol(STPPaymentMethodsViewControllerDelegate));
    STPPaymentMethodsViewController *sut = [self buildViewControllerWithCustomer:customer
                                                                   configuration:config
                                                                        delegate:delegate];
    XCTAssertTrue([sut.internalViewController isKindOfClass:[STPPaymentMethodsInternalViewController class]]);
    UIBarButtonItem *cancelButton = sut.internalViewController.navigationItem.leftBarButtonItem;
    [cancelButton.target performSelector:cancelButton.action withObject:cancelButton];

    OCMVerify([delegate paymentMethodsViewControllerDidCancel:[OCMArg any]]);
}

/**
 When an AddSource view controller creates a source, it should be attached to the
 customer and the correct delegate methods should be called.
 */
- (void)testAddSourceAttachesToCustomerAndFinishes {
    STPTheme *theme = [STPTheme defaultTheme];
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
    config.useSourcesForCards = YES;
    STPCustomer *customer = [STPFixtures customerWithNoSources];
    id<STPBackendAPIAdapter> mockAPIAdapter = [STPMocks staticAPIAdapterWithCustomer:customer];
    id<STPPaymentMethodsViewControllerDelegate>delegate = OCMProtocolMock(@protocol(STPPaymentMethodsViewControllerDelegate));
    STPPaymentMethodsViewController *sut = [[STPPaymentMethodsViewController alloc] initWithConfiguration:config
                                                                                                   theme:theme
                                                                                              apiAdapter:mockAPIAdapter
                                                                                                delegate:delegate];
    XCTAssertNotNil(sut.view);
    XCTAssertTrue([sut.internalViewController isKindOfClass:[STPAddSourceViewController class]]);

    OCMStub([mockAPIAdapter attachSourceToCustomer:[OCMArg any] completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation){
        STPErrorBlock completion;
        [invocation getArgument:&completion atIndex:3];
        completion(nil);
    });

    STPAddSourceViewController *internal = (STPAddSourceViewController *)sut.internalViewController;
    XCTestExpectation *exp = [self expectationWithDescription:@"completion"];
    STPSource *expectedSource = [STPFixtures sepaDebitSource];
    [internal.delegate addSourceViewController:internal didCreateSource:expectedSource completion:^(NSError *error) {
        XCTAssertNil(error);
        [exp fulfill];
    }];

    BOOL (^checker)() = ^BOOL(id obj) {
        STPSource *source = (STPSource *)obj;
        return source.stripeID == expectedSource.stripeID;
    };
    OCMVerify([mockAPIAdapter attachSourceToCustomer:[OCMArg checkWithBlock:checker] completion:[OCMArg any]]);
    OCMVerify([mockAPIAdapter selectDefaultCustomerSource:[OCMArg checkWithBlock:checker] completion:[OCMArg any]]);
    OCMVerify([delegate paymentMethodsViewController:[OCMArg any] didSelectPaymentMethod:[OCMArg checkWithBlock:checker]]);
    OCMVerify([delegate paymentMethodsViewControllerDidFinish:[OCMArg any]]);
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

/**
 When an AddCard view controller creates a source, it should be attached to the
 customer and the correct delegate methods should be called.
 */
- (void)testAddCardAttachesToCustomerAndFinishes {
    STPTheme *theme = [STPTheme defaultTheme];
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
    config.useSourcesForCards = NO;
    STPCustomer *customer = [STPFixtures customerWithNoSources];
    id<STPBackendAPIAdapter> mockAPIAdapter = [STPMocks staticAPIAdapterWithCustomer:customer];
    id<STPPaymentMethodsViewControllerDelegate>delegate = OCMProtocolMock(@protocol(STPPaymentMethodsViewControllerDelegate));
    STPPaymentMethodsViewController *sut = [[STPPaymentMethodsViewController alloc] initWithConfiguration:config
                                                                                                    theme:theme
                                                                                               apiAdapter:mockAPIAdapter
                                                                                                 delegate:delegate];
    XCTAssertNotNil(sut.view);
    XCTAssertTrue([sut.internalViewController isKindOfClass:[STPAddCardViewController class]]);

    OCMStub([mockAPIAdapter attachSourceToCustomer:[OCMArg any] completion:[OCMArg any]])
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

    BOOL (^tokenChecker)() = ^BOOL(id obj) {
        STPToken *token = (STPToken *)obj;
        return token.stripeID == expectedToken.stripeID;
    };
    BOOL (^cardChecker)() = ^BOOL(id obj) {
        STPCard *card = (STPCard *)obj;
        return card.stripeID == expectedToken.card.stripeID;
    };
    OCMVerify([mockAPIAdapter attachSourceToCustomer:[OCMArg checkWithBlock:tokenChecker] completion:[OCMArg any]]);
    OCMVerify([mockAPIAdapter selectDefaultCustomerSource:[OCMArg checkWithBlock:cardChecker] completion:[OCMArg any]]);
    OCMVerify([delegate paymentMethodsViewController:[OCMArg any] didSelectPaymentMethod:[OCMArg checkWithBlock:cardChecker]]);
    OCMVerify([delegate paymentMethodsViewControllerDidFinish:[OCMArg any]]);
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

#pragma clang diagnostic pop

@end
