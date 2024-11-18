//
//  STDSChallengeResponseObjectTest.m
//  Stripe3DS2Tests
//
//  Created by Yuki Tokuhiro on 3/29/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "STDSChallengeResponseObject.h"
#import "STDSTestJSONUtils.h"
#import "NSError+Stripe3DS2.h"

@interface STDSChallengeResponseObjectTest : XCTestCase

@end

@implementation STDSChallengeResponseObjectTest

- (void)testSuccessfulDecode {
    NSDictionary *json = [STDSTestJSONUtils jsonNamed:@"CRes"];
    NSError *error;
    STDSChallengeResponseObject *cr = [STDSChallengeResponseObject decodedObjectFromJSON:json error:&error];
    
    XCTAssertNil(error);
    XCTAssertNotNil(cr);
    
    XCTAssertEqualObjects(cr.threeDSServerTransactionID, @"8a880dc0-d2d2-4067-bcb1-b08d1690b26e");
    XCTAssertEqualObjects(cr.acsTransactionID, @"d7c1ee99-9478-44a6-b1f2-391e29c6b340");
    XCTAssertEqual(cr.acsUIType, STDSACSUITypeText);
    XCTAssertEqual(cr.challengeCompletionIndicator, NO);
    XCTAssertEqualObjects(cr.challengeInfoHeader, @"Header information");
    XCTAssertEqualObjects(cr.challengeInfoLabel, @"One-time-password");
    XCTAssertEqualObjects(cr.challengeInfoText, @"Please enter the received one-time-password");
    XCTAssertEqual(cr.showChallengeInfoTextIndicator, NO);
    XCTAssertEqualObjects(cr.expandInfoLabel, @"Additional instructions");
    XCTAssertEqualObjects(cr.expandInfoText, @"The issuer will send you via SMS a one-time password. Please enter the value in the designated input field above and press continue to complete the 3-D Secure authentication process.");
    XCTAssertEqualObjects(cr.issuerImage.mediumDensityURL, [NSURL URLWithString:@"https://acs.com/medium_image.svg"]);
    XCTAssertEqualObjects(cr.issuerImage.highDensityURL, [NSURL URLWithString:@"https://acs.com/high_image.svg"]);
    XCTAssertEqualObjects(cr.issuerImage.extraHighDensityURL, [NSURL URLWithString:@"https://acs.com/extraHigh_image.svg"]);
    XCTAssertEqualObjects(cr.messageType, @"CRes");
    XCTAssertEqualObjects(cr.messageVersion, @"2.2.0");
    XCTAssertEqualObjects(cr.paymentSystemImage.mediumDensityURL, [NSURL URLWithString:@"https://ds.com/medium_image.svg"]);
    XCTAssertEqualObjects(cr.paymentSystemImage.highDensityURL, [NSURL URLWithString:@"https://ds.com/high_image.svg"]);
    XCTAssertEqualObjects(cr.paymentSystemImage.extraHighDensityURL, [NSURL URLWithString:@"https://ds.com/extraHigh_image.svg"]);
    XCTAssertEqualObjects(cr.resendInformationLabel, @"Send new One-time-password");
    XCTAssertEqualObjects(cr.sdkTransactionID, @"b2385523-a66c-4907-ac3c-91848e8c0067");
    XCTAssertEqualObjects(cr.submitAuthenticationLabel, @"Continue");
    XCTAssertEqualObjects(cr.whyInfoLabel, @"Why using 3-D Secure?");
    XCTAssertEqualObjects(cr.whyInfoText, @"Some explanation about why using 3-D Secure is an excellent idea as part of an online payment transaction");
    XCTAssertEqualObjects(cr.acsCounterACStoSDK, @"001");
}

- (void)testMissingFields {
    NSArray<NSString *> *requiredFields = @[
                                            @"threeDSServerTransID",
                                            @"acsCounterAtoS",
                                            @"acsTransID",
                                            @"acsUiType",
                                            @"challengeCompletionInd",
                                            @"messageType",
                                            @"messageVersion",
                                            @"sdkTransID",
                                            ];
    
    for (NSString *field in requiredFields) {
        NSMutableDictionary *response = [[STDSTestJSONUtils jsonNamed:@"CRes"] mutableCopy];
        [response removeObjectForKey:field];
        
        NSError *error;
        NSError *expectedError = [NSError _stds_missingJSONFieldError:field];
        XCTAssertNil([STDSChallengeResponseObject decodedObjectFromJSON:response error:&error]);
        XCTAssertNotNil(error);
        XCTAssertEqual(error.code, expectedError.code);
        XCTAssertEqualObjects(error.userInfo, expectedError.userInfo);
    }
}

@end
