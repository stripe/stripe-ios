//
//  PollingViewController.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 9/2/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import SafariServices
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

/// For internal SDK use only
@objc(STP_Internal_PollingViewController)
class PollingViewController: UIViewController {
    private enum PollingState {
        case polling
        case error
    }

    // MARK: State

    private var oneSecondTimer: Timer?
    private let paymentIntentAction: STPPaymentHandlerPaymentIntentActionParams?
    private let setupIntentAction: STPPaymentHandlerSetupIntentActionParams?
    private let appearance: PaymentSheet.Appearance
    private let viewModel: PollingViewModel
    private let safariViewController: SFSafariViewController?

    private lazy var paymentIntentPoller: IntentStatusPoller? = {
        guard let paymentIntentAction else { return nil }
        let poller = IntentStatusPoller(
            retryInterval: viewModel.retryInterval,
            intentRetriever: paymentIntentAction.apiClient,
            clientSecret: paymentIntentAction.paymentIntent.clientSecret
        )
        poller.delegate = self
        return poller
    }()

    private lazy var setupIntentPoller: SetupIntentStatusPoller? = {
        guard let setupIntentAction else { return nil }
        let poller = SetupIntentStatusPoller(
            retryInterval: viewModel.retryInterval,
            intentRetriever: setupIntentAction.apiClient,
            clientSecret: setupIntentAction.setupIntent.clientSecret
        )
        poller.delegate = self
        return poller
    }()

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
        let navBar = SheetNavigationBar(isTestMode: false,
                                        appearance: appearance)
        navBar.delegate = self
        navBar.setStyle(.none)
        return navBar
    }()

    // MARK: Overrides

    init(currentAction: STPPaymentHandlerPaymentIntentActionParams, viewModel: PollingViewModel, appearance: PaymentSheet.Appearance, safariViewController: SFSafariViewController? = nil) {
        self.paymentIntentAction = currentAction
        self.setupIntentAction = nil
        self.appearance = appearance
        self.viewModel = viewModel
        if let expiresAt = currentAction.paymentIntent.nextAction?.pixDisplayQrCode?.expiresAt {
            self.viewModel.deadline = expiresAt
        }
        self.safariViewController = safariViewController

        super.init(nibName: nil, bundle: nil)
    }

    init(currentAction: STPPaymentHandlerSetupIntentActionParams, viewModel: PollingViewModel, appearance: PaymentSheet.Appearance, safariViewController: SFSafariViewController? = nil) {
        self.paymentIntentAction = nil
        self.setupIntentAction = currentAction
        self.appearance = appearance
        self.viewModel = viewModel
        if let expiresAt = currentAction.setupIntent.nextAction?.pixDisplayQrCode?.expiresAt {
            self.viewModel.deadline = expiresAt
        }
        self.safariViewController = safariViewController

        super.init(nibName: nil, bundle: nil)
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
        let authenticationContext = paymentIntentAction?.authenticationContext ?? setupIntentAction?.authenticationContext
        if let authContext = authenticationContext as? PaymentSheetAuthenticationContext {
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
        paymentIntentPoller?.beginPolling()
        setupIntentPoller?.beginPolling()
    }

    private func suspendPolling() {
        paymentIntentPoller?.suspendPolling()
        setupIntentPoller?.suspendPolling()
    }

    private func pollOnce(completion: @escaping (Bool) -> Void) {
        if let paymentIntentPoller {
            paymentIntentPoller.pollOnce { completion($0 == .succeeded) }
        } else if let setupIntentPoller {
            setupIntentPoller.pollOnce { completion($0 == .succeeded) }
        }
    }

    private func complete(with status: STPPaymentHandlerActionStatus) {
        paymentIntentAction?.complete(with: status, error: nil)
        setupIntentAction?.complete(with: status, error: nil)
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

// MARK: IntentStatusPollerDelegate

extension PollingViewController: IntentStatusPollerDelegate {
    func didUpdate(paymentIntent: STPPaymentIntent) {
        if paymentIntent.status == .succeeded {
            setErrorStateWorkItem.cancel() // cancel the error work item incase it was scheduled
            paymentIntentAction?.paymentIntent = paymentIntent // update the local copy of the intent with the latest from the server
            dismiss {
                self.complete(with: .succeeded)
            }
        } else if paymentIntent.status != .requiresAction {
            // an error occured to take the intent out of requires action
            // update polling state to indicate that we have encountered an error
            pollingState = .error
        }
    }
}

extension PollingViewController: SetupIntentStatusPollerDelegate {
    func didUpdate(setupIntent: STPSetupIntent) {
        if setupIntent.status == .succeeded {
            setErrorStateWorkItem.cancel()
            setupIntentAction?.setupIntent = setupIntent
            dismiss {
                self.complete(with: .succeeded)
            }
        } else if setupIntent.status != .requiresAction {
            pollingState = .error
        }
    }
}
