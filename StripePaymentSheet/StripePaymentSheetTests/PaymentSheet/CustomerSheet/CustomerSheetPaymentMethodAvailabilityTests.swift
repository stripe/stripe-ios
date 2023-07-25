//
//  CustomerSheet+PaymentMethodAvailabilityTests.swift
//  StripePaymentSheetTests
//
//

import Foundation

@_spi(PrivateBetaCustomerSheet) @_spi(STP) @testable import StripePaymentSheet
import XCTest

class CustomerSheetPaymentMethodAvailabilityTests: XCTestCase {

    func testSupportedPaymentMethodTypesForAdd_CardOnlySupported() {
        CustomerSheet.supportedPaymentMethods = [.card]

        let elementSession = elementSession(orderedPaymentMethodTypes: ["card"])
        let paymentMethodTypes = elementSession.customerSheetSupportedPaymentMethodTypesForAdd(customerAdapter: mockCustomerAdapterWithSetupIntent)

        XCTAssertEqual(paymentMethodTypes, [.card])
    }

    func testSupportedPaymentMethodTypesForAdd_WithSupportedUSBankAccount() {
        CustomerSheet.supportedPaymentMethods = [.card, .USBankAccount]

        let elementSession = elementSession(orderedPaymentMethodTypes: ["card", "us_bank_account"])
        let paymentMethodTypes = elementSession.customerSheetSupportedPaymentMethodTypesForAdd(customerAdapter: mockCustomerAdapterWithSetupIntent)

        XCTAssertEqual(paymentMethodTypes, [.card, .USBankAccount])
    }
    func testSupportedPaymentMethodTypesForAdd_WithSupportedUSBankAccount_NoSetupIntent() {
        CustomerSheet.supportedPaymentMethods = [.card, .USBankAccount]

        let elementSession = elementSession(orderedPaymentMethodTypes: ["card", "us_bank_account"])
        let paymentMethodTypes = elementSession.customerSheetSupportedPaymentMethodTypesForAdd(customerAdapter: mockCustomerAdapterWithoutSetupIntent)

        XCTAssertEqual(paymentMethodTypes, [.card])
    }

    var mockCustomerAdapterWithSetupIntent: CustomerAdapter {
        return MockCustomerAdapter(mockedValue: true)
    }
    var mockCustomerAdapterWithoutSetupIntent: CustomerAdapter {
        return MockCustomerAdapter(mockedValue: false)
    }
    // Should use the one from StripeiOSTests, but we don't have good infrastructure to share these
    // and we're not using any details from it.
    func elementSession(orderedPaymentMethodTypes: [String]) -> STPElementsSession {
        let apiResponse: [String: Any] = ["payment_method_preference": ["ordered_payment_method_types": orderedPaymentMethodTypes,
                                                                        "country_code": "US", ] as [String: Any],
                                          "session_id": "123",
        ]
        return STPElementsSession.decodedObject(fromAPIResponse: apiResponse)!
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
