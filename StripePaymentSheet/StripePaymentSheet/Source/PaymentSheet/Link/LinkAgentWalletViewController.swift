//
//  LinkAgentWalletViewController.swift
//  StripePaymentSheet
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import SafariServices
import UIKit

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore

/// A view controller that returns a card from the customer's Link account, signing them up for Link if needed.
///
/// When it appears, the view controller checks whether the email address you provide belongs to a Link account.
///
/// If it doesn't, the view controller shows a form prefilled with the email address, phone number, and full name you provide,
/// which the customer can edit. When the customer taps "Add card", the view controller:
/// 1. Creates a Link account for the customer.
/// 2. Saves the card to the new Link account.
/// 3. Calls `completion` with the ID of the saved payment details.
///
/// If it does, the view controller asks the customer to verify their account with a one-time code, then shows the
/// account's default card. When the customer taps "Use card", the view controller calls `completion` with the ID of
/// that card's payment details. If the account doesn't have a card, the customer adds one instead.
///
/// - Note: Put this view controller in a `UINavigationController` before presenting it.
///   It doesn't dismiss itself. Dismiss it from `completion`.
@_spi(LinkAddCardPreview)
public final class LinkAgentWalletViewController: UIViewController {

    /// The result of a `LinkAgentWalletViewController`.
    public enum Result {
        /// The customer chose a card from their Link account. `paymentDetailsID` identifies the card.
        case completed(paymentDetailsID: String)
        /// The customer closed the view controller or canceled verification before choosing a card.
        case canceled
        /// The view controller can't return a card for this customer.
        case failed(error: Swift.Error)
    }

    /// Errors specific to `LinkAgentWalletViewController`.
    public enum Error: Swift.Error {
        /// The customer changed the email address to one that already belongs to a Link account.
        case accountAlreadyExists
    }

    private enum Mode {
        /// Checking whether the email address belongs to a Link account.
        case loading
        /// The email address doesn't belong to a Link account. The customer signs up and adds a card.
        case signUp
        /// The customer verified an existing Link account that has no cards, so they add one.
        case addCardToExistingAccount(PaymentSheetLinkAccount)
        /// The customer verified an existing Link account and can use one of its cards.
        case useExistingCard(PaymentSheetLinkAccount, ConsumerPaymentDetails)
    }

    private let merchantDisplayName: String
    private let apiClient: STPAPIClient
    private let completion: (Result) -> Void
    private let brand: LinkBrand = .link
    private let requestSurface: LinkRequestSurface = .standaloneLink
    /// The configuration for the Link UI this view controller shows, such as the verification dialog.
    private let configuration: PaymentSheet.Configuration
    private let appearance: LinkAppearance?
    private let theme: ElementsAppearance

    private let defaultEmail: String
    private let defaultPhoneNumber: String
    private let defaultFullName: String

    private var mode: Mode = .loading
    /// The Link account created by a previous tap on "Add card", kept so that retrying
    /// after a failure to save the card doesn't try to sign up the same email again.
    private var signedUpLinkAccount: PaymentSheetLinkAccount?
    /// The cards in the verified Link account, which the customer can choose from.
    private var existingCards: [ConsumerPaymentDetails] = []
    private var didStartLookup = false
    private var isProcessing = false
    private var didFinish = false

    // MARK: - Elements

    private lazy var emailElement = TextFieldElement.makeEmail(defaultValue: defaultEmail, theme: theme)

    private lazy var phoneNumberElement = PhoneNumberElement(
        defaultPhoneNumber: defaultPhoneNumber,
        theme: theme
    )

    private lazy var nameElement = TextFieldElement(
        configuration: TextFieldElement.NameConfiguration(type: .full, defaultValue: defaultFullName),
        theme: theme
    )

    private lazy var contactSectionElement = SectionElement(
        elements: [emailElement, phoneNumberElement, nameElement],
        theme: theme
    )

    private lazy var cardSectionElement = CardSectionElement(
        hostedSurface: .paymentSheet,
        theme: theme,
        analyticsHelper: nil,
        linkAppearance: appearance
    )

    private lazy var formElement: FormElement = {
        let formElement = FormElement(
            elements: [contactSectionElement, cardSectionElement],
            theme: theme
        )
        formElement.delegate = self
        return formElement
    }()

    // MARK: - Views

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.color = .linkIconTertiary
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicator
    }()

    private lazy var existingCardView: LinkPaymentMethodPicker.CellContentView = LinkPaymentMethodPicker.CellContentView()

    private lazy var existingCardContainerView: UIView = {
        let chevron = UIImageView(image: StripeUICore.Image.icon_chevron_down.makeImage(template: true))
        chevron.tintColor = .linkIconTertiary
        chevron.contentMode = .center
        chevron.setContentHuggingPriority(.required, for: .horizontal)

        let contentStackView = UIStackView(arrangedSubviews: [existingCardView, chevron])
        contentStackView.spacing = LinkUI.smallContentSpacing
        contentStackView.alignment = .center

        let containerView = UIView()
        containerView.backgroundColor = .linkSurfaceSecondary
        if let cornerRadius = LinkUI.appearance.cornerRadius {
            containerView.layer.cornerRadius = cornerRadius
        } else {
            containerView.ios26_applyDefaultCornerConfiguration()
        }
        containerView.addAndPinSubview(contentStackView, insets: LinkPaymentMethodPicker.Cell.Constants.margins)
        containerView.isAccessibilityElement = true
        containerView.accessibilityTraits = .button
        containerView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(didTapExistingCard))
        )
        return containerView
    }()

    private lazy var logoView: UIView = {
        let image = brand.paymentSheetLogoImage
        let height: CGFloat = 20
        let size = CGSize(width: image.size.width * height / max(image.size.height, 1), height: height)
        let imageView = UIImageView(image: image.resized(to: size) ?? image)
        imageView.tintColor = .linkIconBrand
        imageView.isAccessibilityElement = true
        imageView.accessibilityLabel = brand.accessibilityDisplayName
        // Pin the logo to the leading edge instead of stretching it across the stack view.
        return UIStackView(arrangedSubviews: [imageView, UIView()])
    }()

    /// Holds the Link logo and legal terms, inset like the text in the form fields so that the text lines up.
    private lazy var legalTermsContainerView: UIView = {
        let stackView = UIStackView(arrangedSubviews: [logoView, legalTermsView])
        stackView.axis = .vertical
        stackView.spacing = LinkUI.smallContentSpacing

        let containerView = UIView()
        containerView.addAndPinSubview(
            stackView,
            insets: .insets(leading: theme.textFieldInsets.leading, trailing: theme.textFieldInsets.trailing)
        )
        return containerView
    }()

    private lazy var legalTermsView: LinkLegalTermsView = {
        let legalTermsView = LinkLegalTermsView(
            brand: brand,
            isStandalone: true,
            merchantDisplayName: merchantDisplayName
        )
        legalTermsView.tintColor = appearance?.colors?.primary ?? .linkTextBrand
        legalTermsView.delegate = self
        return legalTermsView
    }()

    private lazy var errorLabel: UILabel = {
        let label = ElementsUI.makeErrorLabel(theme: theme)
        label.isHidden = true
        return label
    }()

    private lazy var confirmButton: ConfirmButton = .makeLinkButton(
        callToAction: .custom(title: String.Localized.add_card),
        showProcessingLabel: false,
        linkAppearance: appearance,
        didTapWhenDisabled: { [weak self] in
            self?.formElement.showAllValidationErrors()
        },
        didTap: { [weak self] in
            self?.didTapConfirmButton()
        }
    )

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            formElement.view,
            existingCardContainerView,
            legalTermsContainerView,
            errorLabel,
        ])
        stackView.axis = .vertical
        stackView.spacing = LinkUI.contentSpacing
        stackView.setCustomSpacing(LinkUI.largeContentSpacing, after: formElement.view)
        stackView.setCustomSpacing(LinkUI.largeContentSpacing, after: existingCardContainerView)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = LinkUI.contentMargins
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    /// Keeps the confirm button at the bottom of the screen, above the keyboard.
    private lazy var buttonContainerView: UIView = {
        let containerView = UIView()
        containerView.addAndPinSubview(
            confirmButton,
            insets: .insets(
                top: LinkUI.contentSpacing,
                leading: LinkUI.contentMargins.leading,
                bottom: LinkUI.contentMargins.bottom,
                trailing: LinkUI.contentMargins.trailing
            )
        )
        containerView.translatesAutoresizingMaskIntoConstraints = false
        return containerView
    }()

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        #if !os(visionOS)
        scrollView.keyboardDismissMode = .onDrag
        #endif
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    // MARK: - Initializers

    /// Initializes a `LinkAgentWalletViewController`.
    /// - Parameters:
    ///   - merchantDisplayName: Your business name, shown in the legal terms.
    ///   - email: The customer's email address. It's used to find the customer's Link account. If there isn't one, the customer can edit it before signing up.
    ///   - phoneNumber: The customer's phone number in E.164 format, for example `+15555555555`. The customer can edit it before signing up.
    ///   - fullName: The customer's full name. The customer can edit it before signing up.
    ///   - appearance: Appearance overrides for the Link UI. If not specified, Link's default appearance is used.
    ///   - apiClient: The API client to use for Link requests. Its publishable key must be set.
    ///   - completion: Called when the customer chooses a card, cancels, or can't choose a card.
    ///     It's called once, on the main thread. Dismiss the view controller here.
    public init(
        merchantDisplayName: String,
        email: String,
        phoneNumber: String,
        fullName: String,
        appearance: LinkAppearance? = nil,
        apiClient: STPAPIClient = .shared,
        completion: @escaping (Result) -> Void
    ) {
        self.merchantDisplayName = merchantDisplayName
        self.defaultEmail = email
        self.defaultPhoneNumber = phoneNumber
        self.defaultFullName = fullName
        self.apiClient = apiClient
        self.completion = completion
        let configuration = Self.makeConfiguration(
            apiClient: apiClient,
            merchantDisplayName: merchantDisplayName,
            appearance: appearance
        )
        // Update the shared Link UI styling before creating any views, so that they use Liquid Glass if available.
        LinkUI.applyLiquidGlassIfPossible(configuration: configuration)
        self.configuration = configuration
        self.appearance = appearance
        self.theme = Self.makeTheme(appearance: appearance)
        super.init(nibName: nil, bundle: nil)
        configuration.style.configure(self)
        title = String.Localized.add_card
        navigationItem.leftBarButtonItem = UIBarButtonItem(
        barButtonSystemItem: .close,
        target: self,
        action: #selector(didTapCloseButton)
    )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private static func makeConfiguration(
        apiClient: STPAPIClient,
        merchantDisplayName: String,
        appearance: LinkAppearance?
    ) -> PaymentSheet.Configuration {
        var configuration = PaymentSheet.Configuration()
        configuration.apiClient = apiClient
        configuration.merchantDisplayName = merchantDisplayName
        if let appearance {
            configuration.style = appearance.style
        }
        #if !os(visionOS)
        if #available(iOS 26.0, *), LiquidGlassDetector.isEnabledInMerchantApp {
            configuration.appearance.applyLiquidGlass()
        }
        #endif
        return configuration
    }

    static func makeTheme(appearance: LinkAppearance?) -> ElementsAppearance {
        var theme = LinkUI.appearance.asElementsTheme
        if let primary = appearance?.colors?.primary {
            theme.colors.primary = primary
        }
        return theme
    }

    // MARK: - Overrides

    override public func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .linkSurfacePrimary
        view.tintColor = .linkTextPrimary

        view.addSubview(scrollView)
        view.addSubview(buttonContainerView)
        view.addSubview(activityIndicator)
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: buttonContainerView.topAnchor),

            buttonContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            buttonContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            buttonContainerView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: LinkUI.contentSpacing),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
        ])

        updateUI()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Report swipe-to-dismiss as a cancellation.
        (navigationController ?? self).presentationController?.delegate = self

        if !didStartLookup {
            didStartLookup = true
            lookUpExistingAccount()
        }
    }

    // MARK: - Actions

    @objc private func didTapCloseButton() {
        guard !isProcessing else {
            return
        }
        finish(with: .canceled)
    }

    @objc private func didTapExistingCard() {
        guard !isProcessing, case .useExistingCard(let linkAccount, let selectedCard) = mode else {
            return
        }

        let listViewController = PaymentDetailsListViewController(
            paymentDetails: existingCards,
            selectedPaymentDetails: selectedCard,
            appearance: appearance,
            addCard: { [weak self] paymentMethodParams in
                guard let self else {
                    throw PaymentSheetError.unknown(debugDescription: "The view controller was deallocated")
                }
                let card = try await self.createPaymentDetails(
                    with: paymentMethodParams,
                    for: linkAccount,
                    isDefault: false
                )
                self.existingCards.append(card)
                return card
            },
            didSelect: { [weak self] card in
                self?.setMode(.useExistingCard(linkAccount, card))
            }
        )
        let navigationController = UINavigationController(rootViewController: listViewController)
        configuration.style.configure(navigationController)
        if let sheetPresentationController = navigationController.sheetPresentationController {
            sheetPresentationController.detents = [.medium(), .large()]
            sheetPresentationController.prefersGrabberVisible = true
        }
        present(navigationController, animated: true)
    }

    private func didTapConfirmButton() {
        guard !isProcessing else {
            return
        }

        if case .useExistingCard(_, let paymentDetails) = mode {
            finish(with: .completed(paymentDetailsID: paymentDetails.stripeID))
            return
        }

        view.endEditing(true)
        updateError(nil)
        isProcessing = true
        updateUI()

        Task { @MainActor in
            do {
                let paymentDetailsID = try await addCard()
                confirmButton.update(status: .succeeded, animated: true) {
                    self.finish(with: .completed(paymentDetailsID: paymentDetailsID))
                }
            } catch Error.accountAlreadyExists {
                finish(with: .failed(error: Error.accountAlreadyExists))
            } catch {
                isProcessing = false
                updateError(error)
                updateUI()
            }
        }
    }

    private func finish(with result: Result) {
        guard !didFinish else {
            return
        }
        didFinish = true
        isProcessing = false
        completion(result)
    }

    // MARK: - Existing Link accounts

    private func lookUpExistingAccount() {
        Task { @MainActor in
            let linkAccount = try? await accountService.lookupAccount(
                withEmail: defaultEmail,
                emailSource: .prefilledEmail,
                doNotLogConsumerFunnelEvent: false,
                requestSurface: requestSurface
            )
            guard let linkAccount, linkAccount.isRegistered else {
                // If the lookup fails, let the customer sign up. Signing up checks for an existing account again.
                setMode(.signUp)
                return
            }
            verify(linkAccount)
        }
    }

    private func verify(_ linkAccount: PaymentSheetLinkAccount) {
        guard linkAccount.sessionState == .requiresVerification else {
            loadExistingCard(for: linkAccount)
            return
        }

        let verificationController = LinkVerificationController(
            linkAccount: linkAccount,
            brand: brand,
            configuration: configuration,
            appearance: appearance
        )
        verificationController.present(from: navigationController ?? self) { [weak self] result in
            switch result {
            case .completed:
                self?.loadExistingCard(for: linkAccount)
            case .canceled, .switchAccount:
                self?.finish(with: .canceled)
            case .failed(let error):
                self?.finish(with: .failed(error: error))
            }
        }
    }

    private func loadExistingCard(for linkAccount: PaymentSheetLinkAccount) {
        Task { @MainActor in
            do {
                let paymentDetails = try await linkAccount.listPaymentDetails(
                    supportedTypes: [.init(.card)],
                    shouldRetryOnAuthError: false
                )
                let cards = paymentDetails.filter {
                    if case .card = $0.details {
                        return true
                    }
                    return false
                }
                existingCards = cards
                if let card = cards.first(where: \.isDefault) ?? cards.first {
                    setMode(.useExistingCard(linkAccount, card))
                } else {
                    setMode(.addCardToExistingAccount(linkAccount))
                }
            } catch {
                finish(with: .failed(error: error))
            }
        }
    }

    // MARK: - Adding cards

    private func addCard() async throws -> String {
        switch mode {
        case .signUp:
            guard
                let email = emailElement.text.nonEmpty,
                let phoneNumber = phoneNumberElement.phoneNumber,
                let fullName = nameElement.text.nonEmpty,
                let params = formElement.updateParams(params: IntentConfirmParams(type: .stripe(.card)))
            else {
                throw PaymentSheetError.unknown(debugDescription: "Tried to add a card with an incomplete form")
            }

            let billingDetails = params.paymentMethodParams.nonnil_billingDetails
            billingDetails.name = fullName
            billingDetails.email = email
            billingDetails.phone = phoneNumber.string(as: .e164)

            let linkAccount = try await signUpIfNeeded(email: email, phoneNumber: phoneNumber, fullName: fullName)
            return try await createPaymentDetails(with: params.paymentMethodParams, for: linkAccount, isDefault: true).stripeID
        case .addCardToExistingAccount(let linkAccount):
            guard let params = cardSectionElement.updateParams(params: IntentConfirmParams(type: .stripe(.card))) else {
                throw PaymentSheetError.unknown(debugDescription: "Tried to add a card with an incomplete form")
            }
            return try await createPaymentDetails(with: params.paymentMethodParams, for: linkAccount, isDefault: true).stripeID
        case .loading, .useExistingCard:
            throw PaymentSheetError.unknown(debugDescription: "Tried to add a card without a card form")
        }
    }

    private func createPaymentDetails(
        with paymentMethodParams: STPPaymentMethodParams,
        for linkAccount: PaymentSheetLinkAccount,
        isDefault: Bool
    ) async throws -> ConsumerPaymentDetails {
        guard let session = linkAccount.currentSession else {
            throw PaymentSheetError.savingWithoutValidLinkSession
        }

        let paymentDetails: ConsumerPaymentDetails = try await withCheckedThrowingContinuation { continuation in
            session.createPaymentDetails(
                paymentMethodParams: paymentMethodParams,
                with: apiClient,
                isDefault: isDefault,
                requestSurface: requestSurface
            ) { result in
                continuation.resume(with: result)
            }
        }
        return paymentDetails
    }

    private func signUpIfNeeded(
        email: String,
        phoneNumber: PhoneNumber,
        fullName: String
    ) async throws -> PaymentSheetLinkAccount {
        if let signedUpLinkAccount, signedUpLinkAccount.email.caseInsensitiveCompare(email) == .orderedSame {
            return signedUpLinkAccount
        }

        let lookedUpAccount = try await accountService.lookupAccount(
            withEmail: email,
            emailSource: email == defaultEmail ? .prefilledEmail : .userAction,
            doNotLogConsumerFunnelEvent: false,
            requestSurface: requestSurface
        )
        if lookedUpAccount?.isRegistered == true {
            throw Error.accountAlreadyExists
        }

        // The lookup returns no account when the email can't be looked up, for example because it's invalid.
        guard let linkAccount = lookedUpAccount else {
            throw PaymentSheetError.unknown(debugDescription: "Couldn't look up a Link account for the email address")
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Swift.Error>) in
            linkAccount.signUp(
                with: phoneNumber,
                legalName: fullName,
                countryCode: nil,
                consentAction: .clicked_button_mobile_v1
            ) { result in
                continuation.resume(with: result)
            }
        }
        signedUpLinkAccount = linkAccount
        return linkAccount
    }

    // Without an elements session, there's no attestation configuration or session ID,
    // so Link requests use the non-attestation endpoints and a session ID scoped to this screen.
    private lazy var accountService = LinkAccountService(
        apiClient: apiClient,
        useMobileEndpoints: false,
        canSyncAttestationState: false,
        sessionID: UUID().uuidString,
        customerID: nil,
        shouldPassCustomerIdToLookup: false,
        merchantLogoUrl: nil
    )

    // MARK: - UI

    private func setMode(_ mode: Mode) {
        self.mode = mode
        switch mode {
        case .loading, .signUp, .useExistingCard:
            break
        case .addCardToExistingAccount:
            // The account already exists, so only collect the card.
            formElement.toggleElements([contactSectionElement], hidden: true, animated: false)
        }
        if case .useExistingCard(_, let paymentDetails) = mode {
            existingCardView.paymentMethod = paymentDetails
            existingCardContainerView.accessibilityLabel = paymentDetails.accessibilityDescription
        }
        updateUI()
    }

    private func updateUI() {
        let isLoading: Bool
        let showsForm: Bool
        let showsExistingCard: Bool
        let showsLegalTerms: Bool
        let isValid: Bool
        let buttonTitle: String
        switch mode {
        case .loading:
            isLoading = true
            showsForm = false
            showsExistingCard = false
            showsLegalTerms = false
            isValid = false
            buttonTitle = String.Localized.add_card
        case .signUp:
            isLoading = false
            showsForm = true
            showsExistingCard = false
            showsLegalTerms = true
            isValid = formElement.validationState.isValid
            buttonTitle = String.Localized.add_card
        case .addCardToExistingAccount:
            isLoading = false
            showsForm = true
            showsExistingCard = false
            showsLegalTerms = false
            isValid = cardSectionElement.validationState.isValid
            buttonTitle = String.Localized.add_card
        case .useExistingCard:
            isLoading = false
            showsForm = false
            showsExistingCard = true
            showsLegalTerms = true
            isValid = true
            buttonTitle = STPLocalizedString(
                "Use card",
                "Title for a button that, when tapped, uses a card saved to the customer's Link account."
            )
        }

        if isLoading {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
        scrollView.isHidden = isLoading
        buttonContainerView.isHidden = isLoading
        formElement.view.isHidden = !showsForm
        existingCardContainerView.isHidden = !showsExistingCard
        legalTermsView.isHidden = !showsLegalTerms
        formElement.view.isUserInteractionEnabled = !isProcessing

        let status: ConfirmButton.Status = {
            if isProcessing {
                return .processing
            }
            return isValid ? .enabled : .disabled
        }()
        confirmButton.update(status: status, callToAction: .custom(title: buttonTitle), animated: true)
    }

    private func updateError(_ error: Swift.Error?) {
        errorLabel.text = error?.nonGenericDescription
        stackView.toggleArrangedSubview(errorLabel, shouldShow: error != nil, animated: true)
    }
}

// MARK: - ElementDelegate

@_spi(STP) extension LinkAgentWalletViewController: ElementDelegate {
    @_spi(STP) public func didUpdate(element: Element) {
        updateUI()
    }

    @_spi(STP) public func continueToNextField(element: Element) {
        // No-op
    }
}

// MARK: - LinkLegalTermsViewDelegate

extension LinkAgentWalletViewController: LinkLegalTermsViewDelegate {
    func legalTermsView(_ legalTermsView: LinkLegalTermsView, didTapOnLinkWithURL url: URL) -> Bool {
        let safariVC = SFSafariViewController(url: url)
        #if !os(visionOS)
        safariVC.dismissButtonStyle = .close
        #endif
        safariVC.modalPresentationStyle = .overFullScreen
        present(safariVC, animated: true)
        return true
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension LinkAgentWalletViewController: UIAdaptivePresentationControllerDelegate {
    public func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return !isProcessing
    }

    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        finish(with: .canceled)
    }
}
