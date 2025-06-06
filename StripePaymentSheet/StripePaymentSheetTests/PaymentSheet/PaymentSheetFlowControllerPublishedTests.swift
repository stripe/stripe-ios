//
//  PaymentSheetFlowControllerPublishedTests.swift
//  StripePaymentSheetTests
//
//  Tests for @Published paymentOption functionality in PaymentSheet.FlowController
//

import Combine
import Foundation
import XCTest

@_spi(STP) @testable import StripeCore
@testable import StripeCoreTestUtils
@_spi(STP) @testable import StripePayments
@_spi(STP) @testable import StripePaymentSheet
@testable @_spi(STP) import StripePaymentsTestUtils

import OHHTTPStubs
import OHHTTPStubsSwift

class PaymentSheetFlowControllerPublishedTests: XCTestCase {

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

    // MARK: - Basic @Published Tests

    func testPaymentOptionIsPublished() {
        // Test that paymentOption conforms to @Published
        var config = PaymentSheet.Configuration()
        config.apiClient = STPAPIClient(publishableKey: "pk_test_123")

        let expectation = XCTestExpectation(description: "FlowController created")

        PaymentSheet.FlowController.create(
            paymentIntentClientSecret: "pi_test_123_secret_123",
            configuration: config
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let flowController):
                // Verify that the flowController conforms to ObservableObject
                XCTAssertTrue(flowController is ObservableObject)

                // Verify we can access the published property
                let publisher = flowController.$paymentOption
                XCTAssertNotNil(publisher)

                expectation.fulfill()
            case .failure(let error):
                XCTFail("FlowController creation failed: \(error)")
            }
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testPaymentOptionPublisherEmitsInitialValue() {
        var config = PaymentSheet.Configuration()
        config.apiClient = STPAPIClient(publishableKey: "pk_test_123")

        let expectation = XCTestExpectation(description: "Initial value received")

        PaymentSheet.FlowController.create(
            paymentIntentClientSecret: "pi_test_123_secret_123",
            configuration: config
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let flowController):
                // Subscribe to payment option changes
                flowController.$paymentOption
                    .sink { _ in
                        // Should receive at least one value (could be nil or non-nil)
                        expectation.fulfill()
                    }
                    .store(in: &self.cancellables)

            case .failure(let error):
                XCTFail("FlowController creation failed: \(error)")
            }
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testMultipleSubscribersReceiveUpdates() {
        var config = PaymentSheet.Configuration()
        config.apiClient = STPAPIClient(publishableKey: "pk_test_123")

        let expectation1 = XCTestExpectation(description: "Subscriber 1 received update")
        let expectation2 = XCTestExpectation(description: "Subscriber 2 received update")

        PaymentSheet.FlowController.create(
            paymentIntentClientSecret: "pi_test_123_secret_123",
            configuration: config
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let flowController):
                // First subscriber
                flowController.$paymentOption
                    .sink { _ in
                        expectation1.fulfill()
                    }
                    .store(in: &self.cancellables)

                // Second subscriber
                flowController.$paymentOption
                    .sink { _ in
                        expectation2.fulfill()
                    }
                    .store(in: &self.cancellables)

            case .failure(let error):
                XCTFail("FlowController creation failed: \(error)")
            }
        }

        wait(for: [expectation1, expectation2], timeout: 10.0)
    }

    // MARK: - Payment Option Update Tests

    func testPaymentOptionUpdatesOnViewControllerDelegate() {
        var config = PaymentSheet.Configuration()
        config.apiClient = STPAPIClient(publishableKey: "pk_test_123")

        let expectation = XCTestExpectation(description: "Payment option updated")
        expectation.expectedFulfillmentCount = 2 // Initial + update

        PaymentSheet.FlowController.create(
            paymentIntentClientSecret: "pi_test_123_secret_123",
            configuration: config
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let flowController):
                var updateCount = 0

                flowController.$paymentOption
                    .sink { _ in
                        updateCount += 1
                        if updateCount == 1 {
                            // Initial value
                            expectation.fulfill()

                            // Simulate a delegate call that should trigger an update
                            DispatchQueue.main.async {
                                flowController.flowControllerViewControllerDidUpdatePaymentOption(
                                    MockFlowControllerViewController()
                                )
                            }
                        } else if updateCount == 2 {
                            // Updated value
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

    func testPaymentOptionUpdatesOnIntentConfigurationUpdate() {
        var config = PaymentSheet.Configuration()
        config.apiClient = STPAPIClient(publishableKey: "pk_test_123")

        let intentConfig = PaymentSheet.IntentConfiguration(
            mode: .payment(amount: 1000, currency: "USD")
        ) { _, _, completion in
            completion(.success("test"))
        }

        let expectation = XCTestExpectation(description: "Payment option updated after intent update")
        expectation.expectedFulfillmentCount = 2 // Initial + after update

        PaymentSheet.FlowController.create(
            intentConfiguration: intentConfig,
            configuration: config
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let flowController):
                var updateCount = 0

                flowController.$paymentOption
                    .sink { _ in
                        updateCount += 1
                        if updateCount == 1 {
                            expectation.fulfill()

                            // Update the intent configuration
                            let newIntentConfig = PaymentSheet.IntentConfiguration(
                                mode: .payment(amount: 2000, currency: "USD")
                            ) { _, _, completion in
                                completion(.success("test"))
                            }

                            flowController.update(intentConfiguration: newIntentConfig) { _ in
                                // Update completion - should trigger another publisher update
                            }
                        } else if updateCount == 2 {
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

    // MARK: - Edge Case Tests

    func testPaymentOptionPublisherDoesNotRetainFlowController() {
        weak var weakFlowController: PaymentSheet.FlowController?

        let expectation = XCTestExpectation(description: "FlowController deallocated")

        var config = PaymentSheet.Configuration()
        config.apiClient = STPAPIClient(publishableKey: "pk_test_123")

        PaymentSheet.FlowController.create(
            paymentIntentClientSecret: "pi_test_123_secret_123",
            configuration: config
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let flowController):
                weakFlowController = flowController

                // Subscribe to updates but don't store the flowController strongly
                flowController.$paymentOption
                    .sink { _ in
                        // This subscription should not prevent deallocation
                    }
                    .store(in: &self.cancellables)

                // Clear the strong reference
                DispatchQueue.main.async {
                    // At this point, flowController should be deallocated
                    // since we're not holding a strong reference
                    DispatchQueue.main.async {
                        if weakFlowController == nil {
                            expectation.fulfill()
                        }
                    }
                }

            case .failure(let error):
                XCTFail("FlowController creation failed: \(error)")
            }
        }

        wait(for: [expectation], timeout: 5.0)
    }

    func testPaymentOptionPublisherWithRapidUpdates() {
        var config = PaymentSheet.Configuration()
        config.apiClient = STPAPIClient(publishableKey: "pk_test_123")

        let expectation = XCTestExpectation(description: "Multiple rapid updates received")
        expectation.expectedFulfillmentCount = 5 // Initial + 4 rapid updates

        PaymentSheet.FlowController.create(
            paymentIntentClientSecret: "pi_test_123_secret_123",
            configuration: config
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let flowController):
                var updateCount = 0

                flowController.$paymentOption
                    .sink { _ in
                        updateCount += 1
                        expectation.fulfill()

                        if updateCount == 1 {
                            // After receiving initial value, send rapid updates
                            DispatchQueue.main.async {
                                let mockVC = MockFlowControllerViewController()
                                for _ in 0..<4 {
                                    flowController.flowControllerViewControllerDidUpdatePaymentOption(mockVC)
                                }
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

    // MARK: - SwiftUI Integration Test

    func testPaymentOptionWorksWithSwiftUIObjectWillChange() {
        var config = PaymentSheet.Configuration()
        config.apiClient = STPAPIClient(publishableKey: "pk_test_123")

        let expectation = XCTestExpectation(description: "ObjectWillChange publisher triggered")

        PaymentSheet.FlowController.create(
            paymentIntentClientSecret: "pi_test_123_secret_123",
            configuration: config
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let flowController):
                // Subscribe to objectWillChange (SwiftUI integration)
                flowController.objectWillChange
                    .sink {
                        expectation.fulfill()
                    }
                    .store(in: &self.cancellables)

                // Trigger an update that should fire objectWillChange
                DispatchQueue.main.async {
                    flowController.flowControllerViewControllerDidUpdatePaymentOption(
                        MockFlowControllerViewController()
                    )
                }

            case .failure(let error):
                XCTFail("FlowController creation failed: \(error)")
            }
        }

        wait(for: [expectation], timeout: 10.0)
    }
}

// MARK: - Mock Classes

private class MockFlowControllerViewController: UIViewController, FlowControllerViewControllerProtocol {
    var error: Error?
    var intent: Intent = Intent.deferredIntent(intentConfig: PaymentSheet.IntentConfiguration(mode: .payment(amount: 100, currency: "USD")) { _, _, _ in })
    var elementsSession: STPElementsSession = .emptyElementsSession
    var linkConfirmOption: PaymentSheet.LinkConfirmOption?
    var selectedPaymentOption: PaymentOption?
    var loadResult: PaymentSheetLoader.LoadResult = PaymentSheetLoader.LoadResult(
        intent: .paymentIntent(STPFixtures.makePaymentIntent()),
        elementsSession: STPElementsSession._testCardValue(),
        savedPaymentMethods: [],
        paymentMethodTypes: []
    )
    var selectedPaymentMethodType: PaymentSheet.PaymentMethodType?
    weak var flowControllerDelegate: FlowControllerViewControllerDelegate?

    func didTapOrSwipeToDismiss() {
        // Mock implementation
    }

    override func dismiss(animated: Bool, completion: (() -> Void)?) {
        completion?()
    }
}
