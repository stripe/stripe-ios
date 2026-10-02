//
//  LinkWalletButton.swift
//  StripePaymentSheet
//

import Combine
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

/// The delegate of a `LinkWalletButton`.
@MainActor
@_spi(STP) @_spi(LinkControllerPreview) public protocol LinkWalletButtonDelegate: AnyObject {
    /// Called when the Link flow launched by the button finishes.
    /// - Parameter button: The button that launched the Link flow.
    /// - Parameter result: `.success(.completed(paymentMethod))` when the customer selects a payment method,
    ///   `.success(.canceled)` when they dismiss the flow, or `.failure(error)` on an error.
    func linkWalletButton(
        _ button: LinkWalletButton,
        didCompleteWith result: Result<LinkController.PaymentMethodResult, Error>
    )

    /// Called right before the button presents the Link flow.
    func linkWalletButtonWillPresent(_ button: LinkWalletButton)
}

@_spi(STP) @_spi(LinkControllerPreview) public extension LinkWalletButtonDelegate {
    func linkWalletButtonWillPresent(_ button: LinkWalletButton) {}
}

/// A "Pay with Link" button that launches the Link flow using a `LinkController`.
///
/// The button reflects the customer's Link account: it shows their email once they're recognized as a Link user,
/// and their payment method once one is available. Tapping it presents Link, and the resulting payment method is
/// delivered to the `delegate`.
@MainActor
@_spi(STP) @_spi(LinkControllerPreview) public final class LinkWalletButton: UIView {

    /// The delegate that receives the result of the Link flow.
    public weak var delegate: LinkWalletButtonDelegate?

    /// The view controller to present the Link flow from.
    /// If `nil`, the top-most view controller of the button's window is used.
    public var presentingViewController: UIViewController?

    /// The customer's email address. The button looks up the associated Link account to display its details.
    public var email: String {
        didSet {
            guard oldValue != email else { return }
            updateButton()
            lookUpIfNeeded()
        }
    }

    /// The customer's phone number in E.164 format, used to prefill the Link signup form.
    public var phoneNumber: String?

    private let linkController: LinkWalletButtonControlling
    private let button: PayWithLinkButton
    private var isPresenting = false
    private var isLookingUp = false
    private var cancellables: Set<AnyCancellable> = []

    /// Creates a `LinkWalletButton`.
    /// - Parameter linkController: The `LinkController` used to look up the customer and present the Link flow.
    /// - Parameter email: The customer's email address.
    /// - Parameter phoneNumber: The customer's phone number in E.164 format, used to prefill the Link signup form.
    public convenience init(linkController: LinkController, email: String, phoneNumber: String? = nil) {
        self.init(controller: linkController, email: email, phoneNumber: phoneNumber)
    }

    init(controller: LinkWalletButtonControlling, email: String, phoneNumber: String?) {
        self.linkController = controller
        self.email = email
        self.phoneNumber = phoneNumber
        self.button = PayWithLinkButton(brand: controller.resolvedLinkBrand, observesLinkAccountContext: false)
        super.init(frame: CGRect(origin: .zero, size: PayWithLinkButton.Constants.defaultSize))

        button.applyDefaultCornerStyle()
        button.accessibilityIdentifier = "link_wallet_button"
        button.addTarget(self, action: #selector(didTap), for: .touchUpInside)
        addAndPinSubview(button)

        controller.stateDidChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.updateButton()
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

    static func accountMatches(_ linkAccount: PaymentSheetLinkAccount?, email: String) -> Bool {
        guard let linkAccount else { return false }
        return linkAccount.email.lowercased() == email.lowercased()
    }

    /// Returns the payment method to display, in order of preference:
    /// the payment method selected in this session, then the account's default payment method.
    static func paymentMethodPreview(
        selectedPaymentDetails: ConsumerPaymentDetails?,
        linkAccount: PaymentSheetLinkAccount
    ) -> LinkPaymentMethodPreview? {
        selectedPaymentDetails.flatMap(LinkPaymentMethodPreview.init(from:))
            ?? LinkPaymentMethodPreview(from: linkAccount.displayablePaymentDetails)
    }

    func updateButton() {
        button.brand = linkController.resolvedLinkBrand

        // Only show account details for the customer the merchant provided
        guard let linkAccount = linkController.linkAccount, Self.accountMatches(linkAccount, email: email) else {
            button.linkAccount = nil
            button.paymentMethodPreview = nil
            return
        }
        button.linkAccount = linkAccount
        button.paymentMethodPreview = Self.paymentMethodPreview(
            selectedPaymentDetails: linkController.selectedPaymentDetails,
            linkAccount: linkAccount
        )
    }

    func lookUpIfNeeded() {
        // Re-evaluated when the in-flight lookup completes
        guard !isLookingUp else { return }

        let email = self.email
        guard !email.isEmpty, !Self.accountMatches(linkController.linkAccount, email: email) else {
            return
        }

        isLookingUp = true
        linkController.lookupConsumer(with: email) { [weak self] _ in
            // Errors are ignored: the button keeps showing "Pay with Link", and `present` looks up the customer again.
            guard let self else { return }
            self.isLookingUp = false
            if self.email != email {
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
        linkController.present(email: email, phoneNumber: phoneNumber, from: presentingViewController) { [weak self] result in
            guard let self else { return }
            self.isPresenting = false
            self.delegate?.linkWalletButton(self, didCompleteWith: result)
        }
    }
}

// MARK: - LinkWalletButtonControlling

/// The subset of `LinkController` used by `LinkWalletButton`.
@MainActor
protocol LinkWalletButtonControlling: AnyObject {
    var linkAccount: PaymentSheetLinkAccount? { get }
    var selectedPaymentDetails: ConsumerPaymentDetails? { get }
    var resolvedLinkBrand: LinkBrand { get }
    /// Emits when `linkAccount` or `selectedPaymentDetails` may have changed.
    var stateDidChange: AnyPublisher<Void, Never> { get }

    func lookupConsumer(with email: String, completion: @escaping (Result<Bool, Error>) -> Void)
    func present(
        email: String,
        phoneNumber: String?,
        from presentingViewController: UIViewController,
        completion: @escaping (Result<LinkController.PaymentMethodResult, Error>) -> Void
    )
}

extension LinkController: LinkWalletButtonControlling {
    var stateDidChange: AnyPublisher<Void, Never> {
        Publishers.Merge(
            $linkAccount.map { _ in () },
            $paymentMethodPreview.map { _ in () }
        )
        .eraseToAnyPublisher()
    }
}
