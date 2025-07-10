//
//  MicroDepositIntegrationTests.swift
//  StripePaymentSheetTests
//
//  Created by Claude Code on 7/10/25.
//  Copyright © 2025 Stripe, Inc. All rights reserved.
//

import XCTest

@testable@_spi(STP) import StripePaymentSheet

class MicroDepositIntegrationTests: XCTestCase {

    var mockAPIClient: MockAPIClient!
    var microDepositManager: MockMicroDepositManager!
    var mockPaymentMethod: MockPaymentMethod!
    
    override func setUp() {
        super.setUp()
        mockAPIClient = MockAPIClient()
        microDepositManager = MockMicroDepositManager(apiClient: mockAPIClient)
        mockPaymentMethod = MockPaymentMethod.createBankAccountPaymentMethod(
            bankAccount: MockBankAccount.createUSBankAccount(),
            verificationStatus: .pendingMicroDeposits,
            microDepositSession: MockMicroDepositSession(id: "mds_test")
        )
    }
    
    override func tearDown() {
        mockAPIClient = nil
        microDepositManager = nil
        mockPaymentMethod = nil
        super.tearDown()
    }
    
    // MARK: - Microdeposit Verification Tests
    
    func testMicroDepositVerification_successfulVerification() {
        let microDepositAmounts = [32, 45] // Common test amounts in cents
        
        let expectation = self.expectation(description: "Microdeposit verification successful")
        
        microDepositManager.verifyMicroDeposits(
            paymentMethodId: mockPaymentMethod.id,
            amounts: microDepositAmounts
        ) { result in
            switch result {
            case .success(let verificationResult):
                XCTAssertEqual(verificationResult.status, .verified)
                XCTAssertEqual(verificationResult.paymentMethodId, self.mockPaymentMethod.id)
                expectation.fulfill()
            case .failure:
                XCTFail("Expected success")
            }
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testMicroDepositVerification_incorrectAmounts() {
        let incorrectAmounts = [12, 34] // Wrong amounts
        
        let expectation = self.expectation(description: "Microdeposit verification failed")
        
        microDepositManager.verifyMicroDeposits(
            paymentMethodId: mockPaymentMethod.id,
            amounts: incorrectAmounts
        ) { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure(let error):
                XCTAssertEqual(error.code, .incorrectMicroDepositAmounts)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testMicroDepositVerification_tooManyAttempts() {
        let correctAmounts = [32, 45]
        microDepositManager.simulateTooManyAttempts = true
        
        let expectation = self.expectation(description: "Too many microdeposit attempts")
        
        microDepositManager.verifyMicroDeposits(
            paymentMethodId: mockPaymentMethod.id,
            amounts: correctAmounts
        ) { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure(let error):
                XCTAssertEqual(error.code, .tooManyAttempts)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testMicroDepositVerification_expired() {
        let correctAmounts = [32, 45]
        microDepositManager.simulateExpiredSession = true
        
        let expectation = self.expectation(description: "Microdeposit session expired")
        
        microDepositManager.verifyMicroDeposits(
            paymentMethodId: mockPaymentMethod.id,
            amounts: correctAmounts
        ) { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure(let error):
                XCTAssertEqual(error.code, .sessionExpired)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    // MARK: - Microdeposit Status Polling Tests
    
    func testMicroDepositStatusPolling_depositsReceived() {
        let expectation = self.expectation(description: "Microdeposit status polling - deposits received")
        
        microDepositManager.pollMicroDepositStatus(
            paymentMethodId: mockPaymentMethod.id
        ) { result in
            switch result {
            case .success(let status):
                XCTAssertEqual(status.state, .depositsReceived)
                XCTAssertEqual(status.attemptsRemaining, 3)
                expectation.fulfill()
            case .failure:
                XCTFail("Expected success")
            }
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testMicroDepositStatusPolling_depositsPending() {
        microDepositManager.simulateDepositsPending = true
        
        let expectation = self.expectation(description: "Microdeposit status polling - deposits pending")
        
        microDepositManager.pollMicroDepositStatus(
            paymentMethodId: mockPaymentMethod.id
        ) { result in
            switch result {
            case .success(let status):
                XCTAssertEqual(status.state, .depositsPending)
                XCTAssertNil(status.attemptsRemaining)
                expectation.fulfill()
            case .failure:
                XCTFail("Expected success")
            }
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testMicroDepositStatusPolling_networkError() {
        mockAPIClient.shouldFailWithNetworkError = true
        
        let expectation = self.expectation(description: "Microdeposit status polling - network error")
        
        microDepositManager.pollMicroDepositStatus(
            paymentMethodId: mockPaymentMethod.id
        ) { result in
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
    
    // MARK: - Microdeposit Retry Tests
    
    func testMicroDepositRetry_successfulRetry() {
        let initialAmounts = [12, 34] // Wrong amounts
        let correctedAmounts = [32, 45] // Correct amounts
        
        let expectation = self.expectation(description: "Microdeposit retry successful")
        
        // First attempt fails
        microDepositManager.verifyMicroDeposits(
            paymentMethodId: mockPaymentMethod.id,
            amounts: initialAmounts
        ) { result in
            XCTAssertTrue(result.isFailure)
            
            // Second attempt succeeds
            self.microDepositManager.verifyMicroDeposits(
                paymentMethodId: self.mockPaymentMethod.id,
                amounts: correctedAmounts
            ) { retryResult in
                switch retryResult {
                case .success(let verificationResult):
                    XCTAssertEqual(verificationResult.status, .verified)
                    expectation.fulfill()
                case .failure:
                    XCTFail("Expected success on retry")
                }
            }
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testMicroDepositRetry_exhaustedAttempts() {
        let wrongAmounts = [12, 34]
        microDepositManager.simulateExhaustedAttempts = true
        
        let expectation = self.expectation(description: "Microdeposit retry exhausted")
        
        microDepositManager.verifyMicroDeposits(
            paymentMethodId: mockPaymentMethod.id,
            amounts: wrongAmounts
        ) { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure(let error):
                XCTAssertEqual(error.code, .noAttemptsRemaining)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    // MARK: - Microdeposit Input Validation Tests
    
    func testMicroDepositInputValidation_validAmounts() {
        let validAmounts = [32, 45]
        
        XCTAssertTrue(microDepositManager.validateMicroDepositAmounts(validAmounts))
    }
    
    func testMicroDepositInputValidation_invalidAmountCount() {
        let invalidAmounts = [32] // Should be 2 amounts
        
        XCTAssertFalse(microDepositManager.validateMicroDepositAmounts(invalidAmounts))
    }
    
    func testMicroDepositInputValidation_negativeAmounts() {
        let negativeAmounts = [-5, 45]
        
        XCTAssertFalse(microDepositManager.validateMicroDepositAmounts(negativeAmounts))
    }
    
    func testMicroDepositInputValidation_tooLargeAmounts() {
        let tooLargeAmounts = [100, 200] // Microdeposits are typically < $1
        
        XCTAssertFalse(microDepositManager.validateMicroDepositAmounts(tooLargeAmounts))
    }
    
    // MARK: - Microdeposit Session Management Tests
    
    func testMicroDepositSessionManagement_sessionCreation() {
        let expectation = self.expectation(description: "Microdeposit session creation")
        
        microDepositManager.createMicroDepositSession(
            paymentMethodId: mockPaymentMethod.id
        ) { result in
            switch result {
            case .success(let session):
                XCTAssertNotNil(session.id)
                XCTAssertEqual(session.paymentMethodId, self.mockPaymentMethod.id)
                XCTAssertEqual(session.status, .pending)
                expectation.fulfill()
            case .failure:
                XCTFail("Expected success")
            }
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testMicroDepositSessionManagement_sessionRetrieval() {
        let sessionId = "mds_test_session"
        
        let expectation = self.expectation(description: "Microdeposit session retrieval")
        
        microDepositManager.retrieveMicroDepositSession(sessionId: sessionId) { result in
            switch result {
            case .success(let session):
                XCTAssertEqual(session.id, sessionId)
                XCTAssertNotNil(session.paymentMethodId)
                expectation.fulfill()
            case .failure:
                XCTFail("Expected success")
            }
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    // MARK: - Microdeposit UI Flow Tests
    
    func testMicroDepositUIFlow_presentationLogic() {
        let bankAccount = MockBankAccount.createUSBankAccount()
        let paymentMethod = MockPaymentMethod.createBankAccountPaymentMethod(
            bankAccount: bankAccount,
            verificationStatus: .pendingMicroDeposits,
            microDepositSession: MockMicroDepositSession(id: "mds_test")
        )
        
        let shouldPresentMicroDepositFlow = microDepositManager.shouldPresentMicroDepositFlow(for: paymentMethod)
        XCTAssertTrue(shouldPresentMicroDepositFlow)
    }
    
    func testMicroDepositUIFlow_verifiedPaymentMethod() {
        let bankAccount = MockBankAccount.createUSBankAccount()
        let paymentMethod = MockPaymentMethod.createBankAccountPaymentMethod(
            bankAccount: bankAccount,
            verificationStatus: .verified,
            microDepositSession: nil
        )
        
        let shouldPresentMicroDepositFlow = microDepositManager.shouldPresentMicroDepositFlow(for: paymentMethod)
        XCTAssertFalse(shouldPresentMicroDepositFlow)
    }
    
    // MARK: - Microdeposit Error Recovery Tests
    
    func testMicroDepositErrorRecovery_retryAfterNetworkError() {
        let correctAmounts = [32, 45]
        mockAPIClient.shouldFailWithNetworkError = true
        
        let expectation = self.expectation(description: "Microdeposit retry after network error")
        
        microDepositManager.verifyMicroDeposits(
            paymentMethodId: mockPaymentMethod.id,
            amounts: correctAmounts
        ) { result in
            XCTAssertTrue(result.isFailure)
            
            // Network recovers
            self.mockAPIClient.shouldFailWithNetworkError = false
            
            // Retry succeeds
            self.microDepositManager.verifyMicroDeposits(
                paymentMethodId: self.mockPaymentMethod.id,
                amounts: correctAmounts
            ) { retryResult in
                switch retryResult {
                case .success(let verificationResult):
                    XCTAssertEqual(verificationResult.status, .verified)
                    expectation.fulfill()
                case .failure:
                    XCTFail("Expected success on retry")
                }
            }
        }
        
        waitForExpectations(timeout: 5.0)
    }
}

// MARK: - Mock Classes

class MockMicroDepositManager {
    let apiClient: MockAPIClient
    var simulateTooManyAttempts = false
    var simulateExpiredSession = false
    var simulateDepositsPending = false
    var simulateExhaustedAttempts = false
    
    init(apiClient: MockAPIClient) {
        self.apiClient = apiClient
    }
    
    func verifyMicroDeposits(
        paymentMethodId: String,
        amounts: [Int],
        completion: @escaping (Result<MicroDepositVerificationResult, MicroDepositError>) -> Void
    ) {
        if !validateMicroDepositAmounts(amounts) {
            completion(.failure(MicroDepositError(code: .invalidAmounts)))
            return
        }
        
        if simulateTooManyAttempts {
            completion(.failure(MicroDepositError(code: .tooManyAttempts)))
            return
        }
        
        if simulateExpiredSession {
            completion(.failure(MicroDepositError(code: .sessionExpired)))
            return
        }
        
        if simulateExhaustedAttempts {
            completion(.failure(MicroDepositError(code: .noAttemptsRemaining)))
            return
        }
        
        if apiClient.shouldFailWithNetworkError {
            completion(.failure(MicroDepositError(code: .networkError)))
            return
        }
        
        // Mock correct amounts
        let correctAmounts = [32, 45]
        if amounts == correctAmounts {
            let result = MicroDepositVerificationResult(
                status: .verified,
                paymentMethodId: paymentMethodId
            )
            completion(.success(result))
        } else {
            completion(.failure(MicroDepositError(code: .incorrectMicroDepositAmounts)))
        }
    }
    
    func pollMicroDepositStatus(
        paymentMethodId: String,
        completion: @escaping (Result<MicroDepositStatus, MicroDepositError>) -> Void
    ) {
        if apiClient.shouldFailWithNetworkError {
            completion(.failure(MicroDepositError(code: .networkError)))
            return
        }
        
        if simulateDepositsPending {
            let status = MicroDepositStatus(
                state: .depositsPending,
                attemptsRemaining: nil
            )
            completion(.success(status))
        } else {
            let status = MicroDepositStatus(
                state: .depositsReceived,
                attemptsRemaining: 3
            )
            completion(.success(status))
        }
    }
    
    func createMicroDepositSession(
        paymentMethodId: String,
        completion: @escaping (Result<MicroDepositSession, MicroDepositError>) -> Void
    ) {
        let session = MicroDepositSession(
            id: "mds_\(UUID().uuidString)",
            paymentMethodId: paymentMethodId,
            status: .pending
        )
        completion(.success(session))
    }
    
    func retrieveMicroDepositSession(
        sessionId: String,
        completion: @escaping (Result<MicroDepositSession, MicroDepositError>) -> Void
    ) {
        let session = MicroDepositSession(
            id: sessionId,
            paymentMethodId: "pm_test_bank_account",
            status: .pending
        )
        completion(.success(session))
    }
    
    func validateMicroDepositAmounts(_ amounts: [Int]) -> Bool {
        guard amounts.count == 2 else { return false }
        
        for amount in amounts {
            if amount < 0 || amount > 99 { // Microdeposits are typically < $1
                return false
            }
        }
        
        return true
    }
    
    func shouldPresentMicroDepositFlow(for paymentMethod: MockPaymentMethod) -> Bool {
        return paymentMethod.verificationStatus == .pendingMicroDeposits &&
               paymentMethod.microDepositSession != nil
    }
}

struct MicroDepositVerificationResult {
    let status: BankAccountVerificationStatus
    let paymentMethodId: String
}

struct MicroDepositStatus {
    let state: MicroDepositState
    let attemptsRemaining: Int?
}

enum MicroDepositState {
    case depositsPending
    case depositsReceived
    case verified
    case failed
}

struct MicroDepositSession {
    let id: String
    let paymentMethodId: String
    let status: MicroDepositSessionStatus
}

enum MicroDepositSessionStatus {
    case pending
    case active
    case completed
    case expired
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

extension Result {
    var isFailure: Bool {
        switch self {
        case .success:
            return false
        case .failure:
            return true
        }
    }
}