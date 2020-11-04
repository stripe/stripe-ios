//
//  STPAddCardViewControllerLocalizationTests.swift
//  Stripe
//
//  Created by Brian Dorfman on 10/17/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import FBSnapshotTestCase

@testable import Stripe

class STPAddCardViewControllerLocalizationTests: FBSnapshotTestCase {
  override func setUp() {
    super.setUp()

    //        self.recordMode = true
  }

  func performSnapshotTest(forLanguage language: String?, delivery: Bool) {
    let config = STPFixtures.paymentConfiguration()
    config.companyName = "Test Company"
    config.requiredBillingAddressFields = .full
    config.shippingType = delivery ? .delivery : .shipping
    config.cardScanningEnabled = true
    STPLocalizationUtils.overrideLanguage(to: language)

    let addCardVC = STPAddCardViewController(
      configuration: config,
      theme: STPTheme.defaultTheme)
    addCardVC.shippingAddress = STPAddress()
    addCardVC.shippingAddress?.line1 = "1"  // trigger "use shipping address" button

    let viewToTest = stp_preparedAndSizedViewForSnapshotTest(from: addCardVC)!

    if delivery {
      addCardVC.addressViewModel.addressFieldTableViewCountryCode = "INVALID"
      FBSnapshotVerifyView(viewToTest, identifier: "delivery")
    } else {
      /// This method rejects nil or empty country codes to stop strange looking behavior
      /// when scrolling to the top "unset" position in the picker, so put in
      /// an invalid country code instead to test seeing the "Country" placeholder
      addCardVC.addressViewModel.addressFieldTableViewCountryCode = "INVALID"
      FBSnapshotVerifyView(viewToTest, identifier: "no_country")

      addCardVC.addressViewModel.addressFieldTableViewCountryCode = "US"
      FBSnapshotVerifyView(viewToTest, identifier: "US")

      addCardVC.addressViewModel.addressFieldTableViewCountryCode = "GB"
      FBSnapshotVerifyView(viewToTest, identifier: "GB")

      addCardVC.addressViewModel.addressFieldTableViewCountryCode = "CA"
      FBSnapshotVerifyView(viewToTest, identifier: "CA")

      addCardVC.addressViewModel.addressFieldTableViewCountryCode = "MX"
      FBSnapshotVerifyView(viewToTest, identifier: "MX")
    }

    STPLocalizationUtils.overrideLanguage(to: nil)
  }

  func testGerman() {
    performSnapshotTest(forLanguage: "de", delivery: false)
    performSnapshotTest(forLanguage: "de", delivery: true)
  }

  func testEnglish() {
    performSnapshotTest(forLanguage: "en", delivery: false)
    performSnapshotTest(forLanguage: "en", delivery: true)
  }

  func testSpanish() {
    performSnapshotTest(forLanguage: "es", delivery: false)
    performSnapshotTest(forLanguage: "es", delivery: true)
  }

  func testFrench() {
    performSnapshotTest(forLanguage: "fr", delivery: false)
    performSnapshotTest(forLanguage: "fr", delivery: true)
  }

  func testItalian() {
    performSnapshotTest(forLanguage: "it", delivery: false)
    performSnapshotTest(forLanguage: "it", delivery: true)
  }

  func testJapanese() {
    performSnapshotTest(forLanguage: "ja", delivery: false)
    performSnapshotTest(forLanguage: "ja", delivery: true)
  }

  func testDutch() {
    performSnapshotTest(forLanguage: "nl", delivery: false)
    performSnapshotTest(forLanguage: "nl", delivery: true)
  }

  func testChinese() {
    performSnapshotTest(forLanguage: "zh-Hans", delivery: false)
    performSnapshotTest(forLanguage: "zh-Hans", delivery: true)
  }
}
