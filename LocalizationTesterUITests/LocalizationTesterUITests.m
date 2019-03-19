//
//  LocalizationTesterUITests.m
//  LocalizationTesterUITests
//
//  Created by Cameron Sabol on 12/11/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface LocalizationTesterUITests : XCTestCase

@end

@implementation LocalizationTesterUITests

- (void)setUp {
    [super setUp];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    // In UI tests it is usually best to stop immediately when a failure occurs.
    self.continueAfterFailure = NO;
    // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
    [[[XCUIApplication alloc] init] launch];
    
    // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testVisitAll {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    XCUIElementQuery *tablesQuery = app.tables;

#pragma mark - Visit Payment Text Field
    [tablesQuery.staticTexts[@"Payment Card Text Field"] tap];
    [self _waitForElementToAppear:app.navigationBars.buttons[@"CardFieldViewControllerDoneButtonIdentifier"]];
    [self _takeScreenShotNamed:@"Payment Card Text Field"];

    [app.navigationBars.buttons[@"CardFieldViewControllerDoneButtonIdentifier"] tap];

#pragma mark - Visit Add Card VC (default)
    [tablesQuery.staticTexts[@"Add Card VC Standard"] tap];
    [self _waitForElementToAppear:app.navigationBars.buttons[@"AddCardViewControllerNavBarCancelButtonIdentifier"]];
    [self _takeScreenShotNamed:@"Add Card VC Standard"];

    [app.buttons[@"AddCardViewControllerNavBarDoneButtonIdentifier"] tap];
    XCUIElement *errorAlert = [app.alerts elementBoundByIndex:0];
    [self _waitForElementToAppear:errorAlert];
    [self _takeScreenShotNamed:@"Add Card VC Alert" suppressAutoScroll:YES];
    [[errorAlert.buttons elementBoundByIndex:0] tap]; // dismiss alert
    [app.navigationBars.buttons[@"AddCardViewControllerNavBarCancelButtonIdentifier"] tap]; // back

#pragma mark - Visit Add Card VC (prefilled shipping)
    [tablesQuery.staticTexts[@"Add Card VC Prefilled Shipping"] tap];
    [self _waitForElementToAppear:app.navigationBars.buttons[@"AddCardViewControllerNavBarCancelButtonIdentifier"]];
    [self _takeScreenShotNamed:@"Add Card VC Prefilled Shipping"];
    [app.navigationBars.buttons[@"AddCardViewControllerNavBarCancelButtonIdentifier"] tap]; // back

#pragma mark - Visit Add Card VC (prefilled delivery)
    [tablesQuery.staticTexts[@"Add Card VC Prefilled Delivery"] tap];
    [self _waitForElementToAppear:app.navigationBars.buttons[@"AddCardViewControllerNavBarCancelButtonIdentifier"]];
    [self _takeScreenShotNamed:@"Add Card VC Prefilled Delivery"];
    [app.navigationBars.buttons[@"AddCardViewControllerNavBarCancelButtonIdentifier"] tap]; // back

#pragma mark - Visit Payment Options VC
    [tablesQuery.staticTexts[@"Payment Options VC"] tap];
    [self _waitForElementToAppear:tablesQuery.cells[@"PaymentOptionsTableViewAddNewCardButtonIdentifier"]];
    [self _takeScreenShotNamed:@"Payment Options VC"];
    [app.buttons[@"PaymentOptionsViewControllerCancelButtonIdentifier"] tap]; // back

#pragma mark - Visit Payment Options VC (loading)
    [tablesQuery.staticTexts[@"Payment Options VC Loading"] tap];
    [self _waitForElementToAppear:app.buttons[@"CoreViewControllerCancelIdentifier"]];
    [self _takeScreenShotNamed:@"Payment Options VC Loading"];
    [app.buttons[@"CoreViewControllerCancelIdentifier"] tap]; // back

#pragma mark - Visit the Shipping Address VC
    [tablesQuery.staticTexts[@"Shipping Address VC"] tap];
    [self _waitForElementToAppear:app.navigationBars.buttons[@"ShippingViewControllerNextButtonIdentifier"]];
    [self _takeScreenShotNamed:@"Shipping Address VC"];

    // Fill out the shipping Info
    [tablesQuery.buttons[@"ShippingAddressViewControllerUseBillingButton"] tap];

    // Go to Shipping Methods
    [app.navigationBars.buttons[@"ShippingViewControllerNextButtonIdentifier"] tap];
    [self _waitForElementToAppear:app.navigationBars.buttons[@"ShippingMethodsViewControllerDoneButtonIdentifier"]];
    [self _takeScreenShotNamed:@"Shipping Methods VC"];

    // Back to main menu
    [app.navigationBars.buttons[@"ShippingMethodsViewControllerDoneButtonIdentifier"] tap];

#pragma mark - Visit the Shipping Address VC Bad Address
    [tablesQuery.staticTexts[@"Shipping Address VC Bad Address"] tap];
    [self _waitForElementToAppear:app.navigationBars.buttons[@"ShippingViewControllerNextButtonIdentifier"]];

    // Fill out the shipping Info
    [tablesQuery.buttons[@"ShippingAddressViewControllerUseBillingButton"] tap];

    // Try to go to Shipping Methods
    [app.navigationBars.buttons[@"ShippingViewControllerNextButtonIdentifier"] tap];

    errorAlert = [app.alerts elementBoundByIndex:0];
    [self _waitForElementToAppear:errorAlert];
    [self _takeScreenShotNamed:@"Shipping Address VC Bad Address Alert" suppressAutoScroll:YES];
    [[errorAlert.buttons elementBoundByIndex:0] tap]; // dismiss alert
    [app.navigationBars.buttons[@"CoreViewControllerCancelIdentifier"] tap];

#pragma mark - Visit the Shipping Info VC for Delivery
    [tablesQuery.staticTexts[@"Shipping Address VC for Delivery"] tap];
    [self _waitForElementToAppear:app.navigationBars.buttons[@"ShippingViewControllerNextButtonIdentifier"]];
    [self _takeScreenShotNamed:@"Shipping Address VC for Delivery"];

    // Back to main menu
    [app.navigationBars.buttons[@"CoreViewControllerCancelIdentifier"] tap];

#pragma mark - Visit the Shipping Info VC for Delivery
    [tablesQuery.staticTexts[@"Shipping Address VC for Contact"] tap];
    [self _waitForElementToAppear:app.navigationBars.buttons[@"ShippingViewControllerNextButtonIdentifier"]];
    [self _takeScreenShotNamed:@"Shipping Address VC for Contact"];

    // Back to main menu
    [app.navigationBars.buttons[@"CoreViewControllerCancelIdentifier"] tap];
}

#pragma mark - Helpers

- (void)_takeScreenShotNamed:(NSString *)name {
    [self _takeScreenShotNamed:name suppressAutoScroll:NO];
}

- (void)_takeScreenShotNamed:(NSString *)name suppressAutoScroll:(BOOL)suppressAutoScroll {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    XCUIElement *table = [app.tables elementBoundByIndex:0];
    XCUIElement *lastCell = [table.cells elementBoundByIndex:table.cells.count - 1];
    NSInteger viewPortScreen = 0;

    do {
        XCUIScreenshot *screenshot = [app.windows.firstMatch screenshot];
        XCTAttachment *attachment = [XCTAttachment attachmentWithScreenshot:screenshot];
        attachment.lifetime = XCTAttachmentLifetimeKeepAlways;
        attachment.name = viewPortScreen > 0 ? [NSString stringWithFormat:@"%@-%ld", name, (long)viewPortScreen] : name;
        [self addAttachment:attachment];

        viewPortScreen += 1;
        if (!suppressAutoScroll &&
            lastCell.exists && !CGRectIsEmpty(lastCell.frame) && !CGRectContainsRect(app.windows.firstMatch.frame, lastCell.frame)) {
            [app swipeUp];
        } else {
            break;
        }
    } while (lastCell.exists && viewPortScreen < 4); // viewPortScreen < 4 as sanity check to avoid infinite loop
}

- (void)_waitForElementToAppear:(XCUIElement *)element {
    XCTAssert([element waitForExistenceWithTimeout:5], "An exepected element did not appear on screen: %@", element);
}

@end
