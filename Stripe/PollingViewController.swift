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
    
    // MARK: State
    
    private let deadline = Date().addingTimeInterval(60 * 5) // in 5 minutes
    private var oneSecondTimer = Timer()
    private let currentAction: STPPaymentHandlerActionParams
    private let apperance: PaymentSheet.Appearance
    
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
    
    // MARK: Views
    
    lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [actvityIndicator,
                                                       titleLabel,
                                                       instructionLabel,
                                                       cancelButton])
        stackView.directionalLayoutMargins = PaymentSheetUI.defaultMargins
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.axis = .vertical
        stackView.spacing = 14
        
        return stackView
    }()
    
    private lazy var actvityIndicator: ActivityIndicator = {
        let indicator = ActivityIndicator(size: .large)
        indicator.tintColor = apperance.colors.primary
        indicator.startAnimating()
        return indicator
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.text = .Localized.approve_payment
        label.textColor = apperance.colors.text
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.sizeToFit()
        return label
    }()
    
    private lazy var instructionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = apperance.colors.textSecondary
        label.text = String(
            format: .Localized.open_upi_app,
            dateFormatter.string(from: timeRemaining) ?? ""
        )
        label.sizeToFit()
        return label
    }()
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(.Localized.cancel_pay_another_way, for: .normal)
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
        button.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)
        button.tintColor = apperance.colors.primary
        return button
    }()
    
    internal lazy var navigationBar: SheetNavigationBar = {
        let navBar = SheetNavigationBar(isTestMode: false,
                                        appearance: apperance)
        navBar.setStyle(.none)
        return navBar
    }()
    
    // MARK: Overrides
    
    init(currentAction: STPPaymentHandlerActionParams, appearance: PaymentSheet.Appearance) {
        self.currentAction = currentAction
        self.apperance = appearance
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let stackView = UIStackView(arrangedSubviews: [stackView])
        stackView.spacing = PaymentSheetUI.defaultPadding
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.backgroundColor = apperance.colors.background
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            view.heightAnchor.constraint(equalTo: stackView.heightAnchor)
        ])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.intentPoller.beginPolling()
        }
        oneSecondTimer = Timer.scheduledTimer(timeInterval: 1,
                                              target: self,
                                              selector: (#selector(updateTimer)),
                                              userInfo: nil,
                                              repeats: true) // TODO will get this out of sync if shown, then hide, then show?
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        intentPoller.suspendPolling()
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
    }
    
    // MARK: Timer
    
    @objc func updateTimer() {
        guard timeRemaining > 0 else {
            oneSecondTimer.invalidate()
            // Do one last force poll after 5 min
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.intentPoller.forcePoll()
            }
            // TODO(porter) dismiss and cancel after x seconds if force poll doesn't result in a success
            return
        }
        
        instructionLabel.text = String(
            format: .Localized.open_upi_app,
            dateFormatter.string(from: timeRemaining) ?? ""
        )
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

// MARK: IntentStatusPollerDelegate

extension PollingViewController: IntentStatusPollerDelegate {
    func didUpdate(paymentIntent: STPPaymentIntent) {
        // TODO(porter) Handle other intent terminal states?
        guard let currentAction = currentAction as? STPPaymentHandlerPaymentIntentActionParams else { return }
        
        if paymentIntent.status == .succeeded {
            currentAction.paymentIntent = paymentIntent
            currentAction.complete(with: .succeeded, error: nil)
            dismiss()
        }
    }
}
