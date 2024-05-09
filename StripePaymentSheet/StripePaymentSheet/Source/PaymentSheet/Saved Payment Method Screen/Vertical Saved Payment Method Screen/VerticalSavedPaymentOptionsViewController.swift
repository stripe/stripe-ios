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

protocol VerticalSavedPaymentOptionsViewControllerDelegate: AnyObject {
    func didSelectPaymentMethod(_ paymentMethod: STPPaymentMethod)
}

/// A view controller that shows a list of saved payment methods in a vertical orientation
class VerticalSavedPaymentOptionsViewController: UIViewController {

    private let configuration: PaymentSheet.Configuration
    private let paymentMethods: [STPPaymentMethod]
    
    // MARK: Internal properties
    weak var delegate: VerticalSavedPaymentOptionsViewControllerDelegate?
    
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
        let nonCardPaymentMethods = paymentMethods.filter({ $0.type != .card })
        label.text = nonCardPaymentMethods.isEmpty ? .Localized.select_card : .Localized.select_payment_method
        return label
    }()
    
    private lazy var paymentMethodRows: [(paymentMethod: STPPaymentMethod, button: PaymentMethodRowButton)] = {
        return paymentMethods.map { paymentMethod in
            let button = PaymentMethodRowButton(viewModel: .init(appearance: configuration.appearance,
                                                                 text: paymentMethod.paymentSheetLabel,
                                                                 image: paymentMethod.makeSavedPaymentMethodRowImage()))
            button.delegate = self
            return (paymentMethod, button)
        }
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [headerLabel] + paymentMethodRows.map{$0.button})
        stackView.directionalLayoutMargins = PaymentSheetUI.defaultMargins
        stackView.isLayoutMarginsRelativeArrangement = true
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
        paymentMethodRows.first?.button.isSelected = true
        view.addAndPinSubviewToSafeArea(stackView, insets: PaymentSheetUI.defaultSheetMargins)
    }
}

// MARK: - BottomSheetContentViewController
extension VerticalSavedPaymentOptionsViewController: BottomSheetContentViewController {
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
extension VerticalSavedPaymentOptionsViewController: SheetNavigationBarDelegate {
    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
        // no-op we are in 'back' style mode
    }

    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {
        _ = bottomSheetController?.popContentViewController()
    }
}

// MARK: - PaymentMethodRowButtonDelegate
extension VerticalSavedPaymentOptionsViewController: PaymentMethodRowButtonDelegate {
    func didSelectButton(_ button: PaymentMethodRowButton) {
        guard let paymentMethod = paymentMethodRows.first(where: { $0.button === button })?.paymentMethod else {
            // TODO(porter) Handle error - no matching payment method found
            return
        }
        
        // Deselect previous button
        paymentMethodRows.filter{$0.button != button && $0.button.isSelected}.forEach{$0.button.isSelected = false}
        
        // Give time for new selected row to show it has been selected before dismissing
        // Makes UX feel a little nicer
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            _ = self?.bottomSheetController?.popContentViewController()
            self?.delegate?.didSelectPaymentMethod(paymentMethod)
        }
    }
}
