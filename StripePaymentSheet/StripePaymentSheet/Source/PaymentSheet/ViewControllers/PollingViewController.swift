//
//  PollingViewController.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 9/2/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import SafariServices
@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripePayments
@_spi(InternalOnlyAPI) import StripePaymentsUI
@_spi(InternalOnlyAPI) import StripeUICore
import UIKit

/// Shows "approve the payment in your app" with a countdown while it polls the intent, then finishes the payment.
///
/// It doesn't know about STPPaymentHandler: it takes a display config (`PollingViewModel`), a `poll` closure that reads
/// the intent once, and a `complete` closure. STPPaymentHandler's polling next actions use
/// `init(currentAction:viewModel:appearance:safariViewController:)`, which adapts its action params; `PaymentConfirmer`
/// passes its own closures.
/// For internal SDK use only
@objc(STP_Internal_PollingViewController)
class PollingViewController: UIViewController {
    private enum PollingState {
        case polling
        case error
    }

    /// One read of the intent.
    struct PollResult {
        let status: STPPaymentHandlerPollingStatus
        /// Accepts the read intent as the payment's latest, e.g. STPPaymentHandler's action params.
        let accept: () -> Void
    }

    /// Reads the intent once. `nil` means the read failed; polling keeps going.
    typealias Poll = (@escaping (PollResult?) -> Void) -> Void

    // MARK: State

    private var oneSecondTimer: Timer?
    /// Set by `stopPolling`, so becoming active again doesn't restart polling.
    private var isStopped = false
    private let authenticationContext: PaymentSheetAuthenticationContext?
    private let poll: Poll
    private let completion: (STPPaymentHandlerActionStatus) -> Void
    private let appearance: PaymentSheet.Appearance
    let viewModel: PollingViewModel
    private let safariViewController: SFSafariViewController?

    private lazy var intentStatusPoller = IntentStatusPoller<PollResult, STPPaymentHandlerPollingStatus>(
        retryInterval: viewModel.retryInterval,
        retrieveValue: poll,
        status: \.status,
        didUpdate: { [weak self] result in
            self?.didUpdate(result)
        }
    )

    private var timeRemaining: TimeInterval {
        return Date().distance(to: viewModel.deadline)
    }

    private var dateFormatter: DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        if timeRemaining > 60 {
            formatter.zeroFormattingBehavior = .dropLeading
        } else {
            formatter.zeroFormattingBehavior = .pad
        }
        formatter.allowedUnits = [.minute, .second]
        return formatter
    }

    private var instructionLabelAttributedText: NSAttributedString {
        guard viewModel.showsCountdown else {
            return NSAttributedString(string: viewModel.CTA)
        }
        let timeRemaining = dateFormatter.string(from: timeRemaining) ?? ""
        let attrText = NSMutableAttributedString(string: String(
                format: viewModel.CTA,
                timeRemaining
        ))
        attrText.addAttributes([.foregroundColor: appearance.colors.primary],
                               range: NSString(string: attrText.string).range(of: timeRemaining))
        return attrText
    }

    private var pollingState: PollingState = .polling {
        didSet {
            if oldValue != pollingState && pollingState == .error {
                moveToErrorState()
            }
        }
    }

    private lazy var setErrorStateWorkItem: DispatchWorkItem = {
        let workItem = DispatchWorkItem { [weak self] in
            self?.pollingState = .error
        }

        return workItem
    }()

    // MARK: Views

    lazy var formStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [errorImageView,
                                                       actvityIndicator,
                                                       titleLabel,
                                                       instructionLabel,
                                                       cancelButton, ])
        stackView.directionalLayoutMargins = appearance.formInsets
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.axis = .vertical
        // hard coded spacing values from figma
        stackView.spacing = 18
        stackView.setCustomSpacing(14, after: errorImageView)
        stackView.setCustomSpacing(8, after: titleLabel)
        stackView.setCustomSpacing(12, after: instructionLabel)
        return stackView
    }()

    private lazy var actvityIndicator: ActivityIndicator = {
        let indicator = ActivityIndicator(size: .large)
        indicator.tintColor = appearance.colors.icon
        indicator.startAnimating()
        return indicator
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.text = .Localized.approve_payment
        label.textColor = appearance.colors.text
        label.font = appearance.scaledFont(for: appearance.font.base.medium, style: .body, maximumPointSize: 25)
        label.sizeToFit()
        return label
    }()

    private lazy var instructionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = appearance.scaledFont(for: appearance.font.base.regular, style: .subheadline, maximumPointSize: 22)
        label.textColor = appearance.colors.textSecondary
        label.attributedText = instructionLabelAttributedText
        label.sizeToFit()
        return label
    }()

    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(.Localized.cancel_pay_another_way, for: .normal)
        button.titleLabel?.font = appearance.scaledFont(for: appearance.font.base.regular, style: .footnote, maximumPointSize: 22)
        button.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)
        button.tintColor = appearance.colors.primary
        return button
    }()

    // MARK: Error state views

    private lazy var errorImageView: UIImageView = {
        let imageView = UIImageView(image: Image.polling_error.makeImage(template: true))
        imageView.tintColor = appearance.colors.danger
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
    }()

    // MARK: Navigation bar

    internal lazy var navigationBar: SheetNavigationBar = {
        let navBar = SheetNavigationBar(appearance: appearance)
        navBar.delegate = self
        navBar.setStyle(.none)
        return navBar
    }()

    // MARK: Overrides

    /// - Parameters:
    ///   - deadline: Overrides the view model's deadline, e.g. Pix's `expires_at`.
    ///   - authenticationContext: Dismisses the screen.
    ///   - complete: Called once, with `.succeeded` or `.canceled`.
    init(
        viewModel: PollingViewModel,
        deadline: Date? = nil,
        authenticationContext: PaymentSheetAuthenticationContext?,
        poll: @escaping Poll,
        complete: @escaping (STPPaymentHandlerActionStatus) -> Void,
        appearance: PaymentSheet.Appearance,
        safariViewController: SFSafariViewController? = nil
    ) {
        self.authenticationContext = authenticationContext
        self.poll = poll
        self.completion = complete
        self.appearance = appearance
        self.viewModel = viewModel
        if let deadline {
            self.viewModel.deadline = deadline
        }
        self.safariViewController = safariViewController

        super.init(nibName: nil, bundle: nil)
    }

    /// For STPPaymentHandler's polling next actions (`PaymentSheetAuthenticationContext.presentPollingVCForAction`).
    convenience init(currentAction: STPPaymentHandlerActionParams, viewModel: PollingViewModel, appearance: PaymentSheet.Appearance, safariViewController: SFSafariViewController? = nil) {
        self.init(
            viewModel: viewModel,
            deadline: currentAction.nextAction()?.pixDisplayQrCode?.expiresAt,
            authenticationContext: currentAction.authenticationContext as? PaymentSheetAuthenticationContext,
            poll: { completion in
                currentAction.retrievePollingResult { result in
                    completion(result.map { result in PollResult(status: result.status, accept: result.updateActionIntent) })
                }
            },
            complete: { status in
                currentAction.complete(with: status, error: nil)
            },
            appearance: appearance,
            safariViewController: safariViewController
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // disable swipe to dismiss
        isModalInPresentation = true

        #if os(visionOS)
        let height = parent?.view.frame.size.height ?? 600 // An arbitrary value for visionOS
        #else
        // Height of the polling view controller is either the height of the parent, or the height of the screen (flow controller use case)
        let height = parent?.view.frame.size.height ?? UIScreen.main.bounds.height
        #endif
        let stackView = UIStackView(arrangedSubviews: [formStackView])
        stackView.spacing = PaymentSheetUI.defaultPadding
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.backgroundColor = appearance.colors.background
        view.backgroundColor = appearance.colors.background
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            view.heightAnchor.constraint(equalToConstant: height - SheetNavigationBar.height(appearance: appearance)),
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if oneSecondTimer == nil {
            oneSecondTimer = Timer.scheduledTimer(timeInterval: 1,
                                  target: self,
                                  selector: (#selector(updateTimer)),
                                  userInfo: nil,
                                  repeats: true)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            self?.beginPolling()
        }

        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        suspendPolling()

        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Handlers

    @objc func didTapCancel() {
        dismiss {
            // Wait a short amount of time before completing the action to ensure smooth animations
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.complete(with: .canceled)
            }
        }
    }

    private func dismiss(completion: (() -> Void)? = nil) {
        if let authContext = authenticationContext {
            authContext.authenticationContextWillDismiss?(self)
            authContext.dismiss(self, completion: completion)
        }

        oneSecondTimer?.invalidate()
    }

    // MARK: App lifecycle observers

    @objc func didBecomeActive(_ notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.beginPolling()
        }
    }

    @objc func didEnterBackground(_ notification: Notification) {
        suspendPolling()
    }

    // MARK: Timer handler

    @objc func updateTimer() {
        guard timeRemaining > 0 else {
            oneSecondTimer?.invalidate()
            finishPolling()
            return
        }

        instructionLabel.attributedText = instructionLabelAttributedText
    }

    // MARK: Private helpers

    private func moveToErrorState() {
        DispatchQueue.main.async {
            self.errorImageView.isHidden = false
            self.actvityIndicator.isHidden = true
            self.cancelButton.isHidden = true
            self.titleLabel.text = .Localized.payment_failed
            self.instructionLabel.text = .Localized.please_go_back
            self.navigationBar.setStyle(.back(showAdditionalButton: false))
            self.suspendPolling()
            self.oneSecondTimer?.invalidate()

            // If the intent is canceled while a web view is presented, we must dismiss it before we can complete the action with .canceled so STPPaymentHandler can properly update its state
            self.safariViewController?.dismiss(animated: true)
            self.complete(with: .canceled)
        }
    }

    // Called after the timer expires to wrap up polling
    private func finishPolling() {
        self.suspendPolling()

        // Do one last force poll after deadline
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let self = self else { return }
            self.pollOnce { [weak self] succeeded in
                if !succeeded {
                    self?.pollingState = .error
                }
            }
        }
    }

    private func beginPolling() {
        guard !isStopped else { return }
        intentStatusPoller.beginPolling()
    }

    private func suspendPolling() {
        intentStatusPoller.suspendPolling()
    }

    private func pollOnce(completion: @escaping (Bool) -> Void) {
        intentStatusPoller.pollOnce { completion($0 == .succeeded) }
    }

    private func complete(with status: STPPaymentHandlerActionStatus) {
        completion(status)
    }

    /// Tests: finishes as if polling saw `status`.
    func _testFinish(with status: STPPaymentHandlerActionStatus) {
        complete(with: status)
    }

    /// Stops polling without finishing, e.g. because the payment finished elsewhere.
    func stopPolling() {
        isStopped = true
        suspendPolling()
        setErrorStateWorkItem.cancel()
        oneSecondTimer?.invalidate()
    }

    private func didUpdate(_ result: PollResult) {
        result.accept()
        switch result.status {
        case .pending:
            break
        case .succeeded:
            setErrorStateWorkItem.cancel()
            dismiss {
                self.complete(with: .succeeded)
            }
        case .failed:
            pollingState = .error
        }
    }

}

// MARK: BottomSheetContentViewController

extension PollingViewController: BottomSheetContentViewController {

    var allowsDragToDismiss: Bool {
        return false
    }

    func didTapOrSwipeToDismiss() {
        // no-op
    }

    var requiresFullScreen: Bool {
        return false
    }
}

// MARK: SheetNavigationBarDelegate

extension PollingViewController: SheetNavigationBarDelegate {

    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
        dismiss()
    }

    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {
        dismiss()
    }

}

// MARK: - Hosting

/// A PaymentSheet container that shows a polling screen someone else built: pushed into the sheet, presented, or
/// presented once the web view in front of it closes. STPPaymentHandler's `presentPollingVCForAction` and
/// `PaymentConfirmer` both go through it.
protocol PollingScreenHosting: PaymentSheetAuthenticationContext {
    var pollingScreenAppearance: PaymentSheet.Appearance { get }
    /// - Parameter safariViewController: The web view showing in front of the screen (PayNow, PromptPay, Pix), if any.
    func presentPollingViewController(_ pollingViewController: PollingViewController, safariViewController: SFSafariViewController?)
}

extension PollingScreenHosting {
    /// STPPaymentHandler's polling next actions.
    func presentPollingVCForAction(action: STPPaymentHandlerActionParams, type: STPPaymentMethodType, safariViewController: SFSafariViewController?) {
        let pollingVC = PollingViewController(currentAction: action, viewModel: PollingViewModel(paymentMethodType: type),
                                              appearance: pollingScreenAppearance, safariViewController: safariViewController)
        presentPollingViewController(pollingVC, safariViewController: safariViewController)
    }
}
