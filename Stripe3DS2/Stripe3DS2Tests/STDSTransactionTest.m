//
//  STDSTransactionTest.m
//  Stripe3DS2Tests
//
//  Created by Yuki Tokuhiro on 3/22/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STDSTransaction+Private.h"
#import "STDSInvalidInputException.h"
#import "STDSChallengeParameters.h"
#import "STDSChallengeStatusReceiver.h"
#import "STDSRuntimeErrorEvent.h"
#import "STDSProtocolErrorEvent.h"
#import "STDSStripe3DS2Error.h"
#import "STDSTransaction.h"
#import "STDSErrorMessage.h"
#import "NSError+Stripe3DS2.h"

@interface STDSTransaction (Private)
@property (nonatomic, weak) id<STDSChallengeStatusReceiver> challengeStatusReceiver;

- (void)_handleError:(NSError *)error;
- (NSString *)_sdkAppIdentifier;
@end

@interface STDSTransactionTest : XCTestCase <STDSChallengeStatusReceiver>
@property (nonatomic, copy) void (^didErrorWithProtocolErrorEvent)(STDSProtocolErrorEvent *);
@property (nonatomic, copy) void (^didErrorWithRuntimeErrorEvent)(STDSRuntimeErrorEvent *);
@end

@implementation STDSTransactionTest

- (void)tearDown {
    self.didErrorWithRuntimeErrorEvent = nil;
    self.didErrorWithProtocolErrorEvent = nil;
    [super tearDown];
}

#pragma mark - Timeout

- (void)testTimeoutBelow5Throws {
    STDSTransaction *transaction = [STDSTransaction new];
    STDSChallengeParameters *challengeParameters = [[STDSChallengeParameters alloc] init];
    XCTAssertThrowsSpecific([transaction doChallengeWithViewController:[UIViewController new]
                                                   challengeParameters:challengeParameters
                                               challengeStatusReceiver:self
                                                               timeout:4 * 60], STDSInvalidInputException);
}

- (void)testTimeoutFires {
    STDSTransaction *transaction = [STDSTransaction new];
    STDSChallengeParameters *challengeParameters = [[STDSChallengeParameters alloc] init];
    
    // Assert timer is scheduled to fire 5 minutes from now, give or take 1 second
    NSInteger timeout = 300;
    [transaction doChallengeWithViewController:[UIViewController new]
                           challengeParameters:challengeParameters
                       challengeStatusReceiver:self
                                       timeout:timeout];
    XCTAssertTrue(transaction.timeoutTimer.isValid);
    NSTimeInterval secondsIntoTheFutureTimerWillFire = [transaction.timeoutTimer.fireDate timeIntervalSinceNow];
    XCTAssertLessThanOrEqual(fabs(secondsIntoTheFutureTimerWillFire - (timeout)), 1);
}

#pragma mark - Error Handling

- (void)testHandleUnknownMessageTypeError {
    NSError *error = [NSError errorWithDomain:STDSStripe3DS2ErrorDomain code:STDSErrorCodeUnknownMessageType userInfo:nil];
    [self _expectProtocolErrorEventForError:error validator:^(STDSProtocolErrorEvent *protocolErrorEvent) {
        XCTAssertEqualObjects(protocolErrorEvent.errorMessage.errorCode, @"101");
    }];
}

- (void)testHandleInvalidJSONError {
    NSError *error = [NSError _stds_invalidJSONFieldError:@"invalid field"];
    [self _expectProtocolErrorEventForError:error validator:^(STDSProtocolErrorEvent *protocolErrorEvent) {
        XCTAssertEqualObjects(protocolErrorEvent.errorMessage.errorCode, @"203");
        XCTAssertEqualObjects(protocolErrorEvent.errorMessage.errorDetails, @"invalid field");
    }];
}

- (void)testHandleMissingJSONError {
    NSError *error = [NSError _stds_missingJSONFieldError:@"missing field"];
    [self _expectProtocolErrorEventForError:error validator:^(STDSProtocolErrorEvent *protocolErrorEvent) {
        XCTAssertEqualObjects(protocolErrorEvent.errorMessage.errorCode, @"201");
        XCTAssertEqualObjects(protocolErrorEvent.errorMessage.errorDetails, @"missing field");
    }];
}

- (void)testHandleReceivedErrorMessage {
    STDSErrorMessage *receivedErrorMessage = [[STDSErrorMessage alloc] initWithErrorCode:@"" errorComponent:@"" errorDescription:@"" errorDetails:nil messageVersion:@"" acsTransactionIdentifier:@"" errorMessageType:@""];
    NSError *error = [NSError errorWithDomain:STDSStripe3DS2ErrorDomain
                                         code:STDSErrorCodeReceivedErrorMessage
                                     userInfo:@{STDSStripe3DS2ErrorMessageErrorKey: receivedErrorMessage}];

    [self _expectProtocolErrorEventForError:error validator:^(STDSProtocolErrorEvent *protocolErrorEvent) {
        XCTAssertEqualObjects(protocolErrorEvent.errorMessage, receivedErrorMessage);
    }];
}

- (void)testHandleNetworkConnectionLostError {
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain
                                         code:NSURLErrorNetworkConnectionLost
                                     userInfo:nil];
    [self _expectRuntimeErrorEventForError:error validator:^(STDSRuntimeErrorEvent *runtimeErrorEvent) {
        XCTAssertEqualObjects(runtimeErrorEvent.errorCode, [@(NSURLErrorNetworkConnectionLost) stringValue]);
    }];
}

- (void)_expectProtocolErrorEventForError:(NSError *)error validator:(void (^)(STDSProtocolErrorEvent *))protocolErrorEventChecker {
    STDSTransaction *transaction = [STDSTransaction new];
    transaction.challengeStatusReceiver = self;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Call didErrorWithProtocolErrorEvent"];
    self.didErrorWithProtocolErrorEvent = ^(STDSProtocolErrorEvent *protocolErrorEvent) {
        protocolErrorEventChecker(protocolErrorEvent);
        [expectation fulfill];
    };
    [transaction _handleError:error];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)_expectRuntimeErrorEventForError:(NSError *)error validator:(void (^)(STDSRuntimeErrorEvent *))runtimeErrorEventChecker {
    STDSTransaction *transaction = [STDSTransaction new];
    transaction.challengeStatusReceiver = self;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Call didErrorWithRuntimeErrorEvent"];
    self.didErrorWithRuntimeErrorEvent = ^(STDSRuntimeErrorEvent *runtimeErrorEvent) {
        runtimeErrorEventChecker(runtimeErrorEvent);
        [expectation fulfill];
    };
    [transaction _handleError:error];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

#pragma mark - STDSChallengeStatusReceiver

- (void)transaction:(nonnull STDSTransaction *)transaction didCompleteChallengeWithCompletionEvent:(nonnull STDSCompletionEvent *)completionEvent {}

- (void)transaction:(nonnull STDSTransaction *)transaction didErrorWithProtocolErrorEvent:(nonnull STDSProtocolErrorEvent *)protocolErrorEvent {
    if (self.didErrorWithProtocolErrorEvent) {
        self.didErrorWithProtocolErrorEvent(protocolErrorEvent);
    }
}

- (void)transaction:(nonnull STDSTransaction *)transaction didErrorWithRuntimeErrorEvent:(nonnull STDSRuntimeErrorEvent *)runtimeErrorEvent {
    if (self.didErrorWithRuntimeErrorEvent) {
        self.didErrorWithRuntimeErrorEvent(runtimeErrorEvent);
    }
}

- (void)transactionDidCancel:(nonnull STDSTransaction *)transaction {}

- (void)transactionDidTimeOut:(nonnull STDSTransaction *)transaction {}

@end
