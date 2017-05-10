//
//  STPAddSourceViewControllerTest.m
//  Stripe
//
//  Created by Ben Guo on 3/28/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <Stripe/Stripe.h>
#import "STPAddressViewModel.h"
#import "STPFixtures.h"
#import "STPIBANTableViewCell.h"
#import "STPPaymentCardTextFieldCell.h"
#import "STPTextFieldTableViewCell.h"

@interface STPAddSourceViewController (Testing)
@property(nonatomic)STPAPIClient *apiClient;
@property(nonatomic)BOOL loading;
@property(nonatomic)STPTextFieldTableViewCell *nameCell;
@property(nonatomic)STPIBANTableViewCell *ibanCell;
@property(nonatomic)STPPaymentCardTextFieldCell *cardCell;
@property(nonatomic)STPAddressViewModel *addressViewModel;
@end

@interface STPAddSourceViewControllerTest : XCTestCase

@end

@implementation STPAddSourceViewControllerTest

- (STPAddSourceViewController *)buildAddSourceViewControllerWithType:(STPSourceType)type {
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
    if (type == STPSourceTypeCard) {
        config.requiredBillingAddressFields = STPBillingAddressFieldsFull;
    }
    STPTheme *theme = [STPTheme defaultTheme];
    STPAddSourceViewController *vc = [[STPAddSourceViewController alloc] initWithSourceType:type
                                                                              configuration:config
                                                                                      theme:theme];
    return vc;
}

- (STPAdditionalSourceInfo *)buildSourceInfo {
    STPAdditionalSourceInfo *info = [STPAdditionalSourceInfo new];
    info.metadata = @{@"foo": @"bar"};
    return info;
}

- (STPUserInformation *)buildUserInfoForCardTests {
    STPUserInformation *info = [STPUserInformation new];
    info.billingAddress = [STPFixtures address];
    return info;
}

- (STPUserInformation *)buildUserInfoForSEPATests {
    STPUserInformation *info = [STPUserInformation new];
    return info;
}

- (void)testInitWithValidSourceTypesNotNil {
    STPAddSourceViewController *cardVC = [self buildAddSourceViewControllerWithType:STPSourceTypeCard];
    XCTAssertNotNil(cardVC);
    STPAddSourceViewController *sepaVC = [self buildAddSourceViewControllerWithType:STPSourceTypeSEPADebit];
    XCTAssertNotNil(sepaVC);
}

- (void)testInitWithInvalidSourceTypeReturnsNil {
    STPAddSourceViewController *sut = [self buildAddSourceViewControllerWithType:STPSourceTypeBancontact];
    XCTAssertNil(sut);
}

- (BOOL)sourceParams:(STPSourceParams *)sourceParams matchCardParams:(STPCardParams *)cardParams {
    return ([sourceParams.additionalAPIParameters[@"card"][@"number"] isEqualToString:cardParams.number] &&
            [sourceParams.additionalAPIParameters[@"card"][@"cvc"] isEqualToString:cardParams.cvc] &&
            [sourceParams.additionalAPIParameters[@"card"][@"exp_month"] isEqual:@(cardParams.expMonth)] &&
            [sourceParams.additionalAPIParameters[@"card"][@"exp_year"]  isEqual:@(cardParams.expYear)]);
}

- (BOOL)sourceParams:(STPSourceParams *)sourceParams matchBillingAddress:(STPAddress *)address {
    return ([sourceParams.owner[@"name"] isEqualToString:address.name] &&
            [sourceParams.owner[@"address"][@"line1"] isEqualToString:address.line1] &&
            [sourceParams.owner[@"address"][@"line2"] isEqualToString:address.line2] &&
            [sourceParams.owner[@"address"][@"city"] isEqualToString:address.city] &&
            [sourceParams.owner[@"address"][@"state"] isEqualToString:address.state] &&
            [sourceParams.owner[@"address"][@"country"] isEqualToString:address.country] &&
            [sourceParams.owner[@"address"][@"postal_code"] isEqualToString:address.postalCode]);
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

#pragma mark - Card

- (void)testCard_nextWithCreateSourceError {
    STPAddSourceViewController *sut = [self buildAddSourceViewControllerWithType:STPSourceTypeCard];
    STPUserInformation *userInfo = [self buildUserInfoForCardTests];
    sut.prefilledInformation = userInfo;
    STPAdditionalSourceInfo *sourceInfo = [self buildSourceInfo];
    sut.sourceInformation = sourceInfo;
    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    sut.apiClient = mockAPIClient;
    XCTAssertNotNil(sut.view);

    STPCardParams *cardParams = [STPFixtures cardParams];
    sut.cardCell.paymentField.cardParams = cardParams;

    XCTestExpectation *exp = [self expectationWithDescription:@"createSource"];
    OCMStub([mockAPIClient createSourceWithParams:[OCMArg any] completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation){
        STPSourceParams *sourceParams;
        STPTokenCompletionBlock completion;
        [invocation getArgument:&sourceParams atIndex:2];
        [invocation getArgument:&completion atIndex:3];
        XCTAssertTrue([self sourceParams:sourceParams matchCardParams:cardParams]);
        XCTAssertTrue([self sourceParams:sourceParams matchBillingAddress:userInfo.billingAddress]);
        XCTAssertEqualObjects(sourceParams.metadata, sourceInfo.metadata);
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

- (void)testCard_nextWithCreateSourceSuccessAndDidCreateSourceError {
    STPAddSourceViewController *sut = [self buildAddSourceViewControllerWithType:STPSourceTypeCard];
    STPUserInformation *userInfo = [self buildUserInfoForCardTests];
    sut.prefilledInformation = userInfo;
    STPAdditionalSourceInfo *sourceInfo = [self buildSourceInfo];
    sut.sourceInformation = sourceInfo;
    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    id mockDelegate = OCMProtocolMock(@protocol(STPAddSourceViewControllerDelegate));
    sut.apiClient = mockAPIClient;
    sut.delegate = mockDelegate;
    XCTAssertNotNil(sut.view);

    STPCardParams *cardParams = [STPFixtures cardParams];
    sut.cardCell.paymentField.cardParams = cardParams;

    STPSource *expectedSource = [STPFixtures cardSource];
    XCTestExpectation *createSourceExp = [self expectationWithDescription:@"createSource"];
    OCMStub([mockAPIClient createSourceWithParams:[OCMArg any] completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation){
        STPSourceParams *sourceParams;
        STPSourceCompletionBlock completion;
        [invocation getArgument:&sourceParams atIndex:2];
        [invocation getArgument:&completion atIndex:3];
        XCTAssertTrue([self sourceParams:sourceParams matchCardParams:cardParams]);
        XCTAssertTrue([self sourceParams:sourceParams matchBillingAddress:userInfo.billingAddress]);
        XCTAssertEqualObjects(sourceParams.metadata, sourceInfo.metadata);
        XCTAssertTrue(sut.loading);
        completion(expectedSource, nil);
        [createSourceExp fulfill];
    });

    XCTestExpectation *didCreateSourceExp = [self expectationWithDescription:@"didCreateSource"];
    OCMStub([mockDelegate addSourceViewController:[OCMArg any] didCreateSource:[OCMArg any] completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation){
        STPSource *source;
        STPErrorBlock completion;
        [invocation getArgument:&source atIndex:3];
        [invocation getArgument:&completion atIndex:4];
        XCTAssertTrue(sut.loading);
        NSError *error = [NSError stp_genericFailedToParseResponseError];
        XCTAssertEqualObjects(source.stripeID, expectedSource.stripeID);
        completion(error);
        XCTAssertFalse(sut.loading);
        [didCreateSourceExp fulfill];
    });

    // tap next button
    UIBarButtonItem *nextButton = sut.navigationItem.rightBarButtonItem;
    [nextButton.target performSelector:nextButton.action withObject:nextButton];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testCard_nextWithCreateSourceSuccessAndDidCreateSourceSuccess {
    STPAddSourceViewController *sut = [self buildAddSourceViewControllerWithType:STPSourceTypeCard];
    STPUserInformation *userInfo = [self buildUserInfoForCardTests];
    sut.prefilledInformation = userInfo;
    STPAdditionalSourceInfo *sourceInfo = [self buildSourceInfo];
    sut.sourceInformation = sourceInfo;
    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    id mockDelegate = OCMProtocolMock(@protocol(STPAddSourceViewControllerDelegate));
    sut.apiClient = mockAPIClient;
    sut.delegate = mockDelegate;
    XCTAssertNotNil(sut.view);

    STPCardParams *cardParams = [STPFixtures cardParams];
    sut.cardCell.paymentField.cardParams = cardParams;

    STPSource *expectedSource = [STPFixtures cardSource];
    XCTestExpectation *createSourceExp = [self expectationWithDescription:@"createSource"];
    OCMStub([mockAPIClient createSourceWithParams:[OCMArg any] completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation){
        STPSourceParams *sourceParams;
        STPSourceCompletionBlock completion;
        [invocation getArgument:&sourceParams atIndex:2];
        [invocation getArgument:&completion atIndex:3];
        XCTAssertTrue([self sourceParams:sourceParams matchCardParams:cardParams]);
        XCTAssertTrue([self sourceParams:sourceParams matchBillingAddress:userInfo.billingAddress]);
        XCTAssertEqualObjects(sourceParams.metadata, sourceInfo.metadata);
        XCTAssertTrue(sut.loading);
        completion(expectedSource, nil);
        [createSourceExp fulfill];
    });

    XCTestExpectation *didCreateSourceExp = [self expectationWithDescription:@"didCreateSource"];
    OCMStub([mockDelegate addSourceViewController:[OCMArg any] didCreateSource:[OCMArg any] completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation){
        STPSource *source;
        STPErrorBlock completion;
        [invocation getArgument:&source atIndex:3];
        [invocation getArgument:&completion atIndex:4];
        XCTAssertTrue(sut.loading);
        XCTAssertEqualObjects(source.stripeID, expectedSource.stripeID);
        completion(nil);
        XCTAssertFalse(sut.loading);
        [didCreateSourceExp fulfill];
    });

    // tap next button
    UIBarButtonItem *nextButton = sut.navigationItem.rightBarButtonItem;
    [nextButton.target performSelector:nextButton.action withObject:nextButton];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

#pragma mark - SEPA Debit

- (void)testSEPA_nextWithCreateSourceError {
    STPAddSourceViewController *sut = [self buildAddSourceViewControllerWithType:STPSourceTypeSEPADebit];
    STPUserInformation *userInfo = [self buildUserInfoForSEPATests];
    sut.prefilledInformation = userInfo;
    STPAdditionalSourceInfo *sourceInfo = [self buildSourceInfo];
    sut.sourceInformation = sourceInfo;
    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    sut.apiClient = mockAPIClient;
    XCTAssertNotNil(sut.view);

    sut.ibanCell.contents = @"DE89370400440532013000";
    sut.nameCell.contents = @"Jenny Rosen";

    XCTestExpectation *exp = [self expectationWithDescription:@"createSource"];
    OCMStub([mockAPIClient createSourceWithParams:[OCMArg any] completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation){
        STPSourceParams *sourceParams;
        STPTokenCompletionBlock completion;
        [invocation getArgument:&sourceParams atIndex:2];
        [invocation getArgument:&completion atIndex:3];
        XCTAssertEqualObjects(sourceParams.additionalAPIParameters[@"sepa_debit"][@"iban"], sut.ibanCell.contents);
        XCTAssertEqualObjects(sourceParams.owner[@"name"], sut.nameCell.contents);
        XCTAssertEqualObjects(sourceParams.metadata, sourceInfo.metadata);
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

- (void)testSEPA_nextWithCreateSourceSuccessAndDidCreateSourceError {
    STPAddSourceViewController *sut = [self buildAddSourceViewControllerWithType:STPSourceTypeSEPADebit];
    STPUserInformation *userInfo = [self buildUserInfoForSEPATests];
    sut.prefilledInformation = userInfo;
    STPAdditionalSourceInfo *sourceInfo = [self buildSourceInfo];
    sut.sourceInformation = sourceInfo;
    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    id mockDelegate = OCMProtocolMock(@protocol(STPAddSourceViewControllerDelegate));
    sut.apiClient = mockAPIClient;
    sut.delegate = mockDelegate;
    XCTAssertNotNil(sut.view);

    sut.ibanCell.contents = @"DE89370400440532013000";
    sut.nameCell.contents = @"Jenny Rosen";

    STPSource *expectedSource = [STPFixtures sepaDebitSource];
    XCTestExpectation *createSourceExp = [self expectationWithDescription:@"createSource"];
    OCMStub([mockAPIClient createSourceWithParams:[OCMArg any] completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation){
        STPSourceParams *sourceParams;
        STPSourceCompletionBlock completion;
        [invocation getArgument:&sourceParams atIndex:2];
        [invocation getArgument:&completion atIndex:3];
        XCTAssertEqualObjects(sourceParams.additionalAPIParameters[@"sepa_debit"][@"iban"], sut.ibanCell.contents);
        XCTAssertEqualObjects(sourceParams.owner[@"name"], sut.nameCell.contents);
        XCTAssertEqualObjects(sourceParams.metadata, sourceInfo.metadata);
        XCTAssertTrue(sut.loading);
        completion(expectedSource, nil);
        [createSourceExp fulfill];
    });

    XCTestExpectation *didCreateSourceExp = [self expectationWithDescription:@"didCreateSource"];
    OCMStub([mockDelegate addSourceViewController:[OCMArg any] didCreateSource:[OCMArg any] completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation){
        STPSource *source;
        STPErrorBlock completion;
        [invocation getArgument:&source atIndex:3];
        [invocation getArgument:&completion atIndex:4];
        XCTAssertTrue(sut.loading);
        NSError *error = [NSError stp_genericFailedToParseResponseError];
        XCTAssertEqualObjects(source.stripeID, expectedSource.stripeID);
        completion(error);
        XCTAssertFalse(sut.loading);
        [didCreateSourceExp fulfill];
    });

    // tap next button
    UIBarButtonItem *nextButton = sut.navigationItem.rightBarButtonItem;
    [nextButton.target performSelector:nextButton.action withObject:nextButton];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testSEPA_nextWithCreateSourceSuccessAndDidCreateSourceSuccess {
    STPAddSourceViewController *sut = [self buildAddSourceViewControllerWithType:STPSourceTypeSEPADebit];
    STPUserInformation *userInfo = [self buildUserInfoForSEPATests];
    sut.prefilledInformation = userInfo;
    STPAdditionalSourceInfo *sourceInfo = [self buildSourceInfo];
    sut.sourceInformation = sourceInfo;
    id mockAPIClient = OCMClassMock([STPAPIClient class]);
    id mockDelegate = OCMProtocolMock(@protocol(STPAddSourceViewControllerDelegate));
    sut.apiClient = mockAPIClient;
    sut.delegate = mockDelegate;
    XCTAssertNotNil(sut.view);

    sut.ibanCell.contents = @"DE89370400440532013000";
    sut.nameCell.contents = @"Jenny Rosen";

    STPSource *expectedSource = [STPFixtures sepaDebitSource];
    XCTestExpectation *createSourceExp = [self expectationWithDescription:@"createSource"];
    OCMStub([mockAPIClient createSourceWithParams:[OCMArg any] completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation){
        STPSourceParams *sourceParams;
        STPSourceCompletionBlock completion;
        [invocation getArgument:&sourceParams atIndex:2];
        [invocation getArgument:&completion atIndex:3];
        XCTAssertEqualObjects(sourceParams.additionalAPIParameters[@"sepa_debit"][@"iban"], sut.ibanCell.contents);
        XCTAssertEqualObjects(sourceParams.owner[@"name"], sut.nameCell.contents);
        XCTAssertEqualObjects(sourceParams.metadata, sourceInfo.metadata);
        XCTAssertTrue(sut.loading);
        completion(expectedSource, nil);
        [createSourceExp fulfill];
    });

    XCTestExpectation *didCreateSourceExp = [self expectationWithDescription:@"didCreateSource"];
    OCMStub([mockDelegate addSourceViewController:[OCMArg any] didCreateSource:[OCMArg any] completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation){
        STPSource *source;
        STPErrorBlock completion;
        [invocation getArgument:&source atIndex:3];
        [invocation getArgument:&completion atIndex:4];
        XCTAssertTrue(sut.loading);
        XCTAssertEqualObjects(source.stripeID, expectedSource.stripeID);
        completion(nil);
        XCTAssertFalse(sut.loading);
        [didCreateSourceExp fulfill];
    });

    // tap next button
    UIBarButtonItem *nextButton = sut.navigationItem.rightBarButtonItem;
    [nextButton.target performSelector:nextButton.action withObject:nextButton];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

#pragma clang diagnostic pop

@end
