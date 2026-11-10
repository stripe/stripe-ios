//
//  LinkWalletButton.swift
//  StripePaymentSheet
//

import Combine
@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripePayments
@_spi(InternalOnlyAPI) import StripeUICore
import UIKit

/// The delegate of a `LinkWalletButton`.
@MainActor
@_spi(InternalOnlyAPI) @_spi(LinkControllerPreview) public protocol LinkWalletButtonDelegate: AnyObject {
    /// Called when the Link flow launched by the button finishes.
    /// - Parameter button: The button that launched the Link flow.
    /// - Parameter result: `.success(.completed(paymentMethod))` when the flow completes: the payment or setup was confirmed
    ///   if the `LinkController` was created with an `IntentConfiguration`, otherwise the customer selected a payment method.
    ///   `.success(.canceled)` when they dismiss the flow, or `.failure(error)` on an error.
    func linkWalletButton(
        _ button: LinkWalletButton,
        didCompleteWith result: Result<LinkController.PaymentMethodResult, Error>
    )

    /// Called right before the button presents the Link flow.
    func linkWalletButtonWillPresent(_ button: LinkWalletButton)
}

@_spi(InternalOnlyAPI) @_spi(LinkControllerPreview) public extension LinkWalletButtonDelegate {
    func linkWalletButtonWillPresent(_ button: LinkWalletButton) {}
}

/// A "Pay with Link" button that launches the Link flow using a `LinkController`.
///
/// The button reflects the customer's Link account: it shows their email once they're recognized as a Link user,
/// and their payment method once one is available. Tapping it presents Link with `LinkController.present`, which either
/// completes the payment or setup, or collects a payment method, depending on how the `LinkController` was created.
/// The result is delivered to the `delegate`.
@MainActor
@_spi(InternalOnlyAPI) @_spi(LinkControllerPreview) public final class LinkWalletButton: UIView {

    /// The delegate that receives the result of the Link flow.
    public weak var delegate: LinkWalletButtonDelegate?

    /// The view controller to present the Link flow from.
    /// If `nil`, the top-most view controller of the button's window is used.
    public var presentingViewController: UIViewController?

    /// Without the controller's `email`, the email of the customer who completed a Link flow launched by the button.
    private var signedInEmail: String?

    /// The controller's `email` when the button last updated, to notice when the merchant changes it.
    private var observedEmail: String?

    /// The email of the customer whose Link account the button shows: the controller's `email`, or else the
    /// customer who signed in through the button. The button never shows other Link accounts on the device.
    private var displayedEmail: String? {
        if let email = linkController.email, !email.isEmpty {
            return email
        }
        return signedInEmail
    }

    private let linkController: LinkWalletButtonControlling
    private let button: PayWithLinkButton
    /// Whether a Link flow launched by the button is in progress. The button shows a loading indicator meanwhile,
    /// e.g. while Link opens, and while the payment method is created or the payment is confirmed after Link closes.
    private(set) var isPresenting = false {
        didSet {
            guard oldValue != isPresenting else { return }
            updateButton()
        }
    }
    private var isLookingUp = false
    private var cancellables: Set<AnyCancellable> = []

    static let stateTransitionDuration: TimeInterval = 0.25

    /// Creates a `LinkWalletButton`.
    ///
    /// The button shows the Link account for the controller's `email`, and prefills its `email` and `phoneNumber` in Link.
    /// If the controller has no `email`, the button shows "Pay with Link", and tapping it lets the customer sign in to or
    /// sign up for Link. Once they complete the Link flow, the button shows their Link account.
    /// - Parameter linkController: The `LinkController` used to look up the customer and present the Link flow.
    public convenience init(linkController: LinkController) {
        self.init(controller: linkController)
    }

    init(controller: LinkWalletButtonControlling) {
        self.linkController = controller
        self.observedEmail = controller.email
        self.button = PayWithLinkButton(brand: controller.resolvedLinkBrand, observesLinkAccountContext: false)
        super.init(frame: CGRect(origin: .zero, size: PayWithLinkButton.Constants.defaultSize))

        button.applyDefaultCornerStyle()
        // Only payments are "Pay with Link"; collecting or setting up a payment method is "Continue with Link"
        button.callToAction = controller.mode == .setup ? .continue : .pay
        button.accessibilityIdentifier = "link_wallet_button"
        button.addTarget(self, action: #selector(didTap), for: .touchUpInside)
        addAndPinSubview(button)

        controller.stateDidChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.controllerStateDidChange()
            }
            .store(in: &cancellables)

        updateButton()
        lookUpIfNeeded()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var intrinsicContentSize: CGSize {
        button.intrinsicContentSize
    }

    // MARK: - Internal

    /// The account and payment method preview that the button displays.
    var displayedLinkAccount: PaymentSheetLinkAccount? { button.linkAccount as? PaymentSheetLinkAccount }
    var displayedPaymentMethodPreview: LinkPaymentMethodPreview? { button.paymentMethodPreview }
    var isDisplayingLoadingIndicator: Bool { button.isLoading }
    var displayedCallToAction: PayWithLinkButton.CallToAction { button.callToAction }

    static func accountMatches(_ linkAccount: PaymentSheetLinkAccount?, email: String?) -> Bool {
        guard let linkAccount, let email else { return false }
        return linkAccount.email.lowercased() == email.lowercased()
    }

    /// Returns the payment method to display, in order of preference: the payment method selected in this session
    /// (in native Link, or else in the Link web popup), then the account's default payment method.
    static func paymentMethodPreview(
        selectedPaymentDetails: ConsumerPaymentDetails?,
        selectedWebPaymentMethod: STPPaymentMethod? = nil,
        linkAccount: PaymentSheetLinkAccount
    ) -> LinkPaymentMethodPreview? {
        if let preview = selectedPaymentDetails.flatMap(LinkPaymentMethodPreview.init(from:)) {
            return preview
        }
        if let selectedWebPaymentMethod {
            // Don't fall back to the default payment method, which may not be the one the customer selected
            return LinkPaymentMethodPreview(from: selectedWebPaymentMethod)
        }
        return LinkPaymentMethodPreview(from: linkAccount.displayablePaymentDetails)
    }

    func updateButton() {
        let brand = linkController.resolvedLinkBrand
        let linkAccount: PaymentSheetLinkAccount?
        let paymentMethodPreview: LinkPaymentMethodPreview?
        // Only show account details for the customer the merchant provided, or who signed in through the button
        if let account = linkController.linkAccount, Self.accountMatches(account, email: displayedEmail) {
            linkAccount = account
            paymentMethodPreview = Self.paymentMethodPreview(
                selectedPaymentDetails: linkController.selectedPaymentDetails,
                selectedWebPaymentMethod: linkController.selectedWebPaymentMethod,
                linkAccount: account
            )
        } else {
            linkAccount = nil
            paymentMethodPreview = nil
        }

        // Animate once the button is on screen, e.g. when the lookup reveals the customer's email
        let isLoading = isPresenting
        button.performStateChange(animated: window != nil, duration: Self.stateTransitionDuration) { [button] in
            button.brand = brand
            button.linkAccount = linkAccount
            button.paymentMethodPreview = paymentMethodPreview
            button.isLoading = isLoading
        }
    }

    func controllerStateDidChange() {
        if linkController.email != observedEmail {
            observedEmail = linkController.email
            // The merchant identified the customer, so stop showing the customer who signed in through the button
            signedInEmail = nil
            lookUpIfNeeded()
        }
        updateButton()
    }

    func lookUpIfNeeded() {
        // Re-evaluated when the in-flight lookup completes
        guard !isLookingUp else { return }

        guard let email = displayedEmail, !email.isEmpty, !Self.accountMatches(linkController.linkAccount, email: email) else {
            return
        }

        isLookingUp = true
        linkController.lookupConsumer(with: email) { [weak self] _ in
            // Errors are ignored: the button keeps showing "Pay with Link", and `present` looks up the customer again.
            guard let self else { return }
            self.isLookingUp = false
            if self.displayedEmail != email {
                self.lookUpIfNeeded()
            }
        }
    }

    @objc
    func didTap() {
        guard !isPresenting else { return }

        guard let presentingViewController = presentingViewController ?? window?.findTopMostPresentedViewController() ?? UIWindow.visibleViewController else {
            delegate?.linkWalletButton(
                self,
                didCompleteWith: .failure(PaymentSheetError.unknown(debugDescription: "Could not find a view controller to present Link from. Set LinkWalletButton.presentingViewController."))
            )
            return
        }

        isPresenting = true
        delegate?.linkWalletButtonWillPresent(self)
        linkController.present(email: linkController.email, phoneNumber: linkController.phoneNumber, from: presentingViewController) { [weak self] result in
            guard let self else { return }
            // Adopt the customer before leaving the loading state, so the button changes to their account in one transition
            self.adoptSignedInCustomerIfNeeded(after: result)
            self.isPresenting = false
            self.lookUpIfNeeded()
            self.delegate?.linkWalletButton(self, didCompleteWith: result)
        }
    }
}

extension LinkWalletButton {
    /// Without the controller's `email`, remembers the customer who completed the Link flow, so the button shows their
    /// Link account: the signed-in account with native Link, or the email on the payment method from the Link web popup.
    func adoptSignedInCustomerIfNeeded(after result: Result<LinkController.PaymentMethodResult, Error>) {
        guard linkController.email?.isEmpty ?? true else {
            return
        }
        if let account = linkController.linkAccount, account.sessionState == .verified {
            signedInEmail = account.email
        } else if case .success(.completed(let paymentMethod)) = result,
                  let paymentMethodEmail = paymentMethod.billingDetails?.email,
                  !paymentMethodEmail.isEmpty {
            signedInEmail = paymentMethodEmail
        }
    }
}

// MARK: - LinkWalletButtonControlling

/// The subset of `LinkController` used by `LinkWalletButton`.
@MainActor
protocol LinkWalletButtonControlling: AnyObject {
    var linkAccount: PaymentSheetLinkAccount? { get }
    var selectedPaymentDetails: ConsumerPaymentDetails? { get }
    /// The payment method selected in the Link web popup, which has no `selectedPaymentDetails`.
    var selectedWebPaymentMethod: STPPaymentMethod? { get }
    var resolvedLinkBrand: LinkBrand { get }
    /// The customer's email and phone number, set by the merchant.
    var email: String? { get }
    var phoneNumber: String? { get }
    /// The intent the controller collects a payment method for. Setup mode includes collecting without an intent.
    var mode: LinkController.Mode { get }
    /// Emits when `email`, `linkAccount` or `selectedPaymentDetails` may have changed.
    var stateDidChange: AnyPublisher<Void, Never> { get }

    func lookupConsumer(with email: String, completion: @escaping (Result<Bool, Error>) -> Void)
    func present(
        email: String?,
        phoneNumber: String?,
        from presentingViewController: UIViewController,
        completion: @escaping (Result<LinkController.PaymentMethodResult, Error>) -> Void
    )
}

extension LinkController: LinkWalletButtonControlling {
    var stateDidChange: AnyPublisher<Void, Never> {
        Publishers.Merge3(
            $email.map { _ in () },
            $linkAccount.map { _ in () },
            $paymentMethodPreview.map { _ in () }
        )
        .eraseToAnyPublisher()
    }
}
