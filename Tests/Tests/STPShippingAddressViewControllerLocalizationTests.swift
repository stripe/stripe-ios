//
//  STPShippingAddressViewControllerLocalizationTests.swift
//  Stripe
//
//  Created by Ben Guo on 11/3/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import FBSnapshotTestCase

@testable import Stripe

class STPShippingAddressViewControllerLocalizationTests: FBSnapshotTestCase {
  override func setUp() {
    super.setUp()
    //        self.recordMode = true
  }

  func performSnapshotTest(
    forLanguage language: String?, shippingType: STPShippingType, contact: Bool
  ) {
    var identifier = (shippingType == .shipping) ? "shipping" : "delivery"
    let config = STPFixtures.paymentConfiguration()
    config.companyName = "Test Company"
    config.requiredShippingAddressFields = Set<STPContactField>([
      .postalAddress,
      .emailAddress,
      .phoneNumber,
      .name,
    ])
    if contact {
      config.requiredShippingAddressFields = Set<STPContactField>([.emailAddress])
      identifier = "contact"
    }
    config.shippingType = shippingType

    STPLocalizationUtils.overrideLanguage(to: language)
    let info = STPUserInformation()
    info.billingAddress = STPAddress()
    info.billingAddress!.email = "@"  // trigger "use billing address" button

    let shippingVC = STPShippingAddressViewController(
      configuration: config,
      theme: STPTheme.defaultTheme,
      currency: nil,
      shippingAddress: nil,
      selectedShippingMethod: nil,
      prefilledInformation: info)

    /// This method rejects nil or empty country codes to stop strange looking behavior
    /// when scrolling to the top "unset" position in the picker, so put in
    /// an invalid country code instead to test seeing the "Country" placeholder
    shippingVC.addressViewModel.addressFieldTableViewCountryCode = "INVALID"

    let viewToTest = stp_preparedAndSizedViewForSnapshotTest(from: shippingVC)!

    FBSnapshotVerifyView(viewToTest, identifier: identifier)

    STPLocalizationUtils.overrideLanguage(to: nil)
  }

  func testGerman() {
    performSnapshotTest(forLanguage: "de", shippingType: .shipping, contact: false)
    performSnapshotTest(forLanguage: "de", shippingType: .shipping, contact: true)
    performSnapshotTest(forLanguage: "de", shippingType: .delivery, contact: false)
  }

  func testEnglish() {
    performSnapshotTest(forLanguage: "en", shippingType: .shipping, contact: false)
    performSnapshotTest(forLanguage: "en", shippingType: .shipping, contact: true)
    performSnapshotTest(forLanguage: "en", shippingType: .delivery, contact: false)
  }

  func testSpanish() {
    performSnapshotTest(forLanguage: "es", shippingType: .shipping, contact: false)
    performSnapshotTest(forLanguage: "es", shippingType: .shipping, contact: true)
    performSnapshotTest(forLanguage: "es", shippingType: .delivery, contact: false)
  }

  func testFrench() {
    performSnapshotTest(forLanguage: "fr", shippingType: .shipping, contact: false)
    performSnapshotTest(forLanguage: "fr", shippingType: .shipping, contact: true)
    performSnapshotTest(forLanguage: "fr", shippingType: .delivery, contact: false)
  }

  func testItalian() {
    performSnapshotTest(forLanguage: "it", shippingType: .shipping, contact: false)
    performSnapshotTest(forLanguage: "it", shippingType: .shipping, contact: true)
    performSnapshotTest(forLanguage: "it", shippingType: .delivery, contact: false)
  }

  func testJapanese() {
    performSnapshotTest(forLanguage: "ja", shippingType: .shipping, contact: false)
    performSnapshotTest(forLanguage: "ja", shippingType: .shipping, contact: true)
    performSnapshotTest(forLanguage: "ja", shippingType: .delivery, contact: false)
  }

  func testDutch() {
    performSnapshotTest(forLanguage: "nl", shippingType: .shipping, contact: false)
    performSnapshotTest(forLanguage: "nl", shippingType: .shipping, contact: true)
    performSnapshotTest(forLanguage: "nl", shippingType: .delivery, contact: false)
  }

  func testChinese() {
    performSnapshotTest(forLanguage: "zh-Hans", shippingType: .shipping, contact: false)
    performSnapshotTest(forLanguage: "zh-Hans", shippingType: .shipping, contact: true)
    performSnapshotTest(forLanguage: "zh-Hans", shippingType: .delivery, contact: false)
  }
}
