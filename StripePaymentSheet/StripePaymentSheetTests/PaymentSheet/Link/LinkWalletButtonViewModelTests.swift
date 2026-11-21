//
//  LinkWalletButtonViewModelTests.swift
//  StripePaymentSheetTests
//

import Combine
@_spi(InternalOnlyAPI) import StripeCore
import StripePayments
@_spi(InternalOnlyAPI) @_spi(LinkControllerPreview) @testable import StripePaymentSheet
@testable import StripePaymentsTestUtils
import UIKit
import XCTest

@MainActor
final class LinkWalletButtonViewModelTests: XCTestCase {

    func testForwardsCustomerDetailsToController() {
        // Given a view model
        let linkController = makeController()
        let viewModel = LinkWalletButtonViewModel(linkController: linkController)

        // When the merchant sets the customer's details
        viewModel.email = "jane.diaz@example.com"
        viewModel.phoneNumber = "+15555555555"

        // Then the controller, which the button reads from, has them
        XCTAssertEqual(linkController.email, "jane.diaz@example.com")
        XCTAssertEqual(linkController.phoneNumber, "+15555555555")
        XCTAssertEqual(viewModel.email, "jane.diaz@example.com")
        XCTAssertEqual(viewModel.phoneNumber, "+15555555555")
    }

    func testPublishesControllerChanges() {
        // Given a view model observed by SwiftUI
        let linkController = makeController()
        let viewModel = LinkWalletButtonViewModel(linkController: linkController)
        var changeCount = 0
        let cancellable = viewModel.objectWillChange.sink { changeCount += 1 }
        defer { cancellable.cancel() }

        // When the controller's state changes
        linkController.email = "jane.diaz@example.com"

        // Then the view model publishes a change
        XCTAssertEqual(changeCount, 1)
    }

    func testOnlyPaymentsArePayWithLink() {
        XCTAssertEqual(LinkController.Mode(LinkWalletButtonViewModel.Mode.payment(clientSecretProvider: { "" })), .payment)
        XCTAssertEqual(LinkController.Mode(LinkWalletButtonViewModel.Mode.setup(clientSecretProvider: { "" })), .setup)
        XCTAssertEqual(LinkController.Mode(LinkWalletButtonViewModel.Mode.paymentMethod), .setup)
    }

    func testResultIsCompletedWhenLinkConfirmedOrCollectedPaymentMethod() {
        let paymentMethod = STPPaymentMethod._testCard()
        guard case .completed(let confirmedPaymentMethod) = LinkWalletButtonResult(.success(.confirmed(paymentMethod))) else {
            return XCTFail("Expected a completed result")
        }
        XCTAssertEqual(confirmedPaymentMethod.stripeId, paymentMethod.stripeId)
        guard case .completed(let selectedPaymentMethod) = LinkWalletButtonResult(.success(.completed(paymentMethod))) else {
            return XCTFail("Expected a completed result")
        }
        XCTAssertEqual(selectedPaymentMethod.stripeId, paymentMethod.stripeId)
    }

    func testResultMapsCancellationAndFailure() {
        guard case .canceled = LinkWalletButtonResult(.success(.canceled)) else {
            return XCTFail("Expected a canceled result")
        }
        guard case .failed(let error) = LinkWalletButtonResult(.failure(LinkController.IntegrationError.linkUnavailable)) else {
            return XCTFail("Expected a failed result")
        }
        XCTAssertEqual(error as? LinkController.IntegrationError, .linkUnavailable)
    }

    func testConfirmingWithoutSelectedPaymentMethodFails() async {
        // Given a view model whose customer hasn't selected a payment method
        let viewModel = LinkWalletButtonViewModel(linkController: makeController(buttonMode: .paymentMethod))

        // When the merchant confirms a PaymentIntent
        let result = await viewModel.confirmPaymentIntent(clientSecret: "pi_123_secret_abc", from: UIViewController())

        // Then it fails without a payment method
        guard case .failed(let error) = result else {
            return XCTFail("Expected a failed result, got \(result)")
        }
        XCTAssertEqual(error as? LinkController.IntegrationError, .noPaymentMethodSelected)
    }

    // MARK: - Helpers

    private func makeController(buttonMode: LinkWalletButtonViewModel.Mode = .paymentMethod) -> LinkController {
        LinkController(
            mode: LinkController.Mode(buttonMode),
            elementsSession: ._testValue(intent: ._testValue()),
            intent: ._testValue(),
            buttonMode: buttonMode,
            paymentElementConfiguration: PaymentSheet.Configuration(),
            linkBrand: .link,
            appearance: nil,
            configuration: nil,
            analyticsHelper: ._testValue(),
            requestSurface: .standaloneLink
        )
    }
}
