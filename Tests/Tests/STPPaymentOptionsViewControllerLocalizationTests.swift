//
//  STPPaymentOptionsViewControllerLocalizationTests.swift
//  Stripe
//
//  Created by Brian Dorfman on 10/17/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import FBSnapshotTestCase

@testable import Stripe

class MockSTPPaymentOptionsViewControllerDelegate: NSObject, STPPaymentOptionsViewControllerDelegate
{
  func paymentOptionsViewController(
    _ paymentOptionsViewController: STPPaymentOptionsViewController,
    didFailToLoadWithError error: Error
  ) {
  }

  func paymentOptionsViewControllerDidFinish(
    _ paymentOptionsViewController: STPPaymentOptionsViewController
  ) {
  }

  func paymentOptionsViewControllerDidCancel(
    _ paymentOptionsViewController: STPPaymentOptionsViewController
  ) {
  }

}

@available(iOS 13.0, *)
class STPPaymentOptionsViewControllerLocalizationTests: FBSnapshotTestCase {
  override func setUp() {
    super.setUp()

    //        self.recordMode = true;
  }

  func performSnapshotTest(forLanguage language: String?) {
    let config = STPFixtures.paymentConfiguration()!
    config.companyName = "Test Company"
    config.requiredBillingAddressFields = .full
    let theme = STPTheme.defaultTheme
    let paymentMethods = [STPFixtures.paymentMethod()!, STPFixtures.paymentMethod()!]
    let customerContext = Testing_StaticCustomerContext.init(
      customer: STPFixtures.customerWithCardTokenAndSourceSources()!, paymentMethods: paymentMethods
    )
    let delegate = MockSTPPaymentOptionsViewControllerDelegate()
    STPLocalizationUtils.overrideLanguage(to: language)
    let paymentOptionsVC = STPPaymentOptionsViewController(
      configuration: config,
      theme: theme,
      customerContext: customerContext,
      delegate: delegate)
    let didLoadExpectation = expectation(description: "VC did load")

    paymentOptionsVC.loadingPromise?.onSuccess({ (_) in
      didLoadExpectation.fulfill()
    })
    wait(for: [didLoadExpectation].compactMap { $0 }, timeout: 2)

    let viewToTest = stp_preparedAndSizedViewForSnapshotTest(from: paymentOptionsVC)!

    FBSnapshotVerifyView(viewToTest, identifier: nil)
    STPLocalizationUtils.overrideLanguage(to: nil)
  }

  func testGerman() {
    performSnapshotTest(forLanguage: "de")
  }

  func testEnglish() {
    performSnapshotTest(forLanguage: "en")
  }

  func testSpanish() {
    performSnapshotTest(forLanguage: "es")
  }

  func testFrench() {
    performSnapshotTest(forLanguage: "fr")
  }

  func testItalian() {
    performSnapshotTest(forLanguage: "it")
  }

  func testJapanese() {
    performSnapshotTest(forLanguage: "ja")
  }

  func testDutch() {
    performSnapshotTest(forLanguage: "nl")
  }

  func testChinese() {
    performSnapshotTest(forLanguage: "zh-Hans")
  }
}
