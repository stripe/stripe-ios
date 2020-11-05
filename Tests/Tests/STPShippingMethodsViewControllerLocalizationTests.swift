//
//  STPShippingMethodsViewControllerLocalizationTests.swift
//  Stripe
//
//  Created by Ben Guo on 11/3/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import FBSnapshotTestCase

@testable import Stripe

class STPShippingMethodsViewControllerLocalizationTests: FBSnapshotTestCase {

  override func setUp() {
    super.setUp()
    //        self.recordMode = true
  }

  func performSnapshotTest(forLanguage language: String?) {
    STPLocalizationUtils.overrideLanguage(to: language)

    let method1 = PKShippingMethod()
    method1.label = "UPS Ground"
    method1.detail = "Arrives in 3-5 days"
    method1.amount = NSDecimalNumber(string: "0.00")
    method1.identifier = "ups_ground"
    let method2 = PKShippingMethod()
    method2.label = "FedEx"
    method2.detail = "Arrives tomorrow"
    method2.amount = NSDecimalNumber(string: "5.99")
    method2.identifier = "fedex"

    let shippingVC = STPShippingMethodsViewController(
      shippingMethods: [method1, method2], selectedShippingMethod: method1, currency: "usd",
      theme: STPTheme.defaultTheme)
    let viewToTest = stp_preparedAndSizedViewForSnapshotTest(from: shippingVC)!
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
