//
//  TestMocks.swift
//  StripePaymentSheetTests
//
//  Created by Claude Code on 7/10/25.
//  Copyright © 2025 Stripe, Inc. All rights reserved.
//

import XCTest

@testable@_spi(STP) import StripePaymentSheet

// MARK: - Shared Mock Classes for PaymentSheet Tests

struct MockPaymentMethod {
    let id: String
    let type: PaymentMethodType
    let isValid: Bool
    let verificationStatus: BankAccountVerificationStatus
    let bankAccount: MockBankAccount?
    let microDepositSession: MockMicroDepositSession?
    
    static func createMockCard(id: String = "pm_card_mock") -> MockPaymentMethod {
        return MockPaymentMethod(
            id: id,
            type: .card,
            isValid: true,
            verificationStatus: .verified,
            bankAccount: nil,
            microDepositSession: nil
        )
    }
    
    static func createMockSepa(id: String = "pm_sepa_mock") -> MockPaymentMethod {
        return MockPaymentMethod(
            id: id,
            type: .sepaDebit,
            isValid: true,
            verificationStatus: .verified,
            bankAccount: nil,
            microDepositSession: nil
        )
    }
    
    static func createInvalidCard() -> MockPaymentMethod {
        return MockPaymentMethod(
            id: "pm_invalid",
            type: .card,
            isValid: false,
            verificationStatus: .failed,
            bankAccount: nil,
            microDepositSession: nil
        )
    }
    
    static func createBankAccountPaymentMethod(
        bankAccount: MockBankAccount,
        verificationStatus: BankAccountVerificationStatus,
        microDepositSession: MockMicroDepositSession?
    ) -> MockPaymentMethod {
        return MockPaymentMethod(
            id: "pm_test_bank_\(UUID().uuidString)",
            type: .usBankAccount,
            isValid: true,
            verificationStatus: verificationStatus,
            bankAccount: bankAccount,
            microDepositSession: microDepositSession
        )
    }
}

struct MockBankAccount {
    let routingNumber: String
    let accountNumber: String
    let accountType: BankAccountType
    let last4: String
    
    static func createUSBankAccount(accountType: BankAccountType = .checking) -> MockBankAccount {
        return MockBankAccount(
            routingNumber: "110000000",
            accountNumber: "000123456789",
            accountType: accountType,
            last4: "6789"
        )
    }
    
    static func createUSBankAccountWithInvalidRouting() -> MockBankAccount {
        return MockBankAccount(
            routingNumber: "123", // Invalid length
            accountNumber: "000123456789",
            accountType: .checking,
            last4: "6789"
        )
    }
    
    static func createUSBankAccountWithInvalidAccount() -> MockBankAccount {
        return MockBankAccount(
            routingNumber: "110000000",
            accountNumber: "123", // Invalid length
            accountType: .checking,
            last4: "123"
        )
    }
}

struct MockMicroDepositSession {
    let id: String
}

// MARK: - Shared Enums

enum PaymentMethodType {
    case card
    case usBankAccount
    case sepaDebit
}

enum BankAccountType {
    case checking
    case savings
}

enum BankAccountVerificationStatus {
    case verified
    case pendingMicroDeposits
    case failed
}

enum BankAccountVerificationType {
    case instant
    case microDeposits
}

// MARK: - Shared Error Types

struct PaymentMethodError: Error {
    let code: PaymentMethodErrorCode
}

enum PaymentMethodErrorCode {
    case networkError
    case duplicatePaymentMethod
    case paymentMethodNotFound
    case invalidPaymentMethod
}

struct BankAccountError: Error {
    let code: BankAccountErrorCode
    let message: String
}

enum BankAccountErrorCode {
    case networkError
    case invalidBankAccount
    case verificationFailed
    case userCancelled
    case authenticationFailed
}

struct MicroDepositError: Error {
    let code: MicroDepositErrorCode
}

enum MicroDepositErrorCode {
    case networkError
    case incorrectMicroDepositAmounts
    case tooManyAttempts
    case sessionExpired
    case noAttemptsRemaining
    case invalidAmounts
}

// MARK: - Result Extensions

extension Result {
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
    
    var isFailure: Bool {
        switch self {
        case .success:
            return false
        case .failure:
            return true
        }
    }
}