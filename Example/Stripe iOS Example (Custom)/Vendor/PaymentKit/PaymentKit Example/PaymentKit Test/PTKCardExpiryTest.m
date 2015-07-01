//
//  PTKCardExpiryTest.m
//  PTKPayment Example
//
//  Created by Alex MacCaw on 2/6/13.
//  Copyright (c) 2013 Stripe. All rights reserved.
//

#import "PTKCardExpiryTest.h"
#import "PTKCardExpiry.h"
#define CEXPIRY(string) [PTKCardExpiry cardExpiryWithString:string]

@interface PTKCardExpiry ()

- (BOOL)isValidWithDate:(NSDate *)dateToCompare;
- (NSDate*)expiryDate;

@end

@implementation PTKCardExpiryTest

- (void)testFromString
{
    XCTAssertEqual([CEXPIRY(@"01") month], (NSUInteger) 1, @"Strips month");
    XCTAssertEqual([CEXPIRY(@"05/") month], (NSUInteger) 5, @"Strips month");
    
    XCTAssertEqual([CEXPIRY(@"03 / 2020") year], (NSUInteger) 2020, @"Strips year");
    XCTAssertEqual([CEXPIRY(@"03/20") year], (NSUInteger) 2020, @"Strips year");
}

- (void)testFormattedString
{
    XCTAssertEqualObjects([CEXPIRY(@"01") formattedString], @"01", @"Formatted");
    XCTAssertEqualObjects([CEXPIRY(@"05/") formattedString], @"05", @"Formatted");

    XCTAssertEqualObjects([CEXPIRY(@"05/20") formattedString], @"05/20", @"Formatted");
    XCTAssertEqualObjects([CEXPIRY(@"05 / 20") formattedString], @"05/20", @"Formatted");

    XCTAssertEqualObjects([CEXPIRY(@"/ 2020") formattedString], @"/2020", @"Formatted");
}

- (void)testFormattedStringWithTrail
{
    XCTAssertEqualObjects([CEXPIRY(@"01") formattedStringWithTrail], @"01/", @"Formatted");
    XCTAssertEqualObjects([CEXPIRY(@"05/") formattedStringWithTrail], @"05/", @"Formatted");
    
    XCTAssertEqualObjects([CEXPIRY(@"05/20") formattedStringWithTrail], @"05/20", @"Formatted");
    XCTAssertEqualObjects([CEXPIRY(@"05 / 20") formattedStringWithTrail], @"05/20", @"Formatted");
}

- (void)testIsValid
{
    XCTAssertTrue(![CEXPIRY(@"01") isValid], @"Is valid");
    XCTAssertTrue(![CEXPIRY(@"") isValid], @"Is valid");
    XCTAssertTrue(![CEXPIRY(@"01/") isValid], @"Is valid");
    XCTAssertTrue(![CEXPIRY(@"01/0") isValid], @"Is valid");
    XCTAssertTrue(![CEXPIRY(@"13/20") isValid], @"Is valid");
    XCTAssertTrue(![CEXPIRY(@"12/2010") isValid], @"Is valid");
    
    XCTAssertTrue([CEXPIRY(@"12/2050") isValid], @"Is valid");
    XCTAssertTrue([CEXPIRY(@"12/50") isValid], @"Is valid");
}

- (void)testIsPartialyValid
{
    XCTAssertTrue([CEXPIRY(@"01") isPartiallyValid], @"Is valid");
    XCTAssertTrue([CEXPIRY(@"") isPartiallyValid], @"Is valid");
    XCTAssertTrue([CEXPIRY(@"01/") isPartiallyValid], @"Is valid");
    XCTAssertTrue(![CEXPIRY(@"13") isPartiallyValid], @"Is valid");
    XCTAssertTrue(![CEXPIRY(@"12/2010") isPartiallyValid], @"Is valid");
    
    XCTAssertTrue([CEXPIRY(@"12/2050") isPartiallyValid], @"Is valid");
    XCTAssertTrue([CEXPIRY(@"12/50") isPartiallyValid], @"Is valid");
}

- (void)testIsValidWithDate
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm";
    PTKCardExpiry *cardExpiry = CEXPIRY(@"02/14");

    NSDate *dateToCompare = [dateFormatter dateFromString:@"2014-01-31 23:59"];
    XCTAssertTrue([cardExpiry isValidWithDate:dateToCompare], @"Is valid");

    dateToCompare = [dateFormatter dateFromString:@"2015-01-31 23:59"];
    XCTAssertFalse([cardExpiry isValidWithDate:dateToCompare], @"Is valid");

    dateToCompare = [dateFormatter dateFromString:@"2014-02-10 12:00"];
    XCTAssertTrue([cardExpiry isValidWithDate:dateToCompare], @"Is valid");

    dateToCompare = [dateFormatter dateFromString:@"2014-02-28 23:49"];
    XCTAssertTrue([cardExpiry isValidWithDate:dateToCompare], @"Is valid");

    dateToCompare = [dateFormatter dateFromString:@"2014-02-28 23:59"];
    XCTAssertTrue([cardExpiry isValidWithDate:dateToCompare], @"Is valid");

    dateToCompare = [dateFormatter dateFromString:@"2014-03-01 00:00"];
    XCTAssertFalse([cardExpiry isValidWithDate:dateToCompare], @"Is valid");

    dateToCompare = [dateFormatter dateFromString:@"2014-03-01 00:01"];
    XCTAssertFalse([cardExpiry isValidWithDate:dateToCompare], @"Is valid");


    cardExpiry = CEXPIRY(@"02/16");

    dateToCompare = [dateFormatter dateFromString:@"2016-02-10 12:00"];
    XCTAssertTrue([cardExpiry isValidWithDate:dateToCompare], @"Is valid");

    dateToCompare = [dateFormatter dateFromString:@"2016-02-28 23:49"];
    XCTAssertTrue([cardExpiry isValidWithDate:dateToCompare], @"Is valid");

    dateToCompare = [dateFormatter dateFromString:@"2016-02-28 23:51"];
    XCTAssertTrue([cardExpiry isValidWithDate:dateToCompare], @"Is valid");

    dateToCompare = [dateFormatter dateFromString:@"2016-02-29 23:51"];
    XCTAssertTrue([cardExpiry isValidWithDate:dateToCompare], @"Is valid");

    dateToCompare = [dateFormatter dateFromString:@"2016-02-29 23:59"];
    XCTAssertTrue([cardExpiry isValidWithDate:dateToCompare], @"Is valid");

    dateToCompare = [dateFormatter dateFromString:@"2016-03-01 00:00"];
    XCTAssertFalse([cardExpiry isValidWithDate:dateToCompare], @"Is valid");

    dateToCompare = [dateFormatter dateFromString:@"2016-03-01 00:01"];
    XCTAssertFalse([cardExpiry isValidWithDate:dateToCompare], @"Is valid");
}

- (void)testCardExpirationAtTheCurrentMonth
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm";
    NSDate *expiryDate = [CEXPIRY(@"02/14") expiryDate];
    
    NSDate *dateToCompare = [dateFormatter dateFromString:@"2014-02-10 12:00"];
    XCTAssertTrue([expiryDate compare:dateToCompare] == NSOrderedDescending, @"Is valid");
    
    dateToCompare = [dateFormatter dateFromString:@"2014-02-28 23:49"];
    XCTAssertTrue([expiryDate compare:dateToCompare] == NSOrderedDescending, @"Is valid");
    
    dateToCompare = [dateFormatter dateFromString:@"2014-02-28 23:51"];
    XCTAssertTrue([expiryDate compare:dateToCompare] == NSOrderedDescending, @"Is valid");
    
    dateToCompare = [dateFormatter dateFromString:@"2014-03-01 00:00"];
    XCTAssertFalse([expiryDate compare:dateToCompare] == NSOrderedDescending, @"Is valid");
    
    dateToCompare = [dateFormatter dateFromString:@"2014-03-01 00:01"];
    XCTAssertFalse([expiryDate compare:dateToCompare] == NSOrderedDescending, @"Is valid");
    
    
    expiryDate = [CEXPIRY(@"02/16") expiryDate];
    
    dateToCompare = [dateFormatter dateFromString:@"2016-02-10 12:00"];
    XCTAssertTrue([expiryDate compare:dateToCompare] == NSOrderedDescending, @"Is valid");
    
    dateToCompare = [dateFormatter dateFromString:@"2016-02-28 23:49"];
    XCTAssertTrue([expiryDate compare:dateToCompare] == NSOrderedDescending, @"Is valid");
    
    dateToCompare = [dateFormatter dateFromString:@"2016-02-28 23:51"];
    XCTAssertTrue([expiryDate compare:dateToCompare] == NSOrderedDescending, @"Is valid");
    
    dateToCompare = [dateFormatter dateFromString:@"2016-02-29 23:51"];
    XCTAssertTrue([expiryDate compare:dateToCompare] == NSOrderedDescending, @"Is valid");
    
    dateToCompare = [dateFormatter dateFromString:@"2016-03-01 00:00"];
    XCTAssertFalse([expiryDate compare:dateToCompare] == NSOrderedDescending, @"Is valid");
    
    dateToCompare = [dateFormatter dateFromString:@"2016-03-01 00:01"];
    XCTAssertFalse([expiryDate compare:dateToCompare] == NSOrderedDescending, @"Is valid");
}

@end
