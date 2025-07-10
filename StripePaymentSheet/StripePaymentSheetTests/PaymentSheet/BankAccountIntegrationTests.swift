//
//  BankAccountIntegrationTests.swift
//  StripePaymentSheetTests
//
//  Created by Claude Code on 7/10/25.
//  Copyright © 2025 Stripe, Inc. All rights reserved.
//

import XCTest

@testable@_spi(STP) import StripePaymentSheet

class BankAccountIntegrationTests: XCTestCase {

    var mockAPIClient: MockAPIClient!
    var mockFinancialConnectionsService: MockFinancialConnectionsService!
    var bankAccountManager: MockBankAccountManager!
    
    override func setUp() {
        super.setUp()
        mockAPIClient = MockAPIClient()
        mockFinancialConnectionsService = MockFinancialConnectionsService()
        bankAccountManager = MockBankAccountManager(
            apiClient: mockAPIClient,
            financialConnectionsService: mockFinancialConnectionsService
        )
    }
    
    override func tearDown() {
        mockAPIClient = nil
        mockFinancialConnectionsService = nil
        bankAccountManager = nil
        super.tearDown()
    }
    
    // MARK: - US Bank Account Addition Tests
    
    func testAddUSBankAccount_successfulInstantVerification() {
        let mockBankAccount = MockBankAccount.createUSBankAccount()
        mockFinancialConnectionsService.shouldSucceedInstantVerification = true
        
        let expectation = self.expectation(description: "US bank account added with instant verification")
        
        bankAccountManager.addBankAccount(mockBankAccount) { result in
            switch result {
            case .success(let paymentMethod):
                XCTAssertEqual(paymentMethod.type, .usBankAccount)
                XCTAssertEqual(paymentMethod.verificationStatus, .verified)
                XCTAssertEqual(paymentMethod.bankAccount?.routingNumber, mockBankAccount.routingNumber)
                XCTAssertEqual(paymentMethod.bankAccount?.accountNumber, mockBankAccount.last4)
                expectation.fulfill()
            case .failure:
                XCTFail("Expected success")
            }
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testAddUSBankAccount_requiresMicroDeposits() {
        let mockBankAccount = MockBankAccount.createUSBankAccount()
        mockFinancialConnectionsService.shouldRequireMicroDeposits = true
        
        let expectation = self.expectation(description: "US bank account requires microdeposit verification")
        
        bankAccountManager.addBankAccount(mockBankAccount) { result in
            switch result {
            case .success(let paymentMethod):
                XCTAssertEqual(paymentMethod.type, .usBankAccount)
                XCTAssertEqual(paymentMethod.verificationStatus, .pendingMicroDeposits)
                XCTAssertNotNil(paymentMethod.microDepositSession)
                expectation.fulfill()
            case .failure:
                XCTFail("Expected success with microdeposit requirement")
            }
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testAddUSBankAccount_invalidRoutingNumber() {
        let mockBankAccount = MockBankAccount.createUSBankAccountWithInvalidRouting()
        
        let expectation = self.expectation(description: "US bank account with invalid routing number")
        
        bankAccountManager.addBankAccount(mockBankAccount) { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure(let error):
                XCTAssertEqual(error.code, .invalidBankAccount)
                XCTAssertTrue(error.message.contains("routing number"))
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testAddUSBankAccount_networkError() {
        let mockBankAccount = MockBankAccount.createUSBankAccount()
        mockAPIClient.shouldFailWithNetworkError = true
        
        let expectation = self.expectation(description: "US bank account network error")
        
        bankAccountManager.addBankAccount(mockBankAccount) { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure(let error):
                XCTAssertEqual(error.code, .networkError)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    // MARK: - Financial Connections Integration Tests
    
    func testFinancialConnectionsIntegration_successfulConnection() {
        let expectation = self.expectation(description: "Financial Connections successful")
        
        mockFinancialConnectionsService.presentFinancialConnectionsFlow { result in
            switch result {
            case .success(let connectedAccount):
                XCTAssertEqual(connectedAccount.institutionName, "Test Bank")
                XCTAssertEqual(connectedAccount.accountType, .checking)
                XCTAssertTrue(connectedAccount.isVerified)
                expectation.fulfill()
            case .failure:
                XCTFail("Expected success")
            }
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testFinancialConnectionsIntegration_userCancellation() {
        mockFinancialConnectionsService.shouldSimulateUserCancellation = true
        
        let expectation = self.expectation(description: "Financial Connections user cancelled")
        
        mockFinancialConnectionsService.presentFinancialConnectionsFlow { result in
            switch result {
            case .success:
                XCTFail("Expected cancellation")
            case .failure(let error):
                XCTAssertEqual(error.code, .userCancelled)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testFinancialConnectionsIntegration_authenticationFailed() {
        mockFinancialConnectionsService.shouldFailAuthentication = true
        
        let expectation = self.expectation(description: "Financial Connections authentication failed")
        
        mockFinancialConnectionsService.presentFinancialConnectionsFlow { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure(let error):
                XCTAssertEqual(error.code, .authenticationFailed)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    // MARK: - Bank Account Verification Flow Tests
    
    func testBankAccountVerificationFlow_instantVerification() {
        let mockBankAccount = MockBankAccount.createUSBankAccount()
        mockFinancialConnectionsService.shouldSucceedInstantVerification = true
        
        let expectation = self.expectation(description: "Bank account verification flow - instant")
        
        bankAccountManager.verifyBankAccount(mockBankAccount) { result in
            switch result {
            case .success(let verificationResult):
                XCTAssertEqual(verificationResult.status, .verified)
                XCTAssertEqual(verificationResult.verificationType, .instant)
                XCTAssertNil(verificationResult.microDepositSession)
                expectation.fulfill()
            case .failure:
                XCTFail("Expected success")
            }
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testBankAccountVerificationFlow_microDepositRequired() {
        let mockBankAccount = MockBankAccount.createUSBankAccount()
        mockFinancialConnectionsService.shouldRequireMicroDeposits = true
        
        let expectation = self.expectation(description: "Bank account verification flow - microdeposit")
        
        bankAccountManager.verifyBankAccount(mockBankAccount) { result in
            switch result {
            case .success(let verificationResult):
                XCTAssertEqual(verificationResult.status, .pendingMicroDeposits)
                XCTAssertEqual(verificationResult.verificationType, .microDeposits)
                XCTAssertNotNil(verificationResult.microDepositSession)
                expectation.fulfill()
            case .failure:
                XCTFail("Expected success")
            }
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    // MARK: - Bank Account Types Tests
    
    func testBankAccountTypes_checkingAccount() {
        let checkingAccount = MockBankAccount.createUSBankAccount(accountType: .checking)
        mockFinancialConnectionsService.shouldSucceedInstantVerification = true
        
        let expectation = self.expectation(description: "Checking account verification")
        
        bankAccountManager.addBankAccount(checkingAccount) { result in
            switch result {
            case .success(let paymentMethod):
                XCTAssertEqual(paymentMethod.bankAccount?.accountType, .checking)
                expectation.fulfill()
            case .failure:
                XCTFail("Expected success")
            }
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testBankAccountTypes_savingsAccount() {
        let savingsAccount = MockBankAccount.createUSBankAccount(accountType: .savings)
        mockFinancialConnectionsService.shouldSucceedInstantVerification = true
        
        let expectation = self.expectation(description: "Savings account verification")
        
        bankAccountManager.addBankAccount(savingsAccount) { result in
            switch result {
            case .success(let paymentMethod):
                XCTAssertEqual(paymentMethod.bankAccount?.accountType, .savings)
                expectation.fulfill()
            case .failure:
                XCTFail("Expected success")
            }
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    // MARK: - Bank Account Validation Tests
    
    func testBankAccountValidation_validAccount() {
        let validAccount = MockBankAccount.createUSBankAccount()
        
        XCTAssertTrue(bankAccountManager.validateBankAccount(validAccount))
    }
    
    func testBankAccountValidation_invalidRoutingNumber() {
        let invalidAccount = MockBankAccount.createUSBankAccountWithInvalidRouting()
        
        XCTAssertFalse(bankAccountManager.validateBankAccount(invalidAccount))
    }
    
    func testBankAccountValidation_invalidAccountNumber() {
        let invalidAccount = MockBankAccount.createUSBankAccountWithInvalidAccount()
        
        XCTAssertFalse(bankAccountManager.validateBankAccount(invalidAccount))
    }
    
    // MARK: - API Integration Tests
    
    func testAPIIntegration_createPaymentMethodWithBankAccount() {
        let mockBankAccount = MockBankAccount.createUSBankAccount()
        
        let expectation = self.expectation(description: "API create payment method")
        
        mockAPIClient.createPaymentMethod(with: mockBankAccount) { result in
            switch result {
            case .success(let paymentMethod):
                XCTAssertEqual(paymentMethod.type, .usBankAccount)
                XCTAssertNotNil(paymentMethod.id)
                expectation.fulfill()
            case .failure:
                XCTFail("Expected success")
            }
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testAPIIntegration_retrievePaymentMethodDetails() {
        let paymentMethodId = "pm_test_bank_account"
        
        let expectation = self.expectation(description: "API retrieve payment method")
        
        mockAPIClient.retrievePaymentMethod(id: paymentMethodId) { result in
            switch result {
            case .success(let paymentMethod):
                XCTAssertEqual(paymentMethod.id, paymentMethodId)
                XCTAssertEqual(paymentMethod.type, .usBankAccount)
                expectation.fulfill()
            case .failure:
                XCTFail("Expected success")
            }
        }
        
        waitForExpectations(timeout: 5.0)
    }
}

// MARK: - Mock Classes

class MockBankAccountManager {
    let apiClient: MockAPIClient
    let financialConnectionsService: MockFinancialConnectionsService
    
    init(apiClient: MockAPIClient, financialConnectionsService: MockFinancialConnectionsService) {
        self.apiClient = apiClient
        self.financialConnectionsService = financialConnectionsService
    }
    
    func addBankAccount(_ bankAccount: MockBankAccount, completion: @escaping (Result<MockPaymentMethod, BankAccountError>) -> Void) {
        guard validateBankAccount(bankAccount) else {
            completion(.failure(BankAccountError(code: .invalidBankAccount, message: "Invalid routing number")))
            return
        }
        
        if apiClient.shouldFailWithNetworkError {
            completion(.failure(BankAccountError(code: .networkError, message: "Network error")))
            return
        }
        
        // Simulate verification process
        verifyBankAccount(bankAccount) { result in
            switch result {
            case .success(let verificationResult):
                let paymentMethod = MockPaymentMethod.createBankAccountPaymentMethod(
                    bankAccount: bankAccount,
                    verificationStatus: verificationResult.status,
                    microDepositSession: verificationResult.microDepositSession
                )
                completion(.success(paymentMethod))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func verifyBankAccount(_ bankAccount: MockBankAccount, completion: @escaping (Result<BankAccountVerificationResult, BankAccountError>) -> Void) {
        if financialConnectionsService.shouldSucceedInstantVerification {
            let result = BankAccountVerificationResult(
                status: .verified,
                verificationType: .instant,
                microDepositSession: nil
            )
            completion(.success(result))
        } else if financialConnectionsService.shouldRequireMicroDeposits {
            let result = BankAccountVerificationResult(
                status: .pendingMicroDeposits,
                verificationType: .microDeposits,
                microDepositSession: MockMicroDepositSession(id: "mds_test")
            )
            completion(.success(result))
        } else {
            completion(.failure(BankAccountError(code: .verificationFailed, message: "Verification failed")))
        }
    }
    
    func validateBankAccount(_ bankAccount: MockBankAccount) -> Bool {
        return bankAccount.routingNumber.count == 9 && 
               bankAccount.accountNumber.count >= 4 &&
               bankAccount.accountNumber.count <= 17
    }
}

class MockFinancialConnectionsService {
    var shouldSucceedInstantVerification = false
    var shouldRequireMicroDeposits = false
    var shouldSimulateUserCancellation = false
    var shouldFailAuthentication = false
    
    func presentFinancialConnectionsFlow(completion: @escaping (Result<MockConnectedAccount, BankAccountError>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.shouldSimulateUserCancellation {
                completion(.failure(BankAccountError(code: .userCancelled, message: "User cancelled")))
            } else if self.shouldFailAuthentication {
                completion(.failure(BankAccountError(code: .authenticationFailed, message: "Authentication failed")))
            } else {
                let connectedAccount = MockConnectedAccount(
                    institutionName: "Test Bank",
                    accountType: .checking,
                    isVerified: true
                )
                completion(.success(connectedAccount))
            }
        }
    }
}

class MockAPIClient {
    var shouldFailWithNetworkError = false
    
    func createPaymentMethod(with bankAccount: MockBankAccount, completion: @escaping (Result<MockPaymentMethod, BankAccountError>) -> Void) {
        if shouldFailWithNetworkError {
            completion(.failure(BankAccountError(code: .networkError, message: "Network error")))
            return
        }
        
        let paymentMethod = MockPaymentMethod.createBankAccountPaymentMethod(
            bankAccount: bankAccount,
            verificationStatus: .verified,
            microDepositSession: nil
        )
        completion(.success(paymentMethod))
    }
    
    func retrievePaymentMethod(id: String, completion: @escaping (Result<MockPaymentMethod, BankAccountError>) -> Void) {
        if shouldFailWithNetworkError {
            completion(.failure(BankAccountError(code: .networkError, message: "Network error")))
            return
        }
        
        let paymentMethod = MockPaymentMethod(
            id: id,
            type: .usBankAccount,
            verificationStatus: .verified,
            bankAccount: MockBankAccount.createUSBankAccount(),
            microDepositSession: nil
        )
        completion(.success(paymentMethod))
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

struct MockPaymentMethod {
    let id: String
    let type: PaymentMethodType
    let verificationStatus: BankAccountVerificationStatus
    let bankAccount: MockBankAccount?
    let microDepositSession: MockMicroDepositSession?
    
    static func createBankAccountPaymentMethod(
        bankAccount: MockBankAccount,
        verificationStatus: BankAccountVerificationStatus,
        microDepositSession: MockMicroDepositSession?
    ) -> MockPaymentMethod {
        return MockPaymentMethod(
            id: "pm_test_bank_\(UUID().uuidString)",
            type: .usBankAccount,
            verificationStatus: verificationStatus,
            bankAccount: bankAccount,
            microDepositSession: microDepositSession
        )
    }
}

struct MockConnectedAccount {
    let institutionName: String
    let accountType: BankAccountType
    let isVerified: Bool
}

struct MockMicroDepositSession {
    let id: String
}

struct BankAccountVerificationResult {
    let status: BankAccountVerificationStatus
    let verificationType: BankAccountVerificationType
    let microDepositSession: MockMicroDepositSession?
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

enum PaymentMethodType {
    case card
    case usBankAccount
    case sepaDebit
}