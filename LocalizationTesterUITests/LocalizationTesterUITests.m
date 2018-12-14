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

    // Visit Payment Text Field
    [tablesQuery.staticTexts[@"Payment Card Text Field"] tap];
    [self _waitForElementToAppear:app.navigationBars.buttons[@"CardFieldViewControllerDoneButtonIdentifier"]];
    [self _takeScreenShotNamed:@"Payment Card Text Field"];

    [app.navigationBars.buttons[@"CardFieldViewControllerDoneButtonIdentifier"] tap];

    // Visit Add Card VC (default)
    [tablesQuery.staticTexts[@"Add Card VC Standard"] tap];
    [self _waitForElementToAppear:app.navigationBars.buttons[@"AddCardViewControllerNavBarCancelButtonIdentifier"]];
    [self _takeScreenShotNamed:@"Add Card VC Standard"];

    [app.buttons[@"AddCardViewControllerNavBarDoneButtonIdentifier"] tap];
    XCUIElement *errorAlert = [app.alerts elementBoundByIndex:0];
    [self _waitForElementToAppear:errorAlert];
    [self _takeScreenShotNamed:@"Add Card VC Alert"];
    [[errorAlert.buttons elementBoundByIndex:0] tap]; // dismiss alert
    [app.navigationBars.buttons[@"AddCardViewControllerNavBarCancelButtonIdentifier"] tap]; // back

    // Visit Add Card VC (prefilled shipping)
    [tablesQuery.staticTexts[@"Add Card VC Prefilled Shipping"] tap];
    [self _waitForElementToAppear:app.navigationBars.buttons[@"AddCardViewControllerNavBarCancelButtonIdentifier"]];
    [self _takeScreenShotNamed:@"Add Card VC Prefilled Shipping"];
    [app.navigationBars.buttons[@"AddCardViewControllerNavBarCancelButtonIdentifier"] tap]; // back

    // Visit Add Card VC (prefilled delivery)
    [tablesQuery.staticTexts[@"Add Card VC Prefilled Delivery"] tap];
    [self _waitForElementToAppear:app.navigationBars.buttons[@"AddCardViewControllerNavBarCancelButtonIdentifier"]];
    [self _takeScreenShotNamed:@"Add Card VC Prefilled Delivery"];
    [app.navigationBars.buttons[@"AddCardViewControllerNavBarCancelButtonIdentifier"] tap]; // back

    // Visit Payment Method VC
    [tablesQuery.staticTexts[@"Payment Methods VC"] tap];
    [self _waitForElementToAppear:tablesQuery.cells[@"PaymentMethodTableViewAddNewCardButtonIdentifier"]];
    [self _takeScreenShotNamed:@"Payment Methods VC"];
    [app.buttons[@"PaymentMethodViewControllerCancelButtonIdentifier"] tap]; // back

    // Visit Payment Method VC (loading)
    [tablesQuery.staticTexts[@"Payment Methods VC Loading"] tap];
    [self _takeScreenShotNamed:@"Payment Methods VC Loading"];
    [app.buttons[@"PaymentMethodViewControllerCancelButtonIdentifier"] tap]; // back


//    // Visit Card Form VC
//    tablesQuery.staticTexts["Card Form with Billing Address"].tap()
//
//    waitForElementToAppear(app.buttons["AddCardViewControllerNavBarCancelButtonIdentifier"])
//    takeScreenshot(name: "Card Form with Billing Address")
//    // TODO : Looks like we'll need new code to preset address and change type to delivery
//    // TODO : Fill with invalid info, press next. Wait for error to pop up. screenshot
//    app.buttons["AddCardViewControllerNavBarCancelButtonIdentifier"].tap()
//
//    // Visit Payment Method VC
//    tablesQuery.staticTexts["Payment Method Picker"].tap()
//    // TODO: Add code for long loading...
//    waitForElementToAppear(tablesQuery.cells["PaymentMethodTableViewAddNewCardButtonIdentifier"])
//    takeScreenshot(name: "Payment Method Picker")
//
//    // Add a new card in the Payment Method VC
//    tablesQuery.cells["PaymentMethodTableViewAddNewCardButtonIdentifier"].tap()
//    waitForElementToAppear(app.buttons["AddCardViewControllerNavBarCancelButtonIdentifier"])
//    takeScreenshot(name: "Payment Method Picker - Add Card")
//
//    app.buttons["AddCardViewControllerNavBarCancelButtonIdentifier"].tap()
//    app.buttons["PaymentMethodViewControllerCancelButtonIdentifier"].tap()
//
//    // Visit the Shipping Info VC
//    tablesQuery.staticTexts["Shipping Info Form"].tap()
//    waitForElementToAppear(app.navigationBars.buttons["ShippingViewControllerNextButtonIdentifier"])
//    takeScreenshot(name: "Shipping Info")
//
//    // Fill out the Shipping Info
//    tablesQuery.textFields["ShippingAddressFieldTypeNameIdentifier"].typeText("Test")
//
//    tablesQuery.textFields["ShippingAddressFieldTypeLine1Identifier"].tap()
//    tablesQuery.textFields["ShippingAddressFieldTypeLine1Identifier"].typeText("Test")
//
//    tablesQuery.textFields["ShippingAddressFieldTypeLine2Identifier"].tap()
//    tablesQuery.textFields["ShippingAddressFieldTypeLine2Identifier"].typeText("Test")
//
//    tablesQuery.textFields["ShippingAddressFieldTypeZipIdentifier"].tap()
//    tablesQuery.textFields["ShippingAddressFieldTypeZipIdentifier"].typeText("1001")
//
//    tablesQuery.textFields["ShippingAddressFieldTypeCityIdentifier"].tap()
//    tablesQuery.textFields["ShippingAddressFieldTypeCityIdentifier"].typeText("Kabul")
//
//    tablesQuery.textFields["ShippingAddressFieldTypeStateIdentifier"].tap()
//    tablesQuery.textFields["ShippingAddressFieldTypeStateIdentifier"].typeText("Kabul")
//
//    tablesQuery.textFields["ShippingAddressFieldTypeCountryIdentifier"].tap()
//    app.pickerWheels.element.adjust(toPickerWheelValue: "Afghanistan")
//
//    // Go to Shipping Methods
//    app.navigationBars.buttons["ShippingViewControllerNextButtonIdentifier"].tap()
//    waitForElementToAppear(app.navigationBars.buttons["ShippingMethodsViewControllerDoneButtonIdentifier"])
//    takeScreenshot(name: "Shipping Methods")
//
//    // Back to main menu
//    app.navigationBars.buttons["ShippingMethodsViewControllerDoneButtonIdentifier"].tap()
}

#pragma mark - Helpers

- (void)_takeScreenShotNamed:(NSString *)name {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    XCUIScreenshot *screenshot = [app.windows.firstMatch screenshot];
    XCTAttachment *attachment = [XCTAttachment attachmentWithScreenshot:screenshot];
    attachment.lifetime = XCTAttachmentLifetimeKeepAlways;
    attachment.name = name;
    [self addAttachment:attachment];
}

- (void)_waitForElementToAppear:(XCUIElement *)element {
    XCTAssert([element waitForExistenceWithTimeout:5], "An exepected element did not appear on screen: \(element)");
}

@end
