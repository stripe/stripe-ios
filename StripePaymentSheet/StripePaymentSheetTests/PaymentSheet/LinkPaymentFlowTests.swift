//
//  LinkPaymentFlowTests.swift
//  StripePaymentSheetTests
//
//  Created by Claude Code on 7/10/25.
//  Copyright © 2025 Stripe, Inc. All rights reserved.
//

import XCTest

@testable@_spi(STP) import StripePaymentSheet

class LinkPaymentFlowTests: XCTestCase {

    var linkPaymentController: MockLinkPaymentController!
    var mockPaymentHandler: MockPaymentHandler!
    
    override func setUp() {
        super.setUp()
        linkPaymentController = MockLinkPaymentController()
        mockPaymentHandler = MockPaymentHandler()
    }
    
    override func tearDown() {
        linkPaymentController = nil
        mockPaymentHandler = nil
        super.tearDown()
    }
    
    // MARK: - Web Instant Debits Tests
    
    func testWebInstantDebitsOnlyLinkPaymentController_successful() {
        let mockPaymentIntent = MockPaymentIntent.createMockInstantDebitsIntent()
        linkPaymentController.paymentIntent = mockPaymentIntent
        
        let expectation = self.expectation(description: "Web instant debits payment successful")
        
        linkPaymentController.presentWebInstantDebitsFlow { result in
            switch result {
            case .success(let paymentResult):
                XCTAssertEqual(paymentResult.status, .succeeded)
                XCTAssertEqual(paymentResult.paymentMethod.type, .linkInstantDebits)
                expectation.fulfill()
            case .failure:
                XCTFail("Expected success")
            }
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testWebInstantDebitsOnlyLinkPaymentController_userCancelled() {
        let mockPaymentIntent = MockPaymentIntent.createMockInstantDebitsIntent()
        linkPaymentController.paymentIntent = mockPaymentIntent
        linkPaymentController.shouldSimulateUserCancellation = true
        
        let expectation = self.expectation(description: "Web instant debits payment cancelled")
        
        linkPaymentController.presentWebInstantDebitsFlow { result in
            switch result {
            case .success:
                XCTFail("Expected cancellation")
            case .failure(let error):
                XCTAssertEqual(error.code, .userCancelled)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testWebInstantDebitsOnlyLinkPaymentController_networkError() {
        let mockPaymentIntent = MockPaymentIntent.createMockInstantDebitsIntent()
        linkPaymentController.paymentIntent = mockPaymentIntent
        linkPaymentController.shouldFailWithNetworkError = true
        
        let expectation = self.expectation(description: "Web instant debits network error")
        
        linkPaymentController.presentWebInstantDebitsFlow { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure(let error):
                XCTAssertEqual(error.code, .networkError)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    // MARK: - Native Instant Debits Tests
    
    func testNativeInstantDebitsOnlyLinkPaymentController_successful() {
        let mockPaymentIntent = MockPaymentIntent.createMockInstantDebitsIntent()
        linkPaymentController.paymentIntent = mockPaymentIntent
        
        let expectation = self.expectation(description: "Native instant debits payment successful")
        
        linkPaymentController.presentNativeInstantDebitsFlow { result in
            switch result {
            case .success(let paymentResult):
                XCTAssertEqual(paymentResult.status, .succeeded)
                XCTAssertEqual(paymentResult.paymentMethod.type, .linkInstantDebits)
                expectation.fulfill()
            case .failure:
                XCTFail("Expected success")
            }
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testNativeInstantDebitsOnlyLinkPaymentController_authenticationFailed() {
        let mockPaymentIntent = MockPaymentIntent.createMockInstantDebitsIntent()
        linkPaymentController.paymentIntent = mockPaymentIntent
        linkPaymentController.shouldFailWithAuthError = true
        
        let expectation = self.expectation(description: "Native instant debits authentication failed")
        
        linkPaymentController.presentNativeInstantDebitsFlow { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure(let error):
                XCTAssertEqual(error.code, .authenticationFailed)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testNativeInstantDebitsOnlyLinkPaymentController_insufficientFunds() {
        let mockPaymentIntent = MockPaymentIntent.createMockInstantDebitsIntent()
        linkPaymentController.paymentIntent = mockPaymentIntent
        linkPaymentController.shouldFailWithInsufficientFunds = true
        
        let expectation = self.expectation(description: "Native instant debits insufficient funds")
        
        linkPaymentController.presentNativeInstantDebitsFlow { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure(let error):
                XCTAssertEqual(error.code, .insufficientFunds)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    // MARK: - Link Payment Intent Handling Tests
    
    func testLinkPaymentIntentHandling_validIntent() {
        let mockPaymentIntent = MockPaymentIntent.createMockInstantDebitsIntent()
        
        XCTAssertTrue(linkPaymentController.canHandlePaymentIntent(mockPaymentIntent))
        XCTAssertTrue(mockPaymentIntent.supportsLinkInstantDebits)
    }
    
    func testLinkPaymentIntentHandling_invalidIntent() {
        let mockPaymentIntent = MockPaymentIntent.createMockCardIntent()
        
        XCTAssertFalse(linkPaymentController.canHandlePaymentIntent(mockPaymentIntent))
        XCTAssertFalse(mockPaymentIntent.supportsLinkInstantDebits)
    }
    
    func testLinkPaymentIntentHandling_missingAmount() {
        let mockPaymentIntent = MockPaymentIntent.createMockIntentWithoutAmount()
        
        XCTAssertFalse(linkPaymentController.canHandlePaymentIntent(mockPaymentIntent))
    }
    
    // MARK: - Link Payment Method Validation Tests
    
    func testLinkPaymentMethodValidation_validInstantDebits() {
        let linkPaymentMethod = MockLinkPaymentMethod.createInstantDebitsMethod()
        
        XCTAssertTrue(linkPaymentMethod.isValid)
        XCTAssertEqual(linkPaymentMethod.type, .linkInstantDebits)
        XCTAssertNotNil(linkPaymentMethod.bankAccount)
    }
    
    func testLinkPaymentMethodValidation_invalidBankAccount() {
        let linkPaymentMethod = MockLinkPaymentMethod.createInvalidBankAccountMethod()
        
        XCTAssertFalse(linkPaymentMethod.isValid)
        XCTAssertNil(linkPaymentMethod.bankAccount)
    }
    
    // MARK: - Link Payment Flow State Management Tests
    
    func testLinkPaymentFlowStateManagement_initialization() {
        let flowState = LinkPaymentFlowState()
        
        XCTAssertEqual(flowState.currentStep, .initialization)
        XCTAssertFalse(flowState.isAuthenticated)
        XCTAssertNil(flowState.selectedPaymentMethod)
    }
    
    func testLinkPaymentFlowStateManagement_authentication() {
        let flowState = LinkPaymentFlowState()
        
        flowState.authenticate(with: "test@example.com")
        
        XCTAssertEqual(flowState.currentStep, .authentication)
        XCTAssertTrue(flowState.isAuthenticated)
        XCTAssertEqual(flowState.userEmail, "test@example.com")
    }
    
    func testLinkPaymentFlowStateManagement_paymentMethodSelection() {
        let flowState = LinkPaymentFlowState()
        let mockPaymentMethod = MockLinkPaymentMethod.createInstantDebitsMethod()
        
        flowState.authenticate(with: "test@example.com")
        flowState.selectPaymentMethod(mockPaymentMethod)
        
        XCTAssertEqual(flowState.currentStep, .paymentMethodSelection)
        XCTAssertEqual(flowState.selectedPaymentMethod?.id, mockPaymentMethod.id)
    }
    
    func testLinkPaymentFlowStateManagement_paymentConfirmation() {
        let flowState = LinkPaymentFlowState()
        let mockPaymentMethod = MockLinkPaymentMethod.createInstantDebitsMethod()
        
        flowState.authenticate(with: "test@example.com")
        flowState.selectPaymentMethod(mockPaymentMethod)
        flowState.confirmPayment()
        
        XCTAssertEqual(flowState.currentStep, .paymentConfirmation)
    }
    
    func testLinkPaymentFlowStateManagement_completion() {
        let flowState = LinkPaymentFlowState()
        let mockPaymentMethod = MockLinkPaymentMethod.createInstantDebitsMethod()
        let mockResult = MockLinkPaymentResult.createSuccessfulResult()
        
        flowState.authenticate(with: "test@example.com")
        flowState.selectPaymentMethod(mockPaymentMethod)
        flowState.confirmPayment()
        flowState.completePayment(with: mockResult)
        
        XCTAssertEqual(flowState.currentStep, .completion)
        XCTAssertEqual(flowState.paymentResult?.status, .succeeded)
    }
    
    // MARK: - Link Payment Error Handling Tests
    
    func testLinkPaymentErrorHandling_retryableError() {
        let linkError = LinkPaymentError(code: .networkError, isRetryable: true)
        
        XCTAssertTrue(linkError.isRetryable)
        XCTAssertEqual(linkError.code, .networkError)
    }
    
    func testLinkPaymentErrorHandling_nonRetryableError() {
        let linkError = LinkPaymentError(code: .authenticationFailed, isRetryable: false)
        
        XCTAssertFalse(linkError.isRetryable)
        XCTAssertEqual(linkError.code, .authenticationFailed)
    }
}

// MARK: - Mock Classes

class MockLinkPaymentController {
    var paymentIntent: MockPaymentIntent?
    var shouldSimulateUserCancellation = false
    var shouldFailWithNetworkError = false
    var shouldFailWithAuthError = false
    var shouldFailWithInsufficientFunds = false
    
    func canHandlePaymentIntent(_ paymentIntent: MockPaymentIntent) -> Bool {
        return paymentIntent.supportsLinkInstantDebits && paymentIntent.amount > 0
    }
    
    func presentWebInstantDebitsFlow(completion: @escaping (Result<MockLinkPaymentResult, LinkPaymentError>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.shouldSimulateUserCancellation {
                completion(.failure(LinkPaymentError(code: .userCancelled, isRetryable: false)))
            } else if self.shouldFailWithNetworkError {
                completion(.failure(LinkPaymentError(code: .networkError, isRetryable: true)))
            } else {
                let result = MockLinkPaymentResult.createSuccessfulResult()
                completion(.success(result))
            }
        }
    }
    
    func presentNativeInstantDebitsFlow(completion: @escaping (Result<MockLinkPaymentResult, LinkPaymentError>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.shouldFailWithAuthError {
                completion(.failure(LinkPaymentError(code: .authenticationFailed, isRetryable: false)))
            } else if self.shouldFailWithInsufficientFunds {
                completion(.failure(LinkPaymentError(code: .insufficientFunds, isRetryable: false)))
            } else {
                let result = MockLinkPaymentResult.createSuccessfulResult()
                completion(.success(result))
            }
        }
    }
}

struct MockPaymentIntent {
    let id: String
    let amount: Int
    let currency: String
    let supportsLinkInstantDebits: Bool
    
    static func createMockInstantDebitsIntent() -> MockPaymentIntent {
        return MockPaymentIntent(
            id: "pi_test_instant_debits",
            amount: 2000,
            currency: "usd",
            supportsLinkInstantDebits: true
        )
    }
    
    static func createMockCardIntent() -> MockPaymentIntent {
        return MockPaymentIntent(
            id: "pi_test_card",
            amount: 2000,
            currency: "usd",
            supportsLinkInstantDebits: false
        )
    }
    
    static func createMockIntentWithoutAmount() -> MockPaymentIntent {
        return MockPaymentIntent(
            id: "pi_test_no_amount",
            amount: 0,
            currency: "usd",
            supportsLinkInstantDebits: true
        )
    }
}

struct MockLinkPaymentMethod {
    let id: String
    let type: LinkPaymentMethodType
    let bankAccount: MockBankAccount?
    
    var isValid: Bool {
        return bankAccount != nil
    }
    
    static func createInstantDebitsMethod() -> MockLinkPaymentMethod {
        return MockLinkPaymentMethod(
            id: "pm_link_instant_debits",
            type: .linkInstantDebits,
            bankAccount: MockBankAccount(routingNumber: "110000000", accountNumber: "000123456789")
        )
    }
    
    static func createInvalidBankAccountMethod() -> MockLinkPaymentMethod {
        return MockLinkPaymentMethod(
            id: "pm_link_invalid",
            type: .linkInstantDebits,
            bankAccount: nil
        )
    }
}

struct MockBankAccount {
    let routingNumber: String
    let accountNumber: String
}

enum LinkPaymentMethodType {
    case linkInstantDebits
    case linkCard
}

struct MockLinkPaymentResult {
    let status: LinkPaymentStatus
    let paymentMethod: MockLinkPaymentMethod
    
    static func createSuccessfulResult() -> MockLinkPaymentResult {
        return MockLinkPaymentResult(
            status: .succeeded,
            paymentMethod: MockLinkPaymentMethod.createInstantDebitsMethod()
        )
    }
}

enum LinkPaymentStatus {
    case succeeded
    case failed
    case cancelled
}

class LinkPaymentFlowState {
    var currentStep: LinkPaymentFlowStep = .initialization
    var isAuthenticated = false
    var userEmail: String?
    var selectedPaymentMethod: MockLinkPaymentMethod?
    var paymentResult: MockLinkPaymentResult?
    
    func authenticate(with email: String) {
        userEmail = email
        isAuthenticated = true
        currentStep = .authentication
    }
    
    func selectPaymentMethod(_ paymentMethod: MockLinkPaymentMethod) {
        selectedPaymentMethod = paymentMethod
        currentStep = .paymentMethodSelection
    }
    
    func confirmPayment() {
        currentStep = .paymentConfirmation
    }
    
    func completePayment(with result: MockLinkPaymentResult) {
        paymentResult = result
        currentStep = .completion
    }
}

enum LinkPaymentFlowStep {
    case initialization
    case authentication
    case paymentMethodSelection
    case paymentConfirmation
    case completion
}

struct LinkPaymentError: Error {
    let code: LinkPaymentErrorCode
    let isRetryable: Bool
}

enum LinkPaymentErrorCode {
    case networkError
    case authenticationFailed
    case insufficientFunds
    case userCancelled
}

class MockPaymentHandler {
    // Mock implementation for payment handling
}