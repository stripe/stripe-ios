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
        let sut = paymentMethodTypes.customerSheetSupportedPaymentMethodTypesForAdd(canCreateSetupIntents: true,
                                                                                    supportedPaymentMethods: supportedPaymentMethods)

        XCTAssertEqual(sut, [.card])
    }

    func testSupportedPaymentMethodTypesForAdd_WithSupportedUSBankAccount() {
        let supportedPaymentMethods: [STPPaymentMethodType] = [.card, .USBankAccount]

        let paymentMethodTypes: [STPPaymentMethodType] = [.card, .USBankAccount]
        let sut = paymentMethodTypes.customerSheetSupportedPaymentMethodTypesForAdd(canCreateSetupIntents: true,
                                                                                    supportedPaymentMethods: supportedPaymentMethods)

        XCTAssertEqual(sut, [.card, .USBankAccount])
    }

    func testSupportedPaymentMethodTypesForAdd_useStaticDefault() {

        let paymentMethodTypes: [STPPaymentMethodType] = [.card, .USBankAccount, .SEPADebit]
        let sut = paymentMethodTypes.customerSheetSupportedPaymentMethodTypesForAdd(canCreateSetupIntents: true)

        XCTAssertEqual(sut, [.card, .USBankAccount, .SEPADebit])
    }

    func testSupportedPaymentMethodTypesForAdd_WithSupportedUSBankAccount_NoSetupIntent() {
        let supportedPaymentMethods: [STPPaymentMethodType] = [.card, .USBankAccount]

        let paymentMethodTypes: [STPPaymentMethodType] = [.card, .USBankAccount]
        let sut = paymentMethodTypes.customerSheetSupportedPaymentMethodTypesForAdd(canCreateSetupIntents: false,
                                                                                    supportedPaymentMethods: supportedPaymentMethods)

        XCTAssertEqual(sut, [.card])
    }
    func testCustomerSheetSupportedPaymentMethodTypes_card() {
        let input = ["card"]
        guard case .success(let result) = CustomerSheet.customerSheetSupportedPaymentMethodTypes(input),
              let result else {
            XCTFail()
            return
        }
        XCTAssertEqual(result, [.card])
    }
    func testCustomerSheetSupportedPaymentMethodTypes_AllValid() {
        let input = ["card", "us_bank_account", "sepa_debit"]
        guard case .success(let result) = CustomerSheet.customerSheetSupportedPaymentMethodTypes(input),
              let result else {
            XCTFail()
            return
        }
        XCTAssertEqual(result, [.card, .USBankAccount, .SEPADebit])
    }
    func testCustomerSheetSupportedPaymentMethodTypes_partialInvalid() {
        let input = ["card", "us_bank_account", "llama_pay"]
        guard case .failure(let err) = CustomerSheet.customerSheetSupportedPaymentMethodTypes(input),
              case CustomerSheetError.unsupportedPaymentMethodType(let unsupported) = err else {
            XCTFail()
            return
        }
        XCTAssertEqual(unsupported, ["llama_pay"])
    }
    func testCustomerSheetSupportedPaymentMethodTypes_allInvalid() {
        let input = ["llama_pay1", "llama_pay2"]
        guard case .failure(let err) = CustomerSheet.customerSheetSupportedPaymentMethodTypes(input),
              case CustomerSheetError.unsupportedPaymentMethodType(let unsupported) = err else {
            XCTFail()
            return
        }
        XCTAssertEqual(unsupported, ["llama_pay1", "llama_pay2"])
    }
    func testCustomerSheetSupportedPaymentMethodTypes_duplicate1() {
        let input = ["card", "card"]
        guard case .success(let result) = CustomerSheet.customerSheetSupportedPaymentMethodTypes(input),
              let result else {
            XCTFail()
            return
        }
        XCTAssertEqual(result, [.card])
    }
    func testCustomerSheetSupportedPaymentMethodTypes_removeDupeInOrder() {
        let input = ["card", "us_bank_account", "card"]
        guard case .success(let result) = CustomerSheet.customerSheetSupportedPaymentMethodTypes(input),
              let result else {
            XCTFail()
            return
        }
        XCTAssertEqual(result, [.card, .USBankAccount])
    }
    func testCustomerSheetSupportedPaymentMethodTypes_duplicate_withInvalid() {
        let input = ["card", "card", "llama_pay"]
        guard case .failure(let err) = CustomerSheet.customerSheetSupportedPaymentMethodTypes(input),
              case CustomerSheetError.unsupportedPaymentMethodType(let unsupported) = err else {
            XCTFail()
            return
        }
        XCTAssertEqual(unsupported, ["llama_pay"])
    }
    func testCustomerSheetSupportedPaymentMethodTypes_empty() {
        let input: [String] = []
        guard case .success(let result) = CustomerSheet.customerSheetSupportedPaymentMethodTypes(input) else {
            XCTFail()
            return
        }
        XCTAssertNil(result)
    }
}
