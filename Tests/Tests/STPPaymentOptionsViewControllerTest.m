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
                                                      paymentMethods:(NSArray<STPPaymentMethod *> *)paymentMethods
                                                       configuration:(STPPaymentConfiguration *)config
                                                            delegate:(id<STPPaymentOptionsViewControllerDelegate>)delegate {
    STPTheme *theme = [STPTheme defaultTheme];
    STPCustomerContext *mockCustomerContext = [STPMocks staticCustomerContextWithCustomer:customer paymentMethods:paymentMethods];
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
                                                                  paymentMethods:@[]
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
    NSArray *paymentMethods = @[[STPFixtures paymentMethod]];
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
    config.additionalPaymentOptions = STPPaymentOptionTypeAll;
    id<STPPaymentOptionsViewControllerDelegate>delegate = OCMProtocolMock(@protocol(STPPaymentOptionsViewControllerDelegate));
    STPPaymentOptionsViewController *sut = [self buildViewControllerWithCustomer:customer
                                                                  paymentMethods:paymentMethods
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
    NSArray *paymentMethods = @[[STPFixtures paymentMethod]];
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
    config.additionalPaymentOptions = STPPaymentOptionTypeNone;
    id<STPPaymentOptionsViewControllerDelegate>delegate = OCMProtocolMock(@protocol(STPPaymentOptionsViewControllerDelegate));
    STPPaymentOptionsViewController *sut = [self buildViewControllerWithCustomer:customer
                                                                  paymentMethods:paymentMethods
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
                                                                  paymentMethods:@[]
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
    NSArray *paymentMethods = @[[STPFixtures paymentMethod]];
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
    id<STPPaymentOptionsViewControllerDelegate>delegate = OCMProtocolMock(@protocol(STPPaymentOptionsViewControllerDelegate));
    STPPaymentOptionsViewController *sut = [self buildViewControllerWithCustomer:customer
                                                                  paymentMethods:paymentMethods
                                                                   configuration:config
                                                                        delegate:delegate];
    XCTAssertTrue([sut.internalViewController isKindOfClass:[STPPaymentOptionsInternalViewController class]]);
    UIBarButtonItem *cancelButton = sut.internalViewController.navigationItem.leftBarButtonItem;
    [cancelButton.target performSelector:cancelButton.action withObject:cancelButton];

    OCMVerify([delegate paymentOptionsViewControllerDidCancel:[OCMArg any]]);
}

/**
 When an AddCard view controller creates a card payment method, it should be attached to the
 customer and the correct delegate methods should be called.
 */
- (void)testAddCardAttachesToCustomerAndFinishes {
    STPTheme *theme = [STPTheme defaultTheme];
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
    STPCustomer *customer = [STPFixtures customerWithNoSources];
    STPCustomerContext *mockCustomerContext = [STPMocks staticCustomerContextWithCustomer:customer paymentMethods:@[]];
    id<STPPaymentOptionsViewControllerDelegate>delegate = OCMProtocolMock(@protocol(STPPaymentOptionsViewControllerDelegate));
    STPPaymentOptionsViewController *sut = [[STPPaymentOptionsViewController alloc] initWithConfiguration:config
                                                                                                    theme:theme
                                                                                          customerContext:mockCustomerContext
                                                                                                 delegate:delegate];
    XCTAssertNotNil(sut.view);
    XCTAssertTrue([sut.internalViewController isKindOfClass:[STPAddCardViewController class]]);

    OCMStub([mockCustomerContext attachPaymentMethodToCustomer:[OCMArg any] completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation){
        STPErrorBlock completion;
        [invocation getArgument:&completion atIndex:3];
        completion(nil);
    });

    STPAddCardViewController *internal = (STPAddCardViewController *)sut.internalViewController;
    XCTestExpectation *exp = [self expectationWithDescription:@"completion"];
    STPPaymentMethod *expectedPaymentMethod = [STPFixtures paymentMethod];
    [internal.delegate addCardViewController:internal didCreatePaymentMethod:expectedPaymentMethod completion:^(NSError *error) {
        XCTAssertNil(error);
        [exp fulfill];
    }];

    BOOL (^paymentMethodChecker)(id) = ^BOOL(id obj) {
        STPPaymentMethod *paymentMethod = (STPPaymentMethod *)obj;
        return paymentMethod.stripeId == expectedPaymentMethod.stripeId;
    };
    OCMVerify([mockCustomerContext attachPaymentMethodToCustomer:[OCMArg checkWithBlock:paymentMethodChecker] completion:[OCMArg any]]);
    OCMVerify([delegate paymentOptionsViewController:[OCMArg any] didSelectPaymentOption:[OCMArg checkWithBlock:paymentMethodChecker]]); // TODO: probably wrong block
    OCMVerify([delegate paymentOptionsViewControllerDidFinish:[OCMArg any]]);
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

#pragma clang diagnostic pop

@end
