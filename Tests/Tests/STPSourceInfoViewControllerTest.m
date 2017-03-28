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

@interface STPSourceInfoViewController ()
@property(nonatomic)STPSourceInfoDataSource *dataSource;
@end

@interface STPSourceInfoViewControllerTest : XCTestCase

@end

@implementation STPSourceInfoViewControllerTest

- (STPSourceInfoViewController *)sutWithType:(STPSourceType)type
                                        info:(STPUserInformation *)info {
    STPTheme *theme = [STPTheme defaultTheme];
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
    // TODO: set returnURL and verify in tests
    NSInteger amount = 100;
    STPSourceInfoViewController *sut = [[STPSourceInfoViewController alloc] initWithSourceType:type
                                                                                        amount:amount
                                                                                 configuration:config
                                                                          prefilledInformation:info
                                                                                         theme:theme
                                                                                    completion:^(__unused STPSourceParams *sourceParams) {
                                                                                        // noop
                                                                                    }];
    UINavigationController *navController = [UINavigationController new];
    navController.view.frame = CGRectMake(0, 0, 320, 750);
    [navController pushViewController:sut animated:NO];
    [navController.view layoutIfNeeded];
    return sut;
}

- (void)testInitWithSourceParams_unsupportedType {
    STPUserInformation *info = [STPUserInformation new];
    STPSourceInfoViewController *sut = [self sutWithType:STPSourceTypeBitcoin info:info];
    XCTAssertNil(sut);
}

- (void)testInitWithSourceParams_bancontact {
    STPUserInformation *info = [STPUserInformation new];
    STPAddress *address = [STPAddress new];
    address.name = @"Jenny Rosen";
    info.billingAddress = address;
    STPSourceInfoViewController *sut = [self sutWithType:STPSourceTypeBancontact
                                                    info:info];

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
}

- (void)testInitWithSourceParams_giropay {
    STPUserInformation *info = [STPUserInformation new];
    STPAddress *address = [STPAddress new];
    address.name = @"Jenny Rosen";
    info.billingAddress = address;
    STPSourceInfoViewController *sut = [self sutWithType:STPSourceTypeGiropay
                                                    info:info];

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
}

- (void)testInitWithSourceParams_iDEAL {
    STPUserInformation *info = [STPUserInformation new];
    STPAddress *address = [STPAddress new];
    address.name = @"Jenny Rosen";
    info.billingAddress = address;
    info.idealBank = @"ing";
    STPSourceInfoViewController *sut = [self sutWithType:STPSourceTypeIDEAL
                                                    info:info];

    // Test initial state
    id<STPSelectorDataSource> selectorDataSource = sut.dataSource.selectorDataSource;
    XCTAssertEqual(sut.dataSource.cells.count, 1U);
    STPTextFieldTableViewCell *nameCell = [sut.dataSource.cells firstObject];
    XCTAssertEqualObjects(nameCell.contents, @"Jenny Rosen");
    NSInteger selectedRow = selectorDataSource.selectedRow;
    NSString *bank = [selectorDataSource selectorValueForRow:selectedRow];
    XCTAssertEqualObjects(bank, @"ing");
    XCTAssertNotNil(sut.completeSourceParams);

    // Unfilled form should not return source params
    nameCell.contents = @"";
    XCTAssertNil(sut.completeSourceParams);
    nameCell.contents = @"John Smith";
    [selectorDataSource selectRowWithValue:@"invalid_bank"];
    XCTAssertEqual(selectorDataSource.selectedRow, NSNotFound);
    XCTAssertNil(sut.completeSourceParams);

    // Filled form should return source params
    [selectorDataSource selectRowWithValue:@"rabobank"];
    XCTAssertNotNil(sut.completeSourceParams);
    XCTAssertEqualObjects(sut.completeSourceParams.owner[@"name"], nameCell.contents);
    NSDictionary *idealDict = sut.completeSourceParams.additionalAPIParameters[@"ideal"];
    XCTAssertEqualObjects(idealDict, @{@"bank": @"rabobank"});
}

- (void)testInitWithSourceParams_sofort {
    STPUserInformation *info = [STPUserInformation new];
    STPAddress *address = [STPAddress new];
    address.country = @"FR";
    info.billingAddress = address;
    STPSourceInfoViewController *sut = [self sutWithType:STPSourceTypeSofort
                                                    info:info];

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

    // Test initializing with a non-Sofort country
    address.country = @"US";
    info.billingAddress = address;
    sut = [self sutWithType:STPSourceTypeSofort info:info];
    XCTAssertNil(sut.completeSourceParams);
}

- (void)testRequiresUserVerification {
    STPUserInformation *info = [STPUserInformation new];
    STPAddress *address = [STPAddress new];
    address.country = @"FR";
    info.billingAddress = address;
    STPSourceInfoViewController *sut = [self sutWithType:STPSourceTypeSofort
                                                    info:info];
    XCTAssertNotNil(sut.completeSourceParams);
    sut.dataSource.requiresUserVerification = YES;
    XCTAssertNil(sut.completeSourceParams);
}

@end
