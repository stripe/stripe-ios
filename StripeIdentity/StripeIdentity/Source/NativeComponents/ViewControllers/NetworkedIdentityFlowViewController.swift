//
//  NetworkedIdentityFlowViewController.swift
//  StripeIdentity
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

@MainActor
protocol NetworkedIdentityFlowViewControllerDelegate: AnyObject {
    func networkedIdentityFlowViewControllerDidCancel(
        _ viewController: NetworkedIdentityFlowViewController
    )

    func networkedIdentityFlowViewController(
        _ viewController: NetworkedIdentityFlowViewController,
        didRequestFullCapture reason: NetworkedIdentityFallbackReason
    )
}

/// Presents the contract-backed portion of Networked Identity without deciding how it enters
/// or exits the VerificationSheet flow.
@MainActor
final class NetworkedIdentityFlowViewController: UIViewController {
    struct Content {
        struct Email {
            let title: String
            let body: String
            let reauthenticationTitle: String
            let reauthenticationBody: String
            let continueButtonText: String
        }

        struct OTP {
            let title: String
            let sendingBody: (String) -> String
            let body: (String) -> String
            let invalidCodeMessage: String
        }

        struct Documents {
            let title: String
            let body: String
            let loadingTitle: String
            let loadingBody: String
            let label: NetworkedIdentityDocumentSelectionView.LabelProvider
            let accessibilityLabel: NetworkedIdentityDocumentSelectionView.AccessibilityLabelProvider
        }

        let email: Email
        let otp: OTP
        let documents: Documents
        let manualCaptureButtonText: String
        let cancelButtonText: String
    }

    enum VisibleStep: Equatable {
        case email
        case otp
        case documents
    }

    private enum AccessibilityScreen: Equatable {
        case email
        case otpSending
        case otp
        case documentLoading
        case documents
    }

    private let coordinator: NetworkedIdentityCoordinator
    private let content: Content
    private let flowView = IdentityFlowView()
    private var displayedPhoneNumber: String?
    private var displayedOTPBody: String?
    private var hasFinished = false
    private var previousInteractivePopGestureEnabled: Bool?
    private var announcedAccessibilityScreen: AccessibilityScreen?
    private var pendingAccessibilityScreen: AccessibilityScreen?
    private weak var pendingAccessibilityFocusView: UIView?
    private var hasAnnouncedCurrentOTPError = false

    weak var delegate: NetworkedIdentityFlowViewControllerDelegate?

    let emailView: NetworkedIdentityEmailView
    let documentSelectionView = NetworkedIdentityDocumentSelectionView()
    private(set) var phoneOtpView: PhoneOtpView?
    private(set) var visibleStep: VisibleStep?

    init(
        coordinator: NetworkedIdentityCoordinator,
        content: Content
    ) {
        self.coordinator = coordinator
        self.content = content
        emailView = NetworkedIdentityEmailView(bodyText: content.email.body)
        super.init(nibName: nil, bundle: nil)

        coordinator.delegate = self
        emailView.delegate = self
        documentSelectionView.delegate = self
        navigationItem.hidesBackButton = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: content.cancelButtonText,
            style: .plain,
            target: self,
            action: #selector(didTapCancel)
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view = flowView
        view.backgroundColor = .systemBackground
        observeKeyboardNotifications()
        render(coordinator.state)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        postPendingAccessibilityScreenChangeIfNeeded()
        if coordinator.state == .awaitingOTP,
           coordinator.lastOTPError == .invalidCode {
            announceInvalidOTPErrorIfNeeded()
        }
        if coordinator.state == .collectEmail || coordinator.state == .reauthenticationRequired {
            emailView.beginEditing()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard let interactivePopGestureRecognizer = navigationController?.interactivePopGestureRecognizer else {
            return
        }
        previousInteractivePopGestureEnabled = interactivePopGestureRecognizer.isEnabled
        interactivePopGestureRecognizer.isEnabled = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if let previousInteractivePopGestureEnabled {
            navigationController?.interactivePopGestureRecognizer?.isEnabled =
                previousInteractivePopGestureEnabled
            self.previousInteractivePopGestureEnabled = nil
        }
    }

    func chooseManualCapture() {
        coordinator.chooseManualCapture()
    }

    func cancel() {
        coordinator.cancel()
    }
}

// MARK: - Rendering

private extension NetworkedIdentityFlowViewController {
    func render(_ state: NetworkedIdentityState) {
        switch state {
        case .otpStartPending, .awaitingOTP, .otpConfirmPending:
            break
        default:
            clearOTPView()
        }

        switch state {
        case .collectEmail, .lookupPending, .reauthenticationRequired:
            renderEmail(state: state)
        case .otpStartPending, .awaitingOTP, .otpConfirmPending:
            renderOTP(state: state)
        case .documentsPending:
            renderDocumentLoading()
        case .selectDocument, .selectedDocument:
            renderDocuments()
        case .fullCaptureFallback:
            // The coordinator's dedicated fallback callback carries the reason.
            break
        case .cancelled:
            finishCancellationIfNeeded()
        }
    }

    func renderEmail(state: NetworkedIdentityState) {
        visibleStep = .email
        let isReauthentication = state == .reauthenticationRequired
        let isLoading = state == .lookupPending
        let title = isReauthentication
            ? content.email.reauthenticationTitle
            : content.email.title
        let body = isReauthentication
            ? content.email.reauthenticationBody
            : content.email.body

        emailView.configure(bodyText: body, isEnabled: !isLoading)
        configureFlow(
            with: .init(
                headerViewModel: plainHeader(title: title),
                contentView: emailView,
                buttons: [
                    .init(
                        text: content.email.continueButtonText,
                        state: isLoading
                            ? .loading
                            : (emailView.hasValidEmailAddress ? .enabled : .disabled),
                        didTap: { [weak self] in
                            self?.submitEmail()
                        }
                    ),
                    manualCaptureButton(),
                ]
            )
        )
        announceScreenChangeIfNeeded(.email, focusView: emailView.emailElement.view)
        if isReauthentication, view.window != nil {
            emailView.beginEditing()
        }
    }

    func renderOTP(state: NetworkedIdentityState) {
        visibleStep = .otp
        let showsInvalidCodeError = state == .awaitingOTP
            && coordinator.lastOTPError == .invalidCode
        if !showsInvalidCodeError {
            hasAnnouncedCurrentOTPError = false
        }
        let phoneNumber = coordinator.redactedFormattedPhoneNumber ?? ""
        let body = state == .otpStartPending
            ? content.otp.sendingBody(phoneNumber)
            : content.otp.body(phoneNumber)
        if state == .otpStartPending
            || phoneOtpView == nil
            || phoneNumber != displayedPhoneNumber
            || body != displayedOTPBody {
            displayedPhoneNumber = phoneNumber
            displayedOTPBody = body
            let phoneOtpView = PhoneOtpView(
                otpLength: 6,
                body: body,
                errorString: content.otp.invalidCodeMessage
            )
            phoneOtpView.delegate = self
            self.phoneOtpView = phoneOtpView
        }

        guard let phoneOtpView else {
            return
        }
        switch state {
        case .awaitingOTP where showsInvalidCodeError:
            phoneOtpView.configure(with: .ErrorOTP)
        case .awaitingOTP:
            phoneOtpView.configure(with: .InputtingOTP)
        case .otpStartPending, .otpConfirmPending:
            phoneOtpView.configure(with: .SubmittingOTP(""))
        default:
            return
        }

        configureFlow(
            with: .init(
                headerViewModel: plainHeader(title: content.otp.title),
                contentView: phoneOtpView,
                buttons: [manualCaptureButton()]
            )
        )
        announceScreenChangeIfNeeded(
            state == .otpStartPending ? .otpSending : .otp,
            focusView: phoneOtpView
        )
        if showsInvalidCodeError {
            announceInvalidOTPErrorIfNeeded()
        }
    }

    func renderDocuments() {
        visibleStep = .documents
        documentSelectionView.configure(
            bodyText: content.documents.body,
            documents: coordinator.availableDocuments,
            selectedDocumentID: coordinator.selectedDocument?.id,
            labelProvider: content.documents.label,
            accessibilityLabelProvider: content.documents.accessibilityLabel
        )
        configureFlow(
            with: .init(
                headerViewModel: plainHeader(title: content.documents.title),
                contentView: documentSelectionView,
                buttons: [manualCaptureButton()]
            )
        )
        announceScreenChangeIfNeeded(
            .documents,
            focusView: documentSelectionView.accessibilityFocusView
        )

        // #TODO - Networked Identity: Present reuse consent and continue into clone once those contracts are defined.
    }

    func renderDocumentLoading() {
        visibleStep = .documents
        documentSelectionView.configureLoading(bodyText: content.documents.loadingBody)
        configureFlow(
            with: .init(
                headerViewModel: plainHeader(title: content.documents.loadingTitle),
                contentView: documentSelectionView,
                buttons: [manualCaptureButton()]
            )
        )
        announceScreenChangeIfNeeded(
            .documentLoading,
            focusView: documentSelectionView.accessibilityFocusView
        )
    }

    func plainHeader(title: String) -> HeaderView.ViewModel {
        // #TODO - Networked Identity: Add approved Link co-branding when its StripeIdentity asset contract is defined.
        .init(
            backgroundColor: .systemBackground,
            headerType: .plain,
            titleText: title
        )
    }

    func manualCaptureButton() -> IdentityFlowView.ViewModel.Button {
        .init(
            text: content.manualCaptureButtonText,
            isPrimary: false,
            didTap: { [weak self] in
                self?.chooseManualCapture()
            }
        )
    }

    func configureFlow(with viewModel: IdentityFlowView.ViewModel) {
        do {
            try flowView.configure(with: viewModel)
        } catch {
            stpAssertionFailure("Networked Identity flow configuration failed: \(error)")
        }
    }

    private func announceScreenChangeIfNeeded(
        _ screen: AccessibilityScreen,
        focusView: UIView
    ) {
        guard announcedAccessibilityScreen != screen else {
            pendingAccessibilityScreen = nil
            pendingAccessibilityFocusView = nil
            return
        }
        pendingAccessibilityScreen = screen
        pendingAccessibilityFocusView = focusView
        postPendingAccessibilityScreenChangeIfNeeded()
    }

    private func postPendingAccessibilityScreenChangeIfNeeded() {
        guard view.window != nil,
              let pendingAccessibilityScreen,
              announcedAccessibilityScreen != pendingAccessibilityScreen else {
            return
        }
        let focusView = pendingAccessibilityFocusView
        announcedAccessibilityScreen = pendingAccessibilityScreen
        self.pendingAccessibilityScreen = nil
        pendingAccessibilityFocusView = nil
        UIAccessibility.post(notification: .screenChanged, argument: focusView)
    }

    private func announceInvalidOTPErrorIfNeeded() {
        guard !hasAnnouncedCurrentOTPError, view.window != nil else {
            return
        }
        hasAnnouncedCurrentOTPError = true
        UIAccessibility.post(
            notification: .announcement,
            argument: content.otp.invalidCodeMessage
        )
    }

    func clearOTPView() {
        phoneOtpView?.clear()
        phoneOtpView?.delegate = nil
        phoneOtpView = nil
        displayedPhoneNumber = nil
        displayedOTPBody = nil
        hasAnnouncedCurrentOTPError = false
    }

    func submitEmail() {
        guard emailView.hasValidEmailAddress else {
            emailView.emailElement.showValidationErrors()
            return
        }
        coordinator.start(emailAddress: emailView.emailAddress)
    }
}

// MARK: - Coordinator delegate

extension NetworkedIdentityFlowViewController: NetworkedIdentityCoordinatorDelegate {
    func networkedIdentityCoordinator(
        _ coordinator: NetworkedIdentityCoordinator,
        didTransitionTo state: NetworkedIdentityState
    ) {
        guard isViewLoaded else {
            return
        }
        render(state)
    }

    func networkedIdentityCoordinatorDidRequestFullCaptureFallback(
        _ coordinator: NetworkedIdentityCoordinator
    ) {
        guard !hasFinished, let reason = coordinator.fallbackReason else {
            return
        }
        hasFinished = true
        delegate?.networkedIdentityFlowViewController(self, didRequestFullCapture: reason)
    }
}

// MARK: - Screen delegates

extension NetworkedIdentityFlowViewController: NetworkedIdentityEmailViewDelegate {
    func networkedIdentityEmailViewDidUpdate(_ view: NetworkedIdentityEmailView) {
        guard coordinator.state == .collectEmail || coordinator.state == .reauthenticationRequired else {
            return
        }
        renderEmail(state: coordinator.state)
    }

    func networkedIdentityEmailViewDidSubmit(_ view: NetworkedIdentityEmailView) {
        submitEmail()
    }
}

extension NetworkedIdentityFlowViewController: PhoneOtpViewDelegate {
    func didInputFullOtp(newOtp: String) {
        coordinator.submitOTP(newOtp)
    }

    func viewStateDidUpdate() {
        // PhoneOtpView reports its own rendering changes; no surrounding UI changes are needed.
    }
}

extension NetworkedIdentityFlowViewController: NetworkedIdentityDocumentSelectionViewDelegate {
    func networkedIdentityDocumentSelectionView(
        _ view: NetworkedIdentityDocumentSelectionView,
        didSelect document: NetworkedIdentityDocument
    ) {
        coordinator.selectDocument(document)
    }
}

// MARK: - Completion and keyboard handling

private extension NetworkedIdentityFlowViewController {
    @objc func didTapCancel() {
        cancel()
    }

    func finishCancellationIfNeeded() {
        guard !hasFinished else {
            return
        }
        hasFinished = true
        delegate?.networkedIdentityFlowViewControllerDidCancel(self)
    }

    func observeKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChange),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChange),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }

    @objc func keyboardWillChange(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
            as? NSValue else {
            return
        }
        flowView.adjustScrollViewForKeyboard(
            keyboardValue.cgRectValue,
            isKeyboardHidden: notification.name == UIResponder.keyboardWillHideNotification
        )
    }
}
