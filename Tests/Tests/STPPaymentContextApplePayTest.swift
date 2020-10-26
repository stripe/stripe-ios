//
//  STPPaymentContextApplePayTest.swift
//  Stripe
//
//  Created by Brian Dorfman on 8/1/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

@testable import Stripe

/// These tests cover STPPaymentContext's Apple Pay specific behavior:
/// - building a PKPaymentRequest
/// - determining paymentSummaryItems
class STPPaymentContextApplePayTest: XCTestCase {
  func buildPaymentContext() -> STPPaymentContext? {
    let config = STPFixtures.paymentConfiguration()
    config?.appleMerchantIdentifier = "fake_merchant_id"
    let theme = STPTheme.defaultTheme
    let customerContext = Testing_StaticCustomerContext()
    let paymentContext = STPPaymentContext(
      customerContext: customerContext,
      configuration: config!,
      theme: theme)
    return paymentContext
  }

  // MARK: - buildPaymentRequest
  func testBuildPaymentRequest_totalAmount() {
    let context = buildPaymentContext()
    context?.paymentAmount = 150
    let request = context?.buildPaymentRequest()

    XCTAssertTrue(
      (request?.paymentSummaryItems.last?.amount == NSDecimalNumber(string: "1.50")),
      "PKPayment total is not equal to STPPaymentContext amount")
  }

  func testBuildPaymentRequest_USDDefault() {
    let context = buildPaymentContext()
    context?.paymentAmount = 100
    let request = context?.buildPaymentRequest()

    XCTAssertTrue(
      (request?.currencyCode == "USD"),
      "Default PKPaymentRequest currency code is not USD")
  }

  func testBuildPaymentRequest_currency() {
    let context = buildPaymentContext()
    context?.paymentAmount = 100
    context?.paymentCurrency = "GBP"
    let request = context?.buildPaymentRequest()

    XCTAssertTrue(
      (request?.currencyCode == "GBP"),
      "PKPaymentRequest currency code is not equal to STPPaymentContext currency")
  }

  func testBuildPaymentRequest_uppercaseCurrency() {
    let context = buildPaymentContext()
    context?.paymentAmount = 100
    context?.paymentCurrency = "eur"
    let request = context?.buildPaymentRequest()

    XCTAssertTrue(
      (request?.currencyCode == "EUR"),
      "PKPaymentRequest currency code is not uppercased")
  }

  func testSummaryItems() -> [PKPaymentSummaryItem]? {
    return [
      PKPaymentSummaryItem(
        label: "First item",
        amount: NSDecimalNumber(mantissa: 20, exponent: 0, isNegative: false)),
      PKPaymentSummaryItem(
        label: "Second item",
        amount: NSDecimalNumber(mantissa: 90, exponent: 0, isNegative: false)),
      PKPaymentSummaryItem(
        label: "Discount",
        amount: NSDecimalNumber(mantissa: 10, exponent: 0, isNegative: true)),
      PKPaymentSummaryItem(
        label: "Total",
        amount: NSDecimalNumber(mantissa: 100, exponent: 0, isNegative: false)),
    ]
  }

  func testBuildPaymentRequest_summaryItems() {
    let context = buildPaymentContext()
    context?.paymentSummaryItems = testSummaryItems()
    let request = context?.buildPaymentRequest()

    XCTAssertTrue((request?.paymentSummaryItems == context?.paymentSummaryItems))
  }

  // MARK: - paymentSummaryItems
  func testSetPaymentAmount_generateSummaryItems() {
    let context = buildPaymentContext()
    context?.paymentAmount = 10000
    context?.paymentCurrency = "USD"
    let itemTotalAmount = context?.paymentSummaryItems?.last?.amount
    let correctTotalAmount = NSDecimalNumber.stp_decimalNumber(
      withAmount: context!.paymentAmount,
      currency: context?.paymentCurrency)

    XCTAssertTrue((itemTotalAmount == correctTotalAmount))
  }

  func testSetPaymentAmount_generateSummaryItemsShippingMethod() {
    let context = buildPaymentContext()
    context?.paymentAmount = 100
    context?.configuration!.companyName = "Foo Company"
    let method = PKShippingMethod()
    method.amount = NSDecimalNumber(string: "5.99")
    method.label = "FedEx"
    method.detail = "foo"
    method.identifier = "123"
    context?.selectedShippingMethod = method

    let items = context?.paymentSummaryItems
    XCTAssertEqual(Int(items?.count ?? 0), 2)
    let item1 = items?[0]
    XCTAssertEqual(item1?.label, "FedEx")
    XCTAssertEqual(item1?.amount, NSDecimalNumber(string: "5.99"))
    let item2 = items?[1]
    XCTAssertEqual(item2?.label, "Foo Company")
    XCTAssertEqual(item2?.amount, NSDecimalNumber(string: "6.99"))
  }

  func testSummaryItemsToSummaryItems_shippingMethod() {
    let context = buildPaymentContext()
    let item1 = PKPaymentSummaryItem()
    item1.amount = NSDecimalNumber(string: "1.00")
    item1.label = "foo"
    let item2 = PKPaymentSummaryItem()
    item2.amount = NSDecimalNumber(string: "9.00")
    item2.label = "bar"
    let item3 = PKPaymentSummaryItem()
    item3.amount = NSDecimalNumber(string: "10.00")
    item3.label = "baz"
    context?.paymentSummaryItems = [item1, item2, item3]
    let method = PKShippingMethod()
    method.amount = NSDecimalNumber(string: "5.99")
    method.label = "FedEx"
    method.detail = "foo"
    method.identifier = "123"
    context?.selectedShippingMethod = method

    let items = context?.paymentSummaryItems
    XCTAssertEqual(Int(items?.count ?? 0), 4)
    let resultItem1 = items?[0]
    XCTAssertEqual(resultItem1?.label, "foo")
    XCTAssertEqual(resultItem1?.amount, NSDecimalNumber(string: "1.00"))
    let resultItem2 = items?[1]
    XCTAssertEqual(resultItem2?.label, "bar")
    XCTAssertEqual(resultItem2?.amount, NSDecimalNumber(string: "9.00"))
    let resultItem3 = items?[2]
    XCTAssertEqual(resultItem3?.label, "FedEx")
    XCTAssertEqual(resultItem3?.amount, NSDecimalNumber(string: "5.99"))
    let resultItem4 = items?[3]
    XCTAssertEqual(resultItem4?.label, "baz")
    XCTAssertEqual(resultItem4?.amount, NSDecimalNumber(string: "15.99"))
  }

  func testAmountToAmount_shippingMethod_usd() {
    let context = buildPaymentContext()
    context?.paymentAmount = 100
    let method = PKShippingMethod()
    method.amount = NSDecimalNumber(string: "5.99")
    method.label = "FedEx"
    method.detail = "foo"
    method.identifier = "123"
    context?.selectedShippingMethod = method
    let amount = context?.paymentAmount ?? 0
    XCTAssertEqual(amount, 699)
  }

  func testSummaryItems_generateAmountDecimalCurrency() {
    let context = buildPaymentContext()
    context?.paymentSummaryItems = testSummaryItems()
    context?.paymentCurrency = "USD"
    XCTAssertTrue(context?.paymentAmount == 10000)
  }

  func testSummaryItems_generateAmountNoDecimalCurrency() {
    let context = buildPaymentContext()
    context?.paymentSummaryItems = testSummaryItems()
    context?.paymentCurrency = "JPY"
    XCTAssertTrue(context?.paymentAmount == 100)
  }
}
