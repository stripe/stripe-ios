//
//  PaymentSheetViewController.swift
//  Stripe
//
//  Created by Yuki Tokuhiro on 9/12/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import PassKit
import UIKit

protocol PaymentSheetViewControllerDelegate: AnyObject {
    func paymentSheetViewControllerShouldConfirm(
        _ paymentSheetViewController: PaymentSheetViewController, with paymentOption: PaymentOption,
        completion: @escaping (PaymentSheetResult) -> Void)
    func paymentSheetViewControllerDidFinish(
        _ paymentSheetViewController: PaymentSheetViewController, result: PaymentSheetResult)
    func paymentSheetViewControllerDidCancel(
        _ paymentSheetViewController: PaymentSheetViewController)
}

class PaymentSheetViewController: UIViewController {
    // MARK: - Read-only Properties
    let savedPaymentMethods: [STPPaymentMethod]
    let isApplePayEnabled: Bool
    let configuration: PaymentSheet.Configuration

    // MARK: - Writable Properties
    weak var delegate: PaymentSheetViewControllerDelegate?
    private(set) var intent: Intent
    enum Mode {
        case selectingSaved
        case addingNew
    }
    private var mode: Mode
    private(set) var error: Error?
    private var isPaymentInFlight: Bool = false
    private(set) var isDismissable: Bool = true

    // MARK: - Views

    private lazy var addPaymentMethodViewController: AddPaymentMethodViewController = {
        let paymentMethodTypes = PaymentSheet.paymentMethodTypes(
            for: intent,
            customerID: configuration.customer?.id
        )
        let shouldDisplaySavePaymentMethodCheckbox: Bool = {
            switch intent {
            case .paymentIntent:
                return configuration.customer != nil
            case .setupIntent:
                return false
            }
        }()
        return AddPaymentMethodViewController(
            paymentMethodTypes: paymentMethodTypes,
            shouldDisplaySavePaymentMethodCheckbox: shouldDisplaySavePaymentMethodCheckbox,
            billingAddressCollection: configuration.billingAddressCollectionLevel,
            merchantDisplayName: configuration.merchantDisplayName,
            delegate: self)
    }()
    private lazy var savedPaymentOptionsViewController: SavedPaymentOptionsViewController = {
        return SavedPaymentOptionsViewController(
            savedPaymentMethods: savedPaymentMethods,
            customerID: configuration.customer?.id,
            isApplePayEnabled: isApplePayEnabled,
            delegate: self)

    }()
    internal lazy var navigationBar: SheetNavigationBar = {
        let navBar = SheetNavigationBar()
        navBar.delegate = self
        return navBar
    }()
    private lazy var applePayHeader: ApplePayHeaderView = {
        return ApplePayHeaderView(didTap: didTapApplePayButton)
    }()
    private lazy var headerLabel: UILabel = {
        return PaymentSheetUI.makeHeaderLabel()
    }()
    private lazy var paymentContainerView: BottomPinningContainerView = {
        return BottomPinningContainerView()
    }()
    private lazy var errorLabel: UILabel = {
        return PaymentSheetUI.makeErrorLabel()
    }()
    private lazy var buyButton: ConfirmButton = {
        let callToAction: ConfirmButton.CallToActionType = {
            switch intent {
            case .paymentIntent(let paymentIntent):
                return .pay(amount: paymentIntent.amount, currency: paymentIntent.currency)
            case .setupIntent:
                return .setup
            }
        }()
        let button = ConfirmButton(
            style: .stripe,
            callToAction: callToAction,
            didTap: didTapBuyButton)
        return button
    }()

    // MARK: - Init

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(
        intent: Intent,
        savedPaymentMethods: [STPPaymentMethod],
        configuration: PaymentSheet.Configuration,
        isApplePayEnabled: Bool,
        delegate: PaymentSheetViewControllerDelegate
    ) {
        self.intent = intent
        self.savedPaymentMethods = savedPaymentMethods
        self.configuration = configuration
        self.isApplePayEnabled = isApplePayEnabled
        self.delegate = delegate

        if savedPaymentMethods.isEmpty {
            self.mode = .addingNew
        } else {
            self.mode = .selectingSaved
        }

        super.init(nibName: nil, bundle: nil)
    }

    // MARK: UIViewController Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        // One stack view contains all our subviews
        let stackView = UIStackView(arrangedSubviews: [
            headerLabel, applePayHeader, paymentContainerView, errorLabel, buyButton,
        ])
        stackView.directionalLayoutMargins = PaymentSheetUI.defaultMargins
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.spacing = PaymentSheetUI.defaultPadding
        stackView.axis = .vertical
        stackView.bringSubviewToFront(headerLabel)

        // Hack: Payment container needs to extend to the edges, so we'll 'cancel out' the layout margins with negative padding
        paymentContainerView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 0, leading: -PaymentSheetUI.defaultSheetMargins.leading, bottom: 0,
            trailing: -PaymentSheetUI.defaultSheetMargins.trailing)

        [stackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor, constant: -PaymentSheetUI.defaultSheetMargins.bottom),
        ])

        updateUI(animated: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        STPAnalyticsClient.sharedClient.logPaymentSheetShow(isCustom: false, paymentMethod: mode.analyticsValue)
    }

    // MARK: Private Methods

    private func configureNavBar() {
        navigationBar.setStyle(
            {
                switch mode {
                case .selectingSaved:
                    if self.savedPaymentOptionsViewController.hasRemovablePaymentMethods {
                        self.configureEditSavedPaymentMethodsButton()
                        return .close(showAdditionalButton: true)
                    } else {
                        self.navigationBar.additionalButton.removeTarget(
                            self, action: #selector(didSelectEditSavedPaymentMethodsButton),
                            for: .touchUpInside)
                        return .close(showAdditionalButton: false)
                    }
                case .addingNew:
                    self.navigationBar.additionalButton.removeTarget(
                        self, action: #selector(didSelectEditSavedPaymentMethodsButton),
                        for: .touchUpInside)
                    return savedPaymentMethods.isEmpty ? .close(showAdditionalButton: false) : .back
                }
            }())

    }

    // state -> view
    private func updateUI(animated: Bool = true) {
        // Disable interaction if necessary
        if isPaymentInFlight {
            sendEventToSubviews(.shouldDisableUserInteraction, from: view)
            view.isUserInteractionEnabled = false
            isDismissable = false
        } else {
            sendEventToSubviews(.shouldEnableUserInteraction, from: view)
            view.isUserInteractionEnabled = true
            isDismissable = true
        }

        // Update our views (starting from the top of the screen):
        configureNavBar()

        // Content header
        applePayHeader.isHidden = {
            switch mode {
            case .selectingSaved:
                return true
            case .addingNew:
                // We already showed Apple Pay in the saved payment methods carousel, so don't show it here
                return !(isApplePayEnabled && savedPaymentMethods.isEmpty)
            }
        }()
        applePayHeader.orPayWithLabel.text = {
            if addPaymentMethodViewController.paymentMethodTypes == [.card] {
                return STPLocalizedString(
                    "Or pay with a card",
                    "Title of a section displayed below an Apple Pay button. The section contains a credit card form as an alternative way to pay."
                )
            } else {
                return STPLocalizedString(
                    "Or pay using",
                    "Title of a section displayed below an Apple Pay button. The section contains alternative ways to pay."
                )
            }
        }()

        headerLabel.isHidden = !applePayHeader.isHidden
        headerLabel.text =
            mode == .selectingSaved
            ? STPLocalizedString(
                "Select your payment method",
                "Title shown above a carousel containing the customer's payment methods")
            : STPLocalizedString(
                "Add your payment information",
                "Title shown above a form where the customer can enter payment information like credit card details, email, billing address, etc."
            )

        // Content
        switchContentIfNecessary(
            to: mode == .selectingSaved
                ? savedPaymentOptionsViewController : addPaymentMethodViewController,
            containerView: paymentContainerView
        )

        // Error
        switch mode {
        case .addingNew:
            if addPaymentMethodViewController.setErrorIfNecessary(for: error) == false {
                errorLabel.text = error?.localizedDescription
            }
        case .selectingSaved:
            errorLabel.text = error?.localizedDescription
        }
        UIView.animate(withDuration: PaymentSheetUI.defaultAnimationDuration) {
            self.errorLabel.setHiddenIfNecessary(self.error == nil)
        }

        // Buy button
        let buyButtonStyle: ConfirmButton.Style
        var buyButtonStatus: ConfirmButton.Status
        switch mode {
        case .selectingSaved:
            if case .applePay = savedPaymentOptionsViewController.selectedPaymentOption {
                buyButtonStyle = .applePay
            } else {
                buyButtonStyle = .stripe
            }
            buyButtonStatus = .enabled
        case .addingNew:
            buyButtonStyle = .stripe
            buyButtonStatus =
                addPaymentMethodViewController.paymentOption == nil ? .disabled : .enabled
        }
        if isPaymentInFlight {
            buyButtonStatus = .processing
        }
        self.buyButton.update(
            state: buyButtonStatus,
            style: buyButtonStyle,
            animated: animated,
            completion: nil
        )
    }

    @objc
    private func didTapApplePayButton() {
        pay(with: .applePay)
    }

    @objc
    private func didTapBuyButton() {
        switch mode {
        case .addingNew:
            guard let newPaymentOption = addPaymentMethodViewController.paymentOption else {
                assertionFailure()
                return
            }
            pay(with: newPaymentOption)
        case .selectingSaved:
            guard
                let selectedPaymentOption = savedPaymentOptionsViewController.selectedPaymentOption
            else {
                assertionFailure()
                return
            }
            pay(with: selectedPaymentOption)
        }
    }

    private func pay(with paymentOption: PaymentOption) {
        view.endEditing(true)
        isPaymentInFlight = true
        // Clear any errors
        error = nil
        updateUI()

        // Confirm the payment with the payment option
        let startTime = NSDate.timeIntervalSinceReferenceDate
        self.delegate?.paymentSheetViewControllerShouldConfirm(self, with: paymentOption) {
            result in
            let elapsedTime = NSDate.timeIntervalSinceReferenceDate - startTime
            DispatchQueue.main.asyncAfter(
                deadline: .now() + max(PaymentSheetUI.minimumFlightTime - elapsedTime, 0)
            ) {
                STPAnalyticsClient.sharedClient.logPaymentSheetPayment(isCustom: false,
                                                                       paymentMethod: paymentOption.analyticsValue,
                                                                       result: result)
                self.isPaymentInFlight = false
                switch result {
                case .canceled:
                    // Do nothing, keep customer on payment sheet
                    self.updateUI()
                case .failed(let error):
                    // Update state
                    self.error = error
                    // Handle error
                    if PaymentSheetError.isUnrecoverable(error: error) {
                        self.delegate?.paymentSheetViewControllerDidFinish(self, result: result)
                    }
                    self.updateUI()
                    UIAccessibility.post(notification: .layoutChanged, argument: self.errorLabel)
                case .completed:
                    // We're done!
                    let delay: TimeInterval =
                        self.presentedViewController?.isBeingDismissed == true ? 1 : 0
                    // Hack: PaymentHandler calls the completion block while SafariVC is still being dismissed - "wait" until it's finished before updating UI
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        self.buyButton.update(state: .succeeded, animated: true)
                        DispatchQueue.main.asyncAfter(
                            deadline: .now() + PaymentSheetUI.delayBetweenSuccessAndDismissal
                        ) {
                            // Wait a bit before closing the sheet
                            self.delegate?.paymentSheetViewControllerDidFinish(
                                self, result: .completed)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - BottomSheetContentViewController
/// :nodoc:
extension PaymentSheetViewController: BottomSheetContentViewController {
    var allowsDragToDismiss: Bool {
        return isDismissable
    }

    func didTapOrSwipeToDismiss() {
        if isDismissable {
            delegate?.paymentSheetViewControllerDidCancel(self)
        }
    }

    var requiresFullScreen: Bool {
        return false
    }
}

// MARK: - SavedPaymentOptionsViewControllerDelegate
/// :nodoc:
extension PaymentSheetViewController: SavedPaymentOptionsViewControllerDelegate {
    func didUpdateSelection(
        viewController: SavedPaymentOptionsViewController,
        paymentMethodSelection: SavedPaymentOptionsViewController.Selection
    ) {
        STPAnalyticsClient.sharedClient.logPaymentSheetPaymentOptionSelect(isCustom: false, paymentMethod: paymentMethodSelection.analyticsValue)
        if case .add = paymentMethodSelection {
            mode = .addingNew
            error = nil  // Clear any errors
        }
        updateUI()
    }

    func didSelectRemove(
        viewController: SavedPaymentOptionsViewController,
        paymentMethodSelection: SavedPaymentOptionsViewController.Selection
    ) {
        guard case .saved(let paymentMethod) = paymentMethodSelection,
            let ephemeralKey = configuration.customer?.ephemeralKeySecret
        else {
            return
        }
        configuration.apiClient.detachPaymentMethod(
            paymentMethod.stripeId, fromCustomerUsing: ephemeralKey
        ) { (_) in
            // no-op
        }
        if !savedPaymentOptionsViewController.hasRemovablePaymentMethods {
            savedPaymentOptionsViewController.isRemovingPaymentMethods = false
            // calling updateUI() at this point causes an issue with the height of the add card vc
            // if you do a subsequent presentation. Since bottom sheet height stuff is complicated,
            // just update the nav bar which is all we need to do anyway
            configureNavBar()
        }
    }

    // MARK: Helpers
    func configureEditSavedPaymentMethodsButton() {
        if savedPaymentOptionsViewController.isRemovingPaymentMethods {
            navigationBar.additionalButton.setTitle(UIButton.doneButtonTitle, for: .normal)
            buyButton.update(state: .disabled)
        } else {
            buyButton.update(state: .enabled)
            navigationBar.additionalButton.setTitle(UIButton.editButtonTitle, for: .normal)
        }
        navigationBar.additionalButton.addTarget(
            self, action: #selector(didSelectEditSavedPaymentMethodsButton), for: .touchUpInside)
    }

    @objc
    func didSelectEditSavedPaymentMethodsButton() {
        savedPaymentOptionsViewController.isRemovingPaymentMethods.toggle()
        configureEditSavedPaymentMethodsButton()
    }
}

// MARK: - AddPaymentMethodViewControllerDelegate
/// :nodoc:
extension PaymentSheetViewController: AddPaymentMethodViewControllerDelegate {
    func didUpdate(_ viewController: AddPaymentMethodViewController) {
        error = nil  // clear error
        updateUI()
    }

}

// MARK: - SheetNavigationBarDelegate
/// :nodoc:
extension PaymentSheetViewController: SheetNavigationBarDelegate {
    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
        delegate?.paymentSheetViewControllerDidCancel(self)
        // If the customer was editing saved payment methods, exit edit mode
        if savedPaymentOptionsViewController.isRemovingPaymentMethods {
            savedPaymentOptionsViewController.isRemovingPaymentMethods = false
            configureEditSavedPaymentMethodsButton()
        }

    }

    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {
        // This is quite hardcoded. Could make some generic "previous state" or "previous VC" that we always go back to
        switch mode {
        case .addingNew:
            error = nil
            mode = .selectingSaved
            updateUI()
        default:
            assertionFailure()
        }
    }
}
