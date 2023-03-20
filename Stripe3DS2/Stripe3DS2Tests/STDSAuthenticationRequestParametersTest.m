//
//  STDSAuthenticationRequestParametersTest.m
//  Stripe3DS2Tests
//
//  Created by Yuki Tokuhiro on 3/25/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STDSAuthenticationRequestParameters.h"
#import "STDSJSONEncoder.h"

@interface STDSAuthenticationRequestParametersTest : XCTestCase

@end

@implementation STDSAuthenticationRequestParametersTest

#pragma mark - STDSJSONEncodable

- (void)testPropertyNamesToJSONKeysMapping {
    STDSAuthenticationRequestParameters *params = [STDSAuthenticationRequestParameters new];
    
    NSDictionary *mapping = [STDSAuthenticationRequestParameters propertyNamesToJSONKeysMapping];
    
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
