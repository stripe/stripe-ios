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
    private let paymentMethods: [STPPaymentMethod]

    private var isEditingPaymentMethods: Bool = false {
        didSet {
            let additionalButtonTitle = isEditingPaymentMethods ? UIButton.doneButtonTitle : UIButton.editButtonTitle
            navigationBar.additionalButton.setTitle(additionalButtonTitle, for: .normal)
            headerLabel.text = headerText

            // If we are entering edit mode, put all buttons in an edit state, otherwise put back in their previous state
            if isEditingPaymentMethods {
                paymentMethodRows.forEach { $0.state = .editing }
            } else {
                paymentMethodRows.forEach { $0.state = $0.previousState }
            }
            // TODO(porter) Handle case where we delete the selected card
        }
    }

    private var headerText: String {
        if isEditingPaymentMethods {
            return .Localized.manage_payment_methods
        }

        let nonCardPaymentMethods = paymentMethods.filter({ $0.type != .card })
        return nonCardPaymentMethods.isEmpty ? .Localized.select_card : .Localized.select_payment_method
    }

    // MARK: Internal properties
    weak var delegate: VerticalSavedPaymentMethodsViewControllerDelegate?

    // MARK: - UI properties

    lazy var navigationBar: SheetNavigationBar = {
        let navBar = SheetNavigationBar(isTestMode: configuration.apiClient.isTestmode,
                                        appearance: configuration.appearance)
        // TODO(porter) Only show edit button if we should
        navBar.setStyle(.back(showAdditionalButton: true))
        navBar.delegate = self
        navBar.additionalButton.configureCommonEditButton(isEditingPaymentMethods: isEditingPaymentMethods)
        // TODO(porter) Read color from new secondary action color from appearance
        navBar.additionalButton.setTitleColor(configuration.appearance.colors.primary, for: .normal)
        navBar.additionalButton.setTitleColor(configuration.appearance.colors.primary.disabledColor, for: .disabled)
        navBar.additionalButton.addTarget(self, action: #selector(didSelectEditSavedPaymentMethodsButton), for: .touchUpInside)
        return navBar
    }()

    private lazy var headerLabel: UILabel = {
        let label = PaymentSheetUI.makeHeaderLabel(appearance: configuration.appearance)
        label.text = headerText
        return label
    }()

    private lazy var paymentMethodRows: [PaymentMethodRowButton] = {
        return paymentMethods.map { paymentMethod in
            let button = PaymentMethodRowButton(paymentMethod: paymentMethod, appearance: configuration.appearance)
            button.delegate = self
            return button
        }
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [headerLabel] + paymentMethodRows)
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.setCustomSpacing(16, after: headerLabel)
        return stackView
    }()

    init(configuration: PaymentSheet.Configuration, paymentMethods: [STPPaymentMethod]) {
        self.configuration = configuration
        self.paymentMethods = paymentMethods
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = configuration.appearance.colors.background
        configuration.style.configure(self)
        // TODO(porter) Pipe in selected payment method, default to selecting first for now
        paymentMethodRows.first?.state = .selected
        view.addAndPinSubview(stackView, insets: PaymentSheetUI.defaultSheetMargins)
    }

    @objc func didSelectEditSavedPaymentMethodsButton() {
        isEditingPaymentMethods = !isEditingPaymentMethods
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

    func didSelectButton(_ button: PaymentMethodRowButton, with paymentMethod: STPPaymentMethod) {
        // Deselect previous button        
        paymentMethodRows.first { $0 != button && $0.isSelected }?.state = .unselected

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

    func didSelectRemoveButton(_ button: PaymentMethodRowButton, with paymentMethod: STPPaymentMethod) {
        print("Remove payment method with id: \(paymentMethod.stripeId)")
    }

    func didSelectEditButton(_ button: PaymentMethodRowButton, with paymentMethod: STPPaymentMethod) {
        print("Edit payment method with id: \(paymentMethod.stripeId)")
    }
}
