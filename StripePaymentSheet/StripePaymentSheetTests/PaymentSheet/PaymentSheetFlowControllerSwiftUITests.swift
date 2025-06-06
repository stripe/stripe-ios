//
//  PaymentSheetFlowControllerSwiftUITests.swift
//  StripePaymentSheetTests
//
//  Tests for SwiftUI integration with @Published paymentOption
//

import Combine
import Foundation
import SwiftUI
import XCTest

@_spi(STP) @testable import StripeCore
@testable import StripeCoreTestUtils
@_spi(STP) @testable import StripePayments
@_spi(STP) @testable import StripePaymentSheet
@testable @_spi(STP) import StripePaymentsTestUtils

import OHHTTPStubs
import OHHTTPStubsSwift

@available(iOS 13.0, *)
class PaymentSheetFlowControllerSwiftUITests: XCTestCase {

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

    // MARK: - SwiftUI Integration Tests

    func testFlowControllerAsObservableObject() {
        var config = PaymentSheet.Configuration()
        config.apiClient = STPAPIClient(publishableKey: "pk_test_123")

        let expectation = XCTestExpectation(description: "FlowController works as ObservableObject")

        PaymentSheet.FlowController.create(
            paymentIntentClientSecret: "pi_test_123_secret_123",
            configuration: config
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let flowController):
                // Test that FlowController can be used as an ObservableObject in SwiftUI
                let viewModel = PaymentViewModel(flowController: flowController)

                // Verify the view model can observe changes
                viewModel.$paymentInfo
                    .sink { paymentInfo in
                        XCTAssertNotNil(paymentInfo)
                        expectation.fulfill()
                    }
                    .store(in: &self.cancellables)

            case .failure(let error):
                XCTFail("FlowController creation failed: \(error)")
            }
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testPaymentOptionInSwiftUIView() {
        var config = PaymentSheet.Configuration()
        config.apiClient = STPAPIClient(publishableKey: "pk_test_123")

        let expectation = XCTestExpectation(description: "Payment option updates in SwiftUI view")

        PaymentSheet.FlowController.create(
            paymentIntentClientSecret: "pi_test_123_secret_123",
            configuration: config
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let flowController):
                let viewModel = PaymentViewModel(flowController: flowController)

                // Simulate SwiftUI view updates
                viewModel.objectWillChange
                    .sink {
                        // This would trigger SwiftUI view updates
                        expectation.fulfill()
                    }
                    .store(in: &self.cancellables)

                // Trigger a payment option change
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

    func testCombineOperatorsWithPaymentOption() {
        var config = PaymentSheet.Configuration()
        config.apiClient = STPAPIClient(publishableKey: "pk_test_123")

        let expectation = XCTestExpectation(description: "Combine operators work with payment option")

        PaymentSheet.FlowController.create(
            paymentIntentClientSecret: "pi_test_123_secret_123",
            configuration: config
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let flowController):
                // Test advanced Combine operators commonly used in SwiftUI
                flowController.$paymentOption
                    .compactMap { $0?.label } // Extract label
                    .removeDuplicates() // Remove duplicates
                    .debounce(for: .milliseconds(100), scheduler: RunLoop.main) // Debounce
                    .sink { label in
                        XCTAssertFalse(label.isEmpty)
                        expectation.fulfill()
                    }
                    .store(in: &self.cancellables)

                // Trigger multiple rapid updates to test debouncing
                DispatchQueue.main.async {
                    let mockVC = MockFlowControllerViewController()
                    for _ in 0..<5 {
                        flowController.flowControllerViewControllerDidUpdatePaymentOption(mockVC)
                    }
                }

            case .failure(let error):
                XCTFail("FlowController creation failed: \(error)")
            }
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testPaymentOptionPublisherWithAsyncAwait() async throws {
        var config = PaymentSheet.Configuration()
        config.apiClient = STPAPIClient(publishableKey: "pk_test_123")

        let flowController = try await withCheckedThrowingContinuation { continuation in
            PaymentSheet.FlowController.create(
                paymentIntentClientSecret: "pi_test_123_secret_123",
                configuration: config
            ) { result in
                continuation.resume(with: result)
            }
        }

        // Test async/await pattern with Combine publishers
        let paymentOption = try await flowController.$paymentOption
            .compactMap { $0 }
            .first()
            .value

        XCTAssertNotNil(paymentOption)
        XCTAssertFalse(paymentOption.label.isEmpty)
    }
}

// MARK: - SwiftUI ViewModel Example

@available(iOS 13.0, *)
private class PaymentViewModel: ObservableObject {
    private let flowController: PaymentSheet.FlowController
    private var cancellables = Set<AnyCancellable>()

    @Published var paymentInfo: String = "No payment method selected"

    init(flowController: PaymentSheet.FlowController) {
        self.flowController = flowController

        // Subscribe to payment option changes
        flowController.$paymentOption
            .map { paymentOption in
                if let paymentOption = paymentOption {
                    return "Payment method: \(paymentOption.label)"
                } else {
                    return "No payment method selected"
                }
            }
            .assign(to: \.paymentInfo, on: self)
            .store(in: &cancellables)
    }
}

// MARK: - Mock SwiftUI View

@available(iOS 13.0, *)
private struct PaymentSelectionView: View {
    @ObservedObject var viewModel: PaymentViewModel

    var body: some View {
        VStack {
            Text(viewModel.paymentInfo)
                .padding()

            Button("Update Payment") {
                // This would trigger payment option updates
            }
        }
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
