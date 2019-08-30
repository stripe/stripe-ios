//
//  STPPinManagementFunctionalTest.m
//  StripeiOS Tests
//
//  Created by Arnaud Cavailhez on 4/29/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

@import XCTest;
@import PassKit;

#import "Stripe.h"
#import "STPPinManagementService.h"
#import "STPNetworkStubbingTestCase.h"
#import "StpEphemeralKeyProvider.h"
#import "STPEphemeralKey.h"
#import "STPAPIRequest.h"

@interface TestEphemeralKeyProvider : STPAPIClient<STPIssuingCardEphemeralKeyProvider>

@end

@implementation TestEphemeralKeyProvider
- (void)createIssuingCardKeyWithAPIVersion:(nonnull NSString *)apiVersion
                                completion:(nonnull STPJSONResponseCompletionBlock)completion {
    NSLog(@"apiVersion %@", apiVersion);
    NSDictionary *response = @{
                               @"id": @"ephkey_token",
                               @"object": @"ephemeral_key",
                               @"associated_objects": @[@{
                                                          @"type": @"issuing.card",
                                                          @"id": @"ic_token"
                                                      }],
                               @"created": @1556656558,
                               @"expires": @1556660158,
                               @"livemode": @true,
                               @"secret": @"ek_live_secret"
                               };
    completion(response, nil);
}

@end

@interface STPPinManagementServiceFunctionalTest : STPNetworkStubbingTestCase

@end

@implementation STPPinManagementServiceFunctionalTest

- (void)setUp {
//     self.recordingMode = YES;
    [super setUp];
}

- (void)testRetrievePin {
    TestEphemeralKeyProvider *keyProvider = [[TestEphemeralKeyProvider alloc] init];
    STPPinManagementService *service = [[STPPinManagementService alloc] initWithKeyProvider:keyProvider];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Received PIN"];
    
    [service retrievePin:@"ic_token"
          verificationId:@"iv_token"
             oneTimeCode:@"123456"
              completion:^(
                           STPIssuingCardPin *cardPin,
                           STPPinStatus status,
                           NSError *error) {
                  if (error == nil && status == STPPinSuccess && [cardPin.pin isEqualToString:@"2345"]) {
                      [expectation fulfill];
                  }
              }];
    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testUpdatePin {
    TestEphemeralKeyProvider *keyProvider = [[TestEphemeralKeyProvider alloc] init];
    STPPinManagementService *service = [[STPPinManagementService alloc] initWithKeyProvider:keyProvider];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Received PIN"];
    
    [service updatePin:@"ic_token"
                newPin:@"3456"
          verificationId:@"iv_token"
             oneTimeCode:@"123-456"
              completion:^(
                           STPIssuingCardPin *cardPin,
                           STPPinStatus status,
                           NSError *error) {
                  if (error == nil && status == STPPinSuccess && [cardPin.pin isEqualToString:@"3456"]) {
                      [expectation fulfill];
                  }
              }];
    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testRetrievePinWithError {
    TestEphemeralKeyProvider *keyProvider = [[TestEphemeralKeyProvider alloc] init];
    STPPinManagementService *service = [[STPPinManagementService alloc] initWithKeyProvider:keyProvider];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Received Error"];
    
    [service retrievePin:@"ic_token"
           verificationId:@"iv_token"
              oneTimeCode:@"123456"
             completion:^(
                        __unused STPIssuingCardPin *cardPin,
                          STPPinStatus status,
                        __unused NSError *error) {
                 if (status == STPPinErrorVerificationAlreadyRedeemed) {
                     [expectation fulfill];
                 }
             }];
    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

@end
