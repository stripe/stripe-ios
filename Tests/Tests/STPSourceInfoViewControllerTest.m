//
//  STPSourceInfoViewControllerTest.m
//  Stripe
//
//  Created by Ben Guo on 2/13/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "STPSourceInfoViewController.h"
#import "STPTextFieldTableViewCell.h"

@interface STPSourceInfoViewController ()
@property(nonatomic)NSArray<STPTextFieldTableViewCell *>*cells;
- (STPSourceParams *)completedSourceParams;
@end

@interface STPSourceInfoViewControllerTest : XCTestCase

@end

@implementation STPSourceInfoViewControllerTest

- (STPSourceInfoViewController *)sutWithParams:(STPSourceParams *)params {
    STPTheme *theme = [STPTheme defaultTheme];
    STPSourceInfoViewController *sut = [[STPSourceInfoViewController alloc] initWithSourceParams:params theme:theme];
    UINavigationController *navController = [UINavigationController new];
    navController.view.frame = CGRectMake(0, 0, 320, 750);
    [navController pushViewController:sut animated:NO];
    [navController.view layoutIfNeeded];
    return sut;
}

- (void)testInitWithSourceParams_unsupportedType {
    STPSourceParams *params = [STPSourceParams new];
    params.type = @"bitcoin";

    STPSourceInfoViewController *sut = [self sutWithParams:params];
    XCTAssertNil(sut);
}

- (void)testInitWithSourceParams_bancontact {
    STPSourceParams *params = [STPSourceParams new];
    params.type = @"bancontact";
    params.owner = @{@"name": @"Jenny Rosen"};

    STPSourceInfoViewController *sut = [self sutWithParams:params];
    XCTAssertEqual(sut.cells.count, 1U);
    STPTextFieldTableViewCell *nameCell = [sut.cells firstObject];
    XCTAssertEqualObjects(nameCell.contents, @"Jenny Rosen");

    nameCell.contents = @"John Smith";
    STPSourceParams *completedParams = [sut completedSourceParams];
    XCTAssertEqualObjects(completedParams.owner[@"name"], nameCell.contents);
}

- (void)testInitWithSourceParams_giropay {
    STPSourceParams *params = [STPSourceParams new];
    params.type = @"giropay";
    params.owner = @{@"name": @"Jenny Rosen"};

    STPSourceInfoViewController *sut = [self sutWithParams:params];
    XCTAssertEqual(sut.cells.count, 1U);
    STPTextFieldTableViewCell *nameCell = [sut.cells firstObject];
    XCTAssertEqualObjects(nameCell.contents, @"Jenny Rosen");

    nameCell.contents = @"John Smith";
    STPSourceParams *completedParams = [sut completedSourceParams];
    XCTAssertEqualObjects(completedParams.owner[@"name"], nameCell.contents);
}

- (void)testInitWithSourceParams_iDEAL {
    STPSourceParams *params = [STPSourceParams new];
    params.type = @"ideal";
    params.owner = @{@"name": @"Jenny Rosen"};
    params.additionalAPIParameters = @{@"ideal": @{@"bank": @"bunq"}};

    STPSourceInfoViewController *sut = [self sutWithParams:params];
    XCTAssertEqual(sut.cells.count, 2U);
    STPTextFieldTableViewCell *nameCell = [sut.cells firstObject];
    XCTAssertEqualObjects(nameCell.contents, @"Jenny Rosen");
    STPTextFieldTableViewCell *bankCell = [sut.cells lastObject];
    XCTAssertEqualObjects(bankCell.contents, @"bunq");

    nameCell.contents = @"John Smith";
    bankCell.contents = @"rabobank";
    STPSourceParams *completedParams = [sut completedSourceParams];
    XCTAssertEqualObjects(completedParams.owner[@"name"], nameCell.contents);
    NSDictionary *idealDict = completedParams.additionalAPIParameters[@"ideal"];
    XCTAssertEqualObjects(idealDict, @{@"bank": @"rabobank"});
}

- (void)testInitWithSourceParams_sofort {
    STPSourceParams *params = [STPSourceParams new];
    params.type = @"sofort";
    params.additionalAPIParameters = @{@"sofort": @{@"country": @"FR"}};

    STPSourceInfoViewController *sut = [self sutWithParams:params];
    XCTAssertEqual(sut.cells.count, 1U);
    STPTextFieldTableViewCell *countryCell = [sut.cells firstObject];
    XCTAssertEqualObjects(countryCell.contents, @"FR");

    countryCell.contents = @"AT";
    STPSourceParams *completedParams = [sut completedSourceParams];
    NSDictionary *sofortDict = completedParams.additionalAPIParameters[@"sofort"];
    XCTAssertEqualObjects(sofortDict, @{@"country": @"AT"});
}

@end
