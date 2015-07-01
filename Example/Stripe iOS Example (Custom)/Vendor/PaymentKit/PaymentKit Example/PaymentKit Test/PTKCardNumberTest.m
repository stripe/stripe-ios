//
//  PTKCardNumberTest.m
//  PTKPayment Example
//
//  Created by Alex MacCaw on 2/6/13.
//  Copyright (c) 2013 Stripe. All rights reserved.
//

#import "PTKCardNumberTest.h"
#import "PTKCardNumber.h"
#define CNUMBER(string) [PTKCardNumber cardNumberWithString:string]

@implementation PTKCardNumberTest

- (void)testCardType
{
    XCTAssertEqual([CNUMBER(@"378282246310005") cardType], PTKCardTypeAmex, @"Detects Amex");
    XCTAssertEqual([CNUMBER(@"371449635398431") cardType], PTKCardTypeAmex, @"Detects Amex");
    XCTAssertEqual([CNUMBER(@"30569309025904") cardType], PTKCardTypeDinersClub, @"Detects Diners Club");
    XCTAssertEqual([CNUMBER(@"6011111111111117") cardType], PTKCardTypeDiscover, @"Detects Discover");
    XCTAssertEqual([CNUMBER(@"6011000990139424") cardType], PTKCardTypeDiscover, @"Detects Discover");
    XCTAssertEqual([CNUMBER(@"6221270990139424") cardType], PTKCardTypeDiscover, @"Detects Discover");
    XCTAssertEqual([CNUMBER(@"6461270990139424") cardType], PTKCardTypeDiscover, @"Detects Discover");
    XCTAssertEqual([CNUMBER(@"3530111333300000") cardType], PTKCardTypeJCB, @"Detects JCB");
    XCTAssertEqual([CNUMBER(@"5555555555554444") cardType], PTKCardTypeMasterCard, @"Detects MasterCard");
    XCTAssertEqual([CNUMBER(@"4111111111111111") cardType], PTKCardTypeVisa, @"Detects Visa");
    XCTAssertEqual([CNUMBER(@"4012888888881881") cardType], PTKCardTypeVisa, @"Detects Visa");
    
    XCTAssertEqual([CNUMBER(@"6001270990139424") cardType], PTKCardTypeUnknown, @"Detects Discover");
    XCTAssertEqual([CNUMBER(@"6229260990139424") cardType], PTKCardTypeUnknown, @"Detects Discover");
}

- (void)testLast4
{
    XCTAssertEqualObjects([CNUMBER(@"378282246310005") last4], @"0005", @"Asserts last 4");
    XCTAssertEqualObjects([CNUMBER(@"4012888888881881") last4], @"1881", @"Asserts last 4");
}

- (void)testLastGroup
{
    XCTAssertEqualObjects([CNUMBER(@"4111111111111111") lastGroup], @"1111", @"Asserts last group for visa");
    XCTAssertEqualObjects([CNUMBER(@"378282246310005") lastGroup], @"10005", @"Asserts last group for amex");
}

- (void)testStripsNonIntegers
{
    XCTAssertEqualObjects([CNUMBER(@"411111ddd1111111111") string], @"4111111111111111", @"Strips non integers");
}

- (void)testFormattedString
{
    XCTAssertEqualObjects([CNUMBER(@"4012888888881881") formattedString], @"4012 8888 8888 1881", @"Formats Visa");
    XCTAssertEqualObjects([CNUMBER(@"378734493671000") formattedString], @"3787 344936 71000", @"Formats Amex");
}

- (void)testFormttedStringWithTrail
{
    XCTAssertEqualObjects([CNUMBER(@"4012888888881881") formattedStringWithTrail], @"4012 8888 8888 1881", @"Formats Visa");
    XCTAssertEqualObjects([CNUMBER(@"378734493671000") formattedStringWithTrail], @"3787 344936 71000", @"Formats Amex");

    XCTAssertEqualObjects([CNUMBER(@"4012") formattedStringWithTrail], @"4012 ", @"Formats Visa");
    XCTAssertEqualObjects([CNUMBER(@"4012 8") formattedStringWithTrail], @"4012 8", @"Formats Visa");
    
    XCTAssertEqualObjects([CNUMBER(@"3787344936") formattedStringWithTrail], @"3787 344936 ", @"Formats Amex");
    XCTAssertEqualObjects([CNUMBER(@"37873449367") formattedStringWithTrail], @"3787 344936 7", @"Formats Amex");
}

- (void)testIsValid
{
    XCTAssertTrue([CNUMBER(@"378282246310005") isValid], @"Detects Amex");
    XCTAssertTrue([CNUMBER(@"371449635398431") isValid], @"Detects Amex");
    XCTAssertTrue([CNUMBER(@"30569309025904") isValid], @"Detects Diners Club");
    XCTAssertTrue([CNUMBER(@"6011111111111117") isValid], @"Detects Discover");
    XCTAssertTrue([CNUMBER(@"6011000990139424") isValid], @"Detects Discover");
    XCTAssertTrue([CNUMBER(@"3530111333300000") isValid], @"Detects JCB");
    XCTAssertTrue([CNUMBER(@"5555555555554444") isValid], @"Detects MasterCard");
    XCTAssertTrue([CNUMBER(@"4111111111111111") isValid], @"Detects Visa");
    XCTAssertTrue([CNUMBER(@"4012888888881881") isValid], @"Detects Visa");

    XCTAssertTrue(![CNUMBER(@"401288888881881") isValid], @"Assert fails Luhn invalid");
    XCTAssertTrue(![CNUMBER(@"60110990139424") isValid], @"Assert fails Luhn invalid");
    XCTAssertTrue(![CNUMBER(@"424242424242") isValid], @"Assert fails length test invalid");
}

- (void)testIsPartiallyValidWhenGivenValidNumber
{
    XCTAssertTrue([CNUMBER(@"378282246310005") isPartiallyValid], @"Detects Amex");
    XCTAssertTrue([CNUMBER(@"371449635398431") isPartiallyValid], @"Detects Amex");
    XCTAssertTrue([CNUMBER(@"30569309025904") isPartiallyValid], @"Detects Diners Club");
    XCTAssertTrue([CNUMBER(@"6011111111111117") isPartiallyValid], @"Detects Discover");
    XCTAssertTrue([CNUMBER(@"6011000990139424") isPartiallyValid], @"Detects Discover");
    XCTAssertTrue([CNUMBER(@"3530111333300000") isPartiallyValid], @"Detects JCB");
    XCTAssertTrue([CNUMBER(@"5555555555554444") isPartiallyValid], @"Detects MasterCard");
    XCTAssertTrue([CNUMBER(@"4111111111111111") isPartiallyValid], @"Detects Visa");
    XCTAssertTrue([CNUMBER(@"4012888888881881") isPartiallyValid], @"Detects Visa");
}

- (void)testIsPartiallyValidWhenGivenValidNumberMissingDigits
{
    XCTAssertTrue([CNUMBER(@"3") isPartiallyValid], @"Too short to determine type");    
    XCTAssertTrue([CNUMBER(@"411111") isPartiallyValid], @"Visa many digits short");
    XCTAssertTrue([CNUMBER(@"37828224631000") isPartiallyValid], @"Amex one digit short");
    XCTAssertTrue([CNUMBER(@"3056930902590") isPartiallyValid], @"Diners Club one digit short");
    XCTAssertTrue([CNUMBER(@"601111111111111") isPartiallyValid], @"Discover one digit short");
    XCTAssertTrue([CNUMBER(@"353011133330000") isPartiallyValid], @"JCB one digit short");
    XCTAssertTrue([CNUMBER(@"555555555555444") isPartiallyValid], @"MasterCard one digit short");
    XCTAssertTrue([CNUMBER(@"411111111111111") isPartiallyValid], @"Visa one digit short");
}

- (void)testIsPartiallyValidIsFalseWhenOverMaxDigitLengthForCardType
{
    XCTAssertTrue(![CNUMBER(@"3782822463100053") isPartiallyValid], @"Amex cannot be more than 15 digits");
    XCTAssertTrue(![CNUMBER(@"305693090259042") isPartiallyValid], @"Diners Club cannot be more than 14 digits");
    XCTAssertTrue(![CNUMBER(@"41111111111111111") isPartiallyValid], @"Visa cannot be more than 16 digits");
}

@end
