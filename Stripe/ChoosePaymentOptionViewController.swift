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
    // MARK: - Read-only Properties
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
    var isDismissable: Bool = true

    // MARK: - Writable Properties
    enum Mode {
        case selectingSaved
        case addingNew
    }
    private var mode: Mode {
        didSet(previousState) {
            updateUI()
        }
    }
    private var error: Error?
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
    lazy var navigationBar: SheetNavigationBar = {
        let navBar = SheetNavigationBar()
        navBar.delegate = self
        return navBar
    }()
    private lazy var headerLabel: UILabel = {
        return PaymentSheetUI.makeHeaderLabel()
    }()
    private lazy var paymentContainerView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
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
        stackView.spacing = PaymentSheetUI.defaultPadding
        stackView.axis = .vertical
        [stackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        // Get our margins in order
        view.preservesSuperviewLayoutMargins = true
        // Hack: Payment container needs to extend to the edges, so we'll 'cancel out' the layout margins with negative padding
        paymentContainerView.layoutMargins = UIEdgeInsets(top: 0, left: -PaymentSheetUI.defaultSheetMargins.leading, bottom: 0, right: -PaymentSheetUI.defaultSheetMargins.trailing)
        paymentContainerView.isLayoutMarginsRelativeArrangement = true

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor),
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

        headerLabel.text = mode == .selectingSaved ? STPLocalizedString("Select a payment method", "TODO") : STPLocalizedString("Add a payment method", "TODO")

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
            // We're selecting a saved PM, there's no 'Add' button
            confirmButton.isHidden = true
        case .addingNew:
            // Configure add button
            confirmButton.isHidden = false
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
}

// MARK: - BottomSheetContentViewController
/// :nodoc:
extension ChoosePaymentOptionViewController: BottomSheetContentViewController {
    var allowsDragToDismiss: Bool {
        return isDismissable
    }

    func didTapOrSwipeToDismiss() {
        if isDismissable {
            delegate?.choosePaymentOptionViewControllerShouldClose(self)
        }
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
            // Fade in the AddPaymentMethodVC
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
        delegate?.choosePaymentOptionViewControllerShouldClose(self)
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
