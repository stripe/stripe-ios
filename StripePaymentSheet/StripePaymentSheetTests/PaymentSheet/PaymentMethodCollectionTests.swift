//
//  PaymentMethodCollectionTests.swift
//  StripePaymentSheetTests
//
//  Created by Claude Code on 7/10/25.
//  Copyright © 2025 Stripe, Inc. All rights reserved.
//

import XCTest

@testable@_spi(STP) import StripePaymentSheet

class PaymentMethodCollectionTests: XCTestCase {

    var paymentMethodManager: MockPaymentMethodManager!
    var customerSessionManager: MockCustomerSessionManager!
    
    override func setUp() {
        super.setUp()
        paymentMethodManager = MockPaymentMethodManager()
        customerSessionManager = MockCustomerSessionManager()
    }
    
    override func tearDown() {
        paymentMethodManager = nil
        customerSessionManager = nil
        super.tearDown()
    }
    
    // MARK: - Add Payment Method Tests
    
    func testAddPaymentMethod_successful() {
        let mockCard = MockPaymentMethod.createMockCard()
        
        let expectation = self.expectation(description: "Payment method added")
        
        paymentMethodManager.addPaymentMethod(mockCard) { result in
            switch result {
            case .success(let paymentMethod):
                XCTAssertEqual(paymentMethod.id, mockCard.id)
                XCTAssertEqual(paymentMethod.type, .card)
                expectation.fulfill()
            case .failure:
                XCTFail("Expected success")
            }
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testAddPaymentMethod_duplicate() {
        let mockCard = MockPaymentMethod.createMockCard()
        
        // Add the same card twice
        paymentMethodManager.addPaymentMethod(mockCard) { _ in }
        
        let expectation = self.expectation(description: "Duplicate payment method rejected")
        
        paymentMethodManager.addPaymentMethod(mockCard) { result in
            switch result {
            case .success:
                XCTFail("Expected failure for duplicate")
            case .failure(let error):
                XCTAssertEqual(error.code, .duplicatePaymentMethod)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testAddPaymentMethod_networkError() {
        let mockCard = MockPaymentMethod.createMockCard()
        paymentMethodManager.shouldFailWithNetworkError = true
        
        let expectation = self.expectation(description: "Network error handled")
        
        paymentMethodManager.addPaymentMethod(mockCard) { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure(let error):
                XCTAssertEqual(error.code, .networkError)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    // MARK: - Remove Payment Method Tests
    
    func testRemovePaymentMethod_successful() {
        let mockCard = MockPaymentMethod.createMockCard()
        
        // First add a payment method
        paymentMethodManager.addPaymentMethod(mockCard) { _ in }
        
        let expectation = self.expectation(description: "Payment method removed")
        
        paymentMethodManager.removePaymentMethod(mockCard.id) { result in
            switch result {
            case .success:
                XCTAssertFalse(self.paymentMethodManager.paymentMethods.contains { $0.id == mockCard.id })
                expectation.fulfill()
            case .failure:
                XCTFail("Expected success")
            }
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testRemovePaymentMethod_notFound() {
        let nonExistentId = "pm_nonexistent"
        
        let expectation = self.expectation(description: "Payment method not found")
        
        paymentMethodManager.removePaymentMethod(nonExistentId) { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure(let error):
                XCTAssertEqual(error.code, .paymentMethodNotFound)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testRemovePaymentMethod_beforeConfirming() {
        let mockCard = MockPaymentMethod.createMockCard()
        
        // Add payment method
        paymentMethodManager.addPaymentMethod(mockCard) { _ in }
        
        // Remove before confirming
        let expectation = self.expectation(description: "Payment method removed before confirming")
        
        paymentMethodManager.removePaymentMethod(mockCard.id) { result in
            switch result {
            case .success:
                XCTAssertEqual(self.paymentMethodManager.paymentMethods.count, 0)
                expectation.fulfill()
            case .failure:
                XCTFail("Expected success")
            }
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    // MARK: - Multiple Payment Methods Tests
    
    func testAddTwoPaymentMethods_successful() {
        let mockCard1 = MockPaymentMethod.createMockCard(id: "pm_card_1")
        let mockCard2 = MockPaymentMethod.createMockCard(id: "pm_card_2")
        
        let expectation = self.expectation(description: "Two payment methods added")
        expectation.expectedFulfillmentCount = 2
        
        paymentMethodManager.addPaymentMethod(mockCard1) { result in
            XCTAssertTrue(result.isSuccess)
            expectation.fulfill()
        }
        
        paymentMethodManager.addPaymentMethod(mockCard2) { result in
            XCTAssertTrue(result.isSuccess)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
        
        XCTAssertEqual(paymentMethodManager.paymentMethods.count, 2)
    }
    
    func testRemoveTwoPaymentMethods_successful() {
        let mockCard1 = MockPaymentMethod.createMockCard(id: "pm_card_1")
        let mockCard2 = MockPaymentMethod.createMockCard(id: "pm_card_2")
        
        // Add two payment methods
        paymentMethodManager.addPaymentMethod(mockCard1) { _ in }
        paymentMethodManager.addPaymentMethod(mockCard2) { _ in }
        
        let expectation = self.expectation(description: "Two payment methods removed")
        expectation.expectedFulfillmentCount = 2
        
        paymentMethodManager.removePaymentMethod(mockCard1.id) { result in
            XCTAssertTrue(result.isSuccess)
            expectation.fulfill()
        }
        
        paymentMethodManager.removePaymentMethod(mockCard2.id) { result in
            XCTAssertTrue(result.isSuccess)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
        
        XCTAssertEqual(paymentMethodManager.paymentMethods.count, 0)
    }
    
    // MARK: - Customer Session Tests
    
    func testRemoveCardPaymentMethod_customerSession() {
        let mockCard = MockPaymentMethod.createMockCard()
        
        // Add payment method through customer session
        customerSessionManager.addPaymentMethod(mockCard) { _ in }
        
        let expectation = self.expectation(description: "Card payment method removed from customer session")
        
        customerSessionManager.removePaymentMethod(mockCard.id) { result in
            switch result {
            case .success:
                XCTAssertFalse(self.customerSessionManager.savedPaymentMethods.contains { $0.id == mockCard.id })
                expectation.fulfill()
            case .failure:
                XCTFail("Expected success")
            }
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testRemoveSepaPaymentMethod_customerSession() {
        let mockSepa = MockPaymentMethod.createMockSepa()
        
        // Add SEPA payment method through customer session
        customerSessionManager.addPaymentMethod(mockSepa) { _ in }
        
        let expectation = self.expectation(description: "SEPA payment method removed from customer session")
        
        customerSessionManager.removePaymentMethod(mockSepa.id) { result in
            switch result {
            case .success:
                XCTAssertFalse(self.customerSessionManager.savedPaymentMethods.contains { $0.id == mockSepa.id })
                expectation.fulfill()
            case .failure:
                XCTFail("Expected success")
            }
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    // MARK: - Payment Method State Management Tests
    
    func testPaymentMethodStateConsistency() {
        let mockCard1 = MockPaymentMethod.createMockCard(id: "pm_card_1")
        let mockCard2 = MockPaymentMethod.createMockCard(id: "pm_card_2")
        
        // Add first card
        paymentMethodManager.addPaymentMethod(mockCard1) { _ in }
        XCTAssertEqual(paymentMethodManager.paymentMethods.count, 1)
        
        // Add second card
        paymentMethodManager.addPaymentMethod(mockCard2) { _ in }
        XCTAssertEqual(paymentMethodManager.paymentMethods.count, 2)
        
        // Remove first card
        paymentMethodManager.removePaymentMethod(mockCard1.id) { _ in }
        XCTAssertEqual(paymentMethodManager.paymentMethods.count, 1)
        XCTAssertEqual(paymentMethodManager.paymentMethods.first?.id, mockCard2.id)
        
        // Remove second card
        paymentMethodManager.removePaymentMethod(mockCard2.id) { _ in }
        XCTAssertEqual(paymentMethodManager.paymentMethods.count, 0)
    }
    
    func testPaymentMethodValidation() {
        let invalidCard = MockPaymentMethod.createInvalidCard()
        
        let expectation = self.expectation(description: "Invalid payment method rejected")
        
        paymentMethodManager.addPaymentMethod(invalidCard) { result in
            switch result {
            case .success:
                XCTFail("Expected failure for invalid card")
            case .failure(let error):
                XCTAssertEqual(error.code, .invalidPaymentMethod)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1.0)
    }
}

// MARK: - Mock Classes

class MockPaymentMethodManager {
    var paymentMethods: [MockPaymentMethod] = []
    var shouldFailWithNetworkError = false
    
    func addPaymentMethod(_ paymentMethod: MockPaymentMethod, completion: @escaping (Result<MockPaymentMethod, PaymentMethodError>) -> Void) {
        if shouldFailWithNetworkError {
            completion(.failure(PaymentMethodError(code: .networkError)))
            return
        }
        
        if !paymentMethod.isValid {
            completion(.failure(PaymentMethodError(code: .invalidPaymentMethod)))
            return
        }
        
        if paymentMethods.contains(where: { $0.id == paymentMethod.id }) {
            completion(.failure(PaymentMethodError(code: .duplicatePaymentMethod)))
            return
        }
        
        paymentMethods.append(paymentMethod)
        completion(.success(paymentMethod))
    }
    
    func removePaymentMethod(_ paymentMethodId: String, completion: @escaping (Result<Void, PaymentMethodError>) -> Void) {
        if let index = paymentMethods.firstIndex(where: { $0.id == paymentMethodId }) {
            paymentMethods.remove(at: index)
            completion(.success(()))
        } else {
            completion(.failure(PaymentMethodError(code: .paymentMethodNotFound)))
        }
    }
}

class MockCustomerSessionManager {
    var savedPaymentMethods: [MockPaymentMethod] = []
    
    func addPaymentMethod(_ paymentMethod: MockPaymentMethod, completion: @escaping (Result<MockPaymentMethod, PaymentMethodError>) -> Void) {
        savedPaymentMethods.append(paymentMethod)
        completion(.success(paymentMethod))
    }
    
    func removePaymentMethod(_ paymentMethodId: String, completion: @escaping (Result<Void, PaymentMethodError>) -> Void) {
        if let index = savedPaymentMethods.firstIndex(where: { $0.id == paymentMethodId }) {
            savedPaymentMethods.remove(at: index)
            completion(.success(()))
        } else {
            completion(.failure(PaymentMethodError(code: .paymentMethodNotFound)))
        }
    }
}

struct MockPaymentMethod {
    let id: String
    let type: PaymentMethodType
    let isValid: Bool
    
    static func createMockCard(id: String = "pm_card_mock") -> MockPaymentMethod {
        return MockPaymentMethod(id: id, type: .card, isValid: true)
    }
    
    static func createMockSepa(id: String = "pm_sepa_mock") -> MockPaymentMethod {
        return MockPaymentMethod(id: id, type: .sepaDebit, isValid: true)
    }
    
    static func createInvalidCard() -> MockPaymentMethod {
        return MockPaymentMethod(id: "pm_invalid", type: .card, isValid: false)
    }
}

enum PaymentMethodType {
    case card
    case sepaDebit
    case usBankAccount
}

struct PaymentMethodError: Error {
    let code: PaymentMethodErrorCode
}

enum PaymentMethodErrorCode {
    case networkError
    case duplicatePaymentMethod
    case paymentMethodNotFound
    case invalidPaymentMethod
}

extension Result {
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
}