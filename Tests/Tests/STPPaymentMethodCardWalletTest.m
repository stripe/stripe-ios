//
//  STPPaymentMethodCardWalletTest.m
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 3/9/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPPaymentMethodCardWallet.h"
#import "STPPaymentMethodCardWallet+Private.h"
#import "STPFixtures.h"
#import "STPTestUtils.h"

@interface STPPaymentMethodCardWalletTest : XCTestCase

@end

@implementation STPPaymentMethodCardWalletTest

#pragma mark - STPPaymentMethodCardWalletType Tests

- (void)testTypeFromString {
    XCTAssertEqual([STPPaymentMethodCardWallet typeFromString:@"amex_express_checkout"], STPPaymentMethodCardWalletTypeAmexExpressCheckout);
    XCTAssertEqual([STPPaymentMethodCardWallet typeFromString:@"AMEX_EXPRESS_CHECKOUT"], STPPaymentMethodCardWalletTypeAmexExpressCheckout);
    XCTAssertEqual([STPPaymentMethodCardWallet typeFromString:@"apple_pay"], STPPaymentMethodCardWalletTypeApplePay);
    XCTAssertEqual([STPPaymentMethodCardWallet typeFromString:@"APPLE_PAY"], STPPaymentMethodCardWalletTypeApplePay);
    XCTAssertEqual([STPPaymentMethodCardWallet typeFromString:@"google_pay"], STPPaymentMethodCardWalletTypeGooglePay);
    XCTAssertEqual([STPPaymentMethodCardWallet typeFromString:@"GOOGLE_PAY"], STPPaymentMethodCardWalletTypeGooglePay);
    XCTAssertEqual([STPPaymentMethodCardWallet typeFromString:@"masterpass"], STPPaymentMethodCardWalletTypeMasterpass);
    XCTAssertEqual([STPPaymentMethodCardWallet typeFromString:@"MASTERPASS"], STPPaymentMethodCardWalletTypeMasterpass);
    XCTAssertEqual([STPPaymentMethodCardWallet typeFromString:@"samsung_pay"], STPPaymentMethodCardWalletTypeSamsungPay);
    XCTAssertEqual([STPPaymentMethodCardWallet typeFromString:@"SAMSUNG_PAY"], STPPaymentMethodCardWalletTypeSamsungPay);
    XCTAssertEqual([STPPaymentMethodCardWallet typeFromString:@"visa_checkout"], STPPaymentMethodCardWalletTypeVisaCheckout);
    XCTAssertEqual([STPPaymentMethodCardWallet typeFromString:@"VISA_CHECKOUT"], STPPaymentMethodCardWalletTypeVisaCheckout);
}

#pragma mark - STPAPIResponseDecodable Tests

- (void)testDecodedObjectFromAPIResponseMapping {
    NSDictionary *response = [STPTestUtils jsonNamed:STPTestJSONPaymentMethod][@"card"][@"wallet"];
    STPPaymentMethodCardWallet *wallet = [STPPaymentMethodCardWallet decodedObjectFromAPIResponse:response];
    XCTAssertNotNil(wallet);
    XCTAssertEqual(wallet.type, STPPaymentMethodCardWalletTypeVisaCheckout);
}

@end
