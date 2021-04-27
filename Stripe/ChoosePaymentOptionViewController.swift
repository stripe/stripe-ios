//
//  ChoosePaymentOptionViewController.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 11/4/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

protocol ChoosePaymentOptionViewControllerDelegate: AnyObject {
    func choosePaymentOptionViewControllerShouldClose(
        _ choosePaymentOptionViewController: ChoosePaymentOptionViewController)
}

class ChoosePaymentOptionViewController: UIViewController {
    // MARK: - Internal Properties
    let intent: Intent
    let configuration: PaymentSheet.Configuration
    var savedPaymentMethods: [STPPaymentMethod] {
        return savedPaymentOptionsViewController.savedPaymentMethods
    }
    var selectedPaymentOption: PaymentOption? {
        switch mode {
        case .addingNew:
            if let paymentOption = addPaymentMethodViewController.paymentOption {
                return paymentOption
            }
            return nil
        case .selectingSaved:
            return savedPaymentOptionsViewController.selectedPaymentOption
        }
    }
    var selectedPaymentMethodType: STPPaymentMethodType {
        return addPaymentMethodViewController.selectedPaymentMethodType
    }
    weak var delegate: ChoosePaymentOptionViewControllerDelegate?
    lazy var navigationBar: SheetNavigationBar = {
        let navBar = SheetNavigationBar()
        navBar.delegate = self
        return navBar
    }()
    private(set) var error: Error?
    private(set) var isDismissable: Bool = true

    // MARK: - Private Properties
    enum Mode {
        case selectingSaved
        case addingNew
    }
    private var mode: Mode
    private var isSavingInProgress: Bool = false

    // MARK: - Views
    private lazy var addPaymentMethodViewController: AddPaymentMethodViewController = {
        let paymentMethodTypes = PaymentSheet.paymentMethodTypes(
            for: intent,
            customerID: savedPaymentOptionsViewController.customerID
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
    private let savedPaymentOptionsViewController: SavedPaymentOptionsViewController
    private lazy var headerLabel: UILabel = {
        return PaymentSheetUI.makeHeaderLabel()
    }()
    private lazy var paymentContainerView: BottomPinningContainerView = {
        return BottomPinningContainerView()
    }()
    private lazy var errorLabel: UILabel = {
        return PaymentSheetUI.makeErrorLabel()
    }()
    private lazy var confirmButton: ConfirmButton = {
        let button = ConfirmButton(
            style: .stripe,
            callToAction: .add(paymentMethodType: selectedPaymentMethodType),
            didTap: didTapAddButton
        )
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
        delegate: ChoosePaymentOptionViewControllerDelegate
    ) {
        self.intent = intent
        self.savedPaymentOptionsViewController = SavedPaymentOptionsViewController(
            savedPaymentMethods: savedPaymentMethods,
            customerID: configuration.customer?.id,
            isApplePayEnabled: isApplePayEnabled)
        self.configuration = configuration
        self.delegate = delegate

        if savedPaymentMethods.count > 0 || isApplePayEnabled {
            self.mode = .selectingSaved
        } else {
            self.mode = .addingNew
        }

        super.init(nibName: nil, bundle: nil)
        self.savedPaymentOptionsViewController.delegate = self
    }

    // MARK: - UIViewController Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        // One stack view contains all our subviews
        let stackView = UIStackView(arrangedSubviews: [
            headerLabel, paymentContainerView, errorLabel, confirmButton,
        ])
        stackView.bringSubviewToFront(headerLabel)
        stackView.directionalLayoutMargins = PaymentSheetUI.defaultMargins
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.spacing = PaymentSheetUI.defaultPadding
        stackView.axis = .vertical
        [stackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        // Get our margins in order
        view.directionalLayoutMargins = PaymentSheetUI.defaultSheetMargins
        // Hack: Payment container needs to extend to the edges, so we'll 'cancel out' the layout margins with negative padding
        paymentContainerView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 0, leading: -PaymentSheetUI.defaultSheetMargins.leading, bottom: 0,
            trailing: -PaymentSheetUI.defaultSheetMargins.trailing)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor, constant: -PaymentSheetUI.defaultSheetMargins.bottom),
        ])

        updateUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        STPAnalyticsClient.sharedClient.logPaymentSheetShow(isCustom: true, paymentMethod: mode.analyticsValue)
    }

    // MARK: - Private Methods

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
                    return savedPaymentOptionsViewController.hasPaymentOptions
                        ? .back : .close(showAdditionalButton: false)
                }
            }())
    }

    // state -> view
    private func updateUI() {
        // Disable interaction if necessary
        if isSavingInProgress {
            sendEventToSubviews(.shouldDisableUserInteraction, from: view)
            isDismissable = false
        } else {
            sendEventToSubviews(.shouldEnableUserInteraction, from: view)
            isDismissable = true
        }

        configureNavBar()

        headerLabel.text = {
            switch mode {
            case .selectingSaved:
                return STPLocalizedString(
                    "Select your payment method",
                    "Title shown above a carousel containing the customer's payment methods")
            case .addingNew:
                if addPaymentMethodViewController.paymentMethodTypes == [.card] {
                    return STPLocalizedString("Add a card", "Title shown above a card entry form")
                } else {
                    return STPLocalizedString("Choose a payment method", "TODO")
                }
            }
        }()

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
        switch mode {
        case .selectingSaved:
            UIView.animate(withDuration: PaymentSheetUI.defaultAnimationDuration) {
                // We're selecting a saved PM, there's no 'Add' button
                self.confirmButton.alpha = 0
                self.confirmButton.isHidden = true
            }
        case .addingNew:
            // Configure add button
            if confirmButton.isHidden {
                confirmButton.alpha = 0
                UIView.animate(withDuration: PaymentSheetUI.defaultAnimationDuration) {
                    self.confirmButton.alpha = 1
                    self.confirmButton.isHidden = false
                }
            }
            let confirmButtonState: ConfirmButton.Status = {
                if isSavingInProgress {
                    // We're in the middle of adding the PM
                    return .processing
                } else if addPaymentMethodViewController.paymentOption == nil {
                    // We don't have valid payment method params yet
                    return .disabled
                } else {
                    return .enabled
                }
            }()
            confirmButton.update(
                state: confirmButtonState,
                callToAction: .add(paymentMethodType: selectedPaymentMethodType),
                animated: true
            )
        }
    }

    @objc
    private func didTapAddButton() {
        guard case .new = selectedPaymentOption else {
            assertionFailure()
            return
        }
        self.confirmButton.update(state: .disabled)  // Disable the confirm button until the next time updateUI() is called and the button state is re-calculated
        self.delegate?.choosePaymentOptionViewControllerShouldClose(self)
    }

    func didDismiss() {
        // If the customer was adding a new payment method and it's incomplete/invalid, return to the saved PM screen
        delegate?.choosePaymentOptionViewControllerShouldClose(self)
        if savedPaymentOptionsViewController.isRemovingPaymentMethods {
            savedPaymentOptionsViewController.isRemovingPaymentMethods = false
            configureEditSavedPaymentMethodsButton()
        }
    }
}

// MARK: - BottomSheetContentViewController
/// :nodoc:
extension ChoosePaymentOptionViewController: BottomSheetContentViewController {
    var allowsDragToDismiss: Bool {
        return isDismissable
    }

    func didTapOrSwipeToDismiss() {
        if isDismissable {
            didDismiss()
        }
    }

    var requiresFullScreen: Bool {
        return false
    }
}

//MARK: - SavedPaymentOptionsViewControllerDelegate
/// :nodoc:
extension ChoosePaymentOptionViewController: SavedPaymentOptionsViewControllerDelegate {
    func didUpdateSelection(
        viewController: SavedPaymentOptionsViewController,
        paymentMethodSelection: SavedPaymentOptionsViewController.Selection
    ) {
        STPAnalyticsClient.sharedClient.logPaymentSheetPaymentOptionSelect(isCustom: true, paymentMethod: paymentMethodSelection.analyticsValue)
        guard case Mode.selectingSaved = mode else {
            assertionFailure()
            return
        }
        switch paymentMethodSelection {
        case .add:
            mode = .addingNew
            error = nil // Clear any errors
            updateUI()
        case .applePay, .saved:
            updateUI()
            if isDismissable {
                delegate?.choosePaymentOptionViewControllerShouldClose(self)
            }
        }

        
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
        } else {
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

//MARK: - AddPaymentMethodViewControllerDelegate
/// :nodoc:
extension ChoosePaymentOptionViewController: AddPaymentMethodViewControllerDelegate {
    func didUpdate(_ viewController: AddPaymentMethodViewController) {
        error = nil  // clear error
        updateUI()
    }

}
//MARK: - SheetNavigationBarDelegate
/// :nodoc:
extension ChoosePaymentOptionViewController: SheetNavigationBarDelegate {
    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
        didDismiss()
    }

    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {
        // This is quite hardcoded. Could make some generic "previous mode" or "previous VC" that we always go back to
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
