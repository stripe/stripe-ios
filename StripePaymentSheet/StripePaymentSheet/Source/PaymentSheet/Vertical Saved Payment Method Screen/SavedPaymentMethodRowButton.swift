//
//  SavedPaymentMethodRowButton.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 5/9/24.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

protocol SavedPaymentMethodRowButtonDelegate: AnyObject {
    func didSelectButton(_ button: SavedPaymentMethodRowButton, with paymentMethod: STPPaymentMethod)
    func didSelectUpdateButton(_ button: SavedPaymentMethodRowButton, with paymentMethod: STPPaymentMethod)
}

final class SavedPaymentMethodRowButton: UIView {

    enum State: Equatable {
        case selected
        case unselected
        case editing(allowsRemoval: Bool, allowsUpdating: Bool)
    }

    // MARK: Internal properties

    let paymentMethod: STPPaymentMethod
    let showDefaultPMBadge: Bool
    weak var delegate: SavedPaymentMethodRowButtonDelegate?

    var state: State = .unselected {
        didSet {
            if oldValue == .selected || oldValue == .unselected {
                previousSelectedState = oldValue
            }

            // saved payment methods never show a form
            rowButton.updateSelectedState(isSelected, willDisplayForm: false)
            chevronButton.isHidden = !isEditing
        }
    }

    var isSelected: Bool {
        switch state {
        case .selected:
            return true
        case .unselected, .editing:
            return false
        }
    }

    // MARK: - Private properties

    private let appearance: PaymentSheet.Appearance
    private var linkBrand: LinkBrand

    private var isEditing: Bool {
        switch state {
        case .selected, .unselected:
            return false
        case .editing:
            return true
        }
    }

    private(set) var previousSelectedState: State = .unselected

    private(set) var isLoading: Bool = false

    // MARK: Private views

    private lazy var spinner: ActivityIndicator = {
        let spinner = ActivityIndicator(size: .medium)
        spinner.tintColor = appearance.colors.primary
        spinner.translatesAutoresizingMaskIntoConstraints = false
        return spinner
    }()

    private(set) lazy var chevronButton: RowButton.RightAccessoryButton = {
        let chevronButton = RowButton.RightAccessoryButton(accessoryType: .update, appearance: appearance, didTap: handleUpdateButtonTapped)
        chevronButton.isHidden = !isEditing
        return chevronButton
    }()

    private(set) lazy var rowButton: RowButton = {
        let button: RowButton = .makeForSavedPaymentMethod(
            paymentMethod: paymentMethod,
            appearance: appearance,
            badgeText: badgeText,
            accessoryView: chevronButton,
            linkBrand: linkBrand,
            didTap: handleRowButtonTapped
        )

        return button
    }()

    private lazy var badgeText: String? = {
        return showDefaultPMBadge ? String.Localized.default_text : nil
    }()

    init(paymentMethod: STPPaymentMethod,
         appearance: PaymentSheet.Appearance,
         linkBrand: LinkBrand = .link,
         showDefaultPMBadge: Bool = false,
         previousSelectedState: State = .unselected,
         currentState: State = .unselected) {
        self.paymentMethod = paymentMethod
        self.appearance = appearance
        self.linkBrand = linkBrand
        self.showDefaultPMBadge = showDefaultPMBadge
        self.previousSelectedState = previousSelectedState
        self.state = currentState
        super.init(frame: .zero)

        addAndPinSubview(rowButton)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Tap handlers
    @objc private func handleUpdateButtonTapped() {
        delegate?.didSelectUpdateButton(self, with: paymentMethod)
    }

    @objc private func handleRowButtonTapped(_: RowButton) {
        if isEditing {
            delegate?.didSelectUpdateButton(self, with: paymentMethod)
        } else {
            state = .selected
            delegate?.didSelectButton(self, with: paymentMethod)
        }
    }

    /// Shows or hides a small trailing spinner and dims the row while work is in flight.
    func setLoading(_ loading: Bool) {
        guard loading != isLoading else { return }
        isLoading = loading

        if loading {
            addSubview(spinner)
            NSLayoutConstraint.activate([
                spinner.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
                spinner.centerYAnchor.constraint(equalTo: centerYAnchor),
            ])
            spinner.startAnimating()
            rowButton.alpha = 0.6
        } else {
            spinner.stopAnimating()
            spinner.removeFromSuperview()
            rowButton.alpha = 1.0
        }
    }

    func updateLinkBrand(_ linkBrand: LinkBrand) {
        guard self.linkBrand != linkBrand else {
            return
        }
        self.linkBrand = linkBrand

        guard paymentMethod.isLinkPassthroughMode else {
            return
        }

        rowButton.setLabel(text: linkBrand.displayName)
        rowButton.setSublabel(text: paymentMethod.paymentSheetLabel(brand: linkBrand), animated: false)
    }
}
