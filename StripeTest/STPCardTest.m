//
//  STPCardTest.m
//  Stripe
//
//  Created by Saikat Chakrabarti on 11/5/12.
//
//

#import "STPCard.h"
#import "StripeError.h"
#import "STPUtils.h"
#import <XCTest/XCTest.h>

@implementation NSDate (CardTestOverrides)
+ (NSDate *)date {
    // All card tests will pretend the current date is August 29, 1997.
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setYear:1997];
    [components setMonth:8];
    [components setDay:29];
    return [calendar dateFromComponents:components];
}
@end

@interface STPCardTest : XCTestCase
@property (nonatomic) STPCard *card;
@end

@implementation STPCardTest

- (void)setUp {
    _card = [[STPCard alloc] init];
}

#pragma mark Helpers
- (NSDateComponents *)currentDateComponents {
    // FIXME This is a copy of the code that already exists in a private method in STPCard
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    return [gregorian components:NSCalendarUnitYear fromDate:[NSDate date]];
}

- (NSInteger)currentYear {
    return [[self currentDateComponents] year];
}

#pragma mark -initWithAttributeDictionary: tests
- (NSDictionary *)completeAttributeDictionary {
    return @{
        @"number": @"4242424242424242",
        @"exp_month": @"12",
        @"exp_year": @"2013",
        @"cvc": @"123",
        @"name": @"Smerlock Smolmes",
        @"address_line1": @"221A Baker Street",
        @"address_city": @"New York",
        @"address_state": @"NY",
        @"address_zip": @"12345",
        @"address_country": @"USA",
        @"object": @"something",
        @"last4": @"1234",
        @"type": @"Smastersmard",
        @"fingerprint": @"Fingolfin",
        @"country": @"Japan"
    };
}

- (void)testInitializingCardWithAttributeDictionary {
    STPCard *cardWithAttributes = [[STPCard alloc] initWithAttributeDictionary:[self completeAttributeDictionary]];

    XCTAssertEqualObjects([cardWithAttributes number], @"4242424242424242", @"number is set correctly");
    XCTAssertTrue([cardWithAttributes expMonth] == 12, @"expMonth is set correctly");
    XCTAssertTrue([cardWithAttributes expYear] == 2013, @"expYear is set correctly");
    XCTAssertEqualObjects([cardWithAttributes cvc], @"123", @"CVC is set correctly");
    XCTAssertEqualObjects([cardWithAttributes name], @"Smerlock Smolmes", @"name is set correctly");
    XCTAssertEqualObjects([cardWithAttributes addressLine1], @"221A Baker Street", @"addressLine1 is set correctly");
    XCTAssertEqualObjects([cardWithAttributes addressCity], @"New York", @"addressCity is set correctly");
    XCTAssertEqualObjects([cardWithAttributes addressState], @"NY", @"addressState is set correctly");
    XCTAssertEqualObjects([cardWithAttributes addressZip], @"12345", @"addressZip is set correctly");
    XCTAssertEqualObjects([cardWithAttributes addressCountry], @"USA", @"addressCountry is set correctly");
    XCTAssertEqualObjects([cardWithAttributes object], @"something", @"object is set correctly");
    XCTAssertEqualObjects([cardWithAttributes last4], @"1234", @"last4 is set correctly");
    XCTAssertEqualObjects([cardWithAttributes type], @"Smastersmard", @"type is set correctly");
    XCTAssertEqualObjects([cardWithAttributes fingerprint], @"Fingolfin", @"fingerprint is set correctly");
    XCTAssertEqualObjects([cardWithAttributes country], @"Japan", @"country is set correctly");
}

- (void)testFormEncode {
    NSDictionary *attributes = [self completeAttributeDictionary];
    STPCard *cardWithAttributes = [[STPCard alloc] initWithAttributeDictionary:attributes];

    NSData *encoded = [cardWithAttributes formEncode];
    NSString *formData = [[NSString alloc] initWithData:encoded encoding:NSUTF8StringEncoding];

    NSArray *parts = [formData componentsSeparatedByString:@"&"];

    NSSet *expectedKeys = [NSSet setWithObjects:@"card[number]",
                                                @"card[exp_month]",
                                                @"card[exp_year]",
                                                @"card[cvc]",
                                                @"card[name]",
                                                @"card[address_line1]",
                                                @"card[address_line2]",
                                                @"card[address_city]",
                                                @"card[address_state]",
                                                @"card[address_zip]",
                                                @"card[address_country]",
                                                nil];

    NSArray *values = [attributes allValues];
    NSMutableArray *encodedValues = [NSMutableArray array];
    for (NSString *value in values) {
        [encodedValues addObject:[STPUtils stringByURLEncoding:value]];
    }

    NSSet *expectedValues = [NSSet setWithArray:encodedValues];
    for (NSString *part in parts) {
        NSArray *subparts = [part componentsSeparatedByString:@"="];
        NSString *key = subparts[0];
        NSString *value = subparts[1];

        XCTAssertTrue([expectedKeys containsObject:key], @"unexpected key %@", key);
        XCTAssertTrue([expectedValues containsObject:value], @"unexpected value %@", value);
    }
}

#pragma mark -last4 tests
- (void)testLast4ReturnsCardNumberLast4WhenNotSet {
    self.card.number = @"4242424242424242";
    XCTAssertEqualObjects(self.card.last4, @"4242", @"last4 correctly returns the last 4 digits of the card number");
}

- (void)testLast4ReturnsNullWhenNoCardNumberSet {
    XCTAssertEqualObjects(nil, self.card.last4, @"last4 returns nil when nothing is set");
}

- (void)testLast4ReturnsNullWhenCardNumberIsLessThanLength4 {
    self.card.number = @"123";
    XCTAssertEqualObjects(nil, self.card.last4, @"last4 returns nil when number length is < 3");
}

#pragma mark -type tests
- (void)testTypeReturnsCorrectlyForAmexCard {
    self.card.number = @"3412123412341234";
    XCTAssertEqualObjects(@"American Express", self.card.type, @"Correct card type returned for Amex card");
}

- (void)testTypeReturnsCorrectlyForDiscoverCard {
    self.card.number = @"6452123412341234";
    XCTAssertEqualObjects(@"Discover", self.card.type, @"Correct card type returned for Discover card");
}

- (void)testTypeReturnsCorrectlyForJCBCard {
    self.card.number = @"3512123412341234";
    XCTAssertEqualObjects(@"JCB", self.card.type, @"Correct card type returned for JCB card");
}

- (void)testTypeReturnsCorrectlyForDinersClubCard {
    self.card.number = @"3612123412341234";
    XCTAssertEqualObjects(@"Diners Club", self.card.type, @"Correct card type returned for Diners Club card");
}

- (void)testTypeReturnsCorrectlyForVisaCard {
    self.card.number = @"4123123412341234";
    XCTAssertEqualObjects(@"Visa", self.card.type, @"Correct card type returned for Visa card");
}

- (void)testTypeReturnsCorrectlyForMasterCardCard {
    self.card.number = @"5123123412341234";
    XCTAssertEqualObjects(@"MasterCard", self.card.type, @"Correct card type returned for MasterCard card");
}

#pragma mark -validateNumber:error: tests
- (void)testEmptyCardNumberDoesNotValidate {
    NSString *number = @"";
    BOOL didValidate = [self.card validateNumber:&number error:nil];
    XCTAssertFalse(didValidate, @"Empty card should not validate");
}

- (void)testThatInvalidCardNumberReturnsTheCorrectError {
    NSError *error;
    NSString *number = @"";
    [self.card validateNumber:&number error:&error];
    XCTAssertEqualObjects(
        @"Your card's number is invalid", [error localizedDescription], @"Invalid card number gives an error with a message saying the number is invalid");
    NSDictionary *userInfo = [error userInfo];
    XCTAssertEqualObjects([userInfo valueForKey:STPCardErrorCodeKey], STPInvalidNumber, @"Invalid card number returns the correct card error code");
    XCTAssertEqualObjects([userInfo valueForKey:STPErrorParameterKey], @"number", @"Invaild card number returns the correct error parameter");
    XCTAssertTrue(userInfo[STPErrorMessageKey] != nil, @"Invalid card number returns a developer-facing error message");
}

- (void)testCardNumberWithManySpaces {
    NSString *number = @"      ";
    XCTAssertFalse([self.card validateNumber:&number error:nil], @"A card with a bunch of spaces should not validate");
}

- (void)testValidCardNumber {
    NSString *number = @"4242424242424242";
    XCTAssertTrue([self.card validateNumber:&number error:nil], @"A valid card should validate");
}

- (void)testValidCardNumberWithDashes {
    NSString *number = @"4242-4242-4242-4242";
    XCTAssertTrue([self.card validateNumber:&number error:nil], @"A valid card with dashes should validate");
}

- (void)testValidCardNumberWithSpaces {
    NSString *number = @"4242 4242 4242 4242";
    XCTAssertTrue([self.card validateNumber:&number error:nil], @"A valid card with spaces should validate");
}

- (void)testNonLuhnValidCardNumber {
    NSString *number = @"4242424242424241";
    XCTAssertFalse([self.card validateNumber:&number error:nil], @"A non-Luhn valid card should not validate");
}

- (void)testValidCardNumberWithAlphabetCharacters {
    NSString *number = @"424242424242a4242";
    XCTAssertFalse([self.card validateNumber:&number error:nil], @"A card with non-numeric characters that aren't spaces or dashes should not validate");
}

- (void)testCardNumberWithMoreThanNineteenDigits {
    NSString *number = @"424242424242424242424242";
    XCTAssertFalse([self.card validateNumber:&number error:nil], @"A card with more than 19 digits should not validate");
}

- (void)testCardNumberWithLessThanTenDigits {
    NSString *number = @"42424242";
    XCTAssertFalse([self.card validateNumber:&number error:nil], @"A card with more than 19 digits should not validate");
}

#pragma mark -validateCvc:error: tests
- (void)testInvalidCVCReturnsTheCorrectError {
    NSError *error;
    NSString *cvc = @"";
    XCTAssertFalse([self.card validateCvc:&cvc error:&error], @"Empty CVC should not validate");
    XCTAssertEqualObjects(
        @"Your card's security code is invalid", [error localizedDescription], @"Invalid card CVC gives the correct user-facing error message");
    NSDictionary *userInfo = [error userInfo];
    XCTAssertEqualObjects([userInfo valueForKey:STPCardErrorCodeKey], STPInvalidCVC, @"Invalid card number returns the correct card error code");
    XCTAssertEqualObjects([userInfo valueForKey:STPErrorParameterKey], @"cvc", @"Invaild CVC returns the correct error parameter");
    XCTAssertTrue(userInfo[STPErrorMessageKey] != nil, @"Invalid CVC returns a developer-facing error message");
}

- (void)testValidCVC {
    NSString *cvc = @"123";
    XCTAssertTrue([self.card validateCvc:&cvc error:nil], @"Valid CVC should validate");
}

- (void)testNullCVC {
    NSString *cvc = nil;
    XCTAssertFalse([self.card validateCvc:&cvc error:nil], @"Null CVC should not validate");
}

- (void)testNonNumericCVC {
    NSString *cvc = @"1a3";
    XCTAssertFalse([self.card validateCvc:&cvc error:nil], @"CVC with non-numeric characters should not validate");
}

- (void)testTooShortCVC {
    NSString *cvc = @"13";
    XCTAssertFalse([self.card validateCvc:&cvc error:nil], @"Too short CVC should not validate");
}

- (void)testTooLongCVC {
    NSString *cvc = @"12345";
    XCTAssertFalse([self.card validateCvc:&cvc error:nil], @"Too long CVC should not validate");
}

- (void)testThreeDigitCVCDoesNotValidateForAmexCard {
    NSString *cvc = @"123";
    self.card.number = @"3412123412341234";
    XCTAssertFalse([self.card validateCvc:&cvc error:nil], @"Three digit CVC is too short for Amex card");
}

- (void)testFourDigitCVCValidatesForAmexCard {
    NSString *cvc = @"1234";
    self.card.number = @"3412123412341234";
    XCTAssertTrue([self.card validateCvc:&cvc error:nil], @"Four digit CVC is valid for Amex card");
}

- (void)testFourDigitCVCDoesNotValidateForVisaCard {
    NSString *cvc = @"1234";
    self.card.number = @"4112123412341234";
    XCTAssertFalse([self.card validateCvc:&cvc error:nil], @"Four digit CVC is too long for non-Amex card");
}

- (void)testThreeDigitCVCValidatesForVisaCard {
    NSString *cvc = @"123";
    self.card.number = @"4112123412341234";
    XCTAssertTrue([self.card validateCvc:&cvc error:nil], @"Three digit CVC is valid for non-Amex card");
}

#pragma mark -validateExpMonth:error: tests
- (void)testInvalidExpMonthReturnsTheCorrectError {
    NSError *error;
    NSString *expMonth = @"";
    XCTAssertFalse([self.card validateExpMonth:&expMonth error:&error], @"expMonth must not be empty");
    XCTAssertEqualObjects(
        @"Your card's expiration month is invalid", [error localizedDescription], @"Invalid card expiration month gives the correct user facing error message");
    NSDictionary *userInfo = [error userInfo];
    XCTAssertEqualObjects([userInfo valueForKey:STPCardErrorCodeKey], STPInvalidExpMonth, @"Invalid card expiration month returns the correct card error code");
    XCTAssertEqualObjects([userInfo valueForKey:STPErrorParameterKey], @"expMonth", @"Invaild expiration month returns the correct error parameter");
    XCTAssertTrue(userInfo[STPErrorMessageKey] != nil, @"Invalid expiration month returns a developer-facing error message");
}

- (void)testNullExpMonth {
    NSString *expMonth = nil;
    XCTAssertFalse([self.card validateExpMonth:&expMonth error:nil], @"Null expMonth should not validate.");
}

- (void)testExpMonthGreaterThan12 {
    NSString *expMonth = @"14";
    XCTAssertFalse([self.card validateExpMonth:&expMonth error:nil], @"expMonth must not be less than or equal to 12");
}

- (void)testExpMonthWithNonNumericCharacters {
    NSString *expMonth = @"11a";
    XCTAssertFalse([self.card validateExpMonth:&expMonth error:nil], @"expMonth must not have any non-numeric characters");
}

- (void)testValidExpMonth {
    NSString *expMonth = @"05";
    XCTAssertTrue([self.card validateExpMonth:&expMonth error:nil], @"Numeric expMonth below 13 should validate");
}

- (void)testInvalidExpMonthForYearInPast {
    NSError *error;
    NSString *expMonth = @"12";
    self.card.expYear = 1995;
    XCTAssertFalse([self.card validateExpMonth:&expMonth error:&error], @"The year, when setting an expMonth, must not be invalid");
    NSDictionary *userInfo = [error userInfo];
    XCTAssertEqualObjects([userInfo valueForKey:STPCardErrorCodeKey],
                          STPInvalidExpYear,
                          @"Invalid card expiration year when setting card expiration month returns the correct card error code");
}

- (void)testInvalidExpMonthForYearSameAsCurrentYear {
    self.card.expYear = [self currentYear];
    NSString *expMonth = @"1";
    XCTAssertFalse([self.card validateExpMonth:&expMonth error:nil],
                   @"When the year is already set, if it is the same as the current year and the month is before the current month, the month is invalid");
}

- (void)testValidExpMonthForYearInFuture {
    NSString *expMonth = @"1";
    self.card.expYear = [self currentYear] + 1;
    XCTAssertTrue([self.card validateExpMonth:&expMonth error:nil], @"When the year is already set, if it is in the future, any numeric expMonth is valid");
}

- (void)testValidExpMonthForYearSameAsCurrentYear {
    self.card.expYear = [self currentYear];
    NSString *expMonth = @"12";
    XCTAssertTrue([self.card validateExpMonth:&expMonth error:nil],
                  @"When the year is already set, if it is the same as the current year and the month is the same as the current month, the month is invalid");
}

#pragma mark -validateExpYear:error: tests
- (void)testInvalidExpYearReturnsCorrectError {
    NSError *error;
    NSString *expYear = @"";
    XCTAssertFalse([self.card validateExpYear:&expYear error:&error], @"expYear must not be empty");
    XCTAssertEqualObjects(
        @"Your card's expiration year is invalid", [error localizedDescription], @"Invalid card expiration year gives the correct user facing error message");

    NSDictionary *userInfo = [error userInfo];
    XCTAssertEqualObjects([userInfo valueForKey:STPCardErrorCodeKey], STPInvalidExpYear, @"Invalid card expiration month returns the correct card error code");
    XCTAssertEqualObjects([userInfo valueForKey:STPErrorParameterKey], @"expYear", @"Invaild expiration year returns the correct error parameter");
    XCTAssertTrue(userInfo[STPErrorMessageKey] != nil, @"Invalid expiration year returns a developer-facing error message");
}

- (void)testNullExpYear {
    NSString *expYear = nil;
    XCTAssertFalse([self.card validateExpYear:&expYear error:nil], @"expYear must not be null");
}

- (void)testExpYearBeforeCurrentYear {
    NSString *expYear = @"1995";
    XCTAssertFalse([self.card validateExpYear:&expYear error:nil], @"expYear must not be in the past");
}

- (void)testValidExpYear {
    NSString *expYear = @"2000";
    XCTAssertTrue([self.card validateExpYear:&expYear error:nil], @"expYear in the future is valid");
}

- (void)testInvalidExpYearForYearSameAsCurrentYear {
    NSError *error;
    NSString *expYear = [NSString stringWithFormat:@"%ld", (long)[self currentYear]];
    self.card.expMonth = 1;
    XCTAssertFalse([self.card validateExpYear:&expYear error:&error],
                   @"When the month is already set, if the combination of month and year is in the past, don't validate");

    NSDictionary *userInfo = [error userInfo];
    XCTAssertEqualObjects(userInfo[STPCardErrorCodeKey], STPInvalidExpMonth, @"The error returned should be for the expMonth");
}

- (void)testValidExpYearWhenMonthIsSet {
    self.card.expMonth = 4;
    NSString *expYear = @"2000";
    XCTAssertTrue([self.card validateExpYear:&expYear error:nil], @"expYear in the future is valid even with a month set");
}

#pragma mark -validateCardReturningError: tests
- (void)testValidatingCardWithInvalidNumber {
    NSError *error;
    self.card.number = @"4242424242424241";
    self.card.expMonth = 12;
    self.card.expYear = 2012;
    XCTAssertFalse([self.card validateCardReturningError:&error], @"Card with invalid number should fail overall validation");
    NSDictionary *userInfo = [error userInfo];
    XCTAssertEqualObjects(userInfo[STPCardErrorCodeKey], STPInvalidNumber, @"The error returned should be for the number");
}

- (void)testExpiredCardDoesNotValidate {
    NSError *error;
    self.card.number = @"4242424242424242";
    self.card.expMonth = 1;
    self.card.expYear = 1997;
    XCTAssertFalse([self.card validateCardReturningError:&error], @"Expired card shoul fail overall validation");
    NSDictionary *userInfo = [error userInfo];
    XCTAssertEqualObjects(userInfo[STPCardErrorCodeKey], STPInvalidExpMonth, @"The error returned should be for the expMonth");
}

- (void)testCardWithBadCVCDoesNotValidate {
    NSError *error;
    self.card.number = @"4242424242424242";
    self.card.cvc = @"1234";
    self.card.expMonth = 12;
    self.card.expYear = 2012;
    XCTAssertFalse([self.card validateCardReturningError:&error], @"Card with bad CVC should fail overall validation");
    NSDictionary *userInfo = [error userInfo];
    XCTAssertEqualObjects(userInfo[STPCardErrorCodeKey], STPInvalidCVC, @"The error returned should be for the cvc");
}

- (void)testCardWithMissingExpYearDoesNotValidate {
    NSError *error;
    self.card.number = @"4242424242424242";
    self.card.cvc = @"123";
    self.card.expMonth = 12;
    XCTAssertFalse([self.card validateCardReturningError:&error], @"Card missing expYear should fail validation");
    NSDictionary *userInfo = [error userInfo];
    XCTAssertEqualObjects(userInfo[STPCardErrorCodeKey], STPInvalidExpYear, @"The error returned should be for the expYear");
}

- (void)testCardWithMissingNumberDoesNotValidate {
    NSError *error;
    self.card.expMonth = 12;
    self.card.expYear = 2012;
    XCTAssertFalse([self.card validateCardReturningError:&error], @"Card with missing number should fail overall validation");
    NSDictionary *userInfo = [error userInfo];
    XCTAssertEqualObjects(userInfo[STPCardErrorCodeKey], STPInvalidNumber, @"The error returned should be for the number");
}

- (void)testCardEquals {
    STPCard *card1 = [[STPCard alloc] initWithAttributeDictionary:[self completeAttributeDictionary]];
    STPCard *card2 = [[STPCard alloc] initWithAttributeDictionary:[self completeAttributeDictionary]];

    XCTAssertEqualObjects(card1, card1, @"card should equal itself");
    XCTAssertEqualObjects(card1, card2, @"cards with equal data should be equal");

    card2.addressCity = @"My Fake City";
    XCTAssertNotEqualObjects(card1, card2, @"cards should not match");
}

@end
