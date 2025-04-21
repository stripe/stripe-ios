//
//  STDSErrorMessageTest.m
//  Stripe3DS2Tests
//
//  Created by Yuki Tokuhiro on 3/29/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STDSErrorMessage.h"
#import "STDSJSONEncoder.h"
#import "STDSTestJSONUtils.h"

@interface STDSErrorMessageTest : XCTestCase

@end

@implementation STDSErrorMessageTest

#pragma mark - STDSJSONDecodable

- (void)testSuccessfulDecode {
    NSDictionary *json = [STDSTestJSONUtils jsonNamed:@"ErrorMessage"];
    NSError *error;
    STDSErrorMessage *errorMessage = [STDSErrorMessage decodedObjectFromJSON:json error:&error];
    
    XCTAssertNil(error);
    XCTAssertNotNil(errorMessage);
    XCTAssertEqualObjects(errorMessage.errorCode, @"203");
    XCTAssertEqualObjects(errorMessage.errorComponent, @"A");
    XCTAssertEqualObjects(errorMessage.errorDescription, @"Data element not in the required format. Not numeric or wrong length.");
    XCTAssertEqualObjects(errorMessage.errorDetails, @"billAddrCountry,billAddrPostCode,dsURL");
    XCTAssertEqualObjects(errorMessage.errorMessageType, @"AReq");
    XCTAssertEqualObjects(errorMessage.messageVersion, @"2.2.0");

}

#pragma mark - STDSJSONEncodable

- (void)testPropertyNamesToJSONKeysMapping {
    STDSErrorMessage *params = [STDSErrorMessage new];
    
    NSDictionary *mapping = [STDSErrorMessage propertyNamesToJSONKeysMapping];
    
    for (NSString *propertyName in [mapping allKeys]) {
        XCTAssertFalse([propertyName containsString:@":"]);
        XCTAssert([params respondsToSelector:NSSelectorFromString(propertyName)]);
    }
    
    for (NSString *formFieldName in [mapping allValues]) {
        XCTAssert([formFieldName isKindOfClass:[NSString class]]);
        XCTAssert([formFieldName length] > 0);
    }
    
    XCTAssertEqual([[mapping allValues] count], [[NSSet setWithArray:[mapping allValues]] count]);
    XCTAssertTrue([NSJSONSerialization isValidJSONObject:[STDSJSONEncoder dictionaryForObject:params]]);
}


@end
