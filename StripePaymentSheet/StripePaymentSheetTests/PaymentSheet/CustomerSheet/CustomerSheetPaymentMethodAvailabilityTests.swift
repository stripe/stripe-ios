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
        let supportedPaymentMethods: [STPPaymentMethodType] = [.card]

        let paymentMethodTypes: [STPPaymentMethodType] = [.card]
        let sut = paymentMethodTypes.customerSheetSupportedPaymentMethodTypesForAdd(customerAdapter: mockCustomerAdapterWithSetupIntent,
                                                                                    supportedPaymentMethods: supportedPaymentMethods)

        XCTAssertEqual(sut, [.card])
    }

    func testSupportedPaymentMethodTypesForAdd_WithSupportedUSBankAccount() {
        let supportedPaymentMethods: [STPPaymentMethodType] = [.card, .USBankAccount]

        let paymentMethodTypes: [STPPaymentMethodType] = [.card, .USBankAccount]
        let sut = paymentMethodTypes.customerSheetSupportedPaymentMethodTypesForAdd(customerAdapter: mockCustomerAdapterWithSetupIntent,
                                                                                    supportedPaymentMethods: supportedPaymentMethods)

        XCTAssertEqual(sut, [.card, .USBankAccount])
    }

    func testSupportedPaymentMethodTypesForAdd_useStaticDefault() {

        let paymentMethodTypes: [STPPaymentMethodType] = [.card, .USBankAccount, .SEPADebit]
        let sut = paymentMethodTypes.customerSheetSupportedPaymentMethodTypesForAdd(customerAdapter: mockCustomerAdapterWithSetupIntent)

        XCTAssertEqual(sut, [.card, .USBankAccount, .SEPADebit])
    }

    func testSupportedPaymentMethodTypesForAdd_WithSupportedUSBankAccount_NoSetupIntent() {
        let supportedPaymentMethods: [STPPaymentMethodType] = [.card, .USBankAccount]

        let paymentMethodTypes: [STPPaymentMethodType] = [.card, .USBankAccount]
        let sut = paymentMethodTypes.customerSheetSupportedPaymentMethodTypesForAdd(customerAdapter: mockCustomerAdapterWithoutSetupIntent,
                                                                                    supportedPaymentMethods: supportedPaymentMethods)

        XCTAssertEqual(sut, [.card])
    }
    func testCustomerSheetSupportedPaymentMethodTypes_card() {
        let input = ["card"]
        guard case .success(let result) = input.customerSheetSupportedPaymentMethodTypes(),
              let result else {
            XCTFail()
            return
        }
        XCTAssertEqual(result, [.card])
    }
    func testCustomerSheetSupportedPaymentMethodTypes_AllValid() {
        let input = ["card", "us_bank_account", "sepa_debit"]
        guard case .success(let result) = input.customerSheetSupportedPaymentMethodTypes(),
              let result else {
            XCTFail()
            return
        }
        XCTAssertEqual(result, [.card, .USBankAccount, .SEPADebit])
    }
    func testCustomerSheetSupportedPaymentMethodTypes_partialInvalid() {
        let input = ["card", "us_bank_account", "llama_pay"]
        guard case .failure(let err) = input.customerSheetSupportedPaymentMethodTypes(),
              case CustomerSheetError.unsupportedPaymentMethodType(let unsupported) = err else {
            XCTFail()
            return
        }
        XCTAssertEqual(unsupported, ["llama_pay"])
    }
    func testCustomerSheetSupportedPaymentMethodTypes_allInvalid() {
        let input = ["llama_pay1", "llama_pay2"]
        guard case .failure(let err) = input.customerSheetSupportedPaymentMethodTypes(),
              case CustomerSheetError.unsupportedPaymentMethodType(let unsupported) = err else {
            XCTFail()
            return
        }
        XCTAssertEqual(unsupported, ["llama_pay1", "llama_pay2"])
    }
    func testCustomerSheetSupportedPaymentMethodTypes_empty() {
        let input: [String] = []
        guard case .success(let result) = input.customerSheetSupportedPaymentMethodTypes() else {
            XCTFail()
            return
        }
        XCTAssertNil(result)
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
    var paymentMethodTypes: [String]? {
        return nil
    }
}
