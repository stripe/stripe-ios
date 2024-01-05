//
//  CustomerSheetConfigurationTests.swift
//  StripePaymentSheetTests
//

import XCTest

@testable@_spi(STP) import StripePaymentSheet

class CustomerSheetConfigurationTests: XCTestCase {
    func testIsUsingBillingAddressCollection_Default() {
        let configuration = CustomerSheet.Configuration()
        XCTAssertFalse(configuration.isUsingBillingAddressCollection())
    }

    func testIsUsingBillingAddressCollection_address_never() {
        var configuration = CustomerSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.address = .never
        XCTAssertFalse(configuration.isUsingBillingAddressCollection())
    }

    func testIsUsingBillingAddressCollection_address_full() {
        var configuration = CustomerSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.address = .full
        XCTAssert(configuration.isUsingBillingAddressCollection())
    }

    func testIsUsingBillingAddressCollection_email_never() {
        var configuration = CustomerSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.email = .never
        XCTAssertFalse(configuration.isUsingBillingAddressCollection())
    }

    func testIsUsingBillingAddressCollection_email_full() {
        var configuration = CustomerSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.email = .always
        XCTAssert(configuration.isUsingBillingAddressCollection())
    }

    func testIsUsingBillingAddressCollection_name_never() {
        var configuration = CustomerSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.name = .never
        XCTAssertFalse(configuration.isUsingBillingAddressCollection())
    }

    func testIsUsingBillingAddressCollection_name_full() {
        var configuration = CustomerSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.name = .always
        XCTAssert(configuration.isUsingBillingAddressCollection())
    }

    func testIsUsingBillingAddressCollection_phone_never() {
        var configuration = CustomerSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.phone = .never
        XCTAssertFalse(configuration.isUsingBillingAddressCollection())
    }

    func testIsUsingBillingAddressCollection_phone_full() {
        var configuration = CustomerSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.phone = .always
        XCTAssert(configuration.isUsingBillingAddressCollection())
    }
}
