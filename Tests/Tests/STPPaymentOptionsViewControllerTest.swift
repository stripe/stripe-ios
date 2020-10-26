//
//  STPPaymentOptionsViewControllerTest.swift
//  Stripe
//
//  Created by Brian Dorfman on 10/10/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import OCMock

@testable import Stripe

@available(iOS 13.0, *)
class STPPaymentOptionsViewControllerTest: XCTestCase {
  class MockSTPPaymentOptionsViewControllerDelegate: NSObject,
    STPPaymentOptionsViewControllerDelegate
  {
    var didFail = false
    func paymentOptionsViewController(
      _ paymentOptionsViewController: STPPaymentOptionsViewController,
      didFailToLoadWithError error: Error
    ) {
      didFail = true
    }

    var didFinish = false
    func paymentOptionsViewControllerDidFinish(
      _ paymentOptionsViewController: STPPaymentOptionsViewController
    ) {
      didFinish = true
    }

    var didCancel = false
    func paymentOptionsViewControllerDidCancel(
      _ paymentOptionsViewController: STPPaymentOptionsViewController
    ) {
      didCancel = true
    }

    var didSelect = false
    func paymentOptionsViewController(
      _ paymentOptionsViewController: STPPaymentOptionsViewController,
      didSelect paymentOption: STPPaymentOption?
    ) {
      didSelect = true
    }
  }

  func buildViewController(
    with customer: STPCustomer,
    paymentMethods: [STPPaymentMethod],
    configuration config: STPPaymentConfiguration,
    delegate: STPPaymentOptionsViewControllerDelegate
  ) -> STPPaymentOptionsViewController {
    let mockCustomerContext = Testing_StaticCustomerContext(
      customer: customer, paymentMethods: paymentMethods)
    return buildViewController(with: mockCustomerContext, configuration: config, delegate: delegate)
  }

  func buildViewController(
    with customerContext: STPCustomerContext,
    configuration config: STPPaymentConfiguration,
    delegate: STPPaymentOptionsViewControllerDelegate
  ) -> STPPaymentOptionsViewController {
    let theme = STPTheme.defaultTheme
    let vc = STPPaymentOptionsViewController(
      configuration: config,
      theme: theme,
      customerContext: customerContext,
      delegate: delegate)
    let didLoadExpectation = expectation(description: "VC did load")
    vc.loadingPromise?.onSuccess({ (_) in
      didLoadExpectation.fulfill()
    })

    wait(for: [didLoadExpectation], timeout: 2)

    return vc
  }

  /// When the customer has no sources, and card is the sole available payment
  /// method, STPAddCardViewController should be shown.
  func testInitWithNoSourcesAndConfigWithUseSourcesOffAndCardAvailable() {
    let customer = STPFixtures.customerWithNoSources()!
    let config = STPFixtures.paymentConfiguration()!
    config.applePayEnabled = false
    let delegate = MockSTPPaymentOptionsViewControllerDelegate()
    let sut = buildViewController(
      with: customer,
      paymentMethods: [],
      configuration: config,
      delegate: delegate)
    XCTAssertTrue((sut.internalViewController is STPAddCardViewController))
  }

  /// When the customer has a single card token source and the available payment methods
  /// are card and apple pay, STPPaymentOptionsInternalVC should be shown.
  func testInitWithSingleCardTokenSourceAndCardAvailable() {
    let customer = STPFixtures.customerWithSingleCardTokenSource()!
    let paymentMethods = [STPFixtures.paymentMethod()!]
    let config = STPFixtures.paymentConfiguration()!
    let delegate = MockSTPPaymentOptionsViewControllerDelegate()
    let sut = buildViewController(
      with: customer,
      paymentMethods: paymentMethods.compactMap { $0 },
      configuration: config,
      delegate: delegate)
    XCTAssertTrue((sut.internalViewController is STPPaymentOptionsInternalViewController))
  }

  /// When the customer has a single card source source and the available payment methods
  /// are card only, STPPaymentOptionsInternalVC should be shown.
  func testInitWithSingleCardSourceSourceAndCardAvailable() {
    let customer = STPFixtures.customerWithSingleCardSourceSource()!
    let paymentMethods = [STPFixtures.paymentMethod()!]
    let config = STPFixtures.paymentConfiguration()!
    config.applePayEnabled = false
    let delegate = MockSTPPaymentOptionsViewControllerDelegate()
    let sut = buildViewController(
      with: customer,
      paymentMethods: paymentMethods.compactMap { $0 },
      configuration: config,
      delegate: delegate)
    XCTAssertTrue((sut.internalViewController is STPPaymentOptionsInternalViewController))
  }

  /// Tapping cancel in an internal AddCard view controller should result in a call to
  /// didCancel:
  func testAddCardCancelForwardsToDelegate() {
    let customer = STPFixtures.customerWithNoSources()!
    let config = STPFixtures.paymentConfiguration()!
    let delegate = MockSTPPaymentOptionsViewControllerDelegate()
    let sut = buildViewController(
      with: customer,
      paymentMethods: [],
      configuration: config,
      delegate: delegate)
    XCTAssertTrue((sut.internalViewController is STPAddCardViewController))
    let cancelButton = sut.internalViewController?.navigationItem.leftBarButtonItem
    cancelButton?.target?.perform(cancelButton?.action, with: cancelButton)

    XCTAssertTrue(delegate.didCancel)
  }

  /// Tapping cancel in an internal PaymentOptionsInternal view controller should
  /// result in a call to didCancel:
  func testInternalCancelForwardsToDelegate() {
    let customer = STPFixtures.customerWithSingleCardTokenSource()!
    let paymentMethods = [STPFixtures.paymentMethod()!]
    let config = STPFixtures.paymentConfiguration()!
    let delegate = MockSTPPaymentOptionsViewControllerDelegate()
    let sut = buildViewController(
      with: customer,
      paymentMethods: paymentMethods.compactMap { $0 },
      configuration: config,
      delegate: delegate)
    XCTAssertTrue((sut.internalViewController is STPPaymentOptionsInternalViewController))
    let cancelButton = sut.internalViewController?.navigationItem.leftBarButtonItem
    _ = cancelButton?.target?.perform(cancelButton?.action, with: cancelButton)

    XCTAssertTrue(delegate.didCancel)
  }

  /// When an AddCard view controller creates a card payment method, it should be attached to the
  /// customer and the correct delegate methods should be called.
  func testAddCardAttachesToCustomerAndFinishes() {
    let config = STPFixtures.paymentConfiguration()!
    let customer = STPFixtures.customerWithNoSources()!
    let mockCustomerContext = Testing_StaticCustomerContext(customer: customer, paymentMethods: [])
    let delegate = MockSTPPaymentOptionsViewControllerDelegate()
    let sut = buildViewController(
      with: mockCustomerContext, configuration: config, delegate: delegate)
    XCTAssertNotNil(sut.view)
    XCTAssertTrue((sut.internalViewController is STPAddCardViewController))

    let internalVC = sut.internalViewController as? STPAddCardViewController
    let exp = expectation(description: "completion")
    let expectedPaymentMethod = STPFixtures.paymentMethod()
    internalVC?.delegate?.addCardViewController(
      internalVC!, didCreatePaymentMethod: expectedPaymentMethod!
    ) { error in
      XCTAssertNil(error)
      exp.fulfill()
    }

    let _: ((Any?) -> Bool)? = { obj in
      let paymentMethod = obj as? STPPaymentMethod
      return paymentMethod?.stripeId == expectedPaymentMethod?.stripeId
    }
    XCTAssertTrue(mockCustomerContext.didAttach)
    XCTAssertTrue(delegate.didSelect)
    XCTAssertTrue(delegate.didFinish)
    waitForExpectations(timeout: 2, handler: nil)
  }
}
