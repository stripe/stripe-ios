//
//  LinkWalletButtonViewModel.swift
//  StripePaymentSheet
//

import Combine
import Foundation
@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripePayments
import UIKit

/// The state behind a `LinkWalletButton` or `LinkWalletButtonUIView`: the Link session, the customer, and the payment
/// method they selected.
///
/// Keep it for as long as the button's screen or checkout flow is alive, so the button keeps its state when it's
/// recreated, e.g. when the customer navigates away and back.
@MainActor
@_spi(InternalOnlyAPI) @_spi(LinkControllerPreview) public final class LinkWalletButtonViewModel: ObservableObject {
    /// What Link does when the customer completes the flow.
    public enum Mode {
        /// Link confirms a PaymentIntent, with a "Pay with Link" button. To also save the payment method, set
        /// `setup_future_usage` on the PaymentIntent.
        /// - Parameter clientSecretProvider: Called each time the customer taps the button, before Link opens.
        ///   Create a PaymentIntent on your server (or reuse one), and return its client secret.
        case payment(clientSecretProvider: () async throws -> String)
        /// Link confirms a SetupIntent, with a "Continue with Link" button, e.g. to save a payment method you charge later.
        /// - Parameter clientSecretProvider: Called each time the customer taps the button, before Link opens.
        ///   Create a SetupIntent on your server (or reuse one), and return its client secret.
        case setup(clientSecretProvider: () async throws -> String)
        /// Link returns the customer's selected payment method without confirming anything, with a "Continue with Link"
        /// button. Confirm a PaymentIntent or SetupIntent with it later, using `confirmPaymentIntent` or `confirmSetupIntent`.
        case paymentMethod
    }

    private let linkController: LinkController
    private var cancellables: Set<AnyCancellable> = []

    /// The parts of the `LinkController` that a Link wallet button uses.
    var buttonController: LinkWalletButtonControlling { linkController }

    /// The customer's email address, if you have it. The button looks up the customer's Link account to display its
    /// details, and prefills the email in Link. If `nil`, the customer enters their email in Link.
    public var email: String? {
        get { linkController.email }
        set { linkController.email = newValue }
    }

    /// The customer's phone number in E.164 format, if you have it. Used to prefill the Link signup form.
    public var phoneNumber: String? {
        get { linkController.phoneNumber }
        set { linkController.phoneNumber = newValue }
    }

    /// The payment method the customer selected or paid with in Link, e.g. to show next to your "Place order" button.
    public var paymentMethodPreview: LinkController.PaymentMethodPreview? {
        linkController.paymentMethodPreview
    }

    init(linkController: LinkController) {
        self.linkController = linkController
        linkController.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    /// Loads Link for a `LinkWalletButton` or `LinkWalletButtonUIView`.
    ///
    /// - Parameter apiClient: The `STPAPIClient` instance. Defaults to `.shared`.
    /// - Parameter mode: What Link does when the customer completes the flow.
    /// - Parameter appearance: Link UI appearance overrides.
    /// - Parameter configuration: Configuration for Link behavior.
    /// - Parameter completion: Called with the loaded view model, or an error. Fails with
    ///   `LinkController.IntegrationError.linkUnavailable` if Link isn't enabled, or
    ///   `LinkController.IntegrationError.configurationRequiresNativeLink` if native Link isn't available on the device and
    ///   the Link web popup can't satisfy `configuration`.
    public static func create(
        apiClient: STPAPIClient = .shared,
        mode: Mode,
        appearance: LinkAppearance? = nil,
        configuration: LinkConfiguration? = nil,
        completion: @escaping (Result<LinkWalletButtonViewModel, Error>) -> Void
    ) {
        LinkController.create(
            apiClient: apiClient,
            intentConfiguration: nil,
            buttonMode: mode,
            appearance: appearance,
            configuration: configuration
        ) { result in
            completion(result.map { LinkWalletButtonViewModel(linkController: $0) })
        }
    }

    /// Loads Link for a `LinkWalletButton` or `LinkWalletButtonUIView`.
    ///
    /// - Parameter apiClient: The `STPAPIClient` instance. Defaults to `.shared`.
    /// - Parameter mode: What Link does when the customer completes the flow.
    /// - Parameter appearance: Link UI appearance overrides.
    /// - Parameter configuration: Configuration for Link behavior.
    /// - Returns: The loaded view model. Throws `LinkController.IntegrationError.linkUnavailable` if Link isn't enabled, or
    ///   `LinkController.IntegrationError.configurationRequiresNativeLink` if native Link isn't available on the device and
    ///   the Link web popup can't satisfy `configuration`.
    public static func create(
        apiClient: STPAPIClient = .shared,
        mode: Mode,
        appearance: LinkAppearance? = nil,
        configuration: LinkConfiguration? = nil
    ) async throws -> LinkWalletButtonViewModel {
        try await withCheckedThrowingContinuation { continuation in
            create(apiClient: apiClient, mode: mode, appearance: appearance, configuration: configuration) { result in
                continuation.resume(with: result)
            }
        }
    }

    /// With `.paymentMethod`: confirms a PaymentIntent with the payment method the customer selected in Link, handling
    /// next actions such as 3D Secure.
    /// - Parameter clientSecret: The client secret of the PaymentIntent to confirm.
    /// - Parameter presentingViewController: The view controller to present authentication from, e.g. for 3D Secure.
    /// - Returns: `.completed(paymentMethod)` once the PaymentIntent is confirmed, `.canceled` if the customer cancels
    ///   authentication, or `.failed(error)`. Fails with `LinkController.IntegrationError.noPaymentMethodSelected` if the
    ///   customer hasn't selected a payment method.
    public func confirmPaymentIntent(
        clientSecret: String,
        from presentingViewController: UIViewController
    ) async -> LinkWalletButtonResult {
        await confirmIntent(clientSecret: clientSecret, isPayment: true, from: presentingViewController)
    }

    /// With `.paymentMethod`: confirms a SetupIntent with the payment method the customer selected in Link, handling next
    /// actions such as 3D Secure.
    /// - Parameter clientSecret: The client secret of the SetupIntent to confirm.
    /// - Parameter presentingViewController: The view controller to present authentication from, e.g. for 3D Secure.
    /// - Returns: `.completed(paymentMethod)` once the SetupIntent is confirmed, `.canceled` if the customer cancels
    ///   authentication, or `.failed(error)`. Fails with `LinkController.IntegrationError.noPaymentMethodSelected` if the
    ///   customer hasn't selected a payment method.
    public func confirmSetupIntent(
        clientSecret: String,
        from presentingViewController: UIViewController
    ) async -> LinkWalletButtonResult {
        await confirmIntent(clientSecret: clientSecret, isPayment: false, from: presentingViewController)
    }

    private func confirmIntent(
        clientSecret: String,
        isPayment: Bool,
        from presentingViewController: UIViewController
    ) async -> LinkWalletButtonResult {
        await withCheckedContinuation { continuation in
            linkController.confirmIntent(clientSecret: clientSecret, isPayment: isPayment, from: presentingViewController) { result in
                continuation.resume(returning: LinkWalletButtonResult(result))
            }
        }
    }
}

/// The result of the Link flow launched by a `LinkWalletButton` or `LinkWalletButtonUIView`, or of confirming the payment
/// method the customer selected in it.
@frozen @_spi(InternalOnlyAPI) @_spi(LinkControllerPreview) public enum LinkWalletButtonResult {
    /// With `.payment` or `.setup`, or after `confirmPaymentIntent` or `confirmSetupIntent`: Link confirmed the intent with
    /// this payment method. With `.paymentMethod`: the customer selected this payment method, and you confirm it later.
    case completed(STPPaymentMethod)
    /// The customer dismissed Link, or canceled authentication, before completing.
    case canceled
    /// Loading or confirming the intent failed, e.g. because `clientSecretProvider` threw, or the card was declined.
    case failed(error: Error)

    init(_ result: Result<LinkController.PaymentMethodResult, Error>) {
        switch result {
        case .success(.completed(let paymentMethod)), .success(.confirmed(let paymentMethod)):
            self = .completed(paymentMethod)
        case .success(.canceled):
            self = .canceled
        case .failure(let error):
            self = .failed(error: error)
        }
    }
}
