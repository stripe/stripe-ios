//
//  CustomerSheet+PaymentMethodAvailabilityTests.swift
//  StripePaymentSheetTests
//
//

import Foundation

@_spi(PrivateBetaCustomerSheet) @testable import StripePaymentSheet
import XCTest

class CustomerSheetPaymentMethodAvailabilityTests: XCTestCase {

    func testSupportedPaymentMethodTypesForAdd_CardOnlySupported() {
        CustomerSheet.supportedPaymentMethods = [.card]

        var configuration = CustomerSheet.Configuration()
        configuration.paymentMethodTypes = [.card, .USBankAccount]

        XCTAssertEqual(configuration.supportedPaymentMethodTypesForAdd(customerAdapter: mockCustomerAdapterWithSetupIntent), [.card])
    }
    func testSupportedPaymentMethodTypesForAdd_WithSupportedUSBankAccount() {
        CustomerSheet.supportedPaymentMethods = [.card, .USBankAccount]

        var configuration = CustomerSheet.Configuration()
        configuration.paymentMethodTypes = [.card, .USBankAccount]

        XCTAssertEqual(configuration.supportedPaymentMethodTypesForAdd(customerAdapter: mockCustomerAdapterWithSetupIntent), [.card, .USBankAccount])
    }
    func testSupportedPaymentMethodTypesForAdd_WithSupportedUSBankAccount_NoSetupIntent() {
        CustomerSheet.supportedPaymentMethods = [.card, .USBankAccount]

        var configuration = CustomerSheet.Configuration()
        configuration.paymentMethodTypes = [.card, .USBankAccount]

        XCTAssertEqual(configuration.supportedPaymentMethodTypesForAdd(customerAdapter: mockCustomerAdapterWithoutSetupIntent), [.card])
    }

    func testSupportedPaymentMethodTypesForList() {
        CustomerSheet.supportedPaymentMethods = [.card]

        var configuration = CustomerSheet.Configuration()
        configuration.paymentMethodTypes = [.card, .USBankAccount]

        XCTAssertEqual(configuration.supportedPaymentMethodTypesForList(), [.card])
    }

    func testDedupedPaymentMethodTypesIdentity() {
        var configuration = CustomerSheet.Configuration()
        configuration.paymentMethodTypes = [.card, .USBankAccount]
        XCTAssertEqual(configuration.dedupedPaymentMethodTypes, [.card, .USBankAccount])
    }
    func testDedupedPaymentMethodTypes_dupeCard() {
        var configuration = CustomerSheet.Configuration()
        configuration.paymentMethodTypes = [.card, .card, .USBankAccount]
        XCTAssertEqual(configuration.dedupedPaymentMethodTypes, [.card, .USBankAccount])
    }
    func testDedupedPaymentMethodTypes_dupeBoth() {
        var configuration = CustomerSheet.Configuration()
        configuration.paymentMethodTypes = [.card, .card, .USBankAccount, .USBankAccount]
        XCTAssertEqual(configuration.dedupedPaymentMethodTypes, [.card, .USBankAccount])
    }
    func testDedupedPaymentMethodTypes_TestOrder() {
        var configuration = CustomerSheet.Configuration()
        configuration.paymentMethodTypes = [.USBankAccount, .card, .card, .USBankAccount, .USBankAccount]
        XCTAssertEqual(configuration.dedupedPaymentMethodTypes, [.USBankAccount, .card])
    }

    var mockCustomerAdapterWithSetupIntent: CustomerAdapter {
        return MockCustomerAdapter(mockedValue: true)
    }
    var mockCustomerAdapterWithoutSetupIntent: CustomerAdapter {
        return MockCustomerAdapter(mockedValue: false)
    }
}

class MockCustomerAdapter: CustomerAdapter {
    let mockedValue: Bool
    init(mockedValue: Bool) {
        self.mockedValue = mockedValue
    }
    func fetchPaymentMethods() async throws -> [StripePayments.STPPaymentMethod] {
        return []
    }
    func attachPaymentMethod(_ paymentMethodId: String) async throws {
    }

    func detachPaymentMethod(paymentMethodId: String) async throws {
    }
    func setSelectedPaymentOption(paymentOption: StripePaymentSheet.CustomerPaymentOption?) async throws {
    }
    func fetchSelectedPaymentOption() async throws -> StripePaymentSheet.CustomerPaymentOption? {
        return nil
    }
    func setupIntentClientSecretForCustomerAttach() async throws -> String {
        return ""
    }
    var canCreateSetupIntents: Bool {
        return mockedValue
    }
}
