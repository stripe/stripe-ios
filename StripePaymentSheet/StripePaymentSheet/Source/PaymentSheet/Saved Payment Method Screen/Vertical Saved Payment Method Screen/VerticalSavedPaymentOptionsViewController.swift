//
//  VerticalSavedPaymentOptionsViewController.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 5/7/24.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
@_spi(STP) import StripePaymentsUI
import UIKit

/// A view controller that shows a list of saved payment methods in a vertical orientation
class VerticalSavedPaymentOptionsViewController: UIViewController {

    private let configuration: PaymentSheet.Configuration
    private let paymentMethods: [STPPaymentMethod]

    // MARK: - UI properties

    lazy var navigationBar: SheetNavigationBar = {
        let navBar = SheetNavigationBar(isTestMode: configuration.apiClient.isTestmode,
                                        appearance: configuration.appearance)
        navBar.setStyle(.back)
        navBar.delegate = self
        return navBar
    }()

    private lazy var headerLabel: UILabel = {
        let label = PaymentSheetUI.makeHeaderLabel(appearance: configuration.appearance)
        label.text = .Localized.select_payment_method
        return label
    }()
    
    private lazy var paymentMethodRows: [PaymentMethodRowButton] = {
        return paymentMethods.map {
            let button = PaymentMethodRowButton(viewModel: .init(appearance: configuration.appearance,
                                                                 text: $0.paymentSheetLabel,
                                                                 image: $0.makeSavedPaymentMethodRowImage()))
            button.delegate = self
            return button
        }
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [headerLabel] + paymentMethodRows)
        stackView.directionalLayoutMargins = PaymentSheetUI.defaultMargins
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.axis = .vertical
        stackView.spacing = PaymentSheetUI.defaultPadding
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
        paymentMethodRows.first?.isSelected = true
        view.addAndPinSubviewToSafeArea(stackView, insets: PaymentSheetUI.defaultSheetMargins)
    }
}

// MARK: - BottomSheetContentViewController
extension VerticalSavedPaymentOptionsViewController: BottomSheetContentViewController {
    var allowsDragToDismiss: Bool {
        // TODO
        return true
    }

    func didTapOrSwipeToDismiss() {
        dismiss(animated: true)
    }

    var requiresFullScreen: Bool {
        // TODO
        return false
    }

    func didFinishAnimatingHeight() {
        // no-op
    }
}

// MARK: - SheetNavigationBarDelegate
extension VerticalSavedPaymentOptionsViewController: SheetNavigationBarDelegate {
    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
        // no-op we are in 'back' style mode
    }

    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {
        _ = bottomSheetController?.popContentViewController()
    }
}

// MARK: - PaymentMethodRowDelegate
extension VerticalSavedPaymentOptionsViewController: PaymentMethodRowDelegate {
    func didSelectRow(_ row: PaymentMethodRowButton) {
         // TODO(porter) Handle selection, deselect other rows, etc
        // TODO(porter) How do we know which payment method to operate on/which row was tapped
    }
}
