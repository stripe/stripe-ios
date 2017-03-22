//
//  STPSourceInfoViewControllerTest.m
//  Stripe
//
//  Created by Ben Guo on 2/13/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "STPSourceInfoViewController.h"
#import "STPSourceInfoDataSource.h"
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
    STPPaymentConfiguration *config = [STPPaymentConfiguration sharedConfiguration];
    // TODO: set returnURL and verify in tests
    NSInteger amount = 100;
    STPSourceInfoViewController *sut = [[STPSourceInfoViewController alloc] initWithSourceType:type
                                                                                        amount:amount
                                                                                 configuration:config
                                                                          prefilledInformation:info
                                                                                         theme:theme];
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

    XCTAssertEqual(sut.dataSource.cells.count, 1U);
    STPTextFieldTableViewCell *nameCell = [sut.dataSource.cells firstObject];
    XCTAssertEqualObjects(nameCell.contents, @"Jenny Rosen");

    nameCell.contents = @"";
    XCTAssertNil(sut.completeSourceParams);

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

    XCTAssertEqual(sut.dataSource.cells.count, 1U);
    STPTextFieldTableViewCell *nameCell = [sut.dataSource.cells firstObject];
    XCTAssertEqualObjects(nameCell.contents, @"Jenny Rosen");

    nameCell.contents = @"";
    XCTAssertNil(sut.completeSourceParams);

    nameCell.contents = @"John Smith";
    XCTAssertNotNil(sut.completeSourceParams);
    XCTAssertEqualObjects(sut.completeSourceParams.owner[@"name"], nameCell.contents);
}

- (void)testInitWithSourceParams_iDEAL {
    STPUserInformation *info = [STPUserInformation new];
    // TODO: test setting idealBank in STPUserInformation
    STPAddress *address = [STPAddress new];
    address.name = @"Jenny Rosen";
    info.billingAddress = address;
    STPSourceInfoViewController *sut = [self sutWithType:STPSourceTypeIDEAL
                                                    info:info];

    XCTAssertEqual(sut.dataSource.cells.count, 2U);
    STPTextFieldTableViewCell *nameCell = [sut.dataSource.cells firstObject];
    XCTAssertEqualObjects(nameCell.contents, @"Jenny Rosen");
    STPTextFieldTableViewCell *bankCell = [sut.dataSource.cells lastObject];
//    XCTAssertEqualObjects(bankCell.contents, @"bunq");

    nameCell.contents = @"";
    bankCell.contents = @"";
    XCTAssertNil(sut.completeSourceParams);

    nameCell.contents = @"John Smith";
    bankCell.contents = @"rabobank";
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

    XCTAssertEqual(sut.dataSource.cells.count, 1U);
    STPTextFieldTableViewCell *countryCell = [sut.dataSource.cells firstObject];
    XCTAssertEqualObjects(countryCell.contents, @"FR");

    countryCell.contents = @"";
    XCTAssertNil(sut.completeSourceParams);

    countryCell.contents = @"AT";
    XCTAssertNotNil(sut.completeSourceParams);
    NSDictionary *sofortDict = sut.completeSourceParams.additionalAPIParameters[@"sofort"];
    XCTAssertEqualObjects(sofortDict, @{@"country": @"AT"});
}

@end
