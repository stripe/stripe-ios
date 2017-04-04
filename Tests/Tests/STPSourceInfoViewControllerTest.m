//
//  STPSourceInfoViewControllerTest.m
//  Stripe
//
//  Created by Ben Guo on 2/13/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "STPFixtures.h"
#import "STPSelectorDataSource.h"
#import "STPSourceInfoDataSource.h"
#import "STPSourceInfoViewController.h"
#import "STPTextFieldTableViewCell.h"

NSString * const kReturnURLString = @"testscheme://stripe";


@interface STPSourceInfoViewController ()
@property(nonatomic)STPSourceInfoDataSource *dataSource;
@end

@interface STPSourceInfoViewControllerTest : XCTestCase

@end

@implementation STPSourceInfoViewControllerTest

- (STPSourceInfoViewController *)sutWithType:(STPSourceType)type
                                        info:(STPUserInformation *)info
                                  completion:(STPSourceInfoCompletionBlock)completion {
    STPTheme *theme = [STPTheme defaultTheme];
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
    config.returnURL = [NSURL URLWithString:kReturnURLString];
    NSInteger amount = 100;
    STPSourceInfoViewController *sut = [[STPSourceInfoViewController alloc] initWithSourceType:type
                                                                                        amount:amount
                                                                                 configuration:config
                                                                          prefilledInformation:info
                                                                                         theme:theme
                                                                                    completion:completion];
    UINavigationController *navController = [UINavigationController new];
    navController.view.frame = CGRectMake(0, 0, 320, 750);
    [navController pushViewController:sut animated:NO];
    [navController.view layoutIfNeeded];
    return sut;
}

- (void)testInitWithSourceParams_unsupportedType {
    STPUserInformation *info = [STPUserInformation new];
    STPSourceInfoViewController *sut = [self sutWithType:STPSourceTypeBitcoin
                                                    info:info
                                              completion:nil];
    XCTAssertNil(sut);
}

- (void)testInitWithSourceParams_bancontact {
    STPUserInformation *info = [STPUserInformation new];
    STPAddress *address = [STPAddress new];
    address.name = @"Jenny Rosen";
    info.billingAddress = address;
    STPSourceInfoViewController *sut = [self sutWithType:STPSourceTypeBancontact
                                                    info:info
                                              completion:nil];

    // Test initial state
    XCTAssertEqual(sut.dataSource.cells.count, 1U);
    STPTextFieldTableViewCell *nameCell = [sut.dataSource.cells firstObject];
    XCTAssertEqualObjects(nameCell.contents, @"Jenny Rosen");
    XCTAssertNotNil(sut.completeSourceParams);

    // Unfilled form should not return source params
    nameCell.contents = @"";
    XCTAssertNil(sut.completeSourceParams);

    // Filled form should return source params
    nameCell.contents = @"John Smith";
    XCTAssertNotNil(sut.completeSourceParams);
    XCTAssertEqualObjects(sut.completeSourceParams.owner[@"name"], nameCell.contents);
    XCTAssertEqualObjects(sut.completeSourceParams.redirect[@"return_url"], kReturnURLString);
}

- (void)testInitWithSourceParams_giropay {
    STPUserInformation *info = [STPUserInformation new];
    STPAddress *address = [STPAddress new];
    address.name = @"Jenny Rosen";
    info.billingAddress = address;
    STPSourceInfoViewController *sut = [self sutWithType:STPSourceTypeGiropay
                                                    info:info
                                              completion:nil];

    // Test initial state
    XCTAssertEqual(sut.dataSource.cells.count, 1U);
    STPTextFieldTableViewCell *nameCell = [sut.dataSource.cells firstObject];
    XCTAssertEqualObjects(nameCell.contents, @"Jenny Rosen");
    XCTAssertNotNil(sut.completeSourceParams);

    // Unfilled form should not return source params
    nameCell.contents = @"";
    XCTAssertNil(sut.completeSourceParams);

    // Filled form should return source params
    nameCell.contents = @"John Smith";
    XCTAssertNotNil(sut.completeSourceParams);
    XCTAssertEqualObjects(sut.completeSourceParams.owner[@"name"], nameCell.contents);
    XCTAssertEqualObjects(sut.completeSourceParams.redirect[@"return_url"], kReturnURLString);
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

- (void)testInitWithSourceParams_iDEAL_unfilled {
    STPUserInformation *info = [STPUserInformation new];
    STPAddress *address = [STPAddress new];
    address.name = @"Jenny Rosen";
    info.billingAddress = address;
    info.idealBank = @"ing";

    NSString *expectedName = @"John Smith";
    NSString *expectedBank = @"rabobank";
    XCTestExpectation *exp = [self expectationWithDescription:@"completion"];
    STPSourceInfoViewController *sut = [self sutWithType:STPSourceTypeIDEAL
                                                    info:info
                                              completion:^(STPSourceParams *sourceParams) {
                                                  XCTAssertNotNil(sourceParams);
                                                  XCTAssertEqualObjects(sourceParams.owner[@"name"], expectedName);
                                                  NSDictionary *idealDict = sourceParams.additionalAPIParameters[@"ideal"];
                                                  XCTAssertEqualObjects(idealDict, @{@"bank": expectedBank});
                                                  XCTAssertEqualObjects(sourceParams.redirect[@"return_url"], kReturnURLString);
                                                  [exp fulfill];
                                              }];

    // Test initial state
    id<STPSelectorDataSource> selectorDataSource = sut.dataSource.selectorDataSource;
    XCTAssertEqual(sut.dataSource.cells.count, 1U);
    STPTextFieldTableViewCell *nameCell = [sut.dataSource.cells firstObject];
    XCTAssertEqualObjects(nameCell.contents, @"Jenny Rosen");
    NSInteger selectedRow = selectorDataSource.selectedRow;
    NSString *bank = [selectorDataSource selectorValueForRow:selectedRow];
    XCTAssertEqualObjects(bank, @"ing");
    // completedSourceParams is nil because iDEAL bank requires user verification
    XCTAssertNil(sut.completeSourceParams);

    // Fill form with new values and assert in completion above
    nameCell.contents = expectedName;
    [selectorDataSource selectRowWithValue:expectedBank];

    // tap next button
    UIBarButtonItem *nextButton = sut.navigationItem.rightBarButtonItem;
    [nextButton.target performSelector:nextButton.action withObject:nextButton];

    [self waitForExpectationsWithTimeout:2 handler:nil];
}

#pragma clang diagnostic pop

- (void)testInitWithSourceParams_sofort {
    STPUserInformation *info = [STPUserInformation new];
    STPAddress *address = [STPAddress new];
    address.country = @"FR";
    info.billingAddress = address;
    STPSourceInfoViewController *sut = [self sutWithType:STPSourceTypeSofort
                                                    info:info
                                              completion:nil];

    // Test initial state
    id<STPSelectorDataSource> selectorDataSource = sut.dataSource.selectorDataSource;
    XCTAssertEqual(sut.dataSource.cells.count, 0U);
    NSInteger selectedRow = selectorDataSource.selectedRow;
    NSString *country = [selectorDataSource selectorValueForRow:selectedRow];
    XCTAssertEqualObjects(country, @"FR");
    XCTAssertNotNil(sut.completeSourceParams);

    // Unfilled form should not return source params
    [selectorDataSource selectRowWithValue:@"invalid_country"];
    XCTAssertEqual(selectorDataSource.selectedRow, NSNotFound);
    XCTAssertNil(sut.completeSourceParams);

    // Filled form should return source params
    [selectorDataSource selectRowWithValue:@"AT"];
    XCTAssertNotNil(sut.completeSourceParams);
    NSDictionary *sofortDict = sut.completeSourceParams.additionalAPIParameters[@"sofort"];
    XCTAssertEqualObjects(sofortDict, @{@"country": @"AT"});
    XCTAssertEqualObjects(sut.completeSourceParams.redirect[@"return_url"], kReturnURLString);

    // Test initializing with a non-Sofort country
    address.country = @"US";
    info.billingAddress = address;
    sut = [self sutWithType:STPSourceTypeSofort info:info completion:nil];
    XCTAssertNil(sut.completeSourceParams);
}

- (void)testRequiresUserVerification {
    STPUserInformation *info = [STPUserInformation new];
    STPAddress *address = [STPAddress new];
    address.country = @"FR";
    info.billingAddress = address;
    STPSourceInfoViewController *sut = [self sutWithType:STPSourceTypeSofort
                                                    info:info
                                              completion:nil];
    XCTAssertNotNil(sut.completeSourceParams);
    sut.dataSource.requiresUserVerification = YES;
    XCTAssertNil(sut.completeSourceParams);
}

@end
