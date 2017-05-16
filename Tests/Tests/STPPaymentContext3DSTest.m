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

    XCTestExpectation *exp = [self expectationWithDescription:@"didCreatePaymentResult"];
    OCMStub([self.mockDelegate paymentContext:[OCMArg any] didCreatePaymentResult:[OCMArg any] completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation){
        STPPaymentResult *result;
        STPErrorBlock completion;
        [invocation getArgument:&result atIndex:3];
        [invocation getArgument:&completion atIndex:4];
        XCTAssertEqual(result.source, cardSource);
        completion(nil);
        OCMVerify([self.mockDelegate paymentContext:[OCMArg any] didFinishWithStatus:STPPaymentStatusSuccess
                                              error:[OCMArg any]]);
        [exp fulfill];
    });

    [self.sut requestPayment];
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

#pragma mark - 3DS dynamic, optional on card precheck returns require 3ds
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

    XCTestExpectation *safariExp = [self expectationWithDescription:@"present SafariVC"];
    BOOL (^checker)() = ^BOOL(id vc) {
        if ([vc isKindOfClass:[SFSafariViewController class]]) {
            [safariExp fulfill];
            return YES;
        }
        return NO;
    };

    OCMStub([self.mockHostViewController presentViewController:[OCMArg checkWithBlock:checker]
                                                      animated:YES
                                                    completion:[OCMArg any]]);

    XCTestExpectation *precheckSourceExp = [self expectationWithDescription:@"precheckSource"];

    STPSourcePrecheckResult *precheckResult = [self precheckResultWithRequiredActions:@[STPSourcePrecheckRequiredActionCreateThreeDSecureSource]];
    [STPAPIClient stub:self.mockAPIClient precheckSourceWithParamsCompletion:^(STPSourcePrecheckParams *precheckParams, STPSourcePrecheckCompletionBlock completion) {
        XCTAssertTrue([self precheckParams:precheckParams matchPaymentContext:self.sut]);
        completion(precheckResult, nil);
        [precheckSourceExp fulfill];
    }];

    STPSource *threeDSSource = [self threeDSSourceWithStatus:@"pending"];
    XCTestExpectation *createSourceExp = [self expectationWithDescription:@"createSource"];

    [STPAPIClient stub:self.mockAPIClient createSourceWithParamsCompletion:^(STPSourceParams * _Nonnull sourceParams, STPSourceCompletionBlock  _Nonnull completion) {
        XCTAssertTrue([self threeDSParams:sourceParams matchCardSource:cardSource]);
        completion(threeDSSource, nil);
        [createSourceExp fulfill];
    }];

    [self.sut requestPayment];

    [self waitForExpectationsWithTimeout:2 handler:nil];

}

- (void)test3DSDynamicOptionalOnCardNoActionPrecheck {
    self.config.threeDSecureSupportType = STPThreeDSecureSupportTypeDynamic;
    STPSource *cardSource = [self cardSourceWith3DSStatus:@"optional"];
    self.sut.selectedPaymentMethod = cardSource;
    OCMReject([self.mockHostViewController presentViewController:[OCMArg any] animated:YES completion:[OCMArg any]]);

    XCTestExpectation *precheckSourceExp = [self expectationWithDescription:@"precheckSource"];

    STPSourcePrecheckResult *precheckResult = [self precheckResultWithRequiredActions:@[]];
    [STPAPIClient stub:self.mockAPIClient precheckSourceWithParamsCompletion:^(STPSourcePrecheckParams *precheckParams, STPSourcePrecheckCompletionBlock completion) {
        XCTAssertTrue([self precheckParams:precheckParams matchPaymentContext:self.sut]);
        completion(precheckResult, nil);
        [precheckSourceExp fulfill];
    }];

    XCTestExpectation *exp = [self expectationWithDescription:@"didCreatePaymentResult"];
    OCMStub([self.mockDelegate paymentContext:[OCMArg any] didCreatePaymentResult:[OCMArg any] completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation){
        STPPaymentResult *result;
        STPErrorBlock completion;
        [invocation getArgument:&result atIndex:3];
        [invocation getArgument:&completion atIndex:4];
        XCTAssertEqual(result.source, cardSource);
        completion(nil);
        OCMVerify([self.mockDelegate paymentContext:[OCMArg any] didFinishWithStatus:STPPaymentStatusSuccess
                                              error:[OCMArg any]]);
        [exp fulfill];
    });

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

    XCTestExpectation *safariExp = [self expectationWithDescription:@"present SafariVC"];
    BOOL (^checker)() = ^BOOL(id vc) {
        if ([vc isKindOfClass:[SFSafariViewController class]]) {
            [safariExp fulfill];
            return YES;
        }
        return NO;
    };
    OCMStub([self.mockHostViewController presentViewController:[OCMArg checkWithBlock:checker]
                                                      animated:YES
                                                    completion:[OCMArg any]]);

    STPSource *threeDSSource = [self threeDSSourceWithStatus:@"pending"];
    XCTestExpectation *createSourceExp = [self expectationWithDescription:@"createSource"];
    [STPAPIClient stub:self.mockAPIClient createSourceWithParamsCompletion:^(STPSourceParams * _Nonnull sourceParams, STPSourceCompletionBlock  _Nonnull completion) {
        XCTAssertTrue([self threeDSParams:sourceParams matchCardSource:cardSource]);
        completion(threeDSSource, nil);

        [createSourceExp fulfill];
    }];

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

    STPSource *threeDSSource = [self threeDSSourceWithStatus:@"failed"];
    XCTestExpectation *createSourceExp = [self expectationWithDescription:@"createSource"];
    [STPAPIClient stub:self.mockAPIClient createSourceWithParamsCompletion:^(STPSourceParams * _Nonnull sourceParams, STPSourceCompletionBlock  _Nonnull completion) {
        XCTAssertTrue([self threeDSParams:sourceParams matchCardSource:cardSource]);
        completion(threeDSSource, nil);
        OCMVerify([self.mockDelegate paymentContext:[OCMArg any] didFinishWithStatus:STPPaymentStatusUserCancellation
                                              error:[OCMArg isNil]]);
        [createSourceExp fulfill];
    }];

    [self.sut requestPayment];

    [self waitForExpectationsWithTimeout:2 handler:nil];
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

    STPSource *threeDSSource = [self threeDSSourceWithStatus:@"chargeable"];
    XCTestExpectation *createSourceExp = [self expectationWithDescription:@"createSource"];
    [STPAPIClient stub:self.mockAPIClient createSourceWithParamsCompletion:^(STPSourceParams * _Nonnull sourceParams, STPSourceCompletionBlock  _Nonnull completion) {
        XCTAssertTrue([self threeDSParams:sourceParams matchCardSource:cardSource]);
        completion(threeDSSource, nil);
        OCMVerify([self.mockDelegate paymentContext:[OCMArg any] didFinishWithStatus:STPPaymentStatusSuccess
                                              error:[OCMArg any]]);
        [createSourceExp fulfill];
    }];

    [self.sut requestPayment];

    [self waitForExpectationsWithTimeout:2 handler:nil];
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
    XCTestExpectation *createSourceExp = [self expectationWithDescription:@"createSource"];
    [STPAPIClient stub:self.mockAPIClient createSourceWithParamsCompletion:^(STPSourceParams * _Nonnull sourceParams, STPSourceCompletionBlock  _Nonnull completion) {
        XCTAssertTrue([self threeDSParams:sourceParams matchCardSource:cardSource]);
        completion(nil, expectedError);
        OCMVerify([self.mockDelegate paymentContext:[OCMArg any] didFinishWithStatus:STPPaymentStatusError
                                              error:[OCMArg isEqual:expectedError]]);
        [createSourceExp fulfill];
    }];

    [self.sut requestPayment];

    [self waitForExpectationsWithTimeout:2 handler:nil];
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

    XCTestExpectation *safariExp = [self expectationWithDescription:@"present SafariVC"];
    BOOL (^checker)() = ^BOOL(id vc) {
        if ([vc isKindOfClass:[SFSafariViewController class]]) {
            [safariExp fulfill];
            return YES;
        }
        return NO;
    };
    OCMStub([self.mockHostViewController presentViewController:[OCMArg checkWithBlock:checker]
                                                      animated:YES
                                                    completion:[OCMArg any]]);

    STPSource *threeDSSource = [self threeDSSourceWithStatus:@"pending"];
    XCTestExpectation *createSourceExp = [self expectationWithDescription:@"createSource"];
    [STPAPIClient stub:self.mockAPIClient createSourceWithParamsCompletion:^(STPSourceParams * _Nonnull sourceParams, STPSourceCompletionBlock  _Nonnull completion) {
        XCTAssertTrue([self threeDSParams:sourceParams matchCardSource:cardSource]);
        completion(threeDSSource, nil);

        [createSourceExp fulfill];
    }];

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

    STPSource *threeDSSource = [self threeDSSourceWithStatus:@"failed"];
    XCTestExpectation *createSourceExp = [self expectationWithDescription:@"createSource"];
    [STPAPIClient stub:self.mockAPIClient createSourceWithParamsCompletion:^(STPSourceParams * _Nonnull sourceParams, STPSourceCompletionBlock  _Nonnull completion) {
        XCTAssertTrue([self threeDSParams:sourceParams matchCardSource:cardSource]);
        completion(threeDSSource, nil);
        [createSourceExp fulfill];
    }];

    XCTestExpectation *paymentResultExp = [self expectationWithDescription:@"didCreatePaymentResult"];
    OCMStub([self.mockDelegate paymentContext:[OCMArg any] didCreatePaymentResult:[OCMArg any] completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation){
        STPPaymentResult *result;
        STPErrorBlock completion;
        [invocation getArgument:&result atIndex:3];
        [invocation getArgument:&completion atIndex:4];
        XCTAssertEqual(result.source, cardSource);
        completion(nil);
        OCMVerify([self.mockDelegate paymentContext:[OCMArg any] didFinishWithStatus:STPPaymentStatusSuccess
                                              error:[OCMArg any]]);
        [paymentResultExp fulfill];
    });

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

    STPSource *threeDSSource = [self threeDSSourceWithStatus:@"chargeable"];
    XCTestExpectation *createSourceExp = [self expectationWithDescription:@"createSource"];
    [STPAPIClient stub:self.mockAPIClient createSourceWithParamsCompletion:^(STPSourceParams * _Nonnull sourceParams, STPSourceCompletionBlock  _Nonnull completion) {
        XCTAssertTrue([self threeDSParams:sourceParams matchCardSource:cardSource]);
        completion(threeDSSource, nil);
        OCMVerify([self.mockDelegate paymentContext:[OCMArg any] didFinishWithStatus:STPPaymentStatusSuccess
                                              error:[OCMArg any]]);
        [createSourceExp fulfill];
    }];

    [self.sut requestPayment];

    [self waitForExpectationsWithTimeout:2 handler:nil];
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
    XCTestExpectation *createSourceExp = [self expectationWithDescription:@"createSource"];
    [STPAPIClient stub:self.mockAPIClient createSourceWithParamsCompletion:^(STPSourceParams * _Nonnull sourceParams, STPSourceCompletionBlock  _Nonnull completion) {
        XCTAssertTrue([self threeDSParams:sourceParams matchCardSource:cardSource]);
        completion(nil, expectedError);
        [createSourceExp fulfill];
    }];

    XCTestExpectation *paymentResultExp = [self expectationWithDescription:@"didCreatePaymentResult"];
    OCMStub([self.mockDelegate paymentContext:[OCMArg any] didCreatePaymentResult:[OCMArg any] completion:[OCMArg any]])
    .andDo(^(NSInvocation *invocation){
        STPPaymentResult *result;
        STPErrorBlock completion;
        [invocation getArgument:&result atIndex:3];
        [invocation getArgument:&completion atIndex:4];
        XCTAssertEqual(result.source, cardSource);
        completion(nil);
        OCMVerify([self.mockDelegate paymentContext:[OCMArg any] didFinishWithStatus:STPPaymentStatusSuccess
                                              error:[OCMArg any]]);
        [paymentResultExp fulfill];
    });

    [self.sut requestPayment];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}


@end
