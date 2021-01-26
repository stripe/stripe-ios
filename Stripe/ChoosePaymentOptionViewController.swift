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
    func choosePaymentOptionViewController(_ choosePaymentOptionViewController: ChoosePaymentOptionViewController, shouldAddPaymentMethod paymentMethodParams: STPPaymentMethodParams, completion: @escaping ((Result<STPPaymentMethod, Error>) -> Void))
    func choosePaymentOptionViewControllerShouldClose(_ choosePaymentOptionViewController: ChoosePaymentOptionViewController)
}

class ChoosePaymentOptionViewController: UIViewController {
    // MARK: - Internal Properties
    let paymentIntent: STPPaymentIntent
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
    private var mode: Mode {
        didSet(previousState) {
            updateUI()
        }
    }
    private var isSavingInProgress: Bool = false

    // MARK: - Views
    private lazy var addPaymentMethodViewController: AddPaymentMethodViewController = {
        return AddPaymentMethodViewController(paymentMethodTypes: paymentIntent.paymentMethodTypesSet,
                                              isGuestMode: savedPaymentOptionsViewController.customerID == nil,
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
            callToAction: .pay(amount: paymentIntent.amount, currency: paymentIntent.currency),
            didTap: didTapAddButton)
        return button
    }()

    // MARK: - Init

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(paymentIntent: STPPaymentIntent,
                  savedPaymentMethods: [STPPaymentMethod],
                  configuration: PaymentSheet.Configuration,
                  isApplePayEnabled: Bool,
                  delegate: ChoosePaymentOptionViewControllerDelegate) {
        self.paymentIntent = paymentIntent
        self.savedPaymentOptionsViewController = SavedPaymentOptionsViewController(savedPaymentMethods: savedPaymentMethods,
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
        let stackView = UIStackView(arrangedSubviews: [headerLabel, paymentContainerView, errorLabel, confirmButton,])
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
        paymentContainerView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: -PaymentSheetUI.defaultSheetMargins.leading, bottom: 0, trailing: -PaymentSheetUI.defaultSheetMargins.trailing)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -PaymentSheetUI.defaultSheetMargins.bottom),
        ])

        updateUI()
    }

    // MARK: - Private Methods

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

        // Configure nav bar
        navigationBar.setStyle({
            switch mode {
            case .selectingSaved:
                return .close
            case .addingNew:
                return savedPaymentOptionsViewController.hasPaymentOptions ? .back : .close
            }
        }())

        headerLabel.text = mode == .selectingSaved ?
            STPLocalizedString("Select your payment method", "Title shown above a carousel containing the customer's payment methods") :
            STPLocalizedString("Add a card", "Title shown above a card entry form")

        // Content
        switchContentIfNecessary(
            to: mode == .selectingSaved ? savedPaymentOptionsViewController : addPaymentMethodViewController,
            containerView: paymentContainerView
        )

        // Error
        errorLabel.text = error?.localizedDescription
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
                callToAction: .add,
                animated: true
            )
        }
    }

    @objc
    private func didTapAddButton() {
        guard case let .new(paymentMethodParams, shouldSave) = selectedPaymentOption else {
            assertionFailure()
            return
        }
        // Just dismiss if we don't want to save, there's nothing to do
        guard shouldSave else {
            self.confirmButton.update(state: .disabled) // Disable the confirm button until the next time updateUI() is called and the button state is re-calculated
            self.delegate?.choosePaymentOptionViewControllerShouldClose(self)
            return
        }

        // Create and save the Payment Method
        isSavingInProgress = true
        // Clear any errors
        error = nil
        updateUI()

        let startTime = NSDate.timeIntervalSinceReferenceDate
        self.delegate?.choosePaymentOptionViewController(self, shouldAddPaymentMethod: paymentMethodParams) { result in
            let elapsedTime = NSDate.timeIntervalSinceReferenceDate - startTime
            DispatchQueue.main.asyncAfter(deadline: .now() + max(PaymentSheetUI.minimumFlightTime - elapsedTime, 0)) {
                self.isSavingInProgress = false
                switch result {
                case let .failure(error):
                    self.error = error
                    sendEventToSubviews(.shouldDisplayError(error), from: self.view)
                    self.updateUI()
                    UIAccessibility.post(notification: .layoutChanged, argument: self.errorLabel)
                case let .success(newPaymentMethod):
                    self.confirmButton.update(state: .succeeded, animated: true)
                    // Wait for confirm button to finish animating before closing the sheet
                    DispatchQueue.main.asyncAfter(deadline: .now() + PaymentSheetUI.delayBetweenSuccessAndDismissal) {
                        // Update saved PMs carousel with the new payment method
                        self.savedPaymentOptionsViewController.savedPaymentMethods.insert(newPaymentMethod, at: 0)
                        self.delegate?.choosePaymentOptionViewControllerShouldClose(self)
                        // Switch to the saved PMs carousel
                        self.mode = .selectingSaved
                        // Reset the Add PM view
                        self.addPaymentMethodViewController.removeFromParent()
                        self.addPaymentMethodViewController = AddPaymentMethodViewController(
                            paymentMethodTypes: self.paymentIntent.paymentMethodTypesSet,
                            isGuestMode: self.savedPaymentOptionsViewController.customerID == nil,
                            billingAddressCollection: self.configuration.billingAddressCollectionLevel,
                            merchantDisplayName: self.configuration.merchantDisplayName,
                            delegate: self)
                    }
                }
            }
        }
    }

    func didDismiss() {
        // If the customer was adding a new payment method and it's incomplete/invalid, return to the saved PM screen
        delegate?.choosePaymentOptionViewControllerShouldClose(self)
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
    func didUpdateSelection(viewController: SavedPaymentOptionsViewController, paymentMethodSelection: SavedPaymentOptionsViewController.Selection) {
        guard case Mode.selectingSaved = mode else {
            assertionFailure()
            return
        }
        switch paymentMethodSelection {
        case .add:
            mode = .addingNew
        case .applePay:
            fallthrough
        case .saved:
            updateUI()
            if isDismissable {
                delegate?.choosePaymentOptionViewControllerShouldClose(self)
            }
        }
    }
}

//MARK: - AddPaymentMethodViewControllerDelegate
/// :nodoc:
extension ChoosePaymentOptionViewController: AddPaymentMethodViewControllerDelegate {
    func didUpdatePaymentMethodParams(_ viewController: AddPaymentMethodViewController) {
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
            mode = .selectingSaved
        default:
            assertionFailure()
        }
    }
}
