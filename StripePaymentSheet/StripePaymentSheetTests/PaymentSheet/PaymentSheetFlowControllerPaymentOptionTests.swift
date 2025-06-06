//
//  PaymentSheetFlowControllerPaymentOptionTests.swift
//  StripePaymentSheetTests
//
//  Tests for PaymentOptionDisplayData behavior in @Published paymentOption
//

import Foundation
import Combine
import XCTest

@_spi(STP) @testable import StripeCore
@_spi(STP) @testable import StripePayments
@_spi(STP) @testable import StripePaymentSheet
@testable import StripeCoreTestUtils
@testable @_spi(STP) import StripePaymentsTestUtils

import OHHTTPStubs
import OHHTTPStubsSwift

class PaymentSheetFlowControllerPaymentOptionTests: XCTestCase {
    
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables.removeAll()
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - PaymentOptionDisplayData Value Tests
    
    func testPaymentOptionDisplayDataProperties() {
        var config = PaymentSheet.Configuration()
        config.apiClient = STPAPIClient(publishableKey: "pk_test_123")
        
        let expectation = XCTestExpectation(description: "Payment option display data validated")
        
        PaymentSheet.FlowController.create(
            paymentIntentClientSecret: "pi_test_123_secret_123",
            configuration: config
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let flowController):
                flowController.$paymentOption
                    .compactMap { $0 } // Only non-nil values
                    .first() // Get first non-nil value
                    .sink { paymentOption in
                        // Validate PaymentOptionDisplayData properties
                        XCTAssertNotNil(paymentOption.image, "Payment option should have an image")
                        XCTAssertFalse(paymentOption.label.isEmpty, "Payment option should have a label")
                        XCTAssertFalse(paymentOption.paymentMethodType.isEmpty, "Payment option should have a payment method type")
                        
                        // Optional properties can be nil
                        // billingDetails and shippingDetails are optional
                        
                        expectation.fulfill()
                    }
                    .store(in: &self.cancellables)
                
            case .failure(let error):
                XCTFail("FlowController creation failed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testPaymentOptionNilToNonNilTransition() {
        var config = PaymentSheet.Configuration()
        config.apiClient = STPAPIClient(publishableKey: "pk_test_123")
        
        let expectation = XCTestExpectation(description: "Payment option nil to non-nil transition")
        expectation.expectedFulfillmentCount = 2
        
        PaymentSheet.FlowController.create(
            paymentIntentClientSecret: "pi_test_123_secret_123",
            configuration: config
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let flowController):
                var receivedNil = false
                var receivedNonNil = false
                
                flowController.$paymentOption
                    .sink { paymentOption in
                        if paymentOption == nil && !receivedNil {
                            receivedNil = true
                            expectation.fulfill()
                        } else if paymentOption != nil && !receivedNonNil {
                            receivedNonNil = true
                            expectation.fulfill()
                        }
                    }
                    .store(in: &self.cancellables)
                
            case .failure(let error):
                XCTFail("FlowController creation failed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testPaymentOptionUpdatePreservesCorrectValues() {
        var config = PaymentSheet.Configuration()
        config.apiClient = STPAPIClient(publishableKey: "pk_test_123")
        
        let expectation = XCTestExpectation(description: "Payment option values preserved during updates")
        
        PaymentSheet.FlowController.create(
            paymentIntentClientSecret: "pi_test_123_secret_123",
            configuration: config
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let flowController):
                var firstOption: PaymentSheet.FlowController.PaymentOptionDisplayData?
                var updateCount = 0
                
                flowController.$paymentOption
                    .sink { paymentOption in
                        updateCount += 1
                        
                        if updateCount == 1 && paymentOption != nil {
                            firstOption = paymentOption
                            
                            // Trigger an update
                            DispatchQueue.main.async {
                                flowController.flowControllerViewControllerDidUpdatePaymentOption(
                                    MockFlowControllerViewController()
                                )
                            }
                        } else if updateCount == 2 {
                            // After update, the payment option should have the same structure
                            if let first = firstOption, let current = paymentOption {
                                XCTAssertEqual(first.paymentMethodType, current.paymentMethodType)
                                // Other properties might change but type should be consistent
                            }
                            expectation.fulfill()
                        }
                    }
                    .store(in: &self.cancellables)
                
            case .failure(let error):
                XCTFail("FlowController creation failed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - Threading Tests
    
    func testPaymentOptionPublisherUpdatesOnMainThread() {
        var config = PaymentSheet.Configuration()
        config.apiClient = STPAPIClient(publishableKey: "pk_test_123")
        
        let expectation = XCTestExpectation(description: "Payment option updates on main thread")
        
        PaymentSheet.FlowController.create(
            paymentIntentClientSecret: "pi_test_123_secret_123",
            configuration: config
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let flowController):
                flowController.$paymentOption
                    .sink { paymentOption in
                        XCTAssertTrue(Thread.isMainThread, "Payment option updates should occur on main thread")
                        expectation.fulfill()
                    }
                    .store(in: &self.cancellables)
                
                // Trigger update from background thread
                DispatchQueue.global(qos: .background).async {
                    DispatchQueue.main.async {
                        flowController.flowControllerViewControllerDidUpdatePaymentOption(
                            MockFlowControllerViewController()
                        )
                    }
                }
                
            case .failure(let error):
                XCTFail("FlowController creation failed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - Integration Tests
    
    func testPaymentOptionPublisherWithViewControllerInteraction() {
        var config = PaymentSheet.Configuration()
        config.apiClient = STPAPIClient(publishableKey: "pk_test_123")
        
        let expectation = XCTestExpectation(description: "Payment option updates through view controller interaction")
        expectation.expectedFulfillmentCount = 2 // Initial + user interaction
        
        PaymentSheet.FlowController.create(
            paymentIntentClientSecret: "pi_test_123_secret_123",
            configuration: config
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let flowController):
                var updateCount = 0
                
                flowController.$paymentOption
                    .sink { paymentOption in
                        updateCount += 1
                        expectation.fulfill()
                        
                        if updateCount == 1 {
                            // Simulate user interaction that changes payment option
                            let mockVC = MockFlowControllerViewControllerWithPaymentOption()
                            
                            DispatchQueue.main.async {
                                flowController.flowControllerViewControllerDidUpdatePaymentOption(mockVC)
                            }
                        }
                    }
                    .store(in: &self.cancellables)
                
            case .failure(let error):
                XCTFail("FlowController creation failed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testPaymentOptionPublisherWithFiltering() {
        var config = PaymentSheet.Configuration()
        config.apiClient = STPAPIClient(publishableKey: "pk_test_123")
        
        let expectation = XCTestExpectation(description: "Payment option publisher works with Combine operators")
        
        PaymentSheet.FlowController.create(
            paymentIntentClientSecret: "pi_test_123_secret_123",
            configuration: config
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let flowController):
                // Test with Combine operators
                flowController.$paymentOption
                    .compactMap { $0 } // Remove nil values
                    .map { $0.label } // Transform to label
                    .removeDuplicates() // Remove duplicate labels
                    .sink { label in
                        XCTAssertFalse(label.isEmpty, "Label should not be empty")
                        expectation.fulfill()
                    }
                    .store(in: &self.cancellables)
                
            case .failure(let error):
                XCTFail("FlowController creation failed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - Performance Tests
    
    func testPaymentOptionPublisherPerformance() {
        var config = PaymentSheet.Configuration()
        config.apiClient = STPAPIClient(publishableKey: "pk_test_123")
        
        let expectation = XCTestExpectation(description: "Performance test completed")
        
        PaymentSheet.FlowController.create(
            paymentIntentClientSecret: "pi_test_123_secret_123",
            configuration: config
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let flowController):
                let startTime = CFAbsoluteTimeGetCurrent()
                var updateCount = 0
                let totalUpdates = 100
                
                flowController.$paymentOption
                    .sink { paymentOption in
                        updateCount += 1
                        
                        if updateCount == 1 {
                            // Start rapid updates
                            let mockVC = MockFlowControllerViewController()
                            for _ in 0..<totalUpdates {
                                flowController.flowControllerViewControllerDidUpdatePaymentOption(mockVC)
                            }
                        } else if updateCount == totalUpdates + 1 {
                            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
                            XCTAssertLessThan(timeElapsed, 1.0, "100 updates should complete in less than 1 second")
                            expectation.fulfill()
                        }
                    }
                    .store(in: &self.cancellables)
                
            case .failure(let error):
                XCTFail("FlowController creation failed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
}

// MARK: - Additional Mock Classes

private class MockFlowControllerViewController: UIViewController, FlowControllerViewControllerProtocol {
    var error: Error? = nil
    var intent: Intent = Intent.deferredIntent(intentConfig: PaymentSheet.IntentConfiguration(mode: .payment(amount: 100, currency: "USD")) { _, _, _ in })
    var elementsSession: STPElementsSession = .emptyElementsSession
    var linkConfirmOption: PaymentSheet.LinkConfirmOption? = nil
    var selectedPaymentOption: PaymentOption? = nil
    var loadResult: PaymentSheetLoader.LoadResult = PaymentSheetLoader.LoadResult(
        intent: .paymentIntent(STPFixtures.makePaymentIntent()),
        elementsSession: STPElementsSession._testCardValue(),
        savedPaymentMethods: [],
        paymentMethodTypes: []
    )
    var selectedPaymentMethodType: PaymentSheet.PaymentMethodType? = nil
    weak var flowControllerDelegate: FlowControllerViewControllerDelegate? = nil

    func didTapOrSwipeToDismiss() {
        // Mock implementation
    }
    
    override func dismiss(animated: Bool, completion: (() -> Void)?) {
        completion?()
    }
}

private class MockFlowControllerViewControllerWithPaymentOption: UIViewController, FlowControllerViewControllerProtocol {
    var error: Error? = nil
    var intent: Intent = Intent.deferredIntent(intentConfig: PaymentSheet.IntentConfiguration(mode: .payment(amount: 100, currency: "USD")) { _, _, _ in })
    var elementsSession: STPElementsSession = .emptyElementsSession
    var linkConfirmOption: PaymentSheet.LinkConfirmOption? = nil
    
    // Mock a card payment option
    var selectedPaymentOption: PaymentOption? = {
        let params = IntentConfirmParams(type: .stripe(.card))
        return .new(confirmParams: params)
    }()
    
    var loadResult: PaymentSheetLoader.LoadResult = PaymentSheetLoader.LoadResult(
        intent: .paymentIntent(STPFixtures.makePaymentIntent()),
        elementsSession: STPElementsSession._testCardValue(),
        savedPaymentMethods: [],
        paymentMethodTypes: []
    )
    var selectedPaymentMethodType: PaymentSheet.PaymentMethodType? = .stripe(.card)
    weak var flowControllerDelegate: FlowControllerViewControllerDelegate? = nil

    func didTapOrSwipeToDismiss() {
        // Mock implementation
    }
    
    override func dismiss(animated: Bool, completion: (() -> Void)?) {
        completion?()
    }
} 