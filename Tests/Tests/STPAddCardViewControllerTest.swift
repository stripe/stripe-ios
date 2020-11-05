//
//  STPAddCardViewControllerTest.swift
//  Stripe
//
//  Created by Ben Guo on 7/5/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

@testable import Stripe

class MockAPIClient: STPAPIClient {
  override init() {
    super.init()
  }

  var createPaymentMethodBlock: (STPPaymentMethodParams, STPPaymentMethodCompletionBlock) -> Void =
    { _, _ in }
  override func createPaymentMethod(
    with paymentMethodParams: STPPaymentMethodParams,
    completion: @escaping STPPaymentMethodCompletionBlock
  ) {
    createPaymentMethodBlock(paymentMethodParams, completion)
  }
}

class MockDelegate: NSObject, STPAddCardViewControllerDelegate {
  func addCardViewControllerDidCancel(_ addCardViewController: STPAddCardViewController) {

  }

  var addCardViewControllerDidCreatePaymentMethodBlock:
    (STPAddCardViewController, STPPaymentMethod, STPErrorBlock) -> Void = { _, _, _ in }
  func addCardViewController(
    _ addCardViewController: STPAddCardViewController,
    didCreatePaymentMethod paymentMethod: STPPaymentMethod, completion: @escaping STPErrorBlock
  ) {
    addCardViewControllerDidCreatePaymentMethodBlock(
      addCardViewController, paymentMethod, completion)
  }
}

class STPAddCardViewControllerTest: XCTestCase {
  func buildAddCardViewController() -> STPAddCardViewController? {
    let config = STPFixtures.paymentConfiguration()
    let theme = STPTheme.defaultTheme
    let vc = STPAddCardViewController(
      configuration: config,
      theme: theme)
    XCTAssertNotNil(vc.view)
    return vc
  }

  func testPrefilledBillingAddress_removeAddress() {
    let config = STPFixtures.paymentConfiguration()
    config.requiredBillingAddressFields = .postalCode
    let sut = STPAddCardViewController(
      configuration: config,
      theme: STPTheme.defaultTheme)
    let address = STPAddress()
    address.name = "John Smith Doe"
    address.phone = "8885551212"
    address.email = "foo@example.com"
    address.line1 = "55 John St"
    address.city = "Harare"
    address.postalCode = "10002"
    address.country = "ZW"  // Zimbabwe does not require zip codes, while the default locale for tests (US) does
    // Sanity checks
    XCTAssertFalse(STPPostalCodeValidator.postalCodeIsRequired(forCountryCode: "ZW"))
    XCTAssertTrue(STPPostalCodeValidator.postalCodeIsRequired(forCountryCode: "US"))

    let prefilledInfo = STPUserInformation()
    prefilledInfo.billingAddress = address
    sut.prefilledInformation = prefilledInfo

    XCTAssertNoThrow(sut.loadView())
    XCTAssertNoThrow(sut.viewDidLoad())
  }

  func testPrefilledBillingAddress_addAddress() {
    NSLocale.stp_setCurrentLocale(NSLocale(localeIdentifier: "en_ZW") as Locale)  // Zimbabwe does not require zip codes, while the default locale for tests (US) does
    // Sanity checks
    XCTAssertFalse(STPPostalCodeValidator.postalCodeIsRequired(forCountryCode: "ZW"))
    XCTAssertTrue(STPPostalCodeValidator.postalCodeIsRequired(forCountryCode: "US"))
    let config = STPFixtures.paymentConfiguration()
    config.requiredBillingAddressFields = .postalCode
    let sut = STPAddCardViewController(
      configuration: config,
      theme: STPTheme.defaultTheme)
    let address = STPAddress()
    address.name = "John Smith Doe"
    address.phone = "8885551212"
    address.email = "foo@example.com"
    address.line1 = "55 John St"
    address.city = "New York"
    address.state = "NY"
    address.postalCode = "10002"
    address.country = "US"

    let prefilledInfo = STPUserInformation()
    prefilledInfo.billingAddress = address
    sut.prefilledInformation = prefilledInfo

    XCTAssertNoThrow(sut.loadView())
    XCTAssertNoThrow(sut.viewDidLoad())
    NSLocale.stp_resetCurrentLocale()
  }

  //#pragma clang diagnostic push
  //#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  func testNextWithCreatePaymentMethodError() {
    let sut = buildAddCardViewController()!
    let expectedCardParams = STPFixtures.paymentMethodCardParams()
    sut.paymentCell?.paymentField!.cardParams = expectedCardParams

    let exp = expectation(description: "createPaymentMethodWithCard")

    let mockAPIClient = MockAPIClient()
    mockAPIClient.createPaymentMethodBlock = { (paymentMethodParams, completion) in
      XCTAssertEqual(paymentMethodParams.card!.number, expectedCardParams.number)
      XCTAssertTrue(sut.loading)
      let error = NSError.stp_genericFailedToParseResponseError()
      completion(nil, error)
      XCTAssertFalse(sut.loading)
      exp.fulfill()
    }
    sut.apiClient = mockAPIClient

    // tap next button
    let nextButton = sut.navigationItem.rightBarButtonItem
    _ = nextButton?.target?.perform(nextButton?.action, with: nextButton)

    waitForExpectations(timeout: 2, handler: nil)
  }

  func testNextWithCreatePaymentMethodSuccessAndDidCreatePaymentMethodError() {
    let sut = buildAddCardViewController()!

    let mockAPIClient = MockAPIClient()
    let mockDelegate = MockDelegate()
    sut.apiClient = mockAPIClient
    sut.delegate = mockDelegate
    let expectedCardParams = STPFixtures.paymentMethodCardParams()
    sut.paymentCell?.paymentField!.cardParams = expectedCardParams

    let expectedPaymentMethod = STPFixtures.paymentMethod()
    let createPaymentMethodExp = expectation(description: "createPaymentMethodWithCard")
    mockAPIClient.createPaymentMethodBlock = { (paymentMethodParams, completion) in
      XCTAssertEqual(paymentMethodParams.card?.number, expectedCardParams.number)
      XCTAssertTrue(sut.loading)
      completion(expectedPaymentMethod, nil)
      createPaymentMethodExp.fulfill()
    }

    let didCreatePaymentMethodExp = expectation(description: "didCreatePaymentMethod")

    mockDelegate.addCardViewControllerDidCreatePaymentMethodBlock = {
      (addCardViewController, paymentMethod, completion) in
      XCTAssertTrue(sut.loading)
      let error = NSError.stp_genericFailedToParseResponseError()
      XCTAssertEqual(paymentMethod.stripeId, expectedPaymentMethod.stripeId)
      completion(error)
      XCTAssertFalse(sut.loading)
      didCreatePaymentMethodExp.fulfill()
    }

    // tap next button
    let nextButton = sut.navigationItem.rightBarButtonItem
    _ = nextButton?.target?.perform(nextButton?.action, with: nextButton)

    waitForExpectations(timeout: 2, handler: nil)
  }

  func testNextWithCreateTokenSuccessAndDidCreateTokenSuccess() {
    let sut = buildAddCardViewController()!

    let mockAPIClient = MockAPIClient()
    let mockDelegate = MockDelegate()
    sut.apiClient = mockAPIClient
    sut.delegate = mockDelegate
    let expectedCardParams = STPFixtures.paymentMethodCardParams()
    sut.paymentCell?.paymentField!.cardParams = expectedCardParams

    let expectedPaymentMethod = STPFixtures.paymentMethod()
    let createPaymentMethodExp = expectation(description: "createPaymentMethodWithCard")
    mockAPIClient.createPaymentMethodBlock = { (paymentMethodParams, completion) in
      XCTAssertEqual(paymentMethodParams.card!.number, expectedCardParams.number)
      XCTAssertTrue(sut.loading)
      completion(expectedPaymentMethod, nil)
      createPaymentMethodExp.fulfill()
    }

    let didCreatePaymentMethodExp = expectation(description: "didCreatePaymentMethod")
    mockDelegate.addCardViewControllerDidCreatePaymentMethodBlock = {
      (addCardViewController, paymentMethod, completion) in
      XCTAssertTrue(sut.loading)
      XCTAssertEqual(paymentMethod.stripeId, expectedPaymentMethod.stripeId)
      completion(nil)
      XCTAssertFalse(sut.loading)
      didCreatePaymentMethodExp.fulfill()
    }

    // tap next button
    let nextButton = sut.navigationItem.rightBarButtonItem
    _ = nextButton?.target?.perform(nextButton?.action, with: nextButton)

    waitForExpectations(timeout: 2, handler: nil)
  }
}
