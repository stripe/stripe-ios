//
//  PollingViewController.swift
//  StripeiOS
//
//  Created by Nick Porter on 9/2/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

/// For internal SDK use only
@objc(STP_Internal_PollingViewController)
class PollingViewController: UIViewController {
    private enum PollingState {
        case polling
        case error
    }
    
    // MARK: State
    
    private let deadline = Date().addingTimeInterval(60 * 5) // in 5 minutes
    private var oneSecondTimer: Timer?
    private let currentAction: STPPaymentHandlerActionParams
    private let appearance: PaymentSheet.Appearance
    
    private lazy var intentPoller: IntentStatusPoller = {
        guard let currentAction = currentAction as? STPPaymentHandlerPaymentIntentActionParams,
              let clientSecret = currentAction.paymentIntent?.clientSecret else { fatalError() }
        
        let intentPoller = IntentStatusPoller(apiClient: currentAction.apiClient,
                                              clientSecret: clientSecret,
                                              maxRetries: 12)
        intentPoller.delegate = self
        return intentPoller
    }()
    
    private var timeRemaining: TimeInterval {
        return Date().compatibleDistance(to: deadline)
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
        let timeRemaining = dateFormatter.string(from: timeRemaining) ?? ""
        let attrText = NSMutableAttributedString(string: String(
            format: .Localized.open_upi_app,
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
                                                       cancelButton])
        stackView.directionalLayoutMargins = PaymentSheetUI.defaultMargins
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
    
    init(currentAction: STPPaymentHandlerActionParams, appearance: PaymentSheet.Appearance) {
        self.currentAction = currentAction
        self.appearance = appearance
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Height of the polling view controller is either the height of the parent, or the height of the screen (flow controller use case)
        let height = parent?.view.frame.size.height ?? UIScreen.main.bounds.height
        
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
            view.heightAnchor.constraint(equalToConstant: height - SheetNavigationBar.height),
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.intentPoller.beginPolling()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        intentPoller.suspendPolling()
        
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Handlers
    
    @objc func didTapCancel() {
        currentAction.complete(with: .canceled, error: nil)
        dismiss()
    }
    
    private func dismiss() {
        if let authContext = currentAction.authenticationContext as? PaymentSheetAuthenticationContext {
            authContext.authenticationContextWillDismiss?(self)
            authContext.dismiss(self)
        }
        
        oneSecondTimer?.invalidate()
    }
    
    // MARK: App lifecycle observers

    @objc func didBecomeActive(_ notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.intentPoller.beginPolling()
        }
    }
    
    
    @objc func didEnterBackground(_ notification: Notification) {
        intentPoller.suspendPolling()
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
            self.navigationBar.setStyle(.back)
            self.intentPoller.suspendPolling()
            self.oneSecondTimer?.invalidate()
            self.currentAction.complete(with: .canceled, error: nil)
        }
    }
    
    // Called after the 5 minute timer expires to wrap up polling
    private func finishPolling() {
        // Do one last force poll after 5 min
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let self = self else { return }
            self.intentPoller.forcePoll()
            // If we don't get a terminal status back after 20 seconds from the previous force poll, set error state to suspend polling.
            // This could occur if network connections are unreliable
            DispatchQueue.main.asyncAfter(deadline: .now() + 20, execute: self.setErrorStateWorkItem)
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

// MARK: IntentStatusPollerDelegate

extension PollingViewController: IntentStatusPollerDelegate {
    func didUpdate(paymentIntent: STPPaymentIntent) {
        guard let currentAction = currentAction as? STPPaymentHandlerPaymentIntentActionParams else { return }
        
        if paymentIntent.status == .succeeded {
            setErrorStateWorkItem.cancel() // cancel the error work item incase it was scheduled
            currentAction.paymentIntent = paymentIntent // update the local copy of the intent with the latest from the server
            currentAction.complete(with: .succeeded, error: nil)
            dismiss()
        } else if paymentIntent.status != .requiresAction {
            // an error occured to take the intent out of requires action
            // update polling state to indicate that we have encountered an error
            pollingState = .error
        }
    }
}
