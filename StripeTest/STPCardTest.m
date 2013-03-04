//
//  STPCardTest.m
//  Stripe
//
//  Created by Saikat Chakrabarti on 11/5/12.
//
//

#import "STPCard.h"
#import "StripeError.h"
#import "STPCardTest.h"

@implementation NSDate(CardTestOverrides)
+ (NSDate *)date
{
    // All card tests will pretend the current date is August 29, 1997.
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setYear:1997];
    [components setMonth:8];
    [components setDay:29];
    return [calendar dateFromComponents:components];
}
@end

@interface STPCardTest ()
- (NSDateComponents *)getCurrentDateComponents;
- (NSInteger)getCurrentYear;
@end

@implementation STPCardTest
{
    STPCard *card;
}

- (void)setUp
{
    card = [[STPCard alloc] init];
}

#pragma mark Helpers
- (NSDateComponents *)getCurrentDateComponents
{
    // FIXME This is a copy of the code that already exists in a private method in STPCard
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    return [gregorian components:NSYearCalendarUnit fromDate:[NSDate date]];
}

- (NSInteger)getCurrentYear
{
    return [[self getCurrentDateComponents] year];
}

#pragma mark -initWithAttributeDictionary: tests
- (void)testInitializingCardWithAttributeDictionary
{
    NSDictionary *attributeDict = [NSDictionary dictionaryWithObjectsAndKeys:@"4242424242424242", @"number", @"12", @"expMonth", @"2013", @"expYear", @"123", @"cvc", @"Smerlock Smolmes", @"name", @"221A Baker Street", @"addressLine1", @"New York", @"addressCity", @"NY", @"addressState", @"12345", @"addressZip", @"USA", @"addressCountry", @"something", @"object", @"1234", @"last4", @"Smastersmard", @"type", @"Fingolfin", @"fingerprint", @"Japan", @"country", nil];
    STPCard *cardWithAttributes = [[STPCard alloc] initWithAttributeDictionary:attributeDict];

    STAssertEqualObjects([cardWithAttributes number], @"4242424242424242", @"number is set correctly");
    STAssertTrue([cardWithAttributes expMonth] == 12, @"expMonth is set correctly");
    STAssertTrue([cardWithAttributes expYear] == 2013, @"expYear is set correctly");
    STAssertEqualObjects([cardWithAttributes cvc], @"123", @"CVC is set correctly");
    STAssertEqualObjects([cardWithAttributes name], @"Smerlock Smolmes", @"name is set correctly");
    STAssertEqualObjects([cardWithAttributes addressLine1], @"221A Baker Street", @"addressLine1 is set correctly");
    STAssertEqualObjects([cardWithAttributes addressCity], @"New York", @"addressCity is set correctly");
    STAssertEqualObjects([cardWithAttributes addressState], @"NY", @"addressState is set correctly");
    STAssertEqualObjects([cardWithAttributes addressZip], @"12345", @"addressZip is set correctly");
    STAssertEqualObjects([cardWithAttributes addressCountry], @"USA", @"addressCountry is set correctly");
    STAssertEqualObjects([cardWithAttributes object], @"something", @"object is set correctly");
    STAssertEqualObjects([cardWithAttributes last4], @"1234", @"last4 is set correctly");
    STAssertEqualObjects([cardWithAttributes type], @"Smastersmard", @"type is set correctly");
    STAssertEqualObjects([cardWithAttributes fingerprint], @"Fingolfin", @"fingerprint is set correctly");
    STAssertEqualObjects([cardWithAttributes country], @"Japan", @"country is set correctly");
}

#pragma mark -last4 tests
- (void)testLast4ReturnsCardNumberLast4WhenNotSet
{
    card.number = @"4242424242424242";
    STAssertEqualObjects(card.last4, @"4242", @"last4 correctly returns the last 4 digits of the card number");
}

- (void)testLast4ReturnsNullWhenNoCardNumberSet
{
    STAssertEqualObjects(nil, card.last4, @"last4 returns nil when nothing is set");
}

#pragma mark -type tests
- (void)testTypeReturnsCorrectlyForAmexCard
{
    card.number = @"3412123412341234";
    STAssertEqualObjects(@"American Express", card.type, @"Correct card type returned for Amex card");
}

- (void)testTypeReturnsCorrectlyForDiscoverCard
{
    card.number = @"6452123412341234";
    STAssertEqualObjects(@"Discover", card.type, @"Correct card type returned for Discover card");
}

- (void)testTypeReturnsCorrectlyForJCBCard
{
    card.number = @"3512123412341234";
    STAssertEqualObjects(@"JCB", card.type, @"Correct card type returned for JCB card");
}

- (void)testTypeReturnsCorrectlyForDinersClubCard
{
    card.number = @"3612123412341234";
    STAssertEqualObjects(@"Diners Club", card.type, @"Correct card type returned for Diners Club card");
}

- (void)testTypeReturnsCorrectlyForVisaCard
{
    card.number = @"4123123412341234";
    STAssertEqualObjects(@"Visa", card.type, @"Correct card type returned for Visa card");
}

- (void)testTypeReturnsCorrectlyForMasterCardCard
{
    card.number = @"5123123412341234";
    STAssertEqualObjects(@"MasterCard", card.type, @"Correct card type returned for MasterCard card");
}

#pragma mark -validateNumber:error: tests
- (void)testEmptyCardNumberDoesNotValidate
{
    NSError *error = nil;
    NSString *number = @"";
    BOOL didValidate = [card validateNumber:&number error:&error];
    STAssertFalse(didValidate, @"Empty card should not validate");
}

- (void)testThatInvalidCardNumberReturnsTheCorrectError
{
    NSError *error = nil;
    NSString *number = @"";
    [card validateNumber:&number error:&error];
    STAssertEqualObjects(@"Your card's number is invalid", [error localizedDescription], @"Invalid card number gives an error with a message saying the number is invalid");
    NSDictionary *userInfo = [error userInfo];
    STAssertEqualObjects([userInfo valueForKey:STPCardErrorCodeKey], STPInvalidNumber, @"Invalid card number returns the correct card error code");
    STAssertEqualObjects([userInfo valueForKey:STPErrorParameterKey], @"number", @"Invaild card number returns the correct error parameter");
    STAssertTrue([userInfo objectForKey:STPErrorMessageKey] != nil, @"Invalid card number returns a developer-facing error message");
}

- (void)testCardNumberWithManySpaces
{
    NSError *error = nil;
    NSString *number = @"      ";
    STAssertFalse([card validateNumber:&number error:&error], @"A card with a bunch of spaces should not validate");
}

- (void)testValidCardNumber
{
    NSError *error = nil;
    NSString *number = @"4242424242424242";
    STAssertTrue([card validateNumber:&number error:&error], @"A valid card should validate");
}

- (void)testValidCardNumberWithDashes
{
    NSError *error = nil;
    NSString *number = @"4242-4242-4242-4242";
    STAssertTrue([card validateNumber:&number error:&error], @"A valid card with dashes should validate");
}

- (void)testValidCardNumberWithSpaces
{
    NSError *error = nil;
    NSString *number = @"4242 4242 4242 4242";
    STAssertTrue([card validateNumber:&number error:&error], @"A valid card with spaces should validate");
}

- (void)testNonLuhnValidCardNumber
{
    NSError *error = nil;
    NSString *number = @"4242424242424241";
    STAssertFalse([card validateNumber:&number error:&error], @"A non-Luhn valid card should not validate");
}

- (void)testValidCardNumberWithAlphabetCharacters
{
    NSError *error = nil;
    NSString *number = @"424242424242a4242";
    STAssertFalse([card validateNumber:&number error:&error], @"A card with non-numeric characters that aren't spaces or dashes should not validate");
}

- (void)testCardNumberWithMoreThanNineteenDigits
{
    NSError *error = nil;
    NSString *number = @"424242424242424242424242";
    STAssertFalse([card validateNumber:&number error:&error], @"A card with more than 19 digits should not validate");
}

- (void)testCardNumberWithLessThanTenDigits
{
    NSError *error = nil;
    NSString *number = @"42424242";
    STAssertFalse([card validateNumber:&number error:&error], @"A card with more than 19 digits should not validate");
}


#pragma mark -validateCvc:error: tests
- (void)testInvalidCVCReturnsTheCorrectError
{
    NSError *error = nil;
    NSString *cvc = @"";
    STAssertFalse([card validateCvc:&cvc error:&error], @"Empty CVC should not validate");
    STAssertEqualObjects(@"Your card's security code is invalid", [error localizedDescription], @"Invalid card CVC gives the correct user-facing error message");
    NSDictionary *userInfo = [error userInfo];
    STAssertEqualObjects([userInfo valueForKey:STPCardErrorCodeKey], STPInvalidCVC, @"Invalid card number returns the correct card error code");
    STAssertEqualObjects([userInfo valueForKey:STPErrorParameterKey], @"cvc", @"Invaild CVC returns the correct error parameter");
    STAssertTrue([userInfo objectForKey:STPErrorMessageKey] != nil, @"Invalid CVC returns a developer-facing error message");
}

- (void)testValidCVC
{
    NSError *error = nil;
    NSString *cvc = @"123";
    STAssertTrue([card validateCvc:&cvc error:&error], @"Valid CVC should validate");
}

- (void)testNullCVC
{
    NSError *error = nil;
    NSString *cvc = nil;
    STAssertFalse([card validateCvc:&cvc error:&error], @"Null CVC should not validate");
}

- (void)testNonNumericCVC
{
    NSError *error = nil;
    NSString *cvc = @"1a3";
    STAssertFalse([card validateCvc:&cvc error:&error], @"CVC with non-numeric characters should not validate");
}

- (void)testTooShortCVC
{
    NSError *error = nil;
    NSString *cvc = @"13";
    STAssertFalse([card validateCvc:&cvc error:&error], @"Too short CVC should not validate");
}

- (void)testTooLongCVC
{
    NSError *error = nil;
    NSString *cvc = @"12345";
    STAssertFalse([card validateCvc:&cvc error:&error], @"Too long CVC should not validate");
}

- (void)testThreeDigitCVCDoesNotValidateForAmexCard
{
    NSError *error = nil;
    NSString *cvc = @"123";
    card.number = @"3412123412341234";
    STAssertFalse([card validateCvc:&cvc error:&error], @"Three digit CVC is too short for Amex card");
}

- (void)testFourDigitCVCValidatesForAmexCard
{
    NSError *error = nil;
    NSString *cvc = @"1234";
    card.number = @"3412123412341234";
    STAssertTrue([card validateCvc:&cvc error:&error], @"Four digit CVC is valid for Amex card");
}

- (void)testFourDigitCVCDoesNotValidateForVisaCard
{
    NSError *error = nil;
    NSString *cvc = @"1234";
    card.number = @"4112123412341234";
    STAssertFalse([card validateCvc:&cvc error:&error], @"Four digit CVC is too long for non-Amex card");
}

- (void)testThreeDigitCVCValidatesForVisaCard
{
    NSError *error = nil;
    NSString *cvc = @"123";
    card.number = @"4112123412341234";
    STAssertTrue([card validateCvc:&cvc error:&error], @"Three digit CVC is valid for non-Amex card");
}

#pragma mark -validateExpMonth:error: tests
- (void)testInvalidExpMonthReturnsTheCorrectError
{
    NSError *error = nil;
    NSString *expMonth = @"";
    STAssertFalse([card validateExpMonth:&expMonth error:&error], @"expMonth must not be empty");
    STAssertEqualObjects(@"Your card's expiration month is invalid", [error localizedDescription], @"Invalid card expiration month gives the correct user facing error message");
    NSDictionary *userInfo = [error userInfo];    STAssertEqualObjects([userInfo valueForKey:STPCardErrorCodeKey], STPInvalidExpMonth, @"Invalid card expiration month returns the correct card error code");
    STAssertEqualObjects([userInfo valueForKey:STPErrorParameterKey], @"expMonth", @"Invaild expiration month returns the correct error parameter");
    STAssertTrue([userInfo objectForKey:STPErrorMessageKey] != nil, @"Invalid expiration month returns a developer-facing error message");
}

- (void)testNullExpMonth
{
    NSError *error = nil;
    NSString *expMonth = nil;
    STAssertFalse([card validateExpMonth:&expMonth error:&error], @"Null expMonth should not validate.");
}

- (void)testExpMonthGreaterThan12
{
    NSError *error = nil;
    NSString *expMonth = @"14";
    STAssertFalse([card validateExpMonth:&expMonth error:&error], @"expMonth must not be less than or equal to 12");
}

- (void)testExpMonthWithNonNumericCharacters
{
    NSError *error = nil;
    NSString *expMonth = @"11a";
    STAssertFalse([card validateExpMonth:&expMonth error:&error], @"expMonth must not have any non-numeric characters");
}

- (void)testValidExpMonth
{
    NSError *error = nil;
    NSString *expMonth = @"05";
    STAssertTrue([card validateExpMonth:&expMonth error:&error], @"Numeric expMonth below 13 should validate");
}

- (void)testInvalidExpMonthForYearInPast
{
    NSError *error = nil;
    NSString *expMonth = @"12";
    card.expYear = 1995;
    STAssertFalse([card validateExpMonth:&expMonth error:&error], @"The year, when setting an expMonth, must not be invalid");
    NSDictionary *userInfo = [error userInfo];
    STAssertEqualObjects([userInfo valueForKey:STPCardErrorCodeKey], STPInvalidExpYear, @"Invalid card expiration year when setting card expiration month returns the correct card error code");
}

- (void)testInvalidExpMonthForYearSameAsCurrentYear
{
    NSError *error = nil;
    card.expYear = [self getCurrentYear];
    NSString *expMonth = @"1";
    STAssertFalse([card validateExpMonth:&expMonth error:&error], @"When the year is already set, if it is the same as the current year and the month is before the current month, the month is invalid");
}

- (void)testValidExpMonthForYearInFuture
{
    NSError *error = nil;
    NSString *expMonth = @"1";
    card.expYear = [self getCurrentYear] + 1;
    STAssertTrue([card validateExpMonth:&expMonth error:&error], @"When the year is already set, if it is in the future, any numeric expMonth is valid");
}

- (void)testValidExpMonthForYearSameAsCurrentYear
{
    NSError *error = nil;
    card.expYear = [self getCurrentYear];
    NSString *expMonth = @"12";
    STAssertTrue([card validateExpMonth:&expMonth error:&error], @"When the year is already set, if it is the same as the current year and the month is the same as the current month, the month is invalid");
}

#pragma mark -validateExpYear:error: tests
- (void)testInvalidExpYearReturnsCorrectError
{
    NSError *error = nil;
    NSString *expYear = @"";
    STAssertFalse([card validateExpYear:&expYear error:&error], @"expYear must not be empty");
    STAssertEqualObjects(@"Your card's expiration year is invalid", [error localizedDescription], @"Invalid card expiration year gives the correct user facing error message");

    NSDictionary *userInfo = [error userInfo];
    STAssertEqualObjects([userInfo valueForKey:STPCardErrorCodeKey], STPInvalidExpYear, @"Invalid card expiration month returns the correct card error code");
    STAssertEqualObjects([userInfo valueForKey:STPErrorParameterKey], @"expYear", @"Invaild expiration year returns the correct error parameter");
    STAssertTrue([userInfo objectForKey:STPErrorMessageKey] != nil, @"Invalid expiration year returns a developer-facing error message");
}

- (void)testNullExpYear
{
    NSError *error = nil;
    NSString *expYear = nil;
    STAssertFalse([card validateExpYear:&expYear error:&error], @"expYear must not be null");
}


- (void)testExpYearBeforeCurrentYear
{
    NSError *error = nil;
    NSString *expYear = @"1995";
    STAssertFalse([card validateExpYear:&expYear error:&error], @"expYear must not be in the past");
}

- (void)testValidExpYear
{
    NSError *error = nil;
    NSString *expYear = @"2000";
    STAssertTrue([card validateExpYear:&expYear error:&error], @"expYear in the future is valid");
}

- (void)testInvalidExpYearForYearSameAsCurrentYear
{
    NSError *error = nil;
    NSString *expYear = [NSString stringWithFormat:@"%d", [self getCurrentYear]];
    card.expMonth = 1;
    STAssertFalse([card validateExpYear:&expYear error:&error], @"When the month is already set, if the combination of month and year is in the past, don't validate");

    NSDictionary *userInfo = [error userInfo];
    STAssertEqualObjects([userInfo objectForKey:STPCardErrorCodeKey], STPInvalidExpMonth, @"The error returned should be for the expMonth");
}

- (void)testValidExpYearWhenMonthIsSet
{
    NSError *error = nil;
    card.expMonth = 4;
    NSString *expYear = @"2000";
    STAssertTrue([card validateExpYear:&expYear error:&error], @"expYear in the future is valid even with a month set");
}

#pragma mark -validateCardReturningError: tests
- (void)testValidatingCardWithInvalidNumber
{
    NSError *error = nil;
    card.number = @"4242424242424241";
    card.expMonth = 12;
    card.expYear = 2012;
    STAssertFalse([card validateCardReturningError:&error], @"Card with invalid number should fail overall validation");
    NSDictionary *userInfo = [error userInfo];
    STAssertEqualObjects([userInfo objectForKey:STPCardErrorCodeKey], STPInvalidNumber, @"The error returned should be for the number");
}

- (void)testExpiredCardDoesNotValidate
{
    NSError *error = nil;
    card.number = @"4242424242424242";
    card.expMonth = 1;
    card.expYear = 1997;
    STAssertFalse([card validateCardReturningError:&error], @"Expired card shoul fail overall validation");
    NSDictionary *userInfo = [error userInfo];
    STAssertEqualObjects([userInfo objectForKey:STPCardErrorCodeKey], STPInvalidExpMonth, @"The error returned should be for the expMonth");
}

- (void)testCardWithBadCVCDoesNotValidate
{
    NSError *error = nil;
    card.number = @"4242424242424242";
    card.cvc = @"1234";
    card.expMonth = 12;
    card.expYear = 2012;
    STAssertFalse([card validateCardReturningError:&error], @"Card with bad CVC should fail overall validation");
    NSDictionary *userInfo = [error userInfo];
    STAssertEqualObjects([userInfo objectForKey:STPCardErrorCodeKey], STPInvalidCVC, @"The error returned should be for the cvc");
}

- (void)testCardWithMissingExpYearDoesNotValidate
{
    NSError *error = nil;
    card.number = @"4242424242424242";
    card.cvc = @"123";
    card.expMonth = 12;
    STAssertFalse([card validateCardReturningError:&error], @"Card missing expYear should fail validation");
    NSDictionary *userInfo = [error userInfo];
    STAssertEqualObjects([userInfo objectForKey:STPCardErrorCodeKey], STPInvalidExpYear, @"The error returned should be for the expYear");
}

- (void)testCardWithMissingNumberDoesNotValidate
{
    NSError *error;
    card.expMonth = 12;
    card.expYear = 2012;
    STAssertFalse([card validateCardReturningError:&error], @"Card with missing number should fail overall validation");
    NSDictionary *userInfo = [error userInfo];
    STAssertEqualObjects([userInfo objectForKey:STPCardErrorCodeKey], STPInvalidNumber, @"The error returned should be for the number");
}
@end
