//
//  ManualEntryValidatorTests.swift
//  StripeFinancialConnectionsTests
//
//  Created by Krisjanis Gaidis on 8/26/22.
//

@testable import StripeFinancialConnections
import XCTest

class ManualEntryValidatorTests: XCTestCase {

    func testValidateRoutingNumber() throws {
        XCTAssert(ManualEntryValidator.validateRoutingNumber("") != nil)
        XCTAssert(ManualEntryValidator.validateRoutingNumber("1") != nil)
        XCTAssert(ManualEntryValidator.validateRoutingNumber("12") != nil)
        XCTAssert(ManualEntryValidator.validateRoutingNumber("123") != nil)
        XCTAssert(ManualEntryValidator.validateRoutingNumber("1234") != nil)
        XCTAssert(ManualEntryValidator.validateRoutingNumber("12345") != nil)
        XCTAssert(ManualEntryValidator.validateRoutingNumber("123456") != nil)
        XCTAssert(ManualEntryValidator.validateRoutingNumber("1234567") != nil)
        XCTAssert(ManualEntryValidator.validateRoutingNumber("12345678") != nil)
        XCTAssert(ManualEntryValidator.validateRoutingNumber("123456789") != nil)
        XCTAssert(ManualEntryValidator.validateRoutingNumber("123456789") != nil)
        XCTAssert(ManualEntryValidator.validateRoutingNumber("1234567890") != nil)
        XCTAssert(ManualEntryValidator.validateRoutingNumber("021000021") == nil)
        XCTAssert(ManualEntryValidator.validateRoutingNumber("011401533") == nil)
        XCTAssert(ManualEntryValidator.validateRoutingNumber("091000019") == nil)
        XCTAssert(ManualEntryValidator.validateRoutingNumber("x91000019") != nil)
        XCTAssert(ManualEntryValidator.validateRoutingNumber("09100001x") != nil)
        XCTAssert(ManualEntryValidator.validateRoutingNumber("0910x0019") != nil)
        XCTAssert(ManualEntryValidator.validateRoutingNumber("-21000021") != nil)
        XCTAssert(ManualEntryValidator.validateRoutingNumber(":21000021") != nil)
    }

    func testValidateAccountingNumber() throws {
        XCTAssert(ManualEntryValidator.validateAccountNumber("") != nil)
        XCTAssert(ManualEntryValidator.validateAccountNumber("1") == nil)
        XCTAssert(ManualEntryValidator.validateAccountNumber("12") == nil)
        XCTAssert(ManualEntryValidator.validateAccountNumber("123") == nil)
        XCTAssert(ManualEntryValidator.validateAccountNumber("1234") == nil)
        XCTAssert(ManualEntryValidator.validateAccountNumber("12345") == nil)
        XCTAssert(ManualEntryValidator.validateAccountNumber("123456") == nil)
        XCTAssert(ManualEntryValidator.validateAccountNumber("1234567") == nil)
        XCTAssert(ManualEntryValidator.validateAccountNumber("12345678") == nil)
        XCTAssert(ManualEntryValidator.validateAccountNumber("123456789") == nil)
        XCTAssert(ManualEntryValidator.validateAccountNumber("123456789") == nil)
        XCTAssert(ManualEntryValidator.validateAccountNumber("0123456789") == nil)
        XCTAssert(ManualEntryValidator.validateAccountNumber("00123456789") == nil)
        XCTAssert(ManualEntryValidator.validateAccountNumber("000123456789") == nil)
        XCTAssert(ManualEntryValidator.validateAccountNumber("0000123456789") == nil)
        XCTAssert(ManualEntryValidator.validateAccountNumber("00000123456789") == nil)
        XCTAssert(ManualEntryValidator.validateAccountNumber("000000123456789") == nil)
        XCTAssert(ManualEntryValidator.validateAccountNumber("0000000123456789") == nil)
        XCTAssert(ManualEntryValidator.validateAccountNumber("00000000123456789") == nil)
        XCTAssert(ManualEntryValidator.validateAccountNumber("000000000123456789") != nil)
        XCTAssert(ManualEntryValidator.validateAccountNumber("x0000000123456789") != nil)
        XCTAssert(ManualEntryValidator.validateAccountNumber("-0000000123456789") != nil)
        XCTAssert(ManualEntryValidator.validateAccountNumber(":0000000123456789") != nil)
        XCTAssert(ManualEntryValidator.validateAccountNumber("0000000012345678x") != nil)
        XCTAssert(ManualEntryValidator.validateAccountNumber("0000000x123456789") != nil)
    }

    func testValidateAccountNumberConfirmation() throws {
        XCTAssert(ManualEntryValidator.validateAccountNumberConfirmation("", accountNumber: "") != nil)
        XCTAssert(ManualEntryValidator.validateAccountNumberConfirmation("1", accountNumber: "1") == nil)
        XCTAssert(
            ManualEntryValidator.validateAccountNumberConfirmation(
                "00000000123456789",
                accountNumber: "00000000123456789"
            ) == nil
        )
        XCTAssert(ManualEntryValidator.validateAccountNumberConfirmation("1", accountNumber: "2") != nil)
        XCTAssert(ManualEntryValidator.validateAccountNumberConfirmation("2", accountNumber: "1") != nil)
    }
}
