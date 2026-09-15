//
//  NetworkedIdentityFlowViewController.swift
//  StripeIdentity
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

/// The Link sheet: renders `NetworkedIdentityCoordinator` states and forwards user actions to it.
@MainActor
final class NetworkedIdentityFlowViewController: UIViewController {
    enum VisibleStep: Equatable {
        case progress
        case email
        case phone
        case otp
        case documents
        case documentShared
        case saved
        case saveFailed
    }

    // #TODO - Networked Identity: localize once the final mobile copy is approved.
    enum Copy {
        static let emailTitle = "Continue with Link"
        static let reuseEmailBody = "Sign in to use a saved ID."
        static let saveEmailBody = "To save this ID, sign in or create an account."
        static let reauthenticationTitle = "Sign in again"
        static let reauthenticationBody = "Your Link session expired. Enter your email to sign in again."
        static let phoneBody = "Enter your phone number to create a Link account."
        static let continueButton = "Continue"
        static let manualCapture = "Manually verify identity"
        static let preparing = "Connecting to Link…"
        static let sending = "Sending a verification code…"
        static let confirming = "Confirming your code…"
        static let otpTitle = "Confirm it's you"
        static let otpBody = "Enter the code sent to %@."
        static let otpError = "The provided verification code is incorrect."
        static let resend = "Resend code"
        static let documentsTitle = "Choose a saved ID"
        static let documentsBody = "Select an ID to continue."
        static let documentsLoading = "Loading your saved IDs…"
        static let share = "Share ID"
        static let sharing = "Sharing your ID…"
        static let sharedTitle = "You shared your ID"
        static let sharedBody = "This ID will be used for your verification."
        static let saving = "Saving your ID…"
        static let savedTitle = "Success"
        static let savedBody = "Your credentials were saved with Link."
        static let savedItemID = "ID document"
        static let savedItemSelfie = "Selfie photo"
        static let saveFailedTitle = "Couldn't save your ID"
        static let saveFailedBody = "Something went wrong while saving your ID to Link. Your verification isn't affected."
        static let close = "Close"

        static func documentLabel(_ document: NetworkedIdentityDocument) -> String {
            let type: String
            switch document.documentType {
            case .drivingLicense: type = "Driver's license"
            case .passport: type = "Passport"
            case .idCard: type = "Identity card"
            case .unparsable: type = "Identity document"
            }
            guard let number = document.redactedDocumentNumber, !number.isEmpty else {
                return type
            }
            return "\(type) \(number)"
        }
    }

    private let coordinator: NetworkedIdentityCoordinator
    private let includesSelfie: Bool
    private let flowView = IdentityFlowView()
    private let messageLabel = NetworkedIdentityFlowViewController.makeLabel()

    let emailView = NetworkedIdentityEmailView(bodyText: Copy.reuseEmailBody)
    let phoneElement = PhoneNumberElement(theme: NetworkedIdentityUI.elementsAppearance)
    private let phoneMessageLabel = NetworkedIdentityFlowViewController.makeLabel()
    /// Built once: replacing the content on every update would take focus away from the phone field.
    private lazy var phoneContent: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [phoneMessageLabel, phoneElement.view])
        stack.axis = .vertical
        stack.spacing = 16
        return stack
    }()
    let documentSelectionView = NetworkedIdentityDocumentSelectionView()
    private(set) var phoneOtpView: PhoneOtpView?
    private(set) var visibleStep: VisibleStep?

    init(coordinator: NetworkedIdentityCoordinator, includesSelfie: Bool) {
        self.coordinator = coordinator
        self.includesSelfie = includesSelfie
        super.init(nibName: nil, bundle: nil)

        emailView.delegate = self
        phoneElement.delegate = self
        documentSelectionView.delegate = self

        // #TODO - Networked Identity: Replace this local Link asset if the final mobile handoff supplies
        // a Networked Identity-specific brand lockup.
        let logoView = UIImageView(image: Image.linkLogo.makeImage())
        logoView.contentMode = .scaleAspectFit
        logoView.isAccessibilityElement = true
        logoView.accessibilityLabel = "Link"
        logoView.accessibilityTraits = .header
        logoView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            logoView.widthAnchor.constraint(equalToConstant: 72),
            logoView.heightAnchor.constraint(equalToConstant: 24),
        ])
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: logoView)
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(didTapClose)
        )
        navigationItem.rightBarButtonItem?.accessibilityLabel = String.Localized.close
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view = flowView
        view.backgroundColor = .systemBackground
        flowView.tintColor = .label
        observeKeyboardNotifications()
        render(coordinator.state)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // A swipe-dismissed sheet cancels the attempt; a sheet dismissed after the attempt ended is a no-op.
        if isBeingDismissed || navigationController?.isBeingDismissed == true {
            coordinator.cancel()
        }
    }

    func render(_ state: NetworkedIdentityState) {
        guard isViewLoaded else {
            return
        }
        switch state {
        case .awaitingOTP, .otpConfirmPending:
            break
        default:
            phoneOtpView = nil
        }

        switch state {
        case .idle, .fullCaptureFallback, .cancelled:
            break
        case .preparing:
            renderProgress(Copy.preparing)
        case .collectEmail, .reauthenticationRequired:
            renderEmail(isReauthentication: state == .reauthenticationRequired, isLoading: false)
        case .lookupPending where visibleStep == .email:
            renderEmail(isReauthentication: false, isLoading: true)
        case .lookupPending:
            renderProgress(Copy.preparing)
        case .collectPhone(_, let error):
            renderPhone(isLoading: false, error: error)
        case .signUpPending:
            renderPhone(isLoading: true)
        case .otpStartPending:
            renderProgress(Copy.sending)
        case .awaitingOTP(let invalidCode):
            renderOTP(configuration: invalidCode ? .ErrorOTP : .InputtingOTP)
        case .otpConfirmPending:
            renderOTP(configuration: .SubmittingOTP(""))
        case .documentsPending:
            renderProgress(Copy.documentsLoading)
        case .selectDocument(let documents, let selectedDocumentID):
            renderDocuments(documents, selectedDocumentID: selectedDocumentID, isSharing: false)
        case .sharingDocument(let document):
            renderDocuments([document], selectedDocumentID: document.id, isSharing: true)
        case .documentShared:
            renderResult(step: .documentShared, title: Copy.sharedTitle, body: Copy.sharedBody)
        case .savePending:
            renderProgress(Copy.saving)
        case .saved:
            let items = [Copy.savedItemID] + (includesSelfie ? [Copy.savedItemSelfie] : [])
            let body = ([Copy.savedBody] + items.map { "• \($0)" }).joined(separator: "\n")
            renderResult(step: .saved, title: Copy.savedTitle, body: body)
        case .saveFailed(let details):
            renderSaveFailed(details: details)
        }
    }
}

// MARK: - Rendering

private extension NetworkedIdentityFlowViewController {
    static func makeLabel() -> UILabel {
        let label = UILabel()
        label.font = NetworkedIdentityUI.bodyFont
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }

    func renderProgress(_ text: String) {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.startAnimating()
        let label = Self.makeLabel()
        label.text = text
        let stack = UIStackView(arrangedSubviews: [spinner, label])
        stack.axis = .vertical
        stack.spacing = 16
        show(.progress, title: nil, content: stack, buttons: manualCaptureButtons())
    }

    func renderEmail(isReauthentication: Bool, isLoading: Bool) {
        let body: String
        if isReauthentication {
            body = Copy.reauthenticationBody
        } else {
            body = coordinator.mode == .save ? Copy.saveEmailBody : Copy.reuseEmailBody
        }
        emailView.configure(bodyText: body, isEnabled: !isLoading)
        let continueButton = IdentityFlowView.ViewModel.Button(
            text: Copy.continueButton,
            state: isLoading ? .loading : (emailView.hasValidEmailAddress ? .enabled : .disabled),
            configuration: .networkedIdentityPrimary(),
            didTap: { [weak self] in self?.submitEmail() }
        )
        let isNewStep = visibleStep != .email
        show(
            .email,
            title: isReauthentication ? Copy.reauthenticationTitle : Copy.emailTitle,
            content: emailView,
            buttons: [continueButton] + manualCaptureButtons()
        )
        if isNewStep {
            emailView.beginEditing()
        }
    }

    func renderPhone(isLoading: Bool, error: String? = nil) {
        phoneMessageLabel.text = error.map { "\(Copy.phoneBody)\n\n\($0)" } ?? Copy.phoneBody
        phoneMessageLabel.textColor = error == nil ? .label : .systemRed
        let continueButton = IdentityFlowView.ViewModel.Button(
            text: Copy.continueButton,
            state: isLoading ? .loading : (phoneElement.phoneNumber?.isComplete == true ? .enabled : .disabled),
            configuration: .networkedIdentityPrimary(),
            didTap: { [weak self] in self?.submitPhone() }
        )
        show(.phone, title: Copy.emailTitle, content: phoneContent, buttons: [continueButton])
    }

    func renderOTP(configuration: PhoneOtpView.ViewModel) {
        let otpView: PhoneOtpView
        if let phoneOtpView {
            otpView = phoneOtpView
        } else {
            otpView = PhoneOtpView(
                otpLength: 6,
                body: String(format: Copy.otpBody, coordinator.redactedFormattedPhoneNumber ?? ""),
                errorString: Copy.otpError,
                style: .networkedIdentity
            )
            otpView.delegate = self
            phoneOtpView = otpView
        }
        otpView.configure(with: configuration)
        let resendButton = IdentityFlowView.ViewModel.Button(
            text: Copy.resend,
            state: configuration == .SubmittingOTP("") ? .disabled : .enabled,
            isPrimary: false,
            configuration: .networkedIdentityPlain(),
            didTap: { [weak self] in
                self?.phoneOtpView?.clear()
                self?.coordinator.resendOTP()
            }
        )
        show(.otp, title: Copy.otpTitle, content: otpView, buttons: [resendButton] + manualCaptureButtons())
    }

    func renderDocuments(
        _ documents: [NetworkedIdentityDocument],
        selectedDocumentID: String?,
        isSharing: Bool
    ) {
        documentSelectionView.configure(
            bodyText: isSharing ? Copy.sharing : Copy.documentsBody,
            documents: documents,
            selectedDocumentID: selectedDocumentID,
            labelProvider: Copy.documentLabel,
            accessibilityLabelProvider: { document, isSelected in
                let label = Copy.documentLabel(document)
                return isSelected ? "\(label), selected" : label
            }
        )
        let shareButton = IdentityFlowView.ViewModel.Button(
            text: Copy.share,
            state: isSharing ? .loading : (selectedDocumentID == nil ? .disabled : .enabled),
            configuration: .networkedIdentityPrimary(),
            didTap: { [weak self] in self?.coordinator.shareSelectedDocument() }
        )
        show(.documents, title: Copy.documentsTitle, content: documentSelectionView, buttons: [shareButton] + manualCaptureButtons())
    }

    func renderResult(step: VisibleStep, title: String, body: String) {
        messageLabel.text = body
        let continueButton = IdentityFlowView.ViewModel.Button(
            text: Copy.continueButton,
            configuration: .networkedIdentityPrimary(),
            didTap: { [weak self] in self?.coordinator.continueAfterSuccess() }
        )
        show(step, title: title, content: messageLabel, buttons: [continueButton])
    }

    func renderSaveFailed(details: String?) {
        messageLabel.text = ([Copy.saveFailedBody] + (details.map { [$0] } ?? [])).joined(separator: "\n\n")
        let closeButton = IdentityFlowView.ViewModel.Button(
            text: Copy.close,
            configuration: .networkedIdentityPrimary(),
            didTap: { [weak self] in self?.coordinator.cancel() }
        )
        show(.saveFailed, title: Copy.saveFailedTitle, content: messageLabel, buttons: [closeButton])
    }

    /// Only reuse offers manual capture; in save mode closing the sheet is enough.
    func manualCaptureButtons() -> [IdentityFlowView.ViewModel.Button] {
        guard coordinator.mode == .reuse else {
            return []
        }
        return [
            .init(
                text: Copy.manualCapture,
                isPrimary: false,
                configuration: .networkedIdentitySecondary(),
                didTap: { [weak self] in self?.coordinator.chooseManualCapture() }
            ),
        ]
    }

    func show(
        _ step: VisibleStep,
        title: String?,
        content: UIView,
        buttons: [IdentityFlowView.ViewModel.Button]
    ) {
        let isNewStep = visibleStep != step
        visibleStep = step
        do {
            try flowView.configure(
                with: .init(
                    headerViewModel: title.map {
                        HeaderView.ViewModel(
                            backgroundColor: .systemBackground,
                            headerType: .plain,
                            titleText: $0,
                            titleFont: NetworkedIdentityUI.titleFont,
                            titleTextColor: .label,
                            titleTextAlignment: .center,
                            topInset: NetworkedIdentityUI.compactHeaderTopInset
                        )
                    },
                    contentView: content,
                    buttons: buttons
                )
            )
        } catch {
            stpAssertionFailure("Networked Identity flow configuration failed: \(error)")
        }
        if isNewStep, view.window != nil {
            UIAccessibility.post(notification: .screenChanged, argument: content)
        }
    }

    func submitEmail() {
        guard emailView.hasValidEmailAddress else {
            emailView.emailElement.showValidationErrors()
            return
        }
        coordinator.submitEmail(emailView.emailAddress)
    }

    func submitPhone() {
        guard let phoneNumber = phoneElement.phoneNumber, phoneNumber.isComplete else {
            return
        }
        coordinator.submitPhone(
            phoneNumber: phoneNumber.string(as: .e164),
            country: phoneElement.selectedCountryCode
        )
    }

    @objc func didTapClose() {
        coordinator.cancel()
    }
}

// MARK: - Element delegates

extension NetworkedIdentityFlowViewController: @MainActor NetworkedIdentityEmailViewDelegate {
    func networkedIdentityEmailViewDidUpdate(_ view: NetworkedIdentityEmailView) {
        if coordinator.state == .collectEmail || coordinator.state == .reauthenticationRequired {
            render(coordinator.state)
        }
    }

    func networkedIdentityEmailViewDidSubmit(_ view: NetworkedIdentityEmailView) {
        submitEmail()
    }
}

extension NetworkedIdentityFlowViewController: @MainActor ElementDelegate {
    func didUpdate(element: Element) {
        if case .collectPhone = coordinator.state {
            render(coordinator.state)
        }
    }

    func continueToNextField(element: Element) {
        submitPhone()
    }
}

extension NetworkedIdentityFlowViewController: @MainActor PhoneOtpViewDelegate {
    func didInputFullOtp(newOtp: String) {
        coordinator.submitOTP(newOtp)
    }

    func viewStateDidUpdate() {}
}

extension NetworkedIdentityFlowViewController: @MainActor NetworkedIdentityDocumentSelectionViewDelegate {
    func networkedIdentityDocumentSelectionView(
        _ view: NetworkedIdentityDocumentSelectionView,
        didSelect document: NetworkedIdentityDocument
    ) {
        coordinator.selectDocument(document)
    }
}

// MARK: - Keyboard

private extension NetworkedIdentityFlowViewController {
    func observeKeyboardNotifications() {
        for name in [UIResponder.keyboardWillHideNotification, UIResponder.keyboardWillChangeFrameNotification] {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(keyboardWillChange),
                name: name,
                object: nil
            )
        }
    }

    @objc func keyboardWillChange(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        flowView.adjustScrollViewForKeyboard(
            keyboardValue.cgRectValue,
            isKeyboardHidden: notification.name == UIResponder.keyboardWillHideNotification
        )
    }
}
