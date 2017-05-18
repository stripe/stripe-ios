//
//  STPPaymentContext3DSTest.m
//  Stripe
//
//  Created by Ben Guo on 4/14/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <SafariServices/SafariServices.h>
#import "STPAPIClient.h"
#import "STPAPIClient+OCMStub.h"
#import "STPFixtures.h"
#import "STPFormEncoder.h"
#import "STPMocks.h"
#import "STPSource+Private.h"
#import "STPSourcePrecheckParams.h"
#import "STPSourcePrecheckResult.h"
#import "STPTestUtils.h"
#import "StripeError.h"

@interface STPPaymentContext (Testing)
@property(nonatomic)id<STPPaymentMethod> selectedPaymentMethod;
@property(nonatomic)STPAPIClient *apiClient;
@end

@interface STPPaymentContext3DSTest : XCTestCase
@property (nonatomic) STPPaymentConfiguration *config;
@property (nonatomic) STPPaymentContext *sut;
@property (nonatomic) id mockHostViewController;
@property (nonatomic) id mockAPIClient;
@property (nonatomic) id mockDelegate;
@property (nonatomic) STPSourceParams *expectedSourceParams;
@end

/**
 These tests cover 3DS behavior in STPPaymentContext
 */
@implementation STPPaymentContext3DSTest

- (void)setUp {
    [super setUp];
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
    config.availablePaymentMethodTypes = @[[STPPaymentMethodType card]];
    config.returnURL = [NSURL URLWithString:@"test://redirect"];
    self.config = config;
    STPCustomer *customer = [STPFixtures customerWithNoSources];
    STPPaymentContext *paymentContext = [STPFixtures paymentContextWithCustomer:customer
                                                                  configuration:config];
    paymentContext.paymentAmount = 1099;
    paymentContext.paymentCurrency = @"cad";
    STPAdditionalSourceInfo *sourceInfo = [STPAdditionalSourceInfo new];
    sourceInfo.metadata = @{@"foo": @"bar"};
    sourceInfo.statementDescriptor = @"ORDER 123";
    paymentContext.sourceInformation = sourceInfo;
    self.mockHostViewController = [STPMocks hostViewController];
    paymentContext.hostViewController = self.mockHostViewController;
    self.mockAPIClient = OCMClassMock([STPAPIClient class]);
    paymentContext.apiClient = self.mockAPIClient;
    self.mockDelegate = OCMProtocolMock(@protocol(STPPaymentContextDelegate));
    paymentContext.delegate = self.mockDelegate;
    self.sut = paymentContext;
}

- (STPSource *)cardSourceWith3DSStatus:(NSString *)threeDSStatus {
    NSMutableDictionary *json = [[STPTestUtils jsonNamed:@"CardSource"] mutableCopy];
    NSMutableDictionary *cardDict = [json[@"card"] mutableCopy];
    cardDict[@"three_d_secure"] = threeDSStatus;
    json[@"card"] = cardDict;
    return [STPSource decodedObjectFromAPIResponse:json];
}

- (STPSource *)threeDSSourceWithStatus:(NSString *)status {
    NSMutableDictionary *json = [[STPTestUtils jsonNamed:@"3DSSource"] mutableCopy];
    json[@"status"] = status;
    return [STPSource decodedObjectFromAPIResponse:json];
}

- (STPSourcePrecheckResult *)precheckResultWithRequiredActions:(NSArray<NSString *> *)requiredActions {
    NSMutableDictionary *json = [[STPTestUtils jsonNamed:@"PrecheckResult"] mutableCopy];
    json[@"required_actions"] = requiredActions;
    return [STPSourcePrecheckResult decodedObjectFromAPIResponse:json];
}

- (STPSourceParams *)expected3DSParamsForSource:(STPSource *)source {
    STPSourceParams *expectedParams = [STPSourceParams threeDSecureParamsWithAmount:self.sut.paymentAmount
                                                                           currency:self.sut.paymentCurrency
                                                                          returnURL:self.config.returnURL.absoluteString
                                                                               card:source.stripeID];
    expectedParams.metadata = self.sut.sourceInformation.metadata;
    return expectedParams;
}

- (BOOL)threeDSParams:(STPSourceParams *)sourceParams matchCardSource:(STPSource *)cardSource {
    NSDictionary *dict = [STPFormEncoder dictionaryForObject:sourceParams];
    STPSourceParams *expectedParams = [self expected3DSParamsForSource:cardSource];
    NSDictionary *expectedDict = [STPFormEncoder dictionaryForObject:expectedParams];
    return [expectedDict isEqualToDictionary:dict];
}



- (BOOL)precheckParams:(STPSourcePrecheckParams *)precheckParams matchPaymentContext:(STPPaymentContext *)paymentContext {

    id<STPSourceProtocol> source = nil;
    if ([paymentContext.selectedPaymentMethod conformsToProtocol:@protocol(STPSourceProtocol)]) {
        source = (id<STPSourceProtocol>)paymentContext.selectedPaymentMethod;
    }

    STPSourcePrecheckParams *expectedParams = [STPSourcePrecheckParams new];
    expectedParams.sourceID = source.stripeID;
    expectedParams.paymentAmount = @(paymentContext.paymentAmount);
    expectedParams.paymentCurrency = paymentContext.paymentCurrency;

    NSDictionary *dict = [STPFormEncoder dictionaryForObject:precheckParams];
    NSDictionary *expectedDict = [STPFormEncoder dictionaryForObject:expectedParams];
    return [expectedDict isEqualToDictionary:dict];
}

- (NSError *)paymentMethodNotAvailableError {
    NSDictionary *response = @{
                               @"error": @{
                                        @"type": @"invalid_request",
                                        @"code": @"payment_method_not_available"
                                       }
                               };
    return [NSError stp_errorFromStripeResponse:response];
}

#pragma mark - Stub helpers


- (void)stubAndVerifyCreateSourceCalledAndReturn3DSSource:(STPSource *)threeDSSource {
    [self stubAndVerifyCreateSourceCalledAndReturn3DSSource:threeDSSource
                                              returnedError:(threeDSSource == nil) ? [NSError stp_genericFailedToParseResponseError] : nil];
}

- (void)stubAndVerifyCreateSourceCalledAndReturn3DSSource:(STPSource *)threeDSSource
                                            returnedError:(NSError *)error {
    XCTestExpectation *createSourceExp = [self expectationWithDescription:@"createSource"];

    [STPAPIClient stub:self.mockAPIClient createSourceWithParamsCompletion:^(STPSourceParams * _Nonnull sourceParams, STPSourceCompletionBlock  _Nonnull completion) {
        XCTAssertTrue([self threeDSParams:sourceParams matchCardSource:(STPSource *)self.sut.selectedPaymentMethod]);
        completion(threeDSSource, error);
        [createSourceExp fulfill];
    }];
}

- (void)stubAndVerifyPrecheckCalledAndReturnResult:(STPSourcePrecheckResult *)precheckResult {
    XCTestExpectation *precheckSourceExp = [self expectationWithDescription:@"precheckSource"];

    NSError *error = (precheckResult == nil) ? [NSError stp_genericFailedToParseResponseError] : nil;

    [STPAPIClient stub:self.mockAPIClient precheckSourceWithParamsCompletion:^(STPSourcePrecheckParams *precheckParams, STPSourcePrecheckCompletionBlock completion) {
        XCTAssertTrue([self precheckParams:precheckParams matchPaymentContext:self.sut]);
        completion(precheckResult, error);
        [precheckSourceExp fulfill];
    }];

}

- (void)stubAndVerifyHostViewControllerPresentsViewControllerOfClass:(Class)vcClass {
    XCTestExpectation *vcExp = [self expectationWithDescription:@"present view controller"];
    BOOL (^checker)() = ^BOOL(id vc) {
        if ([vc isKindOfClass:vcClass]) {
            [vcExp fulfill];
            return YES;
        }
        return NO;
    };

    OCMStub([self.mockHostViewController presentViewController:[OCMArg checkWithBlock:checker]
                                                      animated:YES
                                                    completion:[OCMArg any]]);
}

- (void)stubAndVerifyDidCreatePaymentResultCalledWithSource:(STPSource *)source {
    XCTestExpectation *exp = [self expectationWithDescription:@"didCreatePaymentResult"];
    OCMStub([self.mockDelegate paymentContext:[OCMArg any] didCreatePaymentResult:[OCMArg any] completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation){
        STPPaymentResult *result;
        STPErrorBlock completion;
        [invocation getArgument:&result atIndex:3];
        [invocation getArgument:&completion atIndex:4];
        XCTAssertEqual(result.source, source);
        completion(nil);
        OCMVerify([self.mockDelegate paymentContext:[OCMArg any] didFinishWithStatus:STPPaymentStatusSuccess
                                              error:[OCMArg isNil]]);
        [exp fulfill];
    });
}

#pragma mark - 3DS disabled

/**
 When 3DS type is disabled, a card source with 3DS required should be returned
 in didCreatePaymentResult.
 */
- (void)test3DSDisabled {
    self.config.threeDSecureSupportType = STPThreeDSecureSupportTypeDisabled;
    STPSource *cardSource = [self cardSourceWith3DSStatus:@"required"];
    self.sut.selectedPaymentMethod = cardSource;
    OCMReject([self.mockHostViewController presentViewController:[OCMArg any] animated:YES completion:[OCMArg any]]);
    OCMReject([self.mockAPIClient createSourceWithParams:[OCMArg any] completion:[OCMArg any]]);

    [self stubAndVerifyDidCreatePaymentResultCalledWithSource:cardSource];

    [self.sut requestPayment];
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

#pragma mark - 3DS dynamic, not supported on card

/**
 When 3DS type is dynamic, a card source that does not support 3ds
 should behave the same as if 3DS is disabled
 */
- (void)test3DSDynamicNotSupportedOnCard {
    self.config.threeDSecureSupportType = STPThreeDSecureSupportTypeDynamic;
    STPSource *cardSource = [self cardSourceWith3DSStatus:@"not_supported"];
    self.sut.selectedPaymentMethod = cardSource;
    OCMReject([self.mockHostViewController presentViewController:[OCMArg any] animated:YES completion:[OCMArg any]]);
    OCMReject([self.mockAPIClient createSourceWithParams:[OCMArg any] completion:[OCMArg any]]);

    [self stubAndVerifyDidCreatePaymentResultCalledWithSource:cardSource];

    [self.sut requestPayment];
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

#pragma mark - 3DS dynamic, required on card

/**
 When 3DS type is dynamic, a card source with 3DS required
 should not hit precheck and proceed with charging the same as if
 the type were static
 */
- (void)test3DSDynamicRequiredOnCardAndStatusPending {
    self.config.threeDSecureSupportType = STPThreeDSecureSupportTypeDynamic;
    STPSource *cardSource = [self cardSourceWith3DSStatus:@"required"];
    self.sut.selectedPaymentMethod = cardSource;
    OCMReject([self.mockDelegate paymentContext:[OCMArg any] didCreatePaymentResult:[OCMArg any] completion:[OCMArg any]]);
    OCMReject([self.mockDelegate paymentContext:[OCMArg any] didFinishWithStatus:STPPaymentStatusSuccess error:[OCMArg any]]);
    OCMReject([self.mockAPIClient precheckSourceWithParams:[OCMArg any] completion:[OCMArg any]]);

    [self stubAndVerifyCreateSourceCalledAndReturn3DSSource:[self threeDSSourceWithStatus:@"pending"]];
    [self stubAndVerifyHostViewControllerPresentsViewControllerOfClass:[SFSafariViewController class]];

    [self.sut requestPayment];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

#pragma mark - 3DS dynamic, optional on card
/**
 When 3DS type is dynamic, a card source with 3DS optional
 should hit precheck. If it returns create 3ds source as a required action,
 a call to createSource should happen.If the created 3DS source has status 
 pending, SFSafariVC should be presented.
 */
- (void)test3DSDynamicOptionalOnCardRequiredOnPrecheckAndStatusPending {
    self.config.threeDSecureSupportType = STPThreeDSecureSupportTypeDynamic;
    STPSource *cardSource = [self cardSourceWith3DSStatus:@"optional"];
    self.sut.selectedPaymentMethod = cardSource;
    OCMReject([self.mockDelegate paymentContext:[OCMArg any] didCreatePaymentResult:[OCMArg any] completion:[OCMArg any]]);
    OCMReject([self.mockDelegate paymentContext:[OCMArg any] didFinishWithStatus:STPPaymentStatusSuccess error:[OCMArg any]]);

    [self stubAndVerifyPrecheckCalledAndReturnResult:[self precheckResultWithRequiredActions:@[STPSourcePrecheckRequiredActionCreateThreeDSecureSource]]];
    [self stubAndVerifyCreateSourceCalledAndReturn3DSSource:[self threeDSSourceWithStatus:@"pending"]];
    [self stubAndVerifyHostViewControllerPresentsViewControllerOfClass:[SFSafariViewController class]];

    [self.sut requestPayment];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

/**
 When 3DS type is dynamic, a card source with 3DS optional
 should hit precheck. If it returns no required actions, a 3ds source should not
 be created and instead the card source should be charged.
 */
- (void)test3DSDynamicOptionalOnCardNoActionOnPrecheck {
    self.config.threeDSecureSupportType = STPThreeDSecureSupportTypeDynamic;
    STPSource *cardSource = [self cardSourceWith3DSStatus:@"optional"];
    self.sut.selectedPaymentMethod = cardSource;
    OCMReject([self.mockHostViewController presentViewController:[OCMArg any] animated:YES completion:[OCMArg any]]);
    OCMReject([self.mockAPIClient createSourceWithParams:[OCMArg any] completion:[OCMArg any]]);

    [self stubAndVerifyPrecheckCalledAndReturnResult:[self precheckResultWithRequiredActions:@[]]];
    [self stubAndVerifyDidCreatePaymentResultCalledWithSource:cardSource];

    [self.sut requestPayment];
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

/**
 When 3DS type is dynamic, a card source with 3DS optional
 should hit precheck. If precheck errors, we should proceed as if
 it said to create a 3DS source
 */
- (void)test3DSDynamicOptionalOnCardErrorOnPrecheck {
    self.config.threeDSecureSupportType = STPThreeDSecureSupportTypeDynamic;
    STPSource *cardSource = [self cardSourceWith3DSStatus:@"optional"];
    self.sut.selectedPaymentMethod = cardSource;
    OCMReject([self.mockDelegate paymentContext:[OCMArg any] didCreatePaymentResult:[OCMArg any] completion:[OCMArg any]]);
    OCMReject([self.mockDelegate paymentContext:[OCMArg any] didFinishWithStatus:STPPaymentStatusSuccess error:[OCMArg any]]);

    [self stubAndVerifyPrecheckCalledAndReturnResult:[self precheckResultWithRequiredActions:nil]];
    [self stubAndVerifyCreateSourceCalledAndReturn3DSSource:[self threeDSSourceWithStatus:@"pending"]];
    [self stubAndVerifyHostViewControllerPresentsViewControllerOfClass:[SFSafariViewController class]];

    [self.sut requestPayment];
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

#pragma mark - 3DS static, required on card

/**
 When 3DS type is static, a card source with 3DS required should result in
 a call to createSource. If the created 3DS source has status pending, 
 SFSafariVC should be presented.
 */
- (void)test3DSStaticRequiredOnCardAndStatusPending {
    self.config.threeDSecureSupportType = STPThreeDSecureSupportTypeStatic;
    STPSource *cardSource = [self cardSourceWith3DSStatus:@"required"];
    self.sut.selectedPaymentMethod = cardSource;
    OCMReject([self.mockDelegate paymentContext:[OCMArg any] didCreatePaymentResult:[OCMArg any] completion:[OCMArg any]]);
    OCMReject([self.mockDelegate paymentContext:[OCMArg any] didFinishWithStatus:STPPaymentStatusSuccess error:[OCMArg any]]);

    [self stubAndVerifyCreateSourceCalledAndReturn3DSSource:[self threeDSSourceWithStatus:@"pending"]];
    [self stubAndVerifyHostViewControllerPresentsViewControllerOfClass:[SFSafariViewController class]];

    [self.sut requestPayment];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

/**
 When 3DS type is static, a card source with 3DS required should result in
 a call to createSource. If the created 3DS source has status failure, 
 didFinish should be called with status UserCancellation.
 */
- (void)test3DSStaticRequiredOnCardAndStatusFailure {
    self.config.threeDSecureSupportType = STPThreeDSecureSupportTypeStatic;
    STPSource *cardSource = [self cardSourceWith3DSStatus:@"required"];
    self.sut.selectedPaymentMethod = cardSource;
    OCMReject([self.mockDelegate paymentContext:[OCMArg any] didCreatePaymentResult:[OCMArg any] completion:[OCMArg any]]);
    OCMReject([self.mockHostViewController presentViewController:[OCMArg any] animated:YES completion:[OCMArg any]]);

    [self stubAndVerifyCreateSourceCalledAndReturn3DSSource:[self threeDSSourceWithStatus:@"failed"]];

    [self.sut requestPayment];

    [self waitForExpectationsWithTimeout:2 handler:nil];

    OCMVerify([self.mockDelegate paymentContext:[OCMArg any] didFinishWithStatus:STPPaymentStatusUserCancellation
                                          error:[OCMArg isNil]]);
}

/**
 When 3DS type is static, a card source with 3DS required should result in
 a call to createSource. If the created 3DS source has status chargeable,
 didFinish should be called with a success.
 */
- (void)test3DSStaticRequiredOnCardAndStatusChargeable {
    self.config.threeDSecureSupportType = STPThreeDSecureSupportTypeStatic;
    STPSource *cardSource = [self cardSourceWith3DSStatus:@"required"];
    self.sut.selectedPaymentMethod = cardSource;
    OCMReject([self.mockDelegate paymentContext:[OCMArg any] didCreatePaymentResult:[OCMArg any] completion:[OCMArg any]]);
    OCMReject([self.mockHostViewController presentViewController:[OCMArg any] animated:YES completion:[OCMArg any]]);

    [self stubAndVerifyCreateSourceCalledAndReturn3DSSource:[self threeDSSourceWithStatus:@"chargeable"]];

    [self.sut requestPayment];

    [self waitForExpectationsWithTimeout:2 handler:nil];

    OCMVerify([self.mockDelegate paymentContext:[OCMArg any] didFinishWithStatus:STPPaymentStatusSuccess
                                          error:[OCMArg isNil]]);
}

/**
 When 3DS type is static, a card source with 3DS required should result in
 a call to createSource. If the creating a 3DS source errors, didFinish should
 be called with the error.
 */
- (void)test3DSStaticRequiredOnCardAndSourceCreationErrors {
    self.config.threeDSecureSupportType = STPThreeDSecureSupportTypeStatic;
    STPSource *cardSource = [self cardSourceWith3DSStatus:@"required"];
    self.sut.selectedPaymentMethod = cardSource;
    OCMReject([self.mockDelegate paymentContext:[OCMArg any] didCreatePaymentResult:[OCMArg any] completion:[OCMArg any]]);
    OCMReject([self.mockHostViewController presentViewController:[OCMArg any] animated:YES completion:[OCMArg any]]);

    NSError *expectedError = [self paymentMethodNotAvailableError];
    [self stubAndVerifyCreateSourceCalledAndReturn3DSSource:nil
                                              returnedError:expectedError];

    [self.sut requestPayment];

    [self waitForExpectationsWithTimeout:2 handler:nil];

    OCMVerify([self.mockDelegate paymentContext:[OCMArg any] didFinishWithStatus:STPPaymentStatusError
                                          error:[OCMArg isEqual:expectedError]]);
}

#pragma mark - 3DS static, optional on card

/**
 When 3DS type is static, a card source with 3DS optional should result in
 a call to createSource. If the created 3DS source has status pending,
 SFSafariVC should be presented.
 */
- (void)test3DSStaticOptionalOnCardAndStatusPending {
    self.config.threeDSecureSupportType = STPThreeDSecureSupportTypeStatic;
    STPSource *cardSource = [self cardSourceWith3DSStatus:@"optional"];
    self.sut.selectedPaymentMethod = cardSource;
    OCMReject([self.mockDelegate paymentContext:[OCMArg any] didCreatePaymentResult:[OCMArg any] completion:[OCMArg any]]);
    OCMReject([self.mockDelegate paymentContext:[OCMArg any] didFinishWithStatus:STPPaymentStatusSuccess error:[OCMArg any]]);

    [self stubAndVerifyCreateSourceCalledAndReturn3DSSource:[self threeDSSourceWithStatus:@"pending"]];
    [self stubAndVerifyHostViewControllerPresentsViewControllerOfClass:[SFSafariViewController class]];

    [self.sut requestPayment];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

/**
 When 3DS type is static, a card source with 3DS optional should result in
 a call to createSource. If the created 3DS source has status failure,
 the original card source should be returned.
 */
- (void)test3DSStaticOptionalOnCardAndStatusFailure {
    self.config.threeDSecureSupportType = STPThreeDSecureSupportTypeStatic;
    STPSource *cardSource = [self cardSourceWith3DSStatus:@"optional"];
    self.sut.selectedPaymentMethod = cardSource;
    OCMReject([self.mockHostViewController presentViewController:[OCMArg any] animated:YES completion:[OCMArg any]]);

    [self stubAndVerifyCreateSourceCalledAndReturn3DSSource:[self threeDSSourceWithStatus:@"failed"]];
    [self stubAndVerifyDidCreatePaymentResultCalledWithSource:cardSource];
    [self.sut requestPayment];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

/**
 When 3DS type is static, a card source with 3DS optional should result in
 a call to createSource. If the created 3DS source has status chargeable,
 didFinish should be called with a success.
 */
- (void)test3DSStaticOptionalOnCardAndStatusChargeable {
    self.config.threeDSecureSupportType = STPThreeDSecureSupportTypeStatic;
    STPSource *cardSource = [self cardSourceWith3DSStatus:@"optional"];
    self.sut.selectedPaymentMethod = cardSource;
    OCMReject([self.mockDelegate paymentContext:[OCMArg any] didCreatePaymentResult:[OCMArg any] completion:[OCMArg any]]);
    OCMReject([self.mockHostViewController presentViewController:[OCMArg any] animated:YES completion:[OCMArg any]]);

    [self stubAndVerifyCreateSourceCalledAndReturn3DSSource:[self threeDSSourceWithStatus:@"chargeable"]];

    [self.sut requestPayment];

    [self waitForExpectationsWithTimeout:2 handler:nil];

    OCMVerify([self.mockDelegate paymentContext:[OCMArg any] didFinishWithStatus:STPPaymentStatusSuccess
                                          error:[OCMArg isNil]]);
}

/**
 When 3DS type is static, a card source with 3DS optional should result in
 a call to createSource. If the creating a 3DS source errors, the original card
 source should be returned.
 */
- (void)test3DSStaticOptionalOnCardAndSourceCreationErrors {
    self.config.threeDSecureSupportType = STPThreeDSecureSupportTypeStatic;
    STPSource *cardSource = [self cardSourceWith3DSStatus:@"optional"];
    self.sut.selectedPaymentMethod = cardSource;
    OCMReject([self.mockHostViewController presentViewController:[OCMArg any] animated:YES completion:[OCMArg any]]);

    NSError *expectedError = [self paymentMethodNotAvailableError];

    [self stubAndVerifyCreateSourceCalledAndReturn3DSSource:nil
                                              returnedError:expectedError];

    [self stubAndVerifyDidCreatePaymentResultCalledWithSource:cardSource];

    [self.sut requestPayment];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}


@end
