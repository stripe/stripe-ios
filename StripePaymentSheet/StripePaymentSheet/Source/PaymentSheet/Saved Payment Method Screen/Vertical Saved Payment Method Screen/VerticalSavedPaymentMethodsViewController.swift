//
//  VerticalSavedPaymentMethodsViewController.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 5/7/24.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

protocol VerticalSavedPaymentMethodsViewControllerDelegate: AnyObject {
    func didSelectPaymentMethod(_ paymentMethod: STPPaymentMethod)
}

/// A view controller that shows a list of saved payment methods in a vertical orientation
class VerticalSavedPaymentMethodsViewController: UIViewController {

    private let configuration: PaymentSheet.Configuration

    private var isEditingPaymentMethods: Bool = false {
        didSet {
            let additionalButtonTitle = isEditingPaymentMethods ? UIButton.doneButtonTitle : UIButton.editButtonTitle
            navigationBar.additionalButton.setTitle(additionalButtonTitle, for: .normal)
            headerLabel.text = headerText

            // If we are entering edit mode, put all buttons in an edit state, otherwise put back in their previous state
            if isEditingPaymentMethods {
                paymentMethodRows.forEach { $0.button.state = .editing(allowsRemoval: canRemovePaymentMethods,
                                                                       allowsUpdating: $0.paymentMethod.isCoBrandedCard) }
            } else {
                paymentMethodRows.map { $0.button }.forEach { $0.state = $0.previousState }
                navigationBar.setStyle(.back(showAdditionalButton: canEdit)) // Hide edit button if needed
                // If we removed the selected payment method select the first
                if selectedPaymentMethod == nil {
                    paymentMethodRows.first?.button.state = .selected
                }
            }
        }
    }

    private var headerText: String {
        if isEditingPaymentMethods {
            return .Localized.manage_payment_methods
        }

        let nonCardPaymentMethods = paymentMethodRows.filter({ $0.paymentMethod.type != .card })
        return nonCardPaymentMethods.isEmpty ? .Localized.select_card : .Localized.select_payment_method
    }
    
    private var canRemovePaymentMethods: Bool {
        // Can remove a payment method if we have more than one payment method or if we have one payment method and `allowsRemovalOfLastSavedPaymentMethod` is true
        return paymentMethodRows.count > 1 ? true : configuration.allowsRemovalOfLastSavedPaymentMethod
    }
    
    private var canEdit: Bool {
        let hasCoBrandedCards = !paymentMethodRows.filter{$0.paymentMethod.isCoBrandedCard}.isEmpty
        // We can edit if there are removable or editable payment methods
        return canRemovePaymentMethods || hasCoBrandedCards
    }
    
    private var selectedPaymentMethod: STPPaymentMethod? {
        return paymentMethodRows.first {$0.button.isSelected}?.paymentMethod
    }

    // MARK: Internal properties
    weak var delegate: VerticalSavedPaymentMethodsViewControllerDelegate?

    // MARK: - UI properties

    lazy var navigationBar: SheetNavigationBar = {
        let navBar = SheetNavigationBar(isTestMode: configuration.apiClient.isTestmode,
                                        appearance: configuration.appearance)
        navBar.setStyle(.back(showAdditionalButton: canEdit))
        navBar.delegate = self
        navBar.additionalButton.setTitle(UIButton.editButtonTitle, for: .normal)
        navBar.additionalButton.accessibilityIdentifier = "edit_saved_button"
        navBar.additionalButton.titleLabel?.adjustsFontForContentSizeCategory = true
        navBar.additionalButton.addTarget(self, action: #selector(didSelectEditSavedPaymentMethodsButton), for: .touchUpInside)
        return navBar
    }()

    private lazy var headerLabel: UILabel = {
        let label = PaymentSheetUI.makeHeaderLabel(appearance: configuration.appearance)
        label.text = headerText
        return label
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [headerLabel] + paymentMethodRows.map { $0.button })
        stackView.directionalLayoutMargins = PaymentSheetUI.defaultMargins
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.setCustomSpacing(16, after: headerLabel)
        return stackView
    }()

    private var paymentMethodRows: [(paymentMethod: STPPaymentMethod, button: PaymentMethodRowButton)] = []
    
    init(configuration: PaymentSheet.Configuration, paymentMethods: [STPPaymentMethod]) {
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
        self.paymentMethodRows = buildPaymentMethodRows(paymentMethods: paymentMethods)
    }
    
    private func buildPaymentMethodRows(paymentMethods: [STPPaymentMethod]) -> [(paymentMethod: STPPaymentMethod, button: PaymentMethodRowButton)] {
        return paymentMethods.map { paymentMethod in
            let button = PaymentMethodRowButton(viewModel: .init(appearance: configuration.appearance,
                                                                 text: paymentMethod.paymentSheetLabel,
                                                                 image: paymentMethod.makeSavedPaymentMethodRowImage()))
            button.delegate = self
            return (paymentMethod, button)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = configuration.appearance.colors.background
        configuration.style.configure(self)
        // TODO(porter) Pipe in selected payment method, default to selecting first for now
        paymentMethodRows.first?.button.state = .selected
        view.addAndPinSubviewToSafeArea(stackView, insets: PaymentSheetUI.defaultSheetMargins)
    }

    @objc func didSelectEditSavedPaymentMethodsButton() {
        isEditingPaymentMethods = !isEditingPaymentMethods
    }
    
    func remove(paymentMethod: STPPaymentMethod) {
        guard let button = paymentMethodRows.first(where: {$0.paymentMethod.stripeId == paymentMethod.stripeId})?.button,
                let ephemeralKeySecret = configuration.customer?.ephemeralKeySecret else { return }
        
        // Detach the payment method from the customer
        let manager = SavedPaymentMethodManager(configuration: configuration)
        manager.detach(paymentMethod: paymentMethod, using: ephemeralKeySecret)
        
        // Remove the payment method row button
        paymentMethodRows.removeAll{button === $0.button}
        stackView.removeArrangedSubview(button, animated: true)
        
        // If deleted the last payment method kick back out to the main screen
        if self.paymentMethodRows.isEmpty {
            _ = self.bottomSheetController?.popContentViewController()
        } else if !canEdit {
            // If we can no longer edit, exit edit mode and hide edit button
            isEditingPaymentMethods = false
        }
    }
}

// MARK: - BottomSheetContentViewController
extension VerticalSavedPaymentMethodsViewController: BottomSheetContentViewController {
    var allowsDragToDismiss: Bool {
        return true
    }

    func didTapOrSwipeToDismiss() {
        dismiss(animated: true)
    }

    var requiresFullScreen: Bool {
        return false
    }

    func didFinishAnimatingHeight() {
        // no-op
    }
}

// MARK: - SheetNavigationBarDelegate
extension VerticalSavedPaymentMethodsViewController: SheetNavigationBarDelegate {
    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
        // no-op we are in 'back' style mode
    }

    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {
        _ = bottomSheetController?.popContentViewController()
    }
}

// MARK: - PaymentMethodRowButtonDelegate
extension VerticalSavedPaymentMethodsViewController: PaymentMethodRowButtonDelegate {

    private func paymentMethod(from button: PaymentMethodRowButton) -> STPPaymentMethod? {
        return paymentMethodRows.first(where: { $0.button === button })?.paymentMethod
    }

    func didSelectButton(_ button: PaymentMethodRowButton) {
        guard let paymentMethod = paymentMethod(from: button) else {
            // TODO(porter) Handle error - no matching payment method found
            return
        }

        // Deselect previous button        
        paymentMethodRows.first { $0.button != button && $0.button.isSelected }?.button.state = .unselected

        // Disable interaction to prevent double selecting since we will be dismissing soon
        self.view.isUserInteractionEnabled = false
        self.navigationBar.isUserInteractionEnabled = false // Tint buttons in the nav bar to look disabled

        // Give time for new selected row to show it has been selected before dismissing
        // Makes UX feel a little nicer
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            _ = self?.bottomSheetController?.popContentViewController()
            self?.delegate?.didSelectPaymentMethod(paymentMethod)
        }
    }

    func didSelectRemoveButton(_ button: PaymentMethodRowButton) {
        guard let paymentMethod = paymentMethod(from: button) else {
            // TODO(porter) Handle error - no matching payment method found
            return
        }

        let alertController = UIAlertController.makeRemoveAlertController(paymentMethod: paymentMethod,
                                                                          removeSavedPaymentMethodMessage: configuration.removeSavedPaymentMethodMessage) { [weak self] in
            guard let self = self else { return }
            self.remove(paymentMethod: paymentMethod)
        }
        
        present(alertController, animated: true, completion: nil)
    }

    func didSelectEditButton(_ button: PaymentMethodRowButton) {
        guard let paymentMethod = paymentMethod(from: button) else {
            // TODO(porter) Handle error - no matching payment method found
            // TODO(porter) Don't forget to hide the remove button on the update VC if w.r.t to allowsRemovalOfLastSavedPM
            return
        }

        print("Edit payment method with id: \(paymentMethod.stripeId)")
    }
}
