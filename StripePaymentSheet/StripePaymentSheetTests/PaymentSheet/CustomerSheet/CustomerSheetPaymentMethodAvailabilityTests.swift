//
//  CustomerSheet+PaymentMethodAvailabilityTests.swift
//  StripePaymentSheetTests
//
//

import Foundation

@_spi(STP) @testable import StripePaymentSheet
import XCTest

class CustomerSheetPaymentMethodAvailabilityTests: XCTestCase {

    func testSupportedPaymentMethodTypesForAdd_CardOnlySupported() {
        CustomerSheet.supportedPaymentMethods = [.card]

        let paymentMethodTypes: [STPPaymentMethodType] = [.card]
        let sut = paymentMethodTypes.customerSheetSupportedPaymentMethodTypesForAdd(customerAdapter: mockCustomerAdapterWithSetupIntent)

        XCTAssertEqual(sut, [.card])
    }

    func testSupportedPaymentMethodTypesForAdd_WithSupportedUSBankAccount() {
        CustomerSheet.supportedPaymentMethods = [.card, .USBankAccount]

        let paymentMethodTypes: [STPPaymentMethodType] = [.card, .USBankAccount]
        let sut = paymentMethodTypes.customerSheetSupportedPaymentMethodTypesForAdd(customerAdapter: mockCustomerAdapterWithSetupIntent)

        XCTAssertEqual(sut, [.card, .USBankAccount])
    }
    func testSupportedPaymentMethodTypesForAdd_WithSupportedUSBankAccount_NoSetupIntent() {
        CustomerSheet.supportedPaymentMethods = [.card, .USBankAccount]

        let paymentMethodTypes: [STPPaymentMethodType] = [.card, .USBankAccount]
        let sut = paymentMethodTypes.customerSheetSupportedPaymentMethodTypesForAdd(customerAdapter: mockCustomerAdapterWithoutSetupIntent)

        XCTAssertEqual(sut, [.card])
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

    func updatePaymentMethod(paymentMethodId: String, paymentMethodUpdateParams: StripePayments.STPPaymentMethodUpdateParams) async throws -> StripePayments.STPPaymentMethod {
        throw CustomerSheetError.unknown(debugDescription: "Not implemented")
    }
}
