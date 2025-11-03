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

            rowButton.isSelected = isSelected
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

    private var isEditing: Bool {
        switch state {
        case .selected, .unselected:
            return false
        case .editing:
            return true
        }
    }

    private(set) var previousSelectedState: State = .unselected

    // MARK: Private views

    private(set) lazy var chevronButton: RowButton.RightAccessoryButton = {
        let chevronButton = RowButton.RightAccessoryButton(accessoryType: .update, appearance: appearance, didTap: handleUpdateButtonTapped)
        chevronButton.isHidden = !isEditing
        return chevronButton
    }()

    private(set) lazy var rowButton: RowButton = {
        let button: RowButton = .makeForSavedPaymentMethod(paymentMethod: paymentMethod, appearance: appearance, badgeText: badgeText, accessoryView: chevronButton, didTap: handleRowButtonTapped)

        return button
    }()

    private lazy var badgeText: String? = {
        return showDefaultPMBadge ? String.Localized.default_text : nil
    }()

    init(paymentMethod: STPPaymentMethod,
         appearance: PaymentSheet.Appearance,
         showDefaultPMBadge: Bool = false,
         previousSelectedState: State = .unselected,
         currentState: State = .unselected) {
        self.paymentMethod = paymentMethod
        self.appearance = appearance
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
}
